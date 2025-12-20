#!/usr/bin/env bash
# ============================================================
# ACFS Installer - User Normalization Library
# Ensures consistent user setup across VPS providers
# ============================================================

# Target user for ACFS installations
ACFS_TARGET_USER="${ACFS_TARGET_USER:-ubuntu}"
ACFS_TARGET_HOME="/home/$ACFS_TARGET_USER"

# Ensure target user exists
# Creates user if missing, adds to required groups
ensure_user() {
    local target="$ACFS_TARGET_USER"

    if ! id "$target" &>/dev/null; then
        log_detail "Creating user: $target"
        $SUDO useradd -m -s /bin/bash -G sudo "$target"

        # Generate random password (user will use SSH key)
        local passwd
        passwd=$(openssl rand -base64 32)
        echo "$target:$passwd" | $SUDO chpasswd
    else
        log_detail "User $target already exists"
    fi

    # Ensure user is in required groups
    $SUDO usermod -aG sudo "$target" 2>/dev/null || true

    # Docker group (if docker is installed)
    if getent group docker &>/dev/null; then
        $SUDO usermod -aG docker "$target" 2>/dev/null || true
    fi
}

# Enable passwordless sudo for target user
# This is the "vibe mode" default
enable_passwordless_sudo() {
    local target="$ACFS_TARGET_USER"
    local sudoers_file="/etc/sudoers.d/90-ubuntu-acfs"

    log_detail "Enabling passwordless sudo for $target"

    echo "$target ALL=(ALL) NOPASSWD:ALL" | $SUDO tee "$sudoers_file" > /dev/null
    $SUDO chmod 440 "$sudoers_file"

    # Validate sudoers file
    if ! $SUDO visudo -c -f "$sudoers_file" &>/dev/null; then
        log_error "Invalid sudoers file generated, removing"
        $SUDO rm -f "$sudoers_file"
        return 1
    fi

    log_success "Passwordless sudo enabled"
}

# Copy SSH keys from current user to target user
# Handles root -> ubuntu key migration common on fresh VPS
migrate_ssh_keys() {
    local current_user
    current_user=$(whoami)
    local target="$ACFS_TARGET_USER"

    # Nothing to do if we're already the target user
    if [[ "$current_user" == "$target" ]]; then
        log_detail "Already running as $target, no key migration needed"
        return 0
    fi

    local source_keys=""

    # Check for keys in current user's home
    if [[ -f "$HOME/.ssh/authorized_keys" ]]; then
        source_keys="$HOME/.ssh/authorized_keys"
    fi

    # Check for root keys specifically
    if [[ $EUID -eq 0 ]] && [[ -f /root/.ssh/authorized_keys ]]; then
        source_keys="/root/.ssh/authorized_keys"
    fi

    if [[ -z "$source_keys" ]]; then
        log_warn "No SSH keys found to migrate"
        return 0
    fi

    log_detail "Migrating SSH keys from $source_keys"

    # Create .ssh directory for target user
    $SUDO mkdir -p "$ACFS_TARGET_HOME/.ssh"

    # Copy authorized_keys
    $SUDO cp "$source_keys" "$ACFS_TARGET_HOME/.ssh/authorized_keys"

    # Fix permissions
    $SUDO chown -R "$target:$target" "$ACFS_TARGET_HOME/.ssh"
    $SUDO chmod 700 "$ACFS_TARGET_HOME/.ssh"
    $SUDO chmod 600 "$ACFS_TARGET_HOME/.ssh/authorized_keys"

    log_success "SSH keys migrated to $target"
}

# Set default shell for target user
set_default_shell() {
    local shell="$1"
    local target="$ACFS_TARGET_USER"

    if [[ -z "$shell" ]]; then
        shell=$(which zsh)
    fi

    if [[ ! -x "$shell" ]]; then
        log_warn "Shell $shell not found or not executable"
        return 1
    fi

    log_detail "Setting default shell to $shell for $target"
    $SUDO chsh -s "$shell" "$target"
}

# Get current user info
get_current_user_info() {
    echo "Current user: $(whoami)"
    echo "Home: $HOME"
    echo "Shell: $SHELL"
    echo "UID: $EUID"
    echo "Groups: $(groups)"
}

# Check if we can sudo without password
can_sudo_nopasswd() {
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    return 1
}

# Full user normalization sequence
normalize_user() {
    log_step "1/8" "Normalizing user account..."

    ensure_user

    if [[ "${ACFS_MODE:-vibe}" == "vibe" ]]; then
        enable_passwordless_sudo
    fi

    migrate_ssh_keys

    log_success "User normalization complete"
}
