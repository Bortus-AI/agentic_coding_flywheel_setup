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

# Optional security verification for upstream installer scripts.
# Scripts that need it should call: acfs_security_init
ACFS_SECURITY_READY=false
acfs_security_init() {
    if [[ "${ACFS_SECURITY_READY}" == "true" ]]; then
        return 0
    fi

    local security_lib="$SCRIPT_DIR/../lib/security.sh"
    if [[ ! -f "$security_lib" ]]; then
        log_error "Security library not found: $security_lib"
        return 1
    fi

    # shellcheck source=../lib/security.sh
    # shellcheck disable=SC1091  # runtime relative source
    source "$security_lib"
    load_checksums || { log_error "Failed to load checksums.yaml"; return 1; }
    ACFS_SECURITY_READY=true
    return 0
}

# Category: cli
# Modules: 1

# Modern CLI tools referenced by the zshrc intent
install_cli_modern() {
    log_step "Installing cli.modern"

    sudo apt-get install -y ripgrep tmux fzf direnv jq gh git-lfs lsof dnsutils netcat-openbsd strace rsync
    sudo apt-get install -y lsd || true
    sudo apt-get install -y eza || true
    sudo apt-get install -y bat || sudo apt-get install -y batcat || true
    sudo apt-get install -y fd-find || true
    sudo apt-get install -y btop || true
    sudo apt-get install -y dust || true
    sudo apt-get install -y neovim || true
    sudo apt-get install -y docker.io docker-compose-plugin || true
    sudo apt-get install -y lazygit || true
    sudo apt-get install -y lazydocker || true

    # Verify
    rg --version || { log_error "Verify failed: cli.modern"; return 1; }
    tmux -V || { log_error "Verify failed: cli.modern"; return 1; }
    fzf --version || { log_error "Verify failed: cli.modern"; return 1; }
    gh --version || { log_error "Verify failed: cli.modern"; return 1; }
    git-lfs version || { log_error "Verify failed: cli.modern"; return 1; }
    rsync --version || { log_error "Verify failed: cli.modern"; return 1; }
    strace --version || { log_error "Verify failed: cli.modern"; return 1; }
    command -v lsof || { log_error "Verify failed: cli.modern"; return 1; }
    command -v dig || { log_error "Verify failed: cli.modern"; return 1; }
    command -v nc || { log_error "Verify failed: cli.modern"; return 1; }
    command -v lsd || command -v eza || log_warn "Optional: cli.modern verify skipped"

    log_success "cli.modern installed"
}

# Install all cli modules
install_cli() {
    log_section "Installing cli modules"
    install_cli_modern
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cli
fi
