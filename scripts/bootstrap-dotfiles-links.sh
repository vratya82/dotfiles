#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
APPLY=0
BACKUP_TAG="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'EOF'
Usage: bootstrap-dotfiles-links.sh [--apply]

Symlink curated live config paths into ~/dotfiles.

Default mode is a dry run. Use --apply to make changes.

Environment:
  DOTFILES_DIR=/path/to/dotfiles   Override repo path, default: ~/dotfiles
EOF
}

case "${1:-}" in
  --apply)
    APPLY=1
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

log() {
  printf '%s\n' "$*"
}

run() {
  if [ "$APPLY" -eq 1 ]; then
    "$@"
  else
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  fi
}

link_file() {
  local repo_rel="$1"
  local live_path="$2"
  local repo_path="$DOTFILES_DIR/$repo_rel"
  local live_dir
  local target

  live_dir="$(dirname "$live_path")"

  if [ ! -e "$repo_path" ]; then
    log "SKIP missing repo file: $repo_path"
    return 0
  fi

  run mkdir -p "$live_dir"

  if [ -L "$live_path" ]; then
    target="$(readlink "$live_path")"
    if [ "$target" = "$repo_path" ]; then
      log "OK already linked: $live_path -> $repo_path"
      return 0
    fi

    log "SKIP unrelated symlink: $live_path -> $target"
    return 0
  fi

  if [ -e "$live_path" ]; then
    if cmp -s "$live_path" "$repo_path"; then
      run mv "$live_path" "${live_path}.pre-dotfiles-link-${BACKUP_TAG}"
      run ln -s "$repo_path" "$live_path"
      log "LINK matched file: $live_path -> $repo_path"
      return 0
    fi

    run mv "$live_path" "${live_path}.pre-dotfiles-link-${BACKUP_TAG}"
    run ln -s "$repo_path" "$live_path"
    log "LINK backed up differing file: $live_path -> $repo_path"
    return 0
  fi

  run ln -s "$repo_path" "$live_path"
  log "LINK new: $live_path -> $repo_path"
}

if [ ! -d "$DOTFILES_DIR" ]; then
  log "ERROR: DOTFILES_DIR does not exist: $DOTFILES_DIR" >&2
  exit 1
fi

log "Dotfiles: $DOTFILES_DIR"
if [ "$APPLY" -eq 0 ]; then
  log "Mode: dry run. Re-run with --apply to make changes."
else
  log "Mode: apply"
fi

link_file ".bash_aliases" "$HOME/.bash_aliases"
link_file ".gitconfig" "$HOME/.gitconfig"
link_file ".vimrc" "$HOME/.vimrc"

link_file "alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
link_file "fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
link_file "lf/clean" "$HOME/.config/lf/clean"
link_file "lf/lfrc" "$HOME/.config/lf/lfrc"
link_file "lf/preview" "$HOME/.config/lf/preview"
link_file "picom/picom.conf" "$HOME/.config/picom/picom.conf"
link_file "rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
link_file "starship.toml" "$HOME/.config/starship.toml"
link_file "xmobar/xmobarrc" "$HOME/.config/xmobar/xmobarrc"
link_file "xmonad/xmonad.hs" "$HOME/.config/xmonad/xmonad.hs"
link_file "zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

link_file "yazi/init.lua" "$HOME/.config/yazi/init.lua"
link_file "yazi/keymap.toml" "$HOME/.config/yazi/keymap.toml"
link_file "yazi/package.toml" "$HOME/.config/yazi/package.toml"
link_file "yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"

link_file "ranger/commands.py" "$HOME/.config/ranger/commands.py"
link_file "ranger/rc.conf" "$HOME/.config/ranger/rc.conf"
link_file "ranger/rifle.conf" "$HOME/.config/ranger/rifle.conf"
link_file "ranger/scope.sh" "$HOME/.config/ranger/scope.sh"
link_file "ranger/colorschemes/__init__.py" "$HOME/.config/ranger/colorschemes/__init__.py"
link_file "ranger/colorschemes/default.py.gz" "$HOME/.config/ranger/colorschemes/default.py.gz"
link_file "ranger/colorschemes/jungle.py" "$HOME/.config/ranger/colorschemes/jungle.py"
link_file "ranger/colorschemes/snow.py" "$HOME/.config/ranger/colorschemes/snow.py"

log "Done."
