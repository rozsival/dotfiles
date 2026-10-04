#!/usr/bin/env bash
# macOS preferences, declared once and used two ways:
#   macos/defaults.sh           apply: write whatever drifts, restart what changed
#   macos/defaults.sh --check   read-only drift report (no sudo, no writes, no killall)
#
# Every value mirrors the author's live Mac, except the "Security" overrides
# (quarantine, disk-image verification, hibernatemode, firewall), which
# deliberately restore Apple's safe defaults.
#
# Must run on /bin/bash 3.2: a fresh Mac has no Homebrew bash yet.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: defaults.sh [--check] [--help]

  (no args)  Apply settings. Only settings that differ are written; sudo is
             requested lazily, the first time a system-level setting changes.
  --check    Read-only. Prints "✗ <domain> <key>: have <live> want <desired>"
             per drifting setting. Exit 0 = in sync, 1 = drift.
  --help     This text.
EOF
}

MODE=apply
case "${1:-}" in
"") ;;
--check) MODE=check ;;
-h | --help)
  usage
  exit 0
  ;;
*)
  usage >&2
  exit 2
  ;;
esac
[ "$#" -le 1 ] || {
  usage >&2
  exit 2
}

UNSET="(unset)"
TOTAL=0     # settings examined
DRIFT=0     # settings that differ from the desired value
FIXED=0     # drifting settings successfully written (apply mode)
FAILED=0    # writes that errored (apply mode)
RESTART=" " # space-delimited set of apps to bounce once everything is written
SECTION=""
SECTION_SHOWN=0
SUDO_READY=0
TMP_PLIST=""

cleanup() { [ -z "$TMP_PLIST" ] || rm -f "$TMP_PLIST"; }
trap cleanup EXIT

###############################################################################
# Plumbing                                                                    #
###############################################################################

section() {
  SECTION=$1
  SECTION_SHOWN=0
}

warn() { printf '! %s\n' "$*" >&2; }

# sudo is only ever reached from apply paths; check mode must stay unprivileged.
run_sudo() {
  if [ "$MODE" = check ]; then
    warn "internal error: sudo requested in check mode"
    exit 70
  fi
  if [ "$SUDO_READY" -eq 0 ]; then
    sudo -v
    SUDO_READY=1
  fi
  sudo "$@"
}

# defaults reports booleans as 1/0, so compare in that form.
norm() { # type value
  case "$1" in
  bool)
    case "$2" in
    1 | true | TRUE | yes | YES) echo 1 ;;
    0 | false | FALSE | no | NO) echo 0 ;;
    *) echo "$2" ;;
    esac
    ;;
  *) printf '%s\n' "$2" ;;
  esac
}

# Numbers compare numerically so 0.1 == 0.10 and 80 == 80.000000.
same() { # type have want
  [ "$2" != "$UNSET" ] || return 1
  case "$1" in
  int | float) awk -v a="$2" -v b="$3" 'BEGIN { exit !(a + 0 == b + 0) }' ;;
  *) [ "$2" = "$3" ] ;;
  esac
}

show() { # type value
  if [ "$1" = bool ]; then
    case "$2" in 1)
      echo true
      return
      ;;
    0)
      echo false
      return
      ;;
    esac
  fi
  printf '%s\n' "$2"
}

bool_word() {
  if [ "$1" = 1 ]; then echo true; else echo false; fi
}

# Prints the drift line (check) or the intended change (apply). Returns 0 when
# the caller should perform the write.
handle_drift() { # label type have want
  DRIFT=$((DRIFT + 1))
  if [ "$MODE" = check ]; then
    printf '✗ %s: have %s want %s\n' "$1" "$(show "$2" "$3")" "$(show "$2" "$4")"
    return 1
  fi
  if [ "$SECTION_SHOWN" -eq 0 ]; then
    printf '\n==> %s\n' "$SECTION"
    SECTION_SHOWN=1
  fi
  printf '→ %s: %s → %s\n' "$1" "$(show "$2" "$3")" "$(show "$2" "$4")"
}

record_write() { # exit-status label
  if [ "$1" -eq 0 ]; then
    FIXED=$((FIXED + 1))
  else
    FAILED=$((FAILED + 1))
    warn "failed to write $2"
  fi
}

