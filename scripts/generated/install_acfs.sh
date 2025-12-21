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

# Category: acfs
# Modules: 2

# Onboarding TUI tutorial
install_acfs_onboard() {
    log_step "Installing acfs.onboard"

    # Install onboard script to ~/.local/bin/onboard
    log_info "TODO: Install onboard script to ~/.local/bin/onboard"

    # Verify
    onboard --help || command -v onboard || { log_error "Verify failed: acfs.onboard"; return 1; }

    log_success "acfs.onboard installed"
}

# ACFS doctor command for health checks
install_acfs_doctor() {
    log_step "Installing acfs.doctor"

    # Install acfs script to ~/.local/bin/acfs
    log_info "TODO: Install acfs script to ~/.local/bin/acfs"

    # Verify
    acfs doctor --help || command -v acfs || { log_error "Verify failed: acfs.doctor"; return 1; }

    log_success "acfs.doctor installed"
}

# Install all acfs modules
install_acfs() {
    log_section "Installing acfs modules"
    install_acfs_onboard
    install_acfs_doctor
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_acfs
fi
