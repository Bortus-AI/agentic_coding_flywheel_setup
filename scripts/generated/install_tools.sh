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

# Category: tools
# Modules: 4

# Atuin shell history (Ctrl-R superpowers)
install_tools_atuin() {
    log_step "Installing tools.atuin"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for tools.atuin"
        return 1
    fi

    local tool="atuin"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | sh

    # Verify
    ~/.atuin/bin/atuin --version || { log_error "Verify failed: tools.atuin"; return 1; }

    log_success "tools.atuin installed"
}

# Zoxide (better cd)
install_tools_zoxide() {
    log_step "Installing tools.zoxide"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for tools.zoxide"
        return 1
    fi

    local tool="zoxide"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | sh

    # Verify
    command -v zoxide || { log_error "Verify failed: tools.zoxide"; return 1; }

    log_success "tools.zoxide installed"
}

# ast-grep (used by UBS for syntax-aware scanning)
install_tools_ast_grep() {
    log_step "Installing tools.ast_grep"

    ~/.cargo/bin/cargo install ast-grep --locked

    # Verify
    sg --version || { log_error "Verify failed: tools.ast_grep"; return 1; }

    log_success "tools.ast_grep installed"
}

# HashiCorp Vault CLI
install_tools_vault() {
    log_step "Installing tools.vault"

    # Install Vault via official HashiCorp instructions (apt repo or binary)
    log_info "TODO: Install Vault via official HashiCorp instructions (apt repo or binary)"

    # Verify
    vault --version || { log_error "Verify failed: tools.vault"; return 1; }

    log_success "tools.vault installed"
}

# Install all tools modules
install_tools() {
    log_section "Installing tools modules"
    install_tools_atuin
    install_tools_zoxide
    install_tools_ast_grep
    install_tools_vault
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_tools
fi
