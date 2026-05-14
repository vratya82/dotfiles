#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
backup_dir="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

link_one() {
    local source_rel="$1"
    local target="$2"
    local source="$repo_dir/$source_rel"

    if [ ! -e "$source" ]; then
        printf 'skip missing source: %s\n' "$source_rel" >&2
        return 0
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        local current
        current="$(readlink "$target")"
        if [ "$current" = "$source" ]; then
            printf 'ok: %s\n' "$target"
            return 0
        fi
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/$(basename "$target").symlink"
    elif [ -e "$target" ]; then
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/$(basename "$target")"
    fi

    ln -s "$source" "$target"
    printf 'linked: %s -> %s\n' "$target" "$source_rel"
}

# Shell
link_one ".bashrc"       "$HOME/.bashrc"
link_one ".bash_aliases" "$HOME/.bash_aliases"
link_one ".profile"      "$HOME/.profile"
link_one ".vimrc"        "$HOME/.vimrc"

# Terminal / prompt
link_one "alacritty/alacritty.toml"  "$HOME/.config/alacritty/alacritty.toml"
link_one "starship/starship.toml"    "$HOME/.config/starship.toml"

# WM / compositor
link_one "xmonad/xmonad.hs"  "$HOME/.config/xmonad/xmonad.hs"
link_one "xmobar/xmobarrc"   "$HOME/.config/xmobar/xmobarrc"
link_one "picom/picom.conf"  "$HOME/.config/picom/picom.conf"
link_one "awesome/rc.lua"    "$HOME/.config/awesome/rc.lua"
link_one "rofi/config.rasi"  "$HOME/.config/rofi/config.rasi"

# CLI tools
link_one "btop/btop.conf"          "$HOME/.config/btop/btop.conf"
link_one "fastfetch/config.jsonc"  "$HOME/.config/fastfetch/config.jsonc"
link_one "zellij/config.kdl"       "$HOME/.config/zellij/config.kdl"

# lf
link_one "lf/lfrc"    "$HOME/.config/lf/lfrc"
link_one "lf/clean"   "$HOME/.config/lf/clean"
link_one "lf/preview" "$HOME/.config/lf/preview"

# ranger
link_one "ranger/rc.conf"     "$HOME/.config/ranger/rc.conf"
link_one "ranger/rifle.conf"  "$HOME/.config/ranger/rifle.conf"
link_one "ranger/scope.sh"    "$HOME/.config/ranger/scope.sh"
link_one "ranger/commands.py" "$HOME/.config/ranger/commands.py"

# yazi
link_one "yazi/yazi.toml"    "$HOME/.config/yazi/yazi.toml"
link_one "yazi/keymap.toml"  "$HOME/.config/yazi/keymap.toml"
link_one "yazi/package.toml" "$HOME/.config/yazi/package.toml"
link_one "yazi/init.lua"     "$HOME/.config/yazi/init.lua"
link_one "yazi/plugins"      "$HOME/.config/yazi/plugins"

printf '\nDone. Backups, if any, are in: %s\n' "$backup_dir"
