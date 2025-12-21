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

# Category: cloud
# Modules: 3

# Cloudflare Wrangler CLI
install_cloud_wrangler() {
    log_step "Installing cloud.wrangler"

    ~/.bun/bin/bun install -g wrangler

    # Verify
    wrangler --version || { log_error "Verify failed: cloud.wrangler"; return 1; }

    log_success "cloud.wrangler installed"
}

# Supabase CLI
install_cloud_supabase() {
    log_step "Installing cloud.supabase"

    ~/.bun/bin/bun install -g supabase

    # Verify
    supabase --version || { log_error "Verify failed: cloud.supabase"; return 1; }

    log_success "cloud.supabase installed"
}

# Vercel CLI
install_cloud_vercel() {
    log_step "Installing cloud.vercel"

    ~/.bun/bin/bun install -g vercel

    # Verify
    vercel --version || { log_error "Verify failed: cloud.vercel"; return 1; }

    log_success "cloud.vercel installed"
}

# Install all cloud modules
install_cloud() {
    log_section "Installing cloud modules"
    install_cloud_wrangler
    install_cloud_supabase
    install_cloud_vercel
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cloud
fi
