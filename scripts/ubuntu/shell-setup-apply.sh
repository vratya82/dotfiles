#!/usr/bin/env bash
# APPLY — backs up current configs then applies P10k Rainbow Starship setup.
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()  { echo -e "${GREEN}✓ $1${RESET}"; }
info(){ echo -e "${CYAN}→ $1${RESET}"; }
die() { echo -e "${RED}✗ $1${RESET}" >&2; exit 1; }

# ── Backups ──────────────────────────────────────────────────────────────────
BACKUP="$HOME/.shell-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp ~/.config/alacritty/alacritty.toml "$BACKUP/alacritty.toml"
cp ~/.config/starship.toml             "$BACKUP/starship.toml"
cp ~/.bashrc                           "$BACKUP/bashrc"
ok "Backups saved to $BACKUP"

# ── 1. Alacritty font ─────────────────────────────────────────────────────────
info "Updating Alacritty font: Terminus → MesloLGM Nerd Font"
sed -i 's/family = "Terminus"/family = "MesloLGM Nerd Font"/g' \
  ~/.config/alacritty/alacritty.toml
ok "Alacritty font updated"

# ── 2. .bashrc STARSHIP_CONFIG fix ───────────────────────────────────────────
info "Fixing STARSHIP_CONFIG path in ~/.bashrc"
sed -i 's|export STARSHIP_CONFIG=~/example/non/default/path/starship.toml|export STARSHIP_CONFIG=~/.config/starship.toml|' \
  ~/.bashrc
ok ".bashrc STARSHIP_CONFIG fixed"

# ── 3. starship.toml ─────────────────────────────────────────────────────────
info "Writing new ~/.config/starship.toml"
cat > ~/.config/starship.toml << 'STARSHIP_EOF'
"$schema" = "https://starship.rs/config-schema.json"

add_newline = false

# Two-line P10k Rainbow prompt
# Left:  [OS][DIRECTORY][GIT][LANGUAGE] took Xs
# Right: [BATTERY][TIME]
# Line2: ❯
format = """
[](fg:#9A348E)\
$os\
[](bg:#54487A fg:#9A348E)\
$directory\
[](bg:#FCA17D fg:#54487A)\
$git_branch\
$git_status\
[](bg:#86BBD8 fg:#FCA17D)\
$python$nodejs$rust\
[](fg:#86BBD8)\
$cmd_duration\
$fill\
[](fg:#06969A)\
$battery\
[](bg:#33658A fg:#06969A)\
$time\
[](fg:#33658A)\
$line_break\
$character\
"""

[os]
disabled = false
style = "bg:#9A348E fg:#E0DEF4"
format = "[ $symbol ]($style)"

[os.symbols]
Ubuntu = " "

[directory]
style = "bg:#54487A fg:#E0DEF4"
format = "[ $path ]($style)"
truncation_length = 3
truncate_to_repo = false
truncation_symbol = ""
substitutions = { "/" = " ❯ " }
read_only = " 󰌾"

[git_branch]
symbol = " "
style = "bg:#FCA17D fg:#1C1917"
format = "[ $symbol$branch ]($style)"

[git_status]
style = "bg:#FCA17D fg:#1C1917"
format = "[$all_status$ahead_behind]($style)"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
untracked = "?${count}"
stashed = "≡"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[python]
symbol = " "
style = "bg:#86BBD8 fg:#1C1917"
format = "[ $symbol($virtualenv) ]($style)"
detect_extensions = ["py"]
detect_files = ["pyproject.toml", "requirements.txt", ".python-version", "setup.py"]

[nodejs]
symbol = " "
style = "bg:#86BBD8 fg:#1C1917"
format = "[ $symbol($version) ]($style)"
detect_extensions = ["js", "ts", "mjs"]
detect_files = ["package.json", ".node-version", ".nvmrc"]

[rust]
symbol = " "
style = "bg:#86BBD8 fg:#1C1917"
format = "[ $symbol($version) ]($style)"
detect_extensions = ["rs"]
detect_files = ["Cargo.toml"]

[cmd_duration]
min_time = 500
style = "fg:#86BBD8"
format = " took [$duration]($style)"

[battery]
format = "[ $symbol$percentage ]($style)"
disabled = false

[[battery.display]]
threshold = 20
charging_symbol = "󰂄"
discharging_symbol = "󱃌"
style = "bg:#06969A fg:#E15759"

[[battery.display]]
threshold = 100
charging_symbol = "󰂄"
discharging_symbol = "󰂃"
style = "bg:#06969A fg:#E0DEF4"

[time]
disabled = false
style = "bg:#33658A fg:#E0DEF4"
format = "[ 󱑎 $time ]($style)"
time_format = "%H:%M"

[character]
success_symbol = "[❯](bold fg:#9A348E)"
error_symbol = "[❯](bold fg:#E15759)"

[package]
disabled = true
[hostname]
disabled = true
[username]
disabled = true
STARSHIP_EOF
ok "starship.toml written"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}All done. Next steps:${RESET}"
echo "  1. source ~/.bashrc          (reloads prompt in current terminal)"
echo "  2. Reopen Alacritty          (picks up the new font)"
echo ""
echo -e "${CYAN}Known edge cases:${RESET}"
echo "  • Git/language arrows appear even outside git repos — normal for Starship powerline configs"
echo "  • Battery segment only shows on laptop when battery detected"
echo "  • To restore: cp $BACKUP/* ~/.config/ && cp $BACKUP/bashrc ~/.bashrc"
