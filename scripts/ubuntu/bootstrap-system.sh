#!/usr/bin/env bash
# =============================================================================
# bootstrap-system.sh
# Full system bootstrap — reproduces the software stack on Ubuntu / Debian
#
# Usage (as your regular user, NOT root):
#   ./bootstrap-system.sh              # interactive
#   ./bootstrap-system.sh --unattended # accept all defaults
#
# Sections:
#   1.  Apt packages
#   2.  Snap packages
#   3.  Rust (rustup) + cargo tools
#   4.  Python (pyenv) + pipx tools
#   5.  Node (nvm) + npm globals
#   6.  Haskell (ghcup) — GHC, cabal, HLS, hoogle
#   7.  Doom Emacs
#   8.  Starship prompt
#   9.  Nerd Fonts
#   10. Dotfiles (stow)
#   11. Post-install hardening (calls post-install-hardening.sh)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET} $*"; }
info() { echo -e "${CYAN}→${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
hdr()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }
die()  { echo -e "${RED}✗${RESET} $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "Run as your regular user, NOT root. sudo will be called when needed."

UNATTENDED=false
[[ "${1:-}" == "--unattended" ]] && UNATTENDED=true

confirm() {
    $UNATTENDED && return 0
    read -rp "$(echo -e "${CYAN}?${RESET} $1 [y/N]: ")" ans
    [[ "${ans:-n}" =~ ^[Yy] ]]
}

LOGFILE="$HOME/bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1
info "Logging to $LOGFILE"

# =============================================================================
# 1. APT PACKAGES
# =============================================================================
hdr "1 · Apt Packages"

sudo apt-get update -qq

APT_PACKAGES=(
    # ── Build essentials ──────────────────────────────────────────────────────
    build-essential make cmake pkg-config ccache
    git curl wget stow

    # ── C / C++ ───────────────────────────────────────────────────────────────
    gcc clang clangd llvm valgrind gdb
    libssl-dev libffi-dev libreadline-dev libsqlite3-dev
    libbz2-dev liblzma-dev libncurses-dev zlib1g-dev
    libxml2-dev libxmlsec1-dev libgmp-dev tk-dev
    libx11-dev libxft-dev libxinerama-dev libxrandr-dev
    libxcb-cursor0 libxcb-xinerama0 libxcursor-dev
    libxext-dev libxres-dev libxss-dev

    # ── Shells & multiplexers ─────────────────────────────────────────────────
    tmux

    # ── Terminal emulators ────────────────────────────────────────────────────
    alacritty kitty

    # ── Editors ───────────────────────────────────────────────────────────────
    vim emacs
    # neovim via apt (or build from source — see note below)

    # ── Window managers ───────────────────────────────────────────────────────
    xmonad xmobar
    libghc-xmonad-dev libghc-xmonad-contrib-dev libghc-xmonad-contrib-prof
    libghc-xmonad-extras-dev libghc-xmonad-wallpaper-dev
    awesome
    hyprland hyprlock hyprpaper
    waybar
    picom rofi dunst nitrogen
    xscreensaver xscreensaver-data xscreensaver-data-extra
    xscreensaver-gl xscreensaver-gl-extra
    lightdm lightdm-gtk-greeter
    lxsession numlockx
    arandr

    # ── Haskell (system GHC — ghcup adds the rest) ────────────────────────────
    ghc
    libghc-aeson-dev

    # ── Python ───────────────────────────────────────────────────────────────
    python3 python3-pip python3-venv pipx pipenv

    # ── Node ─────────────────────────────────────────────────────────────────
    nodejs npm

    # ── CLI/TUI tools ─────────────────────────────────────────────────────────
    fzf ripgrep fd-find bat
    btop htop glances iotop nvtop s-tui
    lf ranger
    jq
    fastfetch
    lsd
    tree ncdu duf
    zoxide
    starship          # fallback; installer preferred (see section 8)
    trash-cli
    atool
    chafa             # image preview in terminal
    ueberzug          # image overlay for ranger
    ffmpegthumbnailer

    # ── Fonts ─────────────────────────────────────────────────────────────────
    fonts-terminus fonts-anonymous-pro
    fonts-noto-cjk fonts-noto-hinted fonts-symbola
    xfonts-terminus

    # ── Media ─────────────────────────────────────────────────────────────────
    mpv ffmpeg imagemagick
    cmus beets
    fluidsynth fluid-soundfont-gm
    pipewire pipewire-audio pipewire-pulse wireplumber

    # ── Productivity ──────────────────────────────────────────────────────────
    taskwarrior vit
    keepassxc
    syncthing
    pandoc

    # ── File management ───────────────────────────────────────────────────────
    thunar thunar-volman tumbler
    udiskie udisks2
    ntfs-3g
    p7zip-full unzip rsync
    renameutils

    # ── System utils ──────────────────────────────────────────────────────────
    xclip xsel
    maim scrot
    xdg-user-dirs-gtk
    inxi lm-sensors
    policykit-1-gnome
    gparted gnome-disk-utility
    bleachbit
    shellcheck

    # ── Networking ────────────────────────────────────────────────────────────
    net-tools iproute2 curl wget
    nmap netcat-openbsd
    tcpdump iftop nethogs nload bmon mtr vnstat
    dnsutils traceroute

    # ── Virtualisation ────────────────────────────────────────────────────────
    virt-manager libvirt-clients libvirt-daemon-system qemu-utils ovmf
    # virtualbox         # add if needed: sudo apt install virtualbox

    # ── Security tools ────────────────────────────────────────────────────────
    firejail lynis rkhunter auditd audispd-plugins
    fail2ban ufw arpwatch
    binwalk
    debsecan debsums

    # ── Dev extras ────────────────────────────────────────────────────────────
    gdb valgrind
    ansible
    docker.io       # or install docker-ce via docker repo

    # ── Fun / misc ────────────────────────────────────────────────────────────
    cmatrix lolcat figlet toilet cowsay fortune-mod
    screenkey
    w3m w3m-img
    ytfzf gallery-dl
    dosbox
)

info "Installing ${#APT_PACKAGES[@]} apt packages…"
sudo apt-get install -y -qq "${APT_PACKAGES[@]}" 2>/dev/null || {
    warn "Some packages failed — retrying individually…"
    for pkg in "${APT_PACKAGES[@]}"; do
        sudo apt-get install -y -qq "$pkg" 2>/dev/null || warn "Skipped: $pkg"
    done
}
ok "Apt packages done"

# =============================================================================
# 2. SNAP PACKAGES
# =============================================================================
hdr "2 · Snap Packages"

SNAPS_CLASSIC=(
    "code --classic"
    "zellij --classic"
)
SNAPS_CONFINED=(
    "firefox"
    "chromium"
    "obsidian"
    "thunderbird"
    "newsboat"
    "yazi"
    "discord"
)

for snap_pkg in "${SNAPS_CLASSIC[@]}"; do
    snap_name="${snap_pkg%% *}"
    if ! snap list "$snap_name" &>/dev/null; then
        info "Installing snap: $snap_name"
        sudo snap install $snap_pkg 2>/dev/null || warn "Snap failed: $snap_name"
    else
        ok "Already installed: $snap_name"
    fi
done

for snap_name in "${SNAPS_CONFINED[@]}"; do
    if ! snap list "$snap_name" &>/dev/null; then
        info "Installing snap: $snap_name"
        sudo snap install "$snap_name" 2>/dev/null || warn "Snap failed: $snap_name"
    else
        ok "Already installed: $snap_name"
    fi
done

ok "Snaps done"

# =============================================================================
# 3. RUST (rustup) + CARGO TOOLS
# =============================================================================
hdr "3 · Rust + Cargo Tools"

if ! command -v rustup &>/dev/null; then
    info "Installing rustup…"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

export PATH="$HOME/.cargo/bin:$PATH"
source "$HOME/.cargo/env" 2>/dev/null || true

rustup toolchain install stable
rustup default stable
rustup component add rustfmt clippy rust-analyzer
ok "Rust toolchain: $(rustc --version)"

CARGO_TOOLS=(
    lsd         # modern ls
    viu         # image viewer in terminal
    rebos       # declarative package manager
    # starship  # prompt — installed via install script (section 8)
    # ya        # yazi helper — comes with yazi snap
)

for tool in "${CARGO_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null && [[ ! -f "$HOME/.cargo/bin/$tool" ]]; then
        info "Installing cargo: $tool"
        cargo install "$tool" 2>/dev/null || warn "cargo install failed: $tool"
    else
        ok "Already installed: $tool"
    fi
done

ok "Cargo tools done"

# =============================================================================
# 4. PYTHON (pyenv) + PIPX TOOLS
# =============================================================================
hdr "4 · Python (pyenv) + pipx"

# pyenv
if [[ ! -d "$HOME/.pyenv" ]]; then
    info "Installing pyenv…"
    curl -fsSL https://pyenv.run | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

# Python versions to install
PYENV_VERSIONS=("3.14.4" "3.10.14")
for ver in "${PYENV_VERSIONS[@]}"; do
    if ! pyenv versions --bare | grep -q "^${ver}$"; then
        info "Installing Python $ver via pyenv…"
        pyenv install "$ver"
    else
        ok "Python $ver already installed"
    fi
done

pyenv global system  # keep system as default; switch per-project with .python-version

# pipx tools
PIPX_TOOLS=(
    basedpyright  # Python LSP (used by Doom Emacs)
    yt-dlp
    gallery-dl
    ansible
)

for tool in "${PIPX_TOOLS[@]}"; do
    if ! pipx list 2>/dev/null | grep -q "$tool"; then
        info "Installing pipx: $tool"
        pipx install "$tool" 2>/dev/null || warn "pipx failed: $tool"
    else
        ok "Already installed (pipx): $tool"
    fi
done

ok "Python done"

# =============================================================================
# 5. NODE (nvm) + NPM GLOBALS
# =============================================================================
hdr "5 · Node (nvm) + npm globals"

if [[ ! -d "$HOME/.nvm" ]]; then
    info "Installing nvm…"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

if ! nvm ls 22 &>/dev/null; then
    info "Installing Node 22 LTS…"
    nvm install 22
    nvm alias default 22
fi

NPM_GLOBALS=(
    "@google/gemini-cli"
    "@openai/codex"
)

for pkg in "${NPM_GLOBALS[@]}"; do
    if ! npm list -g --depth=0 2>/dev/null | grep -q "${pkg##*/}"; then
        info "Installing npm global: $pkg"
        npm install -g "$pkg" 2>/dev/null || warn "npm failed: $pkg"
    else
        ok "Already installed (npm global): $pkg"
    fi
done

ok "Node done"

# =============================================================================
# 6. HASKELL (ghcup) — GHC, cabal, HLS, hoogle
# =============================================================================
hdr "6 · Haskell (ghcup)"

if [[ ! -f "$HOME/.ghcup/bin/ghcup" ]]; then
    info "Installing ghcup…"
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
        BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
        BOOTSTRAP_HASKELL_NO_UPGRADE=1 \
        sh
fi

export PATH="$HOME/.ghcup/bin:$HOME/.cabal/bin:$PATH"
source "$HOME/.ghcup/env" 2>/dev/null || true

GHCUP_BIN="$HOME/.ghcup/bin/ghcup"

info "Installing HLS (recommended)…"
"$GHCUP_BIN" install hls recommended --force 2>/dev/null || warn "HLS install issue"
"$GHCUP_BIN" set hls recommended 2>/dev/null || true

info "Installing cabal (latest)…"
"$GHCUP_BIN" install cabal latest --force 2>/dev/null || warn "cabal install issue"
"$GHCUP_BIN" set cabal latest 2>/dev/null || true

# hoogle — documentation search used by Doom Emacs :lang haskell
if ! command -v hoogle &>/dev/null && [[ ! -f "$HOME/.cabal/bin/hoogle" ]]; then
    info "Installing hoogle…"
    cabal install hoogle 2>/dev/null || warn "hoogle install failed"
fi

if command -v hoogle &>/dev/null || [[ -f "$HOME/.cabal/bin/hoogle" ]]; then
    info "Generating hoogle database (Stackage)…"
    PATH="$HOME/.cabal/bin:$PATH" hoogle generate 2>/dev/null || warn "hoogle generate failed"
fi

# Add ghcup PATH sourcing to shell rc (idempotent)
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -q "ghcup/env" "$rc"; then
        echo '' >> "$rc"
        echo '# ghcup' >> "$rc"
        echo '. "$HOME/.ghcup/env"' >> "$rc"
        ok "Added ghcup env to $rc"
    fi
done

ok "Haskell done"

# =============================================================================
# 7. DOOM EMACS
# =============================================================================
hdr "7 · Doom Emacs"

if [[ ! -d "$HOME/.config/emacs" ]]; then
    info "Cloning Doom Emacs…"
    git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
    "$HOME/.config/emacs/bin/doom" install --no-confirm
else
    ok "Doom Emacs already installed"
    # Sync to pick up any config changes
    "$HOME/.config/emacs/bin/doom" sync --no-env 2>/dev/null || true
fi

# Add doom bin to PATH (idempotent)
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [[ -f "$rc" ]] && ! grep -q "config/emacs/bin" "$rc"; then
        echo 'export PATH="$HOME/.config/emacs/bin:$PATH"' >> "$rc"
    fi
done

ok "Doom Emacs done"

# =============================================================================
# 8. STARSHIP PROMPT
# =============================================================================
hdr "8 · Starship Prompt"

if ! command -v starship &>/dev/null || [[ ! -f /usr/local/bin/starship ]]; then
    info "Installing starship…"
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

ok "Starship: $(starship --version 2>/dev/null | head -1)"

# Add to bashrc if not already present
if ! grep -q "starship init" "$HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$HOME/.bashrc"
    echo '# Starship prompt' >> "$HOME/.bashrc"
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

ok "Starship done"

# =============================================================================
# 9. NERD FONTS
# =============================================================================
hdr "9 · Nerd Fonts"

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

NF_VERSION="v3.4.0"
NF_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/${NF_VERSION}"

# Fonts confirmed installed on this system
NERD_FONTS=(
    "Terminess"        # Primary Emacs/terminal font
    "Meslo"
    "AnonymousPro"
    "FiraCode"
    "JetBrainsMono"
    "Iosevka"
    "IosevkaTerm"
    "Hack"
    "SourceCodePro"
)

for font in "${NERD_FONTS[@]}"; do
    zip="${font}.zip"
    if ls "$FONTS_DIR"/${font}* &>/dev/null 2>&1 || ls "$FONTS_DIR"/NerdFonts/${font}* &>/dev/null 2>&1; then
        ok "Font already installed: $font"
        continue
    fi
    info "Downloading Nerd Font: $font"
    tmpdir=$(mktemp -d)
    if curl -fsSL "${NF_BASE}/${zip}" -o "${tmpdir}/${zip}" 2>/dev/null; then
        unzip -q "${tmpdir}/${zip}" -d "${tmpdir}/font" 2>/dev/null
        find "${tmpdir}/font" -name "*.ttf" -o -name "*.otf" | \
            xargs -I{} cp {} "$FONTS_DIR/" 2>/dev/null
        ok "Installed: $font"
    else
        warn "Could not download: $font"
    fi
    rm -rf "$tmpdir"
done

fc-cache -fq && ok "Font cache updated"

# =============================================================================
# 10. DOTFILES (stow)
# =============================================================================
hdr "10 · Dotfiles"

DOTFILES_REPO="https://github.com/YOUR_USERNAME/dotfiles"  # CHANGE ME — your dotfiles repo URL
DOTFILES_DIR="$HOME/dotfiles"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
    ok "Dotfiles already cloned at $DOTFILES_DIR"
    if confirm "Pull latest dotfiles?"; then
        git -C "$DOTFILES_DIR" pull --rebase 2>/dev/null || warn "git pull failed"
    fi
elif confirm "Clone dotfiles from $DOTFILES_REPO?"; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

if [[ -d "$DOTFILES_DIR" ]]; then
    cd "$DOTFILES_DIR"
    STOW_PACKAGES=(
        alacritty bash doom dunst fastfetch
        hypr kitty lf mpv picom ranger
        rofi scripts starship tmux waybar yazi zellij
    )
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [[ -d "$pkg" ]]; then
            stow --target="$HOME" --restow "$pkg" 2>/dev/null && ok "Stowed: $pkg" || warn "Stow conflict: $pkg"
        fi
    done
    cd - >/dev/null
fi

# =============================================================================
# 11. HARDENING
# =============================================================================
hdr "11 · Post-install Hardening"

HARDENING_SCRIPT="$(dirname "$0")/post-install-hardening.sh"
if [[ -f "$HARDENING_SCRIPT" ]]; then
    if confirm "Run post-install-hardening.sh now?"; then
        sudo bash "$HARDENING_SCRIPT" ${UNATTENDED:+--unattended}
    else
        warn "Skipped hardening — run manually: sudo $HARDENING_SCRIPT"
    fi
else
    warn "Hardening script not found at $HARDENING_SCRIPT"
    warn "Download it or place post-install-hardening.sh alongside this script"
fi

# =============================================================================
# 12. SHELL ENV — .bashrc additions
# =============================================================================
hdr "12 · Shell Environment"

BASHRC="$HOME/.bashrc"

add_to_bashrc() {
    local marker="$1" line="$2"
    grep -q "$marker" "$BASHRC" 2>/dev/null || echo "$line" >> "$BASHRC"
}

add_to_bashrc "cargo/env"          'source "$HOME/.cargo/env" 2>/dev/null || true'
add_to_bashrc "PYENV_ROOT"         'export PYENV_ROOT="$HOME/.pyenv"'
add_to_bashrc "pyenv/bin"          'export PATH="$PYENV_ROOT/bin:$PATH"'
add_to_bashrc "pyenv init"         'eval "$(pyenv init -)" 2>/dev/null || true'
add_to_bashrc ".cabal/bin"         'export PATH="$HOME/.cabal/bin:$HOME/.local/bin:$PATH"'
add_to_bashrc "NVM_DIR"            'export NVM_DIR="$HOME/.nvm"'
add_to_bashrc "nvm.sh"             '[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"'
add_to_bashrc "zoxide init"        'eval "$(zoxide init bash)"'
add_to_bashrc "starship init"      'eval "$(starship init bash)"'
add_to_bashrc "config/emacs/bin"   'export PATH="$HOME/.config/emacs/bin:$PATH"'

ok "Shell env entries written to $BASHRC"

# =============================================================================
# SUMMARY
# =============================================================================
hdr "Bootstrap Complete"

echo
echo -e "${BOLD}Installed:${RESET}"
for tool in emacs rustc cargo python3 node ghc hls hoogle starship doom; do
    path=$(command -v "$tool" 2>/dev/null || \
           command -v "$HOME/.cargo/bin/$tool" 2>/dev/null || \
           command -v "$HOME/.cabal/bin/$tool" 2>/dev/null || \
           echo "")
    if [[ -n "$path" ]]; then
        echo -e "  ${GREEN}✓${RESET} $tool"
    else
        echo -e "  ${YELLOW}?${RESET} $tool (check PATH after sourcing .bashrc)"
    fi
done

echo
echo -e "${BOLD}Next steps:${RESET}"
echo "  1. source ~/.bashrc          — reload shell environment"
echo "  2. doom sync                 — sync Doom Emacs packages"
echo "  3. sudo lynis audit system   — full security audit"
echo "  4. Review $LOGFILE"
echo
ok "Done. Log: $LOGFILE"
