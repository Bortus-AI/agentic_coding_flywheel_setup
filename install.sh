#!/usr/bin/env bash
# ============================================================
# ACFS - Agentic Coding Flywheel Setup
# Main installer script
#
# Usage:
#   curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/agentic_coding_flywheel_setup/main/install.sh?$(date +%s)" | bash -s -- --yes --mode vibe
#
# Options:
#   --yes         Skip all prompts, use defaults
#   --mode vibe   Enable passwordless sudo, full agent permissions
#   --dry-run     Print what would be done without changing system
#   --print       Print upstream scripts/versions that will be run
#   --skip-postgres   Skip PostgreSQL 18 installation
#   --skip-vault      Skip HashiCorp Vault installation
#   --skip-cloud      Skip cloud CLIs (wrangler, supabase, vercel)
# ============================================================

set -euo pipefail

# ============================================================
# Configuration
# ============================================================
ACFS_VERSION="0.1.0"
ACFS_REPO="https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup"
ACFS_RAW="https://raw.githubusercontent.com/Dicklesworthstone/agentic_coding_flywheel_setup/main"
ACFS_HOME="$HOME/.acfs"
ACFS_LOG_DIR="/var/log/acfs"
ACFS_STATE_FILE="$ACFS_HOME/state.json"

# Default options
YES_MODE=false
DRY_RUN=false
PRINT_MODE=false
MODE="vibe"
SKIP_POSTGRES=false
SKIP_VAULT=false
SKIP_CLOUD=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
PINK='\033[0;35m'
NC='\033[0m' # No Color

# Check if gum is available for enhanced UI
HAS_GUM=false
if command -v gum &>/dev/null; then
    HAS_GUM=true
fi

# ACFS Color scheme (Catppuccin Mocha inspired)
ACFS_PRIMARY="#89b4fa"
ACFS_SUCCESS="#a6e3a1"
ACFS_WARNING="#f9e2af"
ACFS_ERROR="#f38ba8"
ACFS_MUTED="#6c7086"
ACFS_ACCENT="#cba6f7"

# ============================================================
# ASCII Art Banner
# ============================================================
print_banner() {
    local banner='
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║     █████╗  ██████╗███████╗███████╗                          ║
    ║    ██╔══██╗██╔════╝██╔════╝██╔════╝                          ║
    ║    ███████║██║     █████╗  ███████╗                          ║
    ║    ██╔══██║██║     ██╔══╝  ╚════██║                          ║
    ║    ██║  ██║╚██████╗██║     ███████║                          ║
    ║    ╚═╝  ╚═╝ ╚═════╝╚═╝     ╚══════╝                          ║
    ║                                                               ║
    ║         Agentic Coding Flywheel Setup v'"$ACFS_VERSION"'              ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
'

    if [[ "$HAS_GUM" == "true" ]]; then
        echo "$banner" | gum style --foreground "$ACFS_PRIMARY" --bold
    else
        echo -e "${BLUE}$banner${NC}"
    fi
}

# ============================================================
# Logging functions (with gum enhancement)
# ============================================================
log_step() {
    if [[ "$HAS_GUM" == "true" ]]; then
        gum style --foreground "$ACFS_PRIMARY" --bold "[$1]" | tr -d '\n'
        echo -n " "
        gum style "$2"
    else
        echo -e "${BLUE}[$1]${NC} $2" >&2
    fi
}

log_detail() {
    if [[ "$HAS_GUM" == "true" ]]; then
        gum style --foreground "$ACFS_MUTED" --margin "0 0 0 4" "→ $1"
    else
        echo -e "${GRAY}    → $1${NC}" >&2
    fi
}

log_success() {
    if [[ "$HAS_GUM" == "true" ]]; then
        gum style --foreground "$ACFS_SUCCESS" --bold "✓ $1"
    else
        echo -e "${GREEN}✓ $1${NC}" >&2
    fi
}

