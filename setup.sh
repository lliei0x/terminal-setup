#!/usr/bin/env bash
#
# terminal-setup
# Arch Linux / WSL Arch terminal environment setup
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

DRY_RUN=false
SHELL_CHOICE=""
OS=""
SCRIPT_DIR=""
CONFIGS_DIR=""
PACMAN_MIRRORLIST_TEMPLATE=""

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
    exit 1
}

run_cmd() {
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

step_header() {
    local title="$1"
    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}  ${title}${NC}"
    echo -e "${BOLD}========================================${NC}"
}

parse_args() {
    SHELL_CHOICE=""
    DRY_RUN=false

    for arg in "$@"; do
        case "$arg" in
            --fish) SHELL_CHOICE="fish" ;;
            --zsh) SHELL_CHOICE="zsh" ;;
            --dry-run) DRY_RUN=true ;;
            *)
                error "Unknown argument: $arg"
                ;;
        esac
    done
}

get_uname() {
    if [[ -n "${SETUP_UNAME:-}" ]]; then
        printf '%s\n' "$SETUP_UNAME"
    else
        uname -s
    fi
}

get_os_release_file() {
    printf '%s\n' "${SETUP_OS_RELEASE_FILE:-/etc/os-release}"
}

get_proc_version_file() {
    printf '%s\n' "${SETUP_PROC_VERSION_FILE:-/proc/version}"
}

is_arch_linux() {
    local os_release_file
    os_release_file="$(get_os_release_file)"

    [[ -f "$os_release_file" ]] || return 1
    grep -qiE '^(ID|ID_LIKE)=.*arch' "$os_release_file"
}

is_wsl_environment() {
    local proc_version_file
    proc_version_file="$(get_proc_version_file)"

    [[ -f "$proc_version_file" ]] || return 1
    grep -qiE '(microsoft|wsl)' "$proc_version_file"
}

detect_platform() {
    local uname_out
    uname_out="$(get_uname)"

    case "$uname_out" in
        Linux)
            if is_arch_linux; then
                if is_wsl_environment; then
                    echo "arch-wsl"
                else
                    echo "arch"
                fi
            else
                echo "unsupported-linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows-native"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

announce_platform() {
    case "$1" in
        arch)
            info "Detected Arch Linux"
            ;;
        arch-wsl)
            info "Detected Arch Linux inside WSL"
            ;;
        windows-native)
            error "Native Windows (MINGW/MSYS/Cygwin) is not supported.\n  Please install and enter WSL Arch first."
            ;;
        unsupported-linux)
            error "Unsupported Linux distribution.\n  This script now supports Arch Linux only."
            ;;
        *)
            error "Unsupported OS: $(get_uname)\n  This script now supports Arch Linux / WSL Arch only."
            ;;
    esac
}