queue_restart() { # domain key
  local app=""
  case "$1" in
  com.apple.dock | com.apple.WindowManager) app=Dock ;;
  com.apple.finder | com.apple.desktopservices) app=Finder ;;
  com.apple.screencapture) app=SystemUIServer ;;
  NSGlobalDomain)
    case "$2" in
    AppleShowAllExtensions | com.apple.springing.*) app=Finder ;;
    esac
    ;;
  esac
  [ -n "$app" ] || return 0
  case "$RESTART" in
  *" $app "*) ;;
  *) RESTART="$RESTART$app " ;;
  esac
}

###############################################################################
# Preference helpers                                                          #
###############################################################################

read_pref() { # host(0|1) domain key type
  local out
  if [ "$1" = 1 ]; then
    out=$(defaults -currentHost read "$2" "$3" 2>/dev/null) || {
      echo "$UNSET"
      return 0
    }
  else
    out=$(defaults read "$2" "$3" 2>/dev/null) || {
      echo "$UNSET"
      return 0
    }
  fi
  if [ "$4" = int-array ]; then
    # "(\n    4\n)" -> "4"
    out=$(printf '%s' "$out" | tr -d '(),' | tr -s ' \n' ' ')
    out=${out# }
    out=${out% }
  fi
  printf '%s\n' "$out"
}

write_pref() { # host sudo domain key type value
  local -a cmd vals
  cmd=(defaults)
  [ "$1" != 1 ] || cmd+=(-currentHost)
  cmd+=(write "$3" "$4")
  case "$5" in
  bool) cmd+=(-bool "$(bool_word "$6")") ;;
  int) cmd+=(-int "$6") ;;
  float) cmd+=(-float "$6") ;;
  string) cmd+=(-string "$6") ;;
  int-array)
    IFS=' ' read -r -a vals <<<"$6"
    cmd+=(-array "${vals[@]}")
    ;;
  *)
    warn "unknown type $5"
    return 1
    ;;
  esac
  if [ "$2" = 1 ]; then
    run_sudo "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

# pref [-h] [-s] <domain> <key> <bool|int|float|string|int-array> <value>
#   -h  per-host (defaults -currentHost)
#   -s  system-level plist: written with sudo
pref() {
  local host=0 sys=0
  while :; do
    case "${1:-}" in
    -h)
      host=1
      shift
      ;;
    -s)
      sys=1
      shift
      ;;
    *) break ;;
    esac
  done
  local domain=$1 key=$2 type=$3 want have label rc
  want=$(norm "$type" "$4")
  TOTAL=$((TOTAL + 1))
  have=$(read_pref "$host" "$domain" "$key" "$type")
  ! same "$type" "$have" "$want" || return 0
  label="$domain $key"
  [ "$host" -eq 0 ] || label="${domain}[currentHost] $key"
  handle_drift "$label" "$type" "$have" "$want" || return 0
  rc=0
  write_pref "$host" "$sys" "$domain" "$key" "$type" "$want" || rc=$?
  record_write "$rc" "$label"
  [ "$rc" -ne 0 ] || queue_restart "$domain" "$key"
}

# pref_absent <domain> <key>: the key must not exist (Apple's default applies).
pref_absent() {
  local have rc=0
  TOTAL=$((TOTAL + 1))
  have=$(read_pref 0 "$1" "$2" string)
  [ "$have" != "$UNSET" ] || return 0
  handle_drift "$1 $2" string "$have" "$UNSET" || return 0
  defaults delete "$1" "$2" || rc=$?
  record_write "$rc" "$1 $2"
  [ "$rc" -ne 0 ] || queue_restart "$1" "$2"
}

