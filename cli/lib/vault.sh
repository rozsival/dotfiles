## `dot vault`.

vault_entries() { grep -vE '^[[:space:]]*(#|$)' "$DOTFILES/vault.list"; }

# Completion candidates for the title args: `dot __complete` skips initialize,
# so no $DOTFILES here.
vault_titles() { awk '!/^[[:space:]]*(#|$)/ {print $1}' "$(dotfiles_root)/vault.list"; }

op_doc_exists() { op item get "$1" --vault "$DOT_OP_VAULT" --account "$DOT_OP_ACCOUNT" --format json >/dev/null 2>&1; }

# $1: status, pull or push; $2: 1 to overwrite on pull; the rest: titles to act
# on (none: all of vault.list).
vault_sync() {
  local sub="$1" force="$2" title path mode want tmp exists
  shift 2
  op whoami --account "$DOT_OP_ACCOUNT" >/dev/null 2>&1 || op signin --account "$DOT_OP_ACCOUNT" >/dev/null ||
    die "op cannot reach $DOT_OP_ACCOUNT: 1Password app -> Settings -> Developer -> Integrate with 1Password CLI"
  if [ "$sub" = push ] && ! op vault get "$DOT_OP_VAULT" --account "$DOT_OP_ACCOUNT" >/dev/null 2>&1; then
    op vault create "$DOT_OP_VAULT" --account "$DOT_OP_ACCOUNT" >/dev/null
    ok "created vault $DOT_OP_VAULT"
  fi
  umask 077
  # fd 3: op must not read the loop's input as its own stdin.
  while read -r title path mode <&3; do
    if [ $# -gt 0 ]; then
      for want in "$@"; do [ "$want" = "$title" ] && break; done
      [ "$want" = "$title" ] || continue
    fi
    path=${path/#\~/$HOME}
    exists=0
    op_doc_exists "$title" && exists=1
    case "$sub" in
    status)
      if [ -f "$path" ] && [ $exists = 1 ]; then
        ok "$title"
      elif [ $exists = 1 ]; then
        warn "$title: in 1Password, not on disk (dot vault pull)"
      elif [ -f "$path" ]; then
        warn "$title: on disk, not in 1Password (dot vault push)"
      else
        bad "$title: neither on disk nor in 1Password"
      fi
      ;;
    pull)
      if [ -f "$path" ] && [ "$force" = 0 ]; then
        ok "$title: present, kept (--force overwrites)"
      elif [ $exists = 0 ]; then
        bad "$title: not in vault $DOT_OP_VAULT"
      else
        mkdir -p "$(dirname "$path")"
        tmp="$(mktemp)"
        op document get "$title" --vault "$DOT_OP_VAULT" --account "$DOT_OP_ACCOUNT" >"$tmp"
        install -m "$mode" "$tmp" "$path"
        rm -f "$tmp"
        ok "$title -> $(tilde "$path")"
      fi
      ;;
    push)
      if [ ! -f "$path" ]; then
        warn "$title: no $(tilde "$path") to upload"
      elif [ $exists = 1 ]; then
        op document edit "$title" "$path" --vault "$DOT_OP_VAULT" --account "$DOT_OP_ACCOUNT" >/dev/null
        ok "$title: updated"
      else
        op document create "$path" --title "$title" --vault "$DOT_OP_VAULT" --account "$DOT_OP_ACCOUNT" >/dev/null
        ok "$title: created"
      fi
      ;;
    esac
  done 3< <(vault_entries)
  [ $FAILS = 0 ]
}
