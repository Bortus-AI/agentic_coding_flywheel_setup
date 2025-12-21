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

# Category: agents
# Modules: 3

# Claude Code
install_agents_claude() {
    log_step "Installing agents.claude"

    # Install claude code via official method
    log_info "TODO: Install claude code via official method"

    # Verify
    claude --version || claude --help || { log_error "Verify failed: agents.claude"; return 1; }

    log_success "agents.claude installed"
}

# OpenAI Codex CLI
install_agents_codex() {
    log_step "Installing agents.codex"

    ~/.bun/bin/bun install -g @openai/codex@latest

    # Verify
    codex --version || codex --help || { log_error "Verify failed: agents.codex"; return 1; }

    log_success "agents.codex installed"
}

# Google Gemini CLI
install_agents_gemini() {
    log_step "Installing agents.gemini"

    ~/.bun/bin/bun install -g @google/gemini-cli@latest

    # Verify
    gemini --version || gemini --help || { log_error "Verify failed: agents.gemini"; return 1; }

    log_success "agents.gemini installed"
}

# Install all agents modules
install_agents() {
    log_section "Installing agents modules"
    install_agents_claude
    install_agents_codex
    install_agents_gemini
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_agents
fi