# pref_nested <domain> <dotted.key.path> <bool|int|float|string> <value>
# For values inside dicts. Edits go through `defaults export`/`import` so
# cfprefsd stays authoritative (no direct plist surgery, no cfprefsd kill).
pref_nested() {
  local domain=$1 path=$2 type=$3 want have label rc=0 pbtype pbval colon prefix seg
  local -a segs
  want=$(norm "$type" "$4")
  TOTAL=$((TOTAL + 1))
  have=$(defaults export "$domain" - 2>/dev/null | plutil -extract "$path" raw -o - - 2>/dev/null) || have=$UNSET
  have=$(norm "$type" "$have")
  ! same "$type" "$have" "$want" || return 0
  label="$domain $path"
  handle_drift "$label" "$type" "$have" "$want" || return 0

  case "$type" in
  bool)
    pbtype=bool
    pbval=$(bool_word "$want")
    ;;
  int)
    pbtype=integer
    pbval=$want
    ;;
  float)
    pbtype=real
    pbval=$want
    ;;
  *)
    pbtype=string
    pbval=$want
    ;;
  esac
  colon=":${path//./:}"

  TMP_PLIST=$(mktemp "${TMPDIR:-/tmp}/dotdefaults.XXXXXX")
  if defaults export "$domain" "$TMP_PLIST" 2>/dev/null; then
    if ! /usr/libexec/PlistBuddy -c "Set $colon $pbval" "$TMP_PLIST" >/dev/null 2>&1; then
      # Fresh account: the containing dicts may not exist yet.
      prefix=""
      IFS=. read -r -a segs <<<"${path%.*}"
      for seg in "${segs[@]}"; do
        prefix="$prefix:$seg"
        /usr/libexec/PlistBuddy -c "Add $prefix dict" "$TMP_PLIST" >/dev/null 2>&1 || true
      done
      /usr/libexec/PlistBuddy -c "Add $colon $pbtype $pbval" "$TMP_PLIST" >/dev/null 2>&1 || rc=1
    fi
    [ "$rc" -ne 0 ] || defaults import "$domain" "$TMP_PLIST" || rc=$?
  else
    rc=1
  fi
  rm -f "$TMP_PLIST"
  TMP_PLIST=""
  record_write "$rc" "$label"
  [ "$rc" -ne 0 ] || queue_restart "$domain" "$path"
}

# pmset_pref <battery|ac> <key> <value>: `pmset -g custom` is readable without
# root; only changing it needs sudo.
pmset_pref() {
  local src=$1 key=$2 want=$3 head flag have rc=0
  case "$src" in
  battery)
    head="Battery Power:"
    flag=-b
    ;;
  ac)
    head="AC Power:"
    flag=-c
    ;;
  esac
  TOTAL=$((TOTAL + 1))
  have=$(pmset -g custom 2>/dev/null | awk -v head="$head" -v k="$key" '
    /^[^ ]/ { on = ($0 == head) ; next }
    on && $1 == k { print $2; exit }')
  [ -n "$have" ] || have=$UNSET
  ! same int "$have" "$want" || return 0
  handle_drift "pmset $src.$key" int "$have" "$want" || return 0
  run_sudo pmset "$flag" "$key" "$want" >/dev/null || rc=$?
  record_write "$rc" "pmset $src.$key"
}

# Reverts the old "zero-byte immutable sleepimage" trick so macOS can manage
# the hibernation file again. A real (non-empty, mutable) image is left alone.
sleepimage_reset() {
  local f=/private/var/vm/sleepimage flags size rc=0 have
  TOTAL=$((TOTAL + 1))
  [ -e "$f" ] || return 0
  flags=$(/usr/bin/stat -f %f "$f")
  size=$(/usr/bin/stat -f %z "$f")
  if [ "$size" -ne 0 ] && [ $((flags & 2)) -eq 0 ]; then return 0; fi
  if [ "$size" -eq 0 ]; then have="zero-byte file"; else have="immutable file"; fi
  handle_drift "$f state" string "$have" "absent (macOS recreates)" || return 0
  run_sudo chflags nouchg "$f" || rc=$?
  if [ "$rc" -eq 0 ] && [ "$size" -eq 0 ]; then run_sudo rm -f "$f" || rc=$?; fi
  record_write "$rc" "$f"
}

# unhide [-s] <path>: clear the "hidden" file flag (UF_HIDDEN, 0x8000).
unhide() {
  local sys=0 path flags rc=0
  if [ "$1" = -s ]; then
    sys=1
    shift
  fi
  path=$1
  TOTAL=$((TOTAL + 1))
  [ -e "$path" ] || return 0
  flags=$(/usr/bin/stat -f %f "$path")
  [ $((flags & 32768)) -ne 0 ] || return 0
  handle_drift "$path hidden-flag" string hidden visible || return 0
  if [ "$sys" -eq 1 ]; then run_sudo chflags nohidden "$path" || rc=$?; else chflags nohidden "$path" || rc=$?; fi
  record_write "$rc" "$path"
  [ "$rc" -ne 0 ] || queue_restart com.apple.finder hidden
}

