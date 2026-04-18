#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    if [[ "$expected" != "$actual" ]]; then
        fail "expected [$expected], got [$actual]"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        fail "expected output to contain [$needle]"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" == *"$needle"* ]]; then
        fail "expected output not to contain [$needle]"
    fi
}

assert_function_defined() {
    local fn_name="$1"
    if ! declare -F "$fn_name" >/dev/null; then
        fail "expected function [$fn_name] to be defined"
    fi
}
