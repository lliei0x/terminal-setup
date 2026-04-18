#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/tests/helpers/assert.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/setup.sh"

assert_function_defined detect_platform

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/os-release.arch" <<'EOF'
NAME="Arch Linux"
ID=arch
ID_LIKE=archlinux
EOF

cat > "$TMP_DIR/os-release.ubuntu" <<'EOF'
NAME="Ubuntu"
ID=ubuntu
ID_LIKE=debian
EOF

cat > "$TMP_DIR/proc-version.native" <<'EOF'
Linux version 6.14.2-arch1-1
EOF

cat > "$TMP_DIR/proc-version.wsl" <<'EOF'
Linux version 6.6.87.2-microsoft-standard-WSL2
EOF

assert_eq \
    "arch" \
    "$(SETUP_UNAME=Linux SETUP_OS_RELEASE_FILE="$TMP_DIR/os-release.arch" SETUP_PROC_VERSION_FILE="$TMP_DIR/proc-version.native" detect_platform)"

assert_eq \
    "arch-wsl" \
    "$(SETUP_UNAME=Linux SETUP_OS_RELEASE_FILE="$TMP_DIR/os-release.arch" SETUP_PROC_VERSION_FILE="$TMP_DIR/proc-version.wsl" detect_platform)"

assert_eq \
    "unsupported-linux" \
    "$(SETUP_UNAME=Linux SETUP_OS_RELEASE_FILE="$TMP_DIR/os-release.ubuntu" SETUP_PROC_VERSION_FILE="$TMP_DIR/proc-version.native" detect_platform)"

assert_eq \
    "windows-native" \
    "$(SETUP_UNAME=MINGW64_NT-10.0 detect_platform)"

echo "PASS: platform detection"