firewall_on() {
  local fw=/usr/libexec/ApplicationFirewall/socketfilterfw state have rc=0
  TOTAL=$((TOTAL + 1))
  state=$("$fw" --getglobalstate 2>/dev/null | sed -n 's/.*State = \([0-9]*\).*/\1/p')
  case "$state" in
  "") have=$UNSET ;;
  0) have=off ;;
  *) return 0 ;; # 1 = on, 2 = block all incoming: both count as enabled
  esac
  handle_drift "application-firewall globalstate" string "$have" on || return 0
  run_sudo "$fw" --setglobalstate on >/dev/null || rc=$?
  record_write "$rc" "application firewall"
}

###############################################################################
# General UI                                                                  #
###############################################################################
section "General UI"

# Medium sidebar icons.
pref NSGlobalDomain NSTableViewDefaultSizeMode int 2
pref NSGlobalDomain AppleShowScrollBars string Automatic
pref NSGlobalDomain NSUseAnimatedFocusRing bool false
pref NSGlobalDomain NSWindowResizeTime float 0.001

# Expanded save/print panels; save to disk, not iCloud.
pref NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true
pref NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
pref NSGlobalDomain PMPrintingExpandedStateForPrint bool true
pref NSGlobalDomain PMPrintingExpandedStateForPrint2 bool true
pref NSGlobalDomain NSDocumentSaveNewDocumentsToCloud bool false
pref com.apple.print.PrintingPrefs "Quit When Finished" bool true

# Show control characters as ^X in text views; keep apps running.
pref NSGlobalDomain NSTextShowsControlCharacters bool true
pref NSGlobalDomain NSDisableAutomaticTermination bool true

# Click the clock on the login window to reveal hostname/OS/IP.
pref -s /Library/Preferences/com.apple.loginwindow AdminHostInfo string HostName

# Typographic "helpers" corrupt code and shell snippets.
pref NSGlobalDomain NSAutomaticCapitalizationEnabled bool false
pref NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false
pref NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false
pref NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false
pref NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false

###############################################################################
# Input: trackpad, keyboard, accessibility                                    #
###############################################################################
section "Input"

# Tap to click: Bluetooth trackpad, built-in trackpad, and the login screen
# (the per-host + global NSGlobalDomain pair).
pref com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true
pref com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick bool true
pref com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick int 2
pref com.apple.AppleMultitouchTrackpad Clicking bool true
pref com.apple.AppleMultitouchTrackpad TrackpadRightClick bool true
pref com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick int 0
pref -h NSGlobalDomain com.apple.mouse.tapBehavior int 1
pref NSGlobalDomain com.apple.mouse.tapBehavior int 1
pref -h NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior int 1
pref -h NSGlobalDomain com.apple.trackpad.enableSecondaryClick bool true

# Natural scrolling.
pref NSGlobalDomain com.apple.swipescrolldirection bool true

# Full keyboard access: 2 = text boxes and lists only (Tab does not hop
# between every control).
pref NSGlobalDomain AppleKeyboardUIMode int 2

# Key repeat instead of the accent popup; fast repeat.
pref NSGlobalDomain ApplePressAndHoldEnabled bool false
pref NSGlobalDomain KeyRepeat int 1
pref NSGlobalDomain InitialKeyRepeat int 10

# Input-source menu on the login window.
pref -s /Library/Preferences/com.apple.loginwindow showInputMenu bool true

# Ctrl+scroll zooms the screen and follows keyboard focus.
pref com.apple.universalaccess closeViewScrollWheelToggle bool true
pref com.apple.universalaccess HIDScrollZoomModifierMask int 262144
pref com.apple.universalaccess closeViewZoomFollowsFocus bool true

###############################################################################
# Power                                                                       #
###############################################################################
section "Power"

# lidwake/autorestart/standbydelay are not in this Mac's `pmset -g cap`, so
# there is nothing to read or mirror for them.
pmset_pref battery displaysleep 15
pmset_pref ac displaysleep 15
pmset_pref battery sleep 5
pmset_pref ac sleep 1

# Mode 3 (RAM image on disk) survives total battery drain; mode 0 loses work.
pmset_pref battery hibernatemode 3
pmset_pref ac hibernatemode 3
sleepimage_reset

###############################################################################
# Screen and screenshots                                                      #
###############################################################################
section "Screen and screenshots"

pref com.apple.screencapture location string "${HOME}/Desktop"
pref com.apple.screencapture type string png
pref com.apple.screencapture disable-shadow bool true

