#!/usr/bin/env bash
# shellcheck disable=SC1091
# ============================================================
# AUTO-GENERATED FROM acfs.manifest.yaml - DO NOT EDIT
# Regenerate: bun run generate (from packages/manifest)
# ============================================================

set -euo pipefail

# Ensure logging functions available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/../lib/logging.sh" ]]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
else
    # Fallback logging functions if logging.sh not found
    log_step() { echo "[*] $*"; }
    log_section() { echo ""; echo "=== $* ==="; }
    log_success() { echo "[OK] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    log_warn() { echo "[WARN] $*" >&2; }
    log_info() { echo "    $*"; }
fi

# Category: shell
# Modules: 1

# Zsh + Oh My Zsh + Powerlevel10k + plugins + canonical ACFS zshrc
install_shell_zsh() {
    log_step "Installing shell.zsh"

    sudo apt-get install -y zsh
    # Install Oh My Zsh (non-interactive)
    log_info "TODO: Install Oh My Zsh (non-interactive)"
    # Install powerlevel10k theme
    log_info "TODO: Install powerlevel10k theme"
    # Install plugins: zsh-autosuggestions, zsh-syntax-highlighting
    log_info "TODO: Install plugins: zsh-autosuggestions, zsh-syntax-highlighting"
    # Write ~/.acfs/zsh/acfs.zshrc and source it from ~/.zshrc
    log_info "TODO: Write ~/.acfs/zsh/acfs.zshrc and source it from ~/.zshrc"

    # Verify
    zsh --version || { log_error "Verify failed: shell.zsh"; return 1; }
    test -f ~/.acfs/zsh/acfs.zshrc || { log_error "Verify failed: shell.zsh"; return 1; }

    log_success "shell.zsh installed"
}

# Install all shell modules
install_shell() {
    log_section "Installing shell modules"
    install_shell_zsh
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_shell
fi
