#!/usr/bin/env bash
set -Eeuo pipefail

# Minimal Fedora VM bootstrap.
#
# Installs a small desktop/privacy/dev baseline:
# - LibreWolf
# - Mullvad VPN
# - Git
# - CLI/TUI tools
# - terminal image/media viewing tools
#
# Hardening steps are suggested first and require confirmation before execution.
#
# Usage:
#   ./scripts/fedora-vm-bootstrap.sh
#   ./scripts/fedora-vm-bootstrap.sh --yes
#   ./scripts/fedora-vm-bootstrap.sh --baseline-only
#   ./scripts/fedora-vm-bootstrap.sh --plan

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ASSUME_YES=0
BASELINE_ONLY=0
PLAN_ONLY=0

LIBREWOLF_REPO_URL="https://repo.librewolf.net/librewolf.repo"
MULLVAD_REPO_URL="https://repository.mullvad.net/rpm/stable/mullvad.repo"

log() { printf '%b\n' "$*"; }
ok() { log "${GREEN}OK${RESET} $*"; }
info() { log "${CYAN}==>${RESET} $*"; }
warn() { log "${YELLOW}WARN${RESET} $*"; }
die() { log "${RED}ERROR${RESET} $*" >&2; exit 1; }

usage() {
	cat <<EOF
Usage: $0 [options]

Options:
  --yes            Accept baseline prompts and hardening prompts.
  --baseline-only  Install packages/repos only; skip hardening prompts.
  --plan           Print the plan and exit without changing anything.
  -h, --help       Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--yes)
			ASSUME_YES=1
			;;
		--baseline-only)
			BASELINE_ONLY=1
			;;
		--plan)
			PLAN_ONLY=1
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "unknown option: $1"
			;;
	esac
	shift
done

confirm() {
	local prompt="$1"
	if [ "$ASSUME_YES" -eq 1 ]; then
		return 0
	fi
	printf '%b [y/N] ' "${CYAN}?${RESET} ${prompt}"
	read -r answer
	case "${answer:-}" in
		y|Y|yes|YES) return 0 ;;
		*) return 1 ;;
	esac
}

need_fedora() {
	[ -r /etc/os-release ] || die "/etc/os-release not found"
	# shellcheck disable=SC1091
	. /etc/os-release
	[ "${ID:-}" = "fedora" ] || die "this script targets Fedora; detected ID=${ID:-unknown}"
	ok "Detected ${PRETTY_NAME:-Fedora}"
}