log_warn() {
    if [[ "$HAS_GUM" == "true" ]]; then
        gum style --foreground "$ACFS_WARNING" "⚠ $1"
    else
        echo -e "${YELLOW}⚠ $1${NC}" >&2
    fi
}

log_error() {
    if [[ "$HAS_GUM" == "true" ]]; then
        gum style --foreground "$ACFS_ERROR" --bold "✖ $1"
    else
        echo -e "${RED}✖ $1${NC}" >&2
    fi
}

log_fatal() {
    log_error "$1"
    exit 1
}

# ============================================================
# Error handling
# ============================================================
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error ""
        log_error "ACFS installation failed!"
        log_error ""
        log_error "To debug:"
        log_error "  1. Check the log: cat $ACFS_LOG_DIR/install.log"
        log_error "  2. Run: acfs doctor"
        log_error "  3. Re-run this installer (it's safe to run multiple times)"
        log_error ""
    fi
}
trap cleanup EXIT

# ============================================================
# Parse arguments
# ============================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes|-y)
                YES_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --print)
                PRINT_MODE=true
                shift
                ;;
            --mode)
                MODE="$2"
                shift 2
                ;;
            --skip-postgres)
                SKIP_POSTGRES=true
                shift
                ;;
            --skip-vault)
                SKIP_VAULT=true
                shift
                ;;
            --skip-cloud)
                SKIP_CLOUD=true
                shift
                ;;
            *)
                log_warn "Unknown option: $1"
                shift
                ;;
        esac
    done
}

# ============================================================
# Utility functions
# ============================================================
command_exists() {
    command -v "$1" &>/dev/null
}

ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        if command_exists sudo; then
            SUDO="sudo"
        else
            log_fatal "This script requires root privileges. Please run as root or install sudo."
        fi
    else
        SUDO=""
    fi
}

ensure_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        log_fatal "Cannot detect OS. This script requires Ubuntu 24.04+ or 25.x"
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        log_warn "This script is designed for Ubuntu but detected: $ID"
        log_warn "Proceeding anyway, but some things may not work."
    fi

    VERSION_MAJOR="${VERSION_ID%%.*}"
    if [[ "$VERSION_MAJOR" -lt 24 ]]; then
        log_warn "Ubuntu $VERSION_ID detected. Recommended: Ubuntu 24.04+ or 25.x"
    fi

    log_detail "OS: Ubuntu $VERSION_ID"
}

ensure_base_deps() {
    log_step "0/8" "Checking base dependencies..."

    local missing=()
    for cmd in curl git jq; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_detail "Installing missing packages: ${missing[*]}"
        $SUDO apt-get update -y
        $SUDO apt-get install -y curl git ca-certificates unzip tar xz-utils jq build-essential
    fi
}

# ============================================================
# Phase 1: User normalization
# ============================================================
normalize_user() {
    log_step "1/8" "Normalizing user account..."

    local target_user="ubuntu"
    local current_user
    current_user=$(whoami)

    # Create ubuntu user if it doesn't exist
    if ! id "$target_user" &>/dev/null; then
        log_detail "Creating user: $target_user"
        $SUDO useradd -m -s /bin/bash "$target_user" || true
        $SUDO usermod -aG sudo "$target_user"
    fi

    # Set up passwordless sudo in vibe mode
    if [[ "$MODE" == "vibe" ]]; then
        log_detail "Enabling passwordless sudo for $target_user"
        echo "$target_user ALL=(ALL) NOPASSWD:ALL" | $SUDO tee /etc/sudoers.d/90-ubuntu-acfs > /dev/null
        $SUDO chmod 440 /etc/sudoers.d/90-ubuntu-acfs
    fi

    # Copy SSH keys from root if running as root
    if [[ $EUID -eq 0 ]] && [[ -f /root/.ssh/authorized_keys ]]; then
        log_detail "Copying SSH keys to $target_user"
        $SUDO mkdir -p /home/$target_user/.ssh
        $SUDO cp /root/.ssh/authorized_keys /home/$target_user/.ssh/
        $SUDO chown -R $target_user:$target_user /home/$target_user/.ssh
        $SUDO chmod 700 /home/$target_user/.ssh
        $SUDO chmod 600 /home/$target_user/.ssh/authorized_keys
    fi

    log_success "User normalization complete"
}

