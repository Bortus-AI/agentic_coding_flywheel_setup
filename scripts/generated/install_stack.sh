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

# Category: stack
# Modules: 8

# Named tmux manager (agent cockpit)
install_stack_ntm() {
    log_step "Installing stack.ntm"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.ntm"
        return 1
    fi

    local tool="ntm"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s --

    # Verify
    ntm --help || { log_error "Verify failed: stack.ntm"; return 1; }

    log_success "stack.ntm installed"
}

# Like gmail for coding agents; MCP HTTP server + token; installs beads tools
install_stack_mcp_agent_mail() {
    log_step "Installing stack.mcp_agent_mail"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.mcp_agent_mail"
        return 1
    fi

    local tool="mcp_agent_mail"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s -- --yes

    # Verify
    command -v am || { log_error "Verify failed: stack.mcp_agent_mail"; return 1; }
    curl -fsS http://127.0.0.1:8765/health || log_warn "Optional: stack.mcp_agent_mail verify skipped"

    log_success "stack.mcp_agent_mail installed"
}

# UBS bug scanning (easy-mode)
install_stack_ultimate_bug_scanner() {
    log_step "Installing stack.ultimate_bug_scanner"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.ultimate_bug_scanner"
        return 1
    fi

    local tool="ubs"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s -- --easy-mode

    # Verify
    ubs --help || { log_error "Verify failed: stack.ultimate_bug_scanner"; return 1; }
    ubs doctor || log_warn "Optional: stack.ultimate_bug_scanner verify skipped"

    log_success "stack.ultimate_bug_scanner installed"
}

# bv TUI for Beads tasks
install_stack_beads_viewer() {
    log_step "Installing stack.beads_viewer"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.beads_viewer"
        return 1
    fi

    local tool="bv"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s --

    # Verify
    bv --help || bv --version || { log_error "Verify failed: stack.beads_viewer"; return 1; }

    log_success "stack.beads_viewer installed"
}

# Unified search across agent session history
install_stack_cass() {
    log_step "Installing stack.cass"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.cass"
        return 1
    fi

    local tool="cass"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s -- --easy-mode --verify

    # Verify
    cass --help || cass --version || { log_error "Verify failed: stack.cass"; return 1; }

    log_success "stack.cass installed"
}

# Procedural memory for agents (cass-memory)
install_stack_cm() {
    log_step "Installing stack.cm"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.cm"
        return 1
    fi

    local tool="cm"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s -- --easy-mode --verify

    # Verify
    cm --version || { log_error "Verify failed: stack.cm"; return 1; }
    cm doctor --json || log_warn "Optional: stack.cm verify skipped"

    log_success "stack.cm installed"
}

# Instant auth switching for agent CLIs
install_stack_caam() {
    log_step "Installing stack.caam"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.caam"
        return 1
    fi

    local tool="caam"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s --

    # Verify
    caam status || caam --help || { log_error "Verify failed: stack.caam"; return 1; }

    log_success "stack.caam installed"
}

# Two-person rule for dangerous commands (optional guardrails)
install_stack_slb() {
    log_step "Installing stack.slb"

    # Verified upstream installer script (checksums.yaml)
    if ! acfs_security_init; then
        log_error "Security verification unavailable for stack.slb"
        return 1
    fi

    local tool="slb"
    local url="${KNOWN_INSTALLERS[$tool]:-}"
    local expected_sha256
    expected_sha256="$(get_checksum "$tool")"
    if [[ -z "$url" ]] || [[ -z "$expected_sha256" ]]; then
        log_error "Missing checksum entry for $tool"
        return 1
    fi
    verify_checksum "$url" "$expected_sha256" "$tool" | bash -s --

    # Verify
    slb --help || { log_error "Verify failed: stack.slb"; return 1; }

    log_success "stack.slb installed"
}

# Install all stack modules
install_stack() {
    log_section "Installing stack modules"
    install_stack_ntm
    install_stack_mcp_agent_mail
    install_stack_ultimate_bug_scanner
    install_stack_beads_viewer
    install_stack_cass
    install_stack_cm
    install_stack_caam
    install_stack_slb
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_stack
fi