###############################################################################
# Finder                                                                      #
###############################################################################
section "Finder"

pref com.apple.finder QuitMenuItem bool true
pref com.apple.finder DisableAllAnimations bool true

# New windows open the Desktop.
pref com.apple.finder NewWindowTarget string PfDe
pref com.apple.finder NewWindowTargetPath string "file://${HOME}/Desktop/"

pref com.apple.finder ShowExternalHardDrivesOnDesktop bool true
pref com.apple.finder ShowHardDrivesOnDesktop bool true
pref com.apple.finder ShowMountedServersOnDesktop bool true
pref com.apple.finder ShowRemovableMediaOnDesktop bool true
pref com.apple.finder OpenWindowForNewRemovableDisk bool true
pref com.apple.frameworks.diskimages auto-open-ro-root bool true
pref com.apple.frameworks.diskimages auto-open-rw-root bool true

pref com.apple.finder AppleShowAllFiles bool true
pref NSGlobalDomain AppleShowAllExtensions bool true
pref com.apple.finder ShowStatusBar bool true
pref com.apple.finder ShowPathbar bool true
pref com.apple.finder _FXShowPosixPathInTitle bool true
pref com.apple.finder _FXSortFoldersFirst bool true

# Search the current folder; column view as the default; warn on extension
# change and on emptying the Trash; purge Trash after 30 days.
pref com.apple.finder FXDefaultSearchScope string SCcf
pref com.apple.finder FXPreferredViewStyle string clmv
pref com.apple.finder FXEnableExtensionChangeWarning bool true
pref com.apple.finder WarnOnEmptyTrash bool true
pref com.apple.finder FXRemoveOldTrashItems bool true

# Spring-loaded folders without delay.
pref NSGlobalDomain com.apple.springing.enabled bool true
pref NSGlobalDomain com.apple.springing.delay float 0

# No .DS_Store litter on network and USB volumes.
pref com.apple.desktopservices DSDontWriteNetworkStores bool true
pref com.apple.desktopservices DSDontWriteUSBStores bool true

# AirDrop over every interface (e.g. Ethernet).
pref com.apple.NetworkBrowser BrowseAllInterfaces bool true

# Expanded Get Info panes.
pref_nested com.apple.finder FXInfoPanesExpanded.General bool true
pref_nested com.apple.finder FXInfoPanesExpanded.OpenWith bool true
pref_nested com.apple.finder FXInfoPanesExpanded.Privileges bool true

# Icon views (Desktop = free placement with labels to the right; standard
# folder views = snap to grid).
for view in DesktopViewSettings FK_StandardViewSettings StandardViewSettings; do
  pref_nested com.apple.finder "$view.IconViewSettings.showItemInfo" bool true
  pref_nested com.apple.finder "$view.IconViewSettings.gridSpacing" float 100
  pref_nested com.apple.finder "$view.IconViewSettings.iconSize" float 80
done
pref_nested com.apple.finder DesktopViewSettings.IconViewSettings.labelOnBottom bool false
pref_nested com.apple.finder DesktopViewSettings.IconViewSettings.arrangeBy string none
pref_nested com.apple.finder FK_StandardViewSettings.IconViewSettings.arrangeBy string grid
pref_nested com.apple.finder StandardViewSettings.IconViewSettings.arrangeBy string grid

# ~/Library and /Volumes are hidden by default.
unhide "${HOME}/Library"
unhide -s /Volumes

###############################################################################
# Dock and Mission Control                                                    #
###############################################################################
section "Dock and Mission Control"

pref com.apple.dock tilesize float 43
pref com.apple.dock mineffect string scale
pref com.apple.dock minimize-to-application bool true
pref com.apple.dock mouse-over-hilite-stack bool true
pref com.apple.dock enable-spring-load-actions-on-all-items bool true
pref com.apple.dock show-process-indicators bool true
pref com.apple.dock show-recents bool false
pref com.apple.dock showhidden bool true

# Auto-hide with no delay or animation.
pref com.apple.dock autohide bool true
pref com.apple.dock autohide-delay float 0
pref com.apple.dock autohide-time-modifier float 0

pref com.apple.dock expose-animation-duration float 0.1
pref com.apple.dock expose-group-by-app bool false
pref com.apple.dock mru-spaces bool false

