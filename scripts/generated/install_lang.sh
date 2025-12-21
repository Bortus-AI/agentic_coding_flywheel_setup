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

# Category: lang
# Modules: 4

# Bun runtime for JS tooling and global CLIs
install_lang_bun() {
    log_step "Installing lang.bun"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for lang.bun"
        return 1
    fi

    local tool="bun"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s --

    # Verify
    ~/.bun/bin/bun --version || { log_error "Verify failed: lang.bun"; return 1; }

    log_success "lang.bun installed"
}

# uv Python tooling (fast venvs)
install_lang_uv() {
    log_step "Installing lang.uv"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for lang.uv"
        return 1
    fi

    local tool="uv"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | sh

    # Verify
    ~/.local/bin/uv --version || { log_error "Verify failed: lang.uv"; return 1; }

    log_success "lang.uv installed"
}

# Rust + cargo
install_lang_rust() {
    log_step "Installing lang.rust"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for lang.rust"
        return 1
    fi

    local tool="rust"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | sh -s -- -y

    # Verify
    ~/.cargo/bin/cargo --version || { log_error "Verify failed: lang.rust"; return 1; }

    log_success "lang.rust installed"
}

# Go toolchain
install_lang_go() {
    log_step "Installing lang.go"

    sudo apt-get install -y golang-go

    # Verify
    go version || { log_error "Verify failed: lang.go"; return 1; }

    log_success "lang.go installed"
}

# Install all lang modules
install_lang() {
    log_section "Installing lang modules"
    install_lang_bun
    install_lang_uv
    install_lang_rust
    install_lang_go
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_lang
fi
