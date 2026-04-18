#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tests/helpers/assert.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/setup.sh"

CAPTURED_COMMANDS=()

run_cmd() {
    CAPTURED_COMMANDS+=("$*")
}

info() { :; }
success() { :; }
warn() { :; }

prompt_yes_no() {
    return 0
}

has_cmd() {
    return 1
}

fnm_has_lts() {
    return 1
}

OS="arch"

CAPTURED_COMMANDS=()
SHELL_CHOICE="fish"
install_shell_arch
assert_contains "${CAPTURED_COMMANDS[*]}" 'sudo pacman -S --needed fish'

CAPTURED_COMMANDS=()
SHELL_CHOICE="zsh"
install_shell_arch
assert_contains "${CAPTURED_COMMANDS[*]}" 'sudo pacman -S --needed zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions'
assert_not_contains "${CAPTURED_COMMANDS[*]}" 'git clone https://github.com/zsh-users'
assert_not_contains "${CAPTURED_COMMANDS[*]}" 'apt-add-repository'

CAPTURED_COMMANDS=()
install_cli_tools_arch
assert_contains "${CAPTURED_COMMANDS[*]}" 'sudo pacman -S --needed bat eza fd ripgrep jq fzf btop zoxide tealdeer git-delta lazygit'
assert_not_contains "${CAPTURED_COMMANDS[*]}" 'snap install'

CAPTURED_COMMANDS=()
install_starship
assert_contains "${CAPTURED_COMMANDS[*]}" 'sudo pacman -S --needed starship'

CAPTURED_COMMANDS=()
install_fnm_and_node
assert_contains "${CAPTURED_COMMANDS[*]}" 'sudo pacman -S --needed fnm'
assert_contains "${CAPTURED_COMMANDS[*]}" 'fnm install --lts'
assert_contains "${CAPTURED_COMMANDS[*]}" 'fnm default lts-latest'

CAPTURED_COMMANDS=()
install_zellij
assert_contains "${CAPTURED_COMMANDS[*]}" 'sudo pacman -S --needed zellij'

echo "PASS: package flows"
