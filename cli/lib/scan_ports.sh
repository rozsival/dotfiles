## moshi-hook's HTTP server discovery, per project (`dot scan-ports`).
#
# By default moshi-hook HTTP-probes every listening loopback port. The probe also
# reaches the one-shot servers login flows open for their OAuth callback (gcloud,
# GeForce NOW), and the flow fails. Its `scan_ports` setting is a single global
# list, so dot keeps a registry of projects and their dev-server ports and sets
# the live value to their union, `none` when nothing is registered.

# The project a directory belongs to: its main worktree, so every worktree of a
# repo shares one entry; the directory itself outside git.
scan_ports_project() {
  local dir common
  dir="$(cd "$1" 2>/dev/null && pwd -P)" || die "no such directory: $1"
  if common="$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
    case $common in
    */.git) dir="${common%/.git}" ;;
    *) dir="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$common")" ;;
    esac
  fi
  printf '%s' "$dir"
}

# A port list the way moshi-hook stores it (sorted, overlaps merged), checked by
# moshi-hook itself against a scratch config so the live one stays untouched.
scan_ports_normalize() {
  local tmp out rc=0
  tmp="$(mktemp -d)"
  out="$(MOSHI_HOOK_CONFIG_DIR="$tmp" moshi-hook set scan-ports "$1" 2>&1)" || rc=$?
  rm -rf "$tmp"
  [ $rc = 0 ] || {
    printf '%s\n' "$out" >&2
    return 1
  }
  printf '%s\n' "$out" | sed -n 's/^scan-ports: //p'
}

scan_ports_live() { moshi-hook set scan-ports 2>/dev/null | sed -n 's/^scan-ports: //p'; }

# "ports<TAB>project" lines of registered projects that still exist.
scan_ports_entries() {
  local ports project
  [ -f "$SCAN_PORTS_REGISTRY" ] || return 0
  while IFS=$'\t' read -r ports project; do
    [ -d "$project" ] || continue
    printf '%s\t%s\n' "$ports" "$project"
  done <"$SCAN_PORTS_REGISTRY"
}

# The value the live setting should have.
scan_ports_wanted() {
  local union
  union="$(scan_ports_entries | cut -f1 | paste -sd, -)"
  if [ -z "$union" ]; then echo none; else scan_ports_normalize "$union"; fi
}

# Registers (ports) or unregisters (`none`) a project; drops projects whose
# directory is gone.
scan_ports_register() {
  local project="$1" ports="$2" tmp
  if [ "$ports" != none ]; then
    [ "$ports" != all ] || die 'all is the default this command exists to avoid; name the ports'
    ports="$(scan_ports_normalize "$ports")" || die "invalid ports: $2"
  fi
  mkdir -p "$STATE_DIR"
  tmp="$(mktemp "$STATE_DIR/scan-ports.XXXXXX")"
  scan_ports_entries | awk -F'\t' -v p="$project" '$2 != p' >"$tmp"
  [ "$ports" = none ] || printf '%s\t%s\n' "$ports" "$project" >>"$tmp"
  sort -t$'\t' -k2 "$tmp" -o "$tmp"
  mv "$tmp" "$SCAN_PORTS_REGISTRY"
}

scan_ports_list() {
  local ports project
  while IFS=$'\t' read -r ports project; do
    info "$(tilde "$project"): $ports"
  done < <(scan_ports_entries)
}

# check=1 reports drift and changes nothing; otherwise sets the live value.
scan_ports_sync() {
  local check="$1" wanted live
  wanted="$(scan_ports_wanted)" || die "the registry holds ports moshi-hook rejects: $(tilde "$SCAN_PORTS_REGISTRY")"
  live="$(scan_ports_live)"
  if [ "$live" = "$wanted" ]; then
    ok "moshi-hook scan-ports $live"
  elif [ "$check" = 1 ]; then
    bad "moshi-hook scan-ports $live, registered projects want $wanted"
    hint 'dot scan-ports'
  else
    moshi-hook set scan-ports "$wanted" >/dev/null
    ok "moshi-hook scan-ports $wanted (was ${live:-unset})"
  fi
  scan_ports_list
}