prompt_yes_no() {
    local prompt="$1"
    printf "%s" "$prompt"
    read -r reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

shell_path_or_default() {
    local shell_name="$1"
    local shell_path=""

    if shell_path="$(command -v "$shell_name" 2>/dev/null)"; then
        printf '%s\n' "$shell_path"
    else
        printf '/usr/bin/%s\n' "$shell_name"
    fi
}

ensure_dir() {
    run_cmd mkdir -p "$1"
}

pkg_install() {
    local packages=("$@")

    if ((${#packages[@]} == 0)); then
        return 0
    fi

    info "Installing packages: ${packages[*]}"
    run_cmd sudo pacman -S --needed "${packages[@]}"
}

fnm_has_lts() {
    fnm list 2>/dev/null | grep -q 'lts'
}

configure_arch_package_manager() {
    info "Initializing pacman keyring..."
    run_cmd sudo pacman-key --init
    run_cmd sudo pacman-key --populate archlinux

    info "Replacing /etc/pacman.d/mirrorlist with the bundled China mirror list..."
    echo '  Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch'
    echo '  Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch'
    echo '  Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch'
    if [[ -f /etc/pacman.d/mirrorlist ]]; then
        run_cmd sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    fi
    run_cmd sudo cp "$PACMAN_MIRRORLIST_TEMPLATE" /etc/pacman.d/mirrorlist

    info "Refreshing packages against the updated mirrorlist..."
    run_cmd sudo pacman -Syyu

    info "Installing reflector..."
    run_cmd sudo pacman -S reflector

    info "Generating the fastest China mirror list with reflector..."
    run_cmd sudo reflector -c China -a 12 -p https --sort rate --save /etc/pacman.d/mirrorlist
}

install_terminal_emulator() {
    case "$OS" in
        arch)
            if has_cmd ghostty; then
                success "Ghostty already installed"
            else
                info "Installing Ghostty..."
                pkg_install ghostty
                success "Ghostty installed"
            fi
            ;;
        arch-wsl)
            info "WSL detected - terminal emulator runs on the Windows side."
            echo -e "  Install Ghostty for Windows: ${BOLD}https://ghostty.org${NC}"
            echo -e "  Or use Windows Terminal, which works great with WSL."
            info "Skipping terminal emulator installation."
            ;;
    esac
}

install_shell_arch() {
    if [[ "$SHELL_CHOICE" == "fish" ]]; then
        if ! has_cmd fish; then
            info "Installing Fish..."
            pkg_install fish
            success "Fish installed"
        else
            success "Fish already installed"
        fi

        local fish_path
        fish_path="$(shell_path_or_default fish)"
        if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
            info "Adding Fish to /etc/shells..."
            run_cmd sudo sh -c "printf '%s\n' '$fish_path' >> /etc/shells"
        fi

        if [[ "${SHELL:-}" != "$fish_path" ]]; then
            info "Setting Fish as default shell..."
            run_cmd chsh -s "$fish_path"
        fi
    else
        local zsh_packages=(zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
        info "Installing Zsh and plugins..."
        pkg_install "${zsh_packages[@]}"

        local zsh_path
        zsh_path="$(shell_path_or_default zsh)"
        if [[ "${SHELL:-}" != "$zsh_path" ]]; then
            info "Setting Zsh as default shell..."
            run_cmd chsh -s "$zsh_path"
        fi
    fi
}

install_cli_tools_arch() {
    local cli_packages=(
        bat
        eza
        fd
        ripgrep
        jq
        fzf
        btop
        zoxide
        tealdeer
        git-delta
        lazygit
    )

    pkg_install "${cli_packages[@]}"
}

install_starship() {
    if has_cmd starship; then
        success "Starship already installed"
    else
        info "Installing Starship..."
        pkg_install starship
        success "Starship installed"
    fi
}

install_fnm_and_node() {
    local manage_node=false

    if has_cmd fnm; then
        success "fnm already installed"
        manage_node=true
    elif prompt_yes_no "  Install fnm + Node.js? (y/N, default: N): "; then
        info "Installing fnm..."
        pkg_install fnm
        success "fnm installed"
        manage_node=true
    else
        info "Skipping fnm + Node.js"
        return 0
    fi

    if $manage_node; then
        if has_cmd fnm; then
            eval "$(fnm env --use-on-cd --shell bash)"
        fi
        if ! fnm_has_lts; then
            info "Installing Node LTS..."
            run_cmd fnm install --lts
            run_cmd fnm default lts-latest
            run_cmd fnm use lts-latest
            success "Node LTS installed and set as default"
        else
            success "Node LTS already installed"
        fi
    fi
}

install_zellij() {
    if has_cmd zellij; then
        success "Zellij already installed"
    elif prompt_yes_no "  Install Zellij? (y/N): "; then
        info "Installing Zellij..."
        pkg_install zellij
        success "Zellij installed"
    else
        info "Skipping Zellij"
    fi
}

deploy_ghostty_config() {
    local ghostty_config_dir="$HOME/.config/ghostty"

    if [[ "$OS" == "arch-wsl" ]]; then
        info "Ghostty config: configure on the Windows side if using Ghostty for Windows."
        info "Deploying Linux-side config to ~/.config/ghostty/ for reference."
    fi

    ensure_dir "$ghostty_config_dir"
    if [[ -f "$ghostty_config_dir/config" ]]; then
        run_cmd cp "$ghostty_config_dir/config" "$ghostty_config_dir/config.bak.$(date +%s)"
        warn "Backed up existing Ghostty config"
    fi

    run_cmd cp "$CONFIGS_DIR/ghostty.config" "$ghostty_config_dir/config"
    success "Ghostty config deployed"
}

deploy_starship_config() {
    ensure_dir "$HOME/.config"
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        run_cmd cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
        warn "Backed up existing starship.toml"
    fi

    run_cmd cp "$CONFIGS_DIR/starship.toml" "$HOME/.config/starship.toml"
    success "Starship config deployed"
}

deploy_shell_config() {
    if [[ "$SHELL_CHOICE" == "fish" ]]; then
        local fish_config_dir="$HOME/.config/fish"
        ensure_dir "$fish_config_dir"

        if [[ -f "$fish_config_dir/config.fish" ]]; then
            run_cmd cp "$fish_config_dir/config.fish" "$fish_config_dir/config.fish.bak.$(date +%s)"
            warn "Backed up existing config.fish"
        fi

        run_cmd cp "$CONFIGS_DIR/config.fish" "$fish_config_dir/config.fish"
        success "Fish config deployed"
    else
        if [[ -f "$HOME/.zshrc" ]]; then
            run_cmd cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
            warn "Backed up existing .zshrc"
        fi

        run_cmd cp "$CONFIGS_DIR/.zshrc" "$HOME/.zshrc"
        success "Zsh config deployed"
    fi
}

configure_git_delta() {
    if has_cmd delta || $DRY_RUN; then
        info "Configuring git-delta as git pager..."
        run_cmd git config --global core.pager delta
        run_cmd git config --global interactive.diffFilter "delta --color-only"
        run_cmd git config --global delta.navigate true
        run_cmd git config --global delta.dark true
        run_cmd git config --global delta.line-numbers true
        run_cmd git config --global delta.side-by-side true
        run_cmd git config --global merge.conflictstyle diff3
        run_cmd git config --global diff.colorMoved default
        success "git-delta configured"
    fi
}

choose_shell_if_needed() {
    if [[ -n "$SHELL_CHOICE" ]]; then
        return 0
    fi

    echo ""
    echo -e "${BOLD}Which shell do you want to use?${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} ${BOLD}Fish${NC}"
    echo -e "  ${GREEN}2)${NC} ${BOLD}Zsh${NC}"
    echo ""

    while true; do
        read -rp "Choose [1/2]: " choice
        case "$choice" in
            1|fish)
                SHELL_CHOICE="fish"
                break
                ;;
            2|zsh)
                SHELL_CHOICE="zsh"
                break
                ;;
            *)
                echo "Please enter 1 or 2."
                ;;
        esac
    done
}

