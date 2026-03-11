#!/usr/bin/env bash
# mkalias installer

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="mkalias"
REPO_URL="https://raw.githubusercontent.com/Zamyrig/alias_tweak/main/mkalias/mkalias"

info()    { echo -e "${CYAN}::${RESET} $*"; }
success() { echo -e "${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "${RED}✖${RESET}  $*" >&2; exit 1; }

echo ""
echo -e "${BOLD}  mkalias installer${RESET}"
echo -e "  ──────────────────────────"
echo ""

# Check for sudo
if [[ $EUID -ne 0 ]]; then
    error "Please run the installer with sudo: sudo bash install.sh"
fi

# Download or copy
if command -v curl &>/dev/null; then
    info "Downloading mkalias..."
    curl -fsSL "$REPO_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"
elif [[ -f "./mkalias" ]]; then
    info "Copying local mkalias..."
    cp "./mkalias" "$INSTALL_DIR/$SCRIPT_NAME"
else
    error "curl not found and no local mkalias file. Please install curl or clone the repo."
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
success "Installed to $INSTALL_DIR/$SCRIPT_NAME"

# ─── Fish shell integration ───────────────────────────────────────────────────
FISH_CONF_DIR="/etc/fish/conf.d"
if command -v fish &>/dev/null; then
    info "Setting up Fish shell integration..."
    mkdir -p "$FISH_CONF_DIR"
    cat > "$FISH_CONF_DIR/mkalias.fish" <<'EOF'
# mkalias — load global and user aliases as fish functions
# Fish functions are loaded automatically from ~/.config/fish/functions/
# and /etc/fish/functions/ — mkalias writes .fish files there directly.
# This conf.d file is a no-op placeholder for awareness.
EOF
    success "Fish integration ready (functions written per alias, no extra config needed)"
else
    warn "Fish not found — skipping fish integration"
fi

# ─── Bash / Zsh integration ───────────────────────────────────────────────────
BASHRC_LINE='eval "$(mkalias --source-bash 2>/dev/null)" # mkalias'
ZSH_LINE='eval "$(mkalias --source-bash 2>/dev/null)" # mkalias'

integrate_shell() {
    local rcfile="$1"
    local line="$2"
    if [[ -f "$rcfile" ]] && ! grep -q "# mkalias" "$rcfile"; then
        echo "" >> "$rcfile"
        echo "$line" >> "$rcfile"
        success "Added mkalias loader to $rcfile"
    fi
}

for user_home in /root /home/*/; do
    [[ -d "$user_home" ]] || continue
    integrate_shell "$user_home/.bashrc" "$BASHRC_LINE"
    integrate_shell "$user_home/.zshrc"  "$ZSH_LINE"
done

echo ""
echo -e "${BOLD}  Done! 🎉${RESET}"
echo ""
echo -e "  Try: ${CYAN}mkalias dc=docker-compose${RESET}"
echo -e "       ${CYAN}mkalias -l${RESET}"
echo -e "       ${CYAN}sudo mkalias -g m=micro${RESET}"
echo ""