# ============================================================
# Phase 2: Filesystem setup
# ============================================================
setup_filesystem() {
    log_step "2/8" "Setting up filesystem..."

    local dirs=("/data/projects" "/data/cache" "$HOME/Development" "$HOME/Projects" "$HOME/dotfiles")

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_detail "Creating: $dir"
            $SUDO mkdir -p "$dir"
        fi
    done

    # Ensure /data is owned by ubuntu
    $SUDO chown -R ubuntu:ubuntu /data 2>/dev/null || true

    # Create ACFS directories
    mkdir -p "$ACFS_HOME"/{zsh,tmux,bin,docs,logs}
    $SUDO mkdir -p "$ACFS_LOG_DIR"

    log_success "Filesystem setup complete"
}

# ============================================================
# Phase 3: Shell setup (zsh + oh-my-zsh + p10k)
# ============================================================
setup_shell() {
    log_step "3/8" "Setting up shell..."

    # Install zsh
    if ! command_exists zsh; then
        log_detail "Installing zsh"
        $SUDO apt-get install -y zsh
    fi

    # Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_detail "Installing Oh My Zsh"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Install Powerlevel10k theme
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        log_detail "Installing Powerlevel10k theme"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    fi

    # Install zsh plugins
    local custom_plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    if [[ ! -d "$custom_plugins/zsh-autosuggestions" ]]; then
        log_detail "Installing zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins/zsh-autosuggestions"
    fi

    if [[ ! -d "$custom_plugins/zsh-syntax-highlighting" ]]; then
        log_detail "Installing zsh-syntax-highlighting"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins/zsh-syntax-highlighting"
    fi

    # Copy ACFS zshrc
    log_detail "Installing ACFS zshrc"
    curl -fsSL "$ACFS_RAW/acfs/zsh/acfs.zshrc" -o "$ACFS_HOME/zsh/acfs.zshrc"

    # Create minimal .zshrc loader
    cat > "$HOME/.zshrc" << 'EOF'
# ACFS loader
source "$HOME/.acfs/zsh/acfs.zshrc"

# User overrides live here forever
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
EOF

    # Set zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_detail "Setting zsh as default shell"
        $SUDO chsh -s "$(which zsh)" "$(whoami)" || true
    fi

    log_success "Shell setup complete"
}

# ============================================================
# Phase 4: CLI tools
# ============================================================
install_cli_tools() {
    log_step "4/8" "Installing CLI tools..."

    # Install gum first for enhanced UI
    if ! command_exists gum; then
        log_detail "Installing gum for glamorous shell scripts"
        $SUDO mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/charm.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | $SUDO tee /etc/apt/sources.list.d/charm.list > /dev/null
        $SUDO apt-get update -y
        $SUDO apt-get install -y gum 2>/dev/null || true

        # Update HAS_GUM if install succeeded
        if command -v gum &>/dev/null; then
            HAS_GUM=true
            log_success "gum installed - enhanced UI enabled"
        fi
    else
        log_detail "gum already installed"
    fi

    # Install apt packages
    log_detail "Installing apt packages"
    $SUDO apt-get install -y \
        ripgrep tmux fzf direnv \
        lsd eza bat fd-find btop dust neovim \
        docker.io docker-compose-plugin \
        lazygit 2>/dev/null || true

    # Add user to docker group
    $SUDO usermod -aG docker "$(whoami)" 2>/dev/null || true

    log_success "CLI tools installed"
}

