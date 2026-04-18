#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tests/helpers/assert.sh"

fish_config="$(cat "$ROOT_DIR/configs/config.fish")"
zsh_config="$(cat "$ROOT_DIR/configs/.zshrc")"
setup_script="$(cat "$ROOT_DIR/setup.sh")"

assert_not_contains "$fish_config" '/opt/homebrew'
assert_contains "$fish_config" '$HOME/.local/share/pnpm'
assert_contains "$fish_config" 'fish_add_path $HOME/.local/bin'
assert_contains "$fish_config" 'zoxide init fish | source'
assert_contains "$fish_config" 'abbr -a ls "eza --icons --group-directories-first"'

assert_not_contains "$zsh_config" 'BREW_PREFIX='
assert_contains "$zsh_config" 'export PATH="$HOME/.local/bin:$PATH"'
assert_contains "$zsh_config" '/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
assert_contains "$zsh_config" '/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
assert_contains "$zsh_config" '$HOME/.local/share/pnpm'

assert_not_contains "$setup_script" "sed -i 's|/opt/homebrew"
assert_not_contains "$setup_script" 'Patch Homebrew paths'

echo "PASS: config templates"