as_root_or_sudo() {
	if [ "${EUID:-$(id -u)}" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

dnf_install_best_effort() {
	local packages=("$@")
	local failed=()

	if [ "${#packages[@]}" -eq 0 ]; then
		return 0
	fi

	info "Installing ${#packages[@]} Fedora packages"
	if as_root_or_sudo dnf install -y "${packages[@]}"; then
		return 0
	fi

	warn "Bulk package install failed; retrying one by one"
	for pkg in "${packages[@]}"; do
		if as_root_or_sudo dnf install -y "$pkg"; then
			ok "Installed $pkg"
		else
			warn "Skipped unavailable or failing package: $pkg"
			failed+=("$pkg")
		fi
	done

	if [ "${#failed[@]}" -gt 0 ]; then
		warn "Some optional packages were not installed: ${failed[*]}"
	fi
}

add_repo_from_url() {
	local name="$1"
	local url="$2"
	local fallback_path="/etc/yum.repos.d/${name}.repo"

	info "Adding ${name} repo from ${url}"

	if as_root_or_sudo dnf config-manager addrepo --from-repofile="$url"; then
		return 0
	fi

	if as_root_or_sudo dnf config-manager --add-repo "$url"; then
		return 0
	fi

	warn "dnf config-manager could not add ${name}; falling back to repo file download"
	as_root_or_sudo curl -fsSLo "$fallback_path" "$url"
}

print_plan() {
	cat <<'EOF'
Fedora VM bootstrap plan

Baseline:
- Update Fedora packages.
- Add official LibreWolf Fedora repo.
- Add official Mullvad stable RPM repo.
- Install LibreWolf, Mullvad VPN, Git.
- Install CLI/TUI tools: tmux, zellij, vim, nano, ripgrep, fd, fzf, bat, btop,
  htop, ncdu, duf, jq, yq, tree, fastfetch, rsync, unzip, p7zip, ShellCheck.
- Install image/media terminal tools: chafa, ImageMagick, feh, imv, mpv.
- Enable and start the Mullvad daemon when available.

Hardening suggestions, each prompted before execution:
- Enable firewalld with default public zone.
- Ensure SELinux is enforcing.
- Enable fstrim.timer.
- Install and enable dnf-automatic for security updates.
- Install and enable fail2ban if sshd exists.
- Install auditd and enable the audit daemon.
- Install fapolicyd, but do not enable it automatically unless confirmed.
- Disable SSH password authentication only if you confirm it.
- Run a Lynis audit if you confirm it.

No Mullvad login is attempted; sign in with the Mullvad app or mullvad CLI later.
EOF
}

install_baseline() {
	local base_packages=(
		git
		curl
		wget
		ca-certificates
		dnf-plugins-core
	)

	local cli_packages=(
		tmux
		zellij
		vim
		nano
		ripgrep
		fd-find
		fzf
		bat
		btop
		htop
		ncdu
		duf
		jq
		yq
		tree
		fastfetch
		rsync
		unzip
		p7zip
		p7zip-plugins
		ShellCheck
	)

	local image_packages=(
		chafa
		ImageMagick
		feh
		imv
		mpv
	)

	info "Updating Fedora"
	as_root_or_sudo dnf upgrade --refresh -y

	dnf_install_best_effort "${base_packages[@]}"
	add_repo_from_url "librewolf" "$LIBREWOLF_REPO_URL"
	add_repo_from_url "mullvad" "$MULLVAD_REPO_URL"

	info "Refreshing repos"
	as_root_or_sudo dnf makecache -y

	dnf_install_best_effort librewolf mullvad-vpn
	dnf_install_best_effort "${cli_packages[@]}"
	dnf_install_best_effort "${image_packages[@]}"

	if systemctl list-unit-files mullvad-daemon.service >/dev/null 2>&1; then
		info "Enabling Mullvad daemon"
		as_root_or_sudo systemctl enable --now mullvad-daemon.service || warn "Could not start mullvad-daemon"
	else
		warn "mullvad-daemon.service not found after install"
	fi
}

enable_firewalld() {
	info "Installing/enabling firewalld"
	dnf_install_best_effort firewalld
	as_root_or_sudo systemctl enable --now firewalld
	as_root_or_sudo firewall-cmd --set-default-zone=public || true
	as_root_or_sudo firewall-cmd --state || true
}

ensure_selinux_enforcing() {
	info "Checking SELinux"
	if ! command -v getenforce >/dev/null 2>&1; then
		warn "getenforce not found; installing policycoreutils"
		dnf_install_best_effort policycoreutils
	fi

	if command -v getenforce >/dev/null 2>&1; then
		local mode
		mode="$(getenforce)"
		info "Current SELinux mode: $mode"
		if [ "$mode" != "Enforcing" ]; then
			as_root_or_sudo setenforce 1 || warn "setenforce failed; edit /etc/selinux/config if needed"
		fi
	fi

	if [ -f /etc/selinux/config ]; then
		as_root_or_sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
	fi
}

enable_fstrim() {
	info "Enabling fstrim timer"
	as_root_or_sudo systemctl enable --now fstrim.timer
}

enable_dnf_automatic() {
	info "Installing dnf-automatic"
	dnf_install_best_effort dnf-automatic
	if [ -f /etc/dnf/automatic.conf ]; then
		as_root_or_sudo sed -i 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf
		as_root_or_sudo sed -i 's/^upgrade_type = .*/upgrade_type = security/' /etc/dnf/automatic.conf
	fi
	as_root_or_sudo systemctl enable --now dnf-automatic.timer
}

enable_fail2ban_if_ssh() {
	if ! systemctl list-unit-files sshd.service >/dev/null 2>&1; then
		warn "sshd.service not present; skipping fail2ban"
		return 0
	fi

	info "Installing/enabling fail2ban for sshd"
	dnf_install_best_effort fail2ban
	as_root_or_sudo install -d -m 0755 /etc/fail2ban/jail.d
	as_root_or_sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<'EOF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
bantime = 1h
findtime = 10m
EOF
	as_root_or_sudo systemctl enable --now fail2ban
}

enable_auditd() {
	info "Installing/enabling auditd"
	dnf_install_best_effort audit
	as_root_or_sudo systemctl enable --now auditd || warn "auditd may require reboot or root session handling"
}

install_fapolicyd() {
	info "Installing fapolicyd"
	dnf_install_best_effort fapolicyd
	warn "fapolicyd can block unusual binaries. Test before relying on it."
	if confirm "Enable and start fapolicyd now?"; then
		as_root_or_sudo systemctl enable --now fapolicyd
	else
		warn "Installed fapolicyd but left it disabled"
	fi
}

disable_ssh_password_auth() {
	if ! systemctl list-unit-files sshd.service >/dev/null 2>&1; then
		warn "sshd.service not present; skipping SSH password hardening"
		return 0
	fi

	warn "Only do this if key login is already working."
	if confirm "Disable SSH password authentication?"; then
		as_root_or_sudo install -d -m 0755 /etc/ssh/sshd_config.d
		as_root_or_sudo tee /etc/ssh/sshd_config.d/99-disable-password-auth.conf >/dev/null <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
		as_root_or_sudo sshd -t
		as_root_or_sudo systemctl reload sshd
	fi
}

run_lynis() {
	info "Installing Lynis"
	dnf_install_best_effort lynis
	as_root_or_sudo lynis audit system
}

suggest_and_apply_hardening() {
	[ "$BASELINE_ONLY" -eq 0 ] || {
		warn "Skipping hardening prompts because --baseline-only was used"
		return 0
	}

	cat <<'EOF'

Hardening suggestions

Recommended low-risk:
1. Enable firewalld.
2. Ensure SELinux enforcing.
3. Enable fstrim.timer.

Useful but more opinionated:
4. Enable dnf-automatic security updates.
5. Enable fail2ban if SSH server exists.
6. Enable auditd.

Test carefully:
7. Install fapolicyd; optionally enable it.
8. Disable SSH password authentication.
9. Run Lynis audit.
EOF

	confirm "Apply firewalld hardening?" && enable_firewalld || warn "Skipped firewalld"
	confirm "Ensure SELinux enforcing?" && ensure_selinux_enforcing || warn "Skipped SELinux change"
	confirm "Enable fstrim.timer?" && enable_fstrim || warn "Skipped fstrim"
	confirm "Enable dnf-automatic security updates?" && enable_dnf_automatic || warn "Skipped dnf-automatic"
	confirm "Enable fail2ban for SSH if available?" && enable_fail2ban_if_ssh || warn "Skipped fail2ban"
	confirm "Enable auditd?" && enable_auditd || warn "Skipped auditd"
	confirm "Install fapolicyd?" && install_fapolicyd || warn "Skipped fapolicyd"
	disable_ssh_password_auth
	confirm "Run Lynis audit now?" && run_lynis || warn "Skipped Lynis audit"
}

print_next_steps() {
	cat <<'EOF'

Next steps:
- Reboot if Mullvad or kernel/security components request it.
- Log in to Mullvad:
    mullvad account login
    mullvad connect
- Or open the Mullvad GUI from the desktop menu.
- Check installed tools:
    librewolf --version
    git --version
    mullvad version
    fastfetch
EOF
}

main() {
	need_fedora
	print_plan

	if [ "$PLAN_ONLY" -eq 1 ]; then
		warn "Plan mode: no changes made"
		exit 0
	fi

	confirm "Install the Fedora VM baseline now?" || die "aborted"
	install_baseline
	suggest_and_apply_hardening
	print_next_steps
	ok "Fedora VM bootstrap complete"
}

main "$@"