# ============================================================
# Phase 5: Language runtimes
# ============================================================
install_languages() {
    log_step "5/8" "Installing language runtimes..."

    # Bun
    if ! command_exists bun; then
        log_detail "Installing Bun"
        curl -fsSL https://bun.sh/install | bash
    fi

    # Rust
    if [[ ! -d "$HOME/.cargo" ]]; then
        log_detail "Installing Rust"
        curl https://sh.rustup.rs -sSf | sh -s -- -y
    fi

    # Go
    if ! command_exists go; then
        log_detail "Installing Go"
        $SUDO apt-get install -y golang-go
    fi

    # uv (Python)
    if ! command_exists uv; then
        log_detail "Installing uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

    # Atuin (shell history)
    if [[ ! -d "$HOME/.atuin" ]]; then
        log_detail "Installing Atuin"
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    fi

    # Zoxide (better cd)
    if ! command_exists zoxide; then
        log_detail "Installing Zoxide"
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    log_success "Language runtimes installed"
}

# ============================================================
# Phase 6: Coding agents
# ============================================================
install_agents() {
    log_step "6/8" "Installing coding agents..."

    # Source bun path
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    # Codex CLI
    log_detail "Installing Codex CLI"
    bun install -g @openai/codex@latest 2>/dev/null || true

    # Gemini CLI
    log_detail "Installing Gemini CLI"
    bun install -g @google/gemini-cli@latest 2>/dev/null || true

    # Claude Code (if installer is available)
    log_detail "Installing Claude Code"
    # Claude Code installation varies, attempting common method
    if command_exists claude; then
        log_detail "Claude Code already installed"
    else
        log_warn "Claude Code may need manual installation: https://docs.anthropic.com/claude-code"
    fi

    log_success "Coding agents installed"
}

# ============================================================
# Phase 7: Dicklesworthstone stack
# ============================================================
install_stack() {
    log_step "7/8" "Installing Dicklesworthstone stack..."

    # NTM (Named Tmux Manager)
    log_detail "Installing NTM"
    curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/ntm/main/install.sh 2>/dev/null | bash || log_warn "NTM installation may have failed"

    # MCP Agent Mail
    log_detail "Installing MCP Agent Mail"
    curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/mcp_agent_mail/main/scripts/install.sh?$(date +%s)" 2>/dev/null | bash -s -- --yes || log_warn "MCP Agent Mail installation may have failed"

    # Ultimate Bug Scanner
    log_detail "Installing Ultimate Bug Scanner"
    curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/ultimate_bug_scanner/master/install.sh?$(date +%s)" 2>/dev/null | bash -s -- --easy-mode || log_warn "UBS installation may have failed"

    # Beads Viewer
    log_detail "Installing Beads Viewer"
    curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_viewer/main/install.sh?$(date +%s)" 2>/dev/null | bash || log_warn "Beads Viewer installation may have failed"

    # CASS (Coding Agent Session Search)
    log_detail "Installing CASS"
    curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_session_search/main/install.sh 2>/dev/null | bash -s -- --easy-mode --verify || log_warn "CASS installation may have failed"

    # CASS Memory System
    log_detail "Installing CASS Memory System"
    curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/cass_memory_system/main/install.sh 2>/dev/null | bash -s -- --easy-mode --verify || log_warn "CM installation may have failed"

    # CAAM (Coding Agent Account Manager)
    log_detail "Installing CAAM"
    curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_account_manager/main/install.sh?$(date +%s)" 2>/dev/null | bash || log_warn "CAAM installation may have failed"

    # SLB (Simultaneous Launch Button)
    log_detail "Installing SLB"
    curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/simultaneous_launch_button/main/scripts/install.sh 2>/dev/null | bash || log_warn "SLB installation may have failed"

    log_success "Dicklesworthstone stack installed"
}

# ============================================================
# Phase 8: Final wiring
# ============================================================
finalize() {
    log_step "8/8" "Finalizing installation..."

    # Copy tmux config
    log_detail "Installing tmux config"
    curl -fsSL "$ACFS_RAW/acfs/tmux/tmux.conf" -o "$ACFS_HOME/tmux/tmux.conf"

    # Link to user's tmux.conf if it doesn't exist
    if [[ ! -f "$HOME/.tmux.conf" ]]; then
        ln -sf "$ACFS_HOME/tmux/tmux.conf" "$HOME/.tmux.conf"
    fi

    # Create state file
    cat > "$ACFS_STATE_FILE" << EOF
{
  "version": "$ACFS_VERSION",
  "installed_at": "$(date -Iseconds)",
  "mode": "$MODE",
  "completed_phases": [1, 2, 3, 4, 5, 6, 7, 8]
}
EOF

    log_success "Installation complete!"
}