print_summary() {
    echo ""
    echo -e "${BOLD}========================================${NC}"
    if $DRY_RUN; then
        echo -e "${YELLOW}${BOLD}  DRY-RUN complete - no changes were made${NC}"
    else
        echo -e "${GREEN}${BOLD}  All done!${NC}"
    fi
    echo -e "${BOLD}========================================${NC}"
    echo ""
    echo -e "  ${BOLD}Platform:${NC} $OS"
    echo -e "  ${BOLD}Shell:${NC} $SHELL_CHOICE"
    if [[ "$OS" == "arch-wsl" ]]; then
        echo -e "  ${BOLD}Terminal:${NC} Ghostty for Windows or Windows Terminal"
    else
        echo -e "  ${BOLD}Terminal:${NC} Ghostty"
    fi
    echo -e "  ${BOLD}Package manager:${NC} pacman"
    echo ""
}

run_setup_flow() {
    step_header "Step 1/8: Package Manager"
    configure_arch_package_manager
    pkg_install curl git wget
    success "pacman package manager ready"

    step_header "Step 2/8: Terminal Emulator"
    install_terminal_emulator

    step_header "Step 3/8: Shell"
    install_shell_arch

    step_header "Step 4/8: CLI Tools"
    install_cli_tools_arch

    step_header "Step 5/8: Starship Prompt"
    install_starship

    step_header "Step 6/8: fnm + Node.js (optional)"
    install_fnm_and_node

    step_header "Step 7/8: Zellij (optional)"
    install_zellij

    step_header "Step 8/8: Deploying Configs"
    deploy_ghostty_config
    deploy_starship_config
    deploy_shell_config
    configure_git_delta
}

init_runtime() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIGS_DIR="$SCRIPT_DIR/configs"
    PACMAN_MIRRORLIST_TEMPLATE="$CONFIGS_DIR/pacman-mirrorlist"
    OS="$(detect_platform)"
}

main() {
    parse_args "$@"

    if $DRY_RUN; then
        echo ""
        echo -e "${YELLOW}${BOLD}  DRY-RUN MODE - no changes will be made${NC}"
        echo ""
    fi

    init_runtime
    announce_platform "$OS"
    choose_shell_if_needed

    echo ""
    info "Setting up with ${BOLD}${SHELL_CHOICE}${NC} on ${BOLD}${OS}${NC}"

    run_setup_flow
    print_summary
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