# Hot corners: 2 Mission Control, 4 Desktop, 12 Notification Center.
pref com.apple.dock wvous-tl-corner int 2
pref com.apple.dock wvous-tl-modifier int 0
pref com.apple.dock wvous-tr-corner int 2
pref com.apple.dock wvous-tr-modifier int 0
pref com.apple.dock wvous-bl-corner int 4
pref com.apple.dock wvous-bl-modifier int 0
pref com.apple.dock wvous-br-corner int 12
pref com.apple.dock wvous-br-modifier int 0

###############################################################################
# Window tiling and Stage Manager                                             #
###############################################################################
section "Window tiling"

# Edge-drag tiling and margins are off; widgets stay visible; click on the
# wallpaper does not reveal the desktop.
pref com.apple.WindowManager EnableTilingByEdgeDrag bool false
pref com.apple.WindowManager EnableTopTilingByEdgeDrag bool false
pref com.apple.WindowManager EnableTilingOptionAccelerator bool false
pref com.apple.WindowManager EnableTiledWindowMargins bool false
pref com.apple.WindowManager HideDesktop bool true
pref com.apple.WindowManager StandardHideWidgets bool false
pref com.apple.WindowManager StageManagerHideWidgets bool false
pref com.apple.WindowManager AppWindowGroupingBehavior int 1

###############################################################################
# Security                                                                    #
###############################################################################
section "Security"

# Restore Gatekeeper's quarantine prompt and disk-image verification (the
# legacy script disabled both).
pref_absent com.apple.LaunchServices LSQuarantine
pref_absent com.apple.frameworks.diskimages skip-verify
pref_absent com.apple.frameworks.diskimages skip-verify-locked
pref_absent com.apple.frameworks.diskimages skip-verify-remote

firewall_on

# Password immediately after sleep or screen saver.
pref com.apple.screensaver askForPassword int 1
pref com.apple.screensaver askForPasswordDelay int 0

# Block other apps from reading keystrokes typed into Terminal.
pref com.apple.Terminal SecureKeyboardEntry bool true

###############################################################################
# Apps: Terminal, Activity Monitor, Photos, Time Machine, updates             #
###############################################################################
section "Apps"

# Terminal: UTF-8 only, no line marks. (Terminal rewrites its plist on quit,
# so apply this from another terminal app if values do not stick.)
pref com.apple.Terminal StringEncodings int-array 4
pref com.apple.Terminal ShowLineMarks int 0

pref com.apple.ActivityMonitor OpenMainWindow bool false
pref com.apple.ActivityMonitor IconType int 5
pref com.apple.ActivityMonitor ShowCategory int 100
pref com.apple.ActivityMonitor SortColumn string CPUUsage
pref com.apple.ActivityMonitor SortDirection int 0

# Don't launch Photos when a camera or phone is plugged in.
pref -h com.apple.ImageCapture disableHotPlug bool true

pref com.apple.TimeMachine DoNotOfferNewDisksForBackup bool true

pref com.apple.SoftwareUpdate AutomaticCheckEnabled bool true
pref com.apple.SoftwareUpdate ScheduleFrequency int 1
pref com.apple.SoftwareUpdate AutomaticDownload int 1
pref com.apple.SoftwareUpdate CriticalUpdateInstall int 1
pref com.apple.SoftwareUpdate ConfigDataInstall int 1
pref com.apple.commerce AutoUpdate bool true
pref com.apple.commerce AutoUpdateRestartRequired bool true

###############################################################################
# Summary                                                                     #
###############################################################################

if [ "$MODE" = check ]; then
  if [ "$DRIFT" -eq 0 ]; then
    printf '✓ %s settings in sync\n' "$TOTAL"
    exit 0
  fi
  printf '%s of %s settings drift\n' "$DRIFT" "$TOTAL"
  exit 1
fi

# Only bounce what actually changed. Defaults writes go through cfprefsd, so
# it never needs a restart.
for app in Dock Finder SystemUIServer; do
  case "$RESTART" in
  *" $app "*)
    killall "$app" >/dev/null 2>&1 || true
    printf 'restarted %s\n' "$app"
    ;;
  esac
done

printf '\n%s of %s settings changed' "$FIXED" "$TOTAL"
[ "$FAILED" -eq 0 ] || printf ', %s failed' "$FAILED"
printf '. Some changes need a logout or restart.\n'
[ "$FAILED" -eq 0 ]