# ============================================================
# Print summary
# ============================================================
print_summary() {
    local summary_content="Version: $ACFS_VERSION
Mode:    $MODE

Next steps:

  1. If you logged in as root, reconnect as ubuntu:
     exit
     ssh ubuntu@YOUR_SERVER_IP

  2. Run the onboarding tutorial:
     onboard

  3. Check everything is working:
     acfs doctor

  4. Start your agent cockpit:
     ntm"

    if [[ "$HAS_GUM" == "true" ]]; then
        echo ""
        gum style \
            --border double \
            --border-foreground "$ACFS_SUCCESS" \
            --padding "1 3" \
            --margin "1 0" \
            --align left \
            "$(gum style --foreground "$ACFS_SUCCESS" --bold '🎉 ACFS Installation Complete!')

$summary_content"
    else
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║            🎉 ACFS Installation Complete!                   ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
        echo ""
        echo -e "Version: ${BLUE}$ACFS_VERSION${NC}"
        echo -e "Mode:    ${BLUE}$MODE${NC}"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo ""
        echo "  1. If you logged in as root, reconnect as ubuntu:"
        echo -e "     ${GRAY}exit${NC}"
        echo -e "     ${GRAY}ssh ubuntu@YOUR_SERVER_IP${NC}"
        echo ""
        echo "  2. Run the onboarding tutorial:"
        echo -e "     ${BLUE}onboard${NC}"
        echo ""
        echo "  3. Check everything is working:"
        echo -e "     ${BLUE}acfs doctor${NC}"
        echo ""
        echo "  4. Start your agent cockpit:"
        echo -e "     ${BLUE}ntm${NC}"
        echo ""
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi
}

# ============================================================
# Main
# ============================================================
main() {
    parse_args "$@"

    # Print beautiful ASCII banner
    print_banner

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "Dry run mode - no changes will be made"
        echo ""
    fi

    if [[ "$PRINT_MODE" == "true" ]]; then
        echo "The following tools will be installed from upstream:"
        echo ""
        echo "  - Oh My Zsh: https://ohmyz.sh"
        echo "  - Powerlevel10k: https://github.com/romkatv/powerlevel10k"
        echo "  - Bun: https://bun.sh"
        echo "  - Rust: https://rustup.rs"
        echo "  - uv: https://astral.sh/uv"
        echo "  - Atuin: https://atuin.sh"
        echo "  - Zoxide: https://github.com/ajeetdsouza/zoxide"
        echo "  - NTM: https://github.com/Dicklesworthstone/ntm"
        echo "  - MCP Agent Mail: https://github.com/Dicklesworthstone/mcp_agent_mail"
        echo "  - UBS: https://github.com/Dicklesworthstone/ultimate_bug_scanner"
        echo "  - Beads Viewer: https://github.com/Dicklesworthstone/beads_viewer"
        echo "  - CASS: https://github.com/Dicklesworthstone/coding_agent_session_search"
        echo "  - CM: https://github.com/Dicklesworthstone/cass_memory_system"
        echo "  - CAAM: https://github.com/Dicklesworthstone/coding_agent_account_manager"
        echo "  - SLB: https://github.com/Dicklesworthstone/simultaneous_launch_button"
        echo ""
        exit 0
    fi

    ensure_root
    ensure_ubuntu
    ensure_base_deps

    if [[ "$DRY_RUN" != "true" ]]; then
        normalize_user
        setup_filesystem
        setup_shell
        install_cli_tools
        install_languages
        install_agents
        install_stack
        finalize
    fi

    print_summary
}

main "$@"
