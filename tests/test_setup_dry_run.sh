#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tests/helpers/assert.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/os-release.arch" <<'EOF'
NAME="Arch Linux"
ID=arch
ID_LIKE=archlinux
EOF

cat > "$TMP_DIR/proc-version.native" <<'EOF'
Linux version 6.14.2-arch1-1
EOF

cat > "$TMP_DIR/proc-version.wsl" <<'EOF'
Linux version 6.6.87.2-microsoft-standard-WSL2
EOF

arch_output="$(
    SETUP_UNAME=Linux \
    SETUP_OS_RELEASE_FILE="$TMP_DIR/os-release.arch" \
    SETUP_PROC_VERSION_FILE="$TMP_DIR/proc-version.native" \
    bash "$ROOT_DIR/setup.sh" --dry-run --fish 2>&1
)"

assert_contains "$arch_output" 'Step 1/8: Package Manager'
assert_contains "$arch_output" 'Step 8/8: Deploying Configs'
assert_contains "$arch_output" 'sudo pacman-key --init'
assert_contains "$arch_output" 'sudo pacman-key --populate archlinux'
assert_contains "$arch_output" 'sudo pacman -Syu'
assert_contains "$arch_output" 'mirrors.tuna.tsinghua.edu.cn'
assert_contains "$arch_output" 'mirrors.ustc.edu.cn'
assert_contains "$arch_output" 'mirrors.aliyun.com'
assert_contains "$arch_output" 'configs/pacman-mirrorlist'
assert_contains "$arch_output" '/etc/pacman.d/mirrorlist'
assert_contains "$arch_output" 'sudo pacman -Syyu'
assert_contains "$arch_output" 'sudo pacman -S reflector'
assert_contains "$arch_output" 'sudo reflector -c China -a 12 -p https --sort rate --save /etc/pacman.d/mirrorlist'
assert_contains "$arch_output" 'sudo pacman -S --needed curl git wget unzip base-devel'
assert_not_contains "$arch_output" 'sudo vim /etc/pacman.d/mirrorlist'
assert_not_contains "$arch_output" 'Nerd Font'
assert_not_contains "$arch_output" 'apt-get'
assert_not_contains "$arch_output" 'brew install'

wsl_output="$(
    SETUP_UNAME=Linux \
    SETUP_OS_RELEASE_FILE="$TMP_DIR/os-release.arch" \
    SETUP_PROC_VERSION_FILE="$TMP_DIR/proc-version.wsl" \
    bash "$ROOT_DIR/setup.sh" --dry-run --fish 2>&1
)"

assert_contains "$wsl_output" 'Detected Arch Linux inside WSL'
assert_contains "$wsl_output" 'Ghostty for Windows'
assert_contains "$wsl_output" 'Windows Terminal'

echo "PASS: dry-run flow"
