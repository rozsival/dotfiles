## `dot link`.

# Every file under home/ becomes a symlink at the same path under ~ (files, not
# directories, so tools can keep their own state next to them). seed/ files are
# copied once and then owned by the machine: they are rewritten by the tools
# themselves (OMP's config is also rsync'd to the devbox, where a symlink would
# arrive dangling).
# $1: 1 for a dry run.
link_home() {
  local dry="${1:-0}" src rel dst backup='' linked=0 changed=0 manifest="$STATE_DIR/links" current
  current="$(mktemp)"
  while IFS= read -r -d '' src; do
    rel=${src#"$DOTFILES/home/"}
    dst="$HOME/$rel"
    echo "$rel" >>"$current"
    linked=$((linked + 1))
    [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ] && continue
    changed=$((changed + 1))
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      [ -n "$backup" ] || backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
      info "backup ~/$rel -> $(tilde "$backup")/$rel"
      if [ "$dry" = 0 ]; then
        mkdir -p "$(dirname "$backup/$rel")"
        mv "$dst" "$backup/$rel"
      fi
    fi
    info "link   ~/$rel"
    if [ "$dry" = 0 ]; then
      mkdir -p "$(dirname "$dst")"
      ln -s "$src" "$dst"
    fi
  done < <(find "$DOTFILES/home" \( -type f -o -type l \) ! -name .DS_Store -print0)

  # Links whose source left the repo since the last run.
  if [ -f "$manifest" ]; then
    while IFS= read -r rel; do
      dst="$HOME/$rel"
      grep -qxF "$rel" "$current" && continue
      case "$(readlink "$dst" 2>/dev/null)" in "$DOTFILES/home/"*) ;; *) continue ;; esac
      info "unlink ~/$rel (gone from home/)"
      [ "$dry" = 1 ] || rm "$dst"
    done <"$manifest"
  fi

  while IFS= read -r -d '' src; do
    rel=${src#"$DOTFILES/seed/"}
    dst="$HOME/$rel"
    [ -e "$dst" ] && continue
    info "seed   ~/$rel"
    if [ "$dry" = 0 ]; then
      mkdir -p "$(dirname "$dst")"
      cp -p "$src" "$dst"
    fi
  done < <(find "$DOTFILES/seed" -type f ! -name .DS_Store -print0)

  if [ "$dry" = 0 ]; then
    chmod 700 "$HOME/.ssh"
    mkdir -p "$HOME/.ssh/config.d"
    chmod 700 "$HOME/.ssh/config.d"
    mkdir -p "$STATE_DIR"
    mv "$current" "$manifest"
  else
    rm -f "$current"
  fi
  ok "$linked links ($changed changed)${backup:+, replaced files in $(tilde "$backup")}"
}
