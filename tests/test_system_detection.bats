#!/usr/bin/env bats
load test_helper

# =============================================================================
# System Detection Tests for zutils.zsh
# =============================================================================
# Tests for: is_macos, get_architecture, is_apple_silicon, is_intel,
#            get_macos_version
#
# Strategy: First test actual platform behavior, then use mocked uname to test
# the opposite platform path.
# =============================================================================

# --- Helper: create a mock uname script -----------------------------------

# Creates a mock uname in TEST_TMPDIR that returns controlled values.
# Usage: create_mock_uname <uname_output> <uname_m_output>
#   $1 - What `uname` (no args) returns (e.g. "Darwin" or "Linux")
#   $2 - What `uname -m` returns (e.g. "arm64" or "x86_64")
create_mock_uname() {
    local kernel_name="${1}"
    local machine="${2}"
    cat > "${TEST_TMPDIR}/uname" <<SCRIPT
#!/bin/bash
if [[ "\$1" == "-m" ]]; then
    echo "${machine}"
else
    echo "${kernel_name}"
fi
SCRIPT
    chmod +x "${TEST_TMPDIR}/uname"
    export PATH="${TEST_TMPDIR}:${PATH}"
}

# =============================================================================
# is_macos - actual platform tests
# =============================================================================

@test "is_macos: returns 0 on macOS, 1 on Linux (actual platform)" {
    run is_macos
    if [[ "$(command uname)" == "Darwin" ]]; then
        [ "$status" -eq 0 ]
    else
        [ "$status" -eq 1 ]
    fi
}

# =============================================================================
# is_macos - mocked platform tests
# =============================================================================

@test "is_macos: returns 0 when uname reports Darwin (mocked)" {
    create_mock_uname "Darwin" "arm64"
    run is_macos
    [ "$status" -eq 0 ]
}

@test "is_macos: returns 1 when uname reports Linux (mocked)" {
    create_mock_uname "Linux" "x86_64"
    run is_macos
    [ "$status" -eq 1 ]
}

# =============================================================================
# get_architecture - actual platform tests
# =============================================================================

@test "get_architecture: returns non-empty string" {
    run get_architecture
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "get_architecture: returns arm64 or x86_64 on known platforms" {
    run get_architecture
    [ "$status" -eq 0 ]
    [[ "$output" == "arm64" || "$output" == "x86_64" ]]
}

# =============================================================================
# get_architecture - mocked tests
# =============================================================================

@test "get_architecture: returns arm64 when mocked" {
    create_mock_uname "Darwin" "arm64"
    run get_architecture
    [ "$status" -eq 0 ]
    [ "$output" = "arm64" ]
}

@test "get_architecture: returns x86_64 when mocked" {
    create_mock_uname "Darwin" "x86_64"
    run get_architecture
    [ "$status" -eq 0 ]
    [ "$output" = "x86_64" ]
}

# =============================================================================
# is_apple_silicon - actual platform tests
# =============================================================================

@test "is_apple_silicon: matches actual architecture" {
    run is_apple_silicon
    if [[ "$(command uname -m)" == "arm64" ]]; then
        [ "$status" -eq 0 ]
    else
        [ "$status" -eq 1 ]
    fi
}

# =============================================================================
# is_apple_silicon - mocked tests
# =============================================================================

@test "is_apple_silicon: returns 0 on arm64 (mocked)" {
    create_mock_uname "Darwin" "arm64"
    run is_apple_silicon
    [ "$status" -eq 0 ]
}

@test "is_apple_silicon: returns 1 on x86_64 (mocked)" {
    create_mock_uname "Darwin" "x86_64"
    run is_apple_silicon
    [ "$status" -eq 1 ]
}

# =============================================================================
# is_intel - actual platform tests
# =============================================================================

@test "is_intel: matches actual architecture" {
    run is_intel
    if [[ "$(command uname -m)" == "x86_64" ]]; then
        [ "$status" -eq 0 ]
    else
        [ "$status" -eq 1 ]
    fi
}

# =============================================================================
# is_intel - mocked tests
# =============================================================================

@test "is_intel: returns 0 on x86_64 (mocked)" {
    create_mock_uname "Linux" "x86_64"
    run is_intel
    [ "$status" -eq 0 ]
}

@test "is_intel: returns 1 on arm64 (mocked)" {
    create_mock_uname "Darwin" "arm64"
    run is_intel
    [ "$status" -eq 1 ]
}

# =============================================================================
# get_macos_version
# =============================================================================

@test "get_macos_version: returns version string on macOS, 'not_macos' otherwise" {
    run get_macos_version
    [ "$status" -eq 0 ]
    if [[ "$(command uname)" == "Darwin" ]]; then
        # macOS version looks like "13.0" or "14.2.1" - at least one digit, a dot, and another digit
        [[ "$output" =~ ^[0-9]+\.[0-9]+ ]]
    else
        [ "$output" = "not_macos" ]
    fi
}

@test "get_macos_version: returns 'not_macos' when uname reports Linux (mocked)" {
    create_mock_uname "Linux" "x86_64"
    run get_macos_version
    [ "$status" -eq 0 ]
    [ "$output" = "not_macos" ]
}

@test "get_macos_version: calls sw_vers on macOS (mocked as Darwin)" {
    # Mock both uname and sw_vers to test the macOS code path regardless of platform
    create_mock_uname "Darwin" "arm64"
    cat > "${TEST_TMPDIR}/sw_vers" <<'SCRIPT'
#!/bin/bash
if [[ "$1" == "-productVersion" ]]; then
    echo "15.1.2"
fi
SCRIPT
    chmod +x "${TEST_TMPDIR}/sw_vers"

    run get_macos_version
    [ "$status" -eq 0 ]
    [ "$output" = "15.1.2" ]
}

# =============================================================================
# Edge cases: is_apple_silicon and is_intel are mutually exclusive
# =============================================================================

@test "is_apple_silicon and is_intel: exactly one returns 0 on arm64 (mocked)" {
    create_mock_uname "Darwin" "arm64"
    run is_apple_silicon
    local apple_status="$status"
    run is_intel
    local intel_status="$status"
    [ "$apple_status" -eq 0 ]
    [ "$intel_status" -eq 1 ]
}

@test "is_apple_silicon and is_intel: exactly one returns 0 on x86_64 (mocked)" {
    create_mock_uname "Darwin" "x86_64"
    run is_apple_silicon
    local apple_status="$status"
    run is_intel
    local intel_status="$status"
    [ "$apple_status" -eq 1 ]
    [ "$intel_status" -eq 0 ]
}

@test "is_apple_silicon and is_intel: both return 1 on unknown arch (mocked)" {
    create_mock_uname "Linux" "aarch64"
    run is_apple_silicon
    local apple_status="$status"
    run is_intel
    local intel_status="$status"
    # aarch64 is not "arm64" and not "x86_64", so both should fail
    [ "$apple_status" -eq 1 ]
    [ "$intel_status" -eq 1 ]
}
