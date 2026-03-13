#!/usr/bin/env bats
load test_helper

# =============================================================================
# User Interaction Tests for zutils.zsh
# =============================================================================
# Tests for: ask_for_confirmation
#
# The function signature is:
#   ask_for_confirmation <description> <info_url> <command> [args...]
#
# Modes:
#   - Normal: interactive prompt (not easily testable in non-interactive context)
#   - DOTFILES_CI=true: auto-accepts and runs the command
#   - DOTFILES_DRY_RUN=true: shows dry-run message, does not execute the command
#   - Parameter validation: returns 2 if fewer than 3 args
# =============================================================================

# =============================================================================
# Parameter validation
# =============================================================================

@test "ask_for_confirmation: returns 2 with no arguments" {
    run ask_for_confirmation
    [ "$status" -eq 2 ]
    [[ "$output" == *"Illegal number of parameters"* ]]
}

@test "ask_for_confirmation: returns 2 with only 1 argument" {
    run ask_for_confirmation "description"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Illegal number of parameters"* ]]
}

@test "ask_for_confirmation: returns 2 with only 2 arguments" {
    run ask_for_confirmation "description" "http://example.com"
    [ "$status" -eq 2 ]
    [[ "$output" == *"Illegal number of parameters"* ]]
}

# =============================================================================
# CI mode (DOTFILES_CI=true): auto-accepts and executes
# =============================================================================

@test "ask_for_confirmation: CI mode executes the command" {
    export DOTFILES_CI=true
    run ask_for_confirmation "test-tool" "http://example.com" echo "executed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"executed"* ]]
}

@test "ask_for_confirmation: CI mode shows auto-accepting message" {
    export DOTFILES_CI=true
    run ask_for_confirmation "test-tool" "http://example.com" echo "done"
    [ "$status" -eq 0 ]
    [[ "$output" == *"auto-accepting"* ]]
    [[ "$output" == *"test-tool"* ]]
}

@test "ask_for_confirmation: CI mode returns command exit code on success" {
    export DOTFILES_CI=true
    run ask_for_confirmation "test-tool" "http://example.com" true
    [ "$status" -eq 0 ]
}

@test "ask_for_confirmation: CI mode returns command exit code on failure" {
    export DOTFILES_CI=true
    run ask_for_confirmation "test-tool" "http://example.com" false
    [ "$status" -eq 1 ]
}

@test "ask_for_confirmation: CI mode passes arguments to command" {
    export DOTFILES_CI=true
    local outfile="${TEST_TMPDIR}/ci_output.txt"
    # Use a helper script to capture the arguments
    cat > "${TEST_TMPDIR}/capture_args.sh" <<'SCRIPT'
#!/bin/bash
echo "$@" > "$1"
SCRIPT
    chmod +x "${TEST_TMPDIR}/capture_args.sh"

    run ask_for_confirmation "test-tool" "http://example.com" \
        "${TEST_TMPDIR}/capture_args.sh" "${outfile}" "arg1" "arg2"
    [ "$status" -eq 0 ]
    # Verify the file was created (command was executed)
    [ -f "${outfile}" ]
    # Verify arguments were passed correctly
    local captured
    captured="$(cat "${outfile}")"
    [[ "$captured" == *"arg1"* ]]
    [[ "$captured" == *"arg2"* ]]
}

# =============================================================================
# Dry-run mode (DOTFILES_DRY_RUN=true): shows message, does not execute
# =============================================================================

@test "ask_for_confirmation: dry-run shows 'Would install' message" {
    export DOTFILES_DRY_RUN=true
    run ask_for_confirmation "test-tool" "http://example.com" echo "should-not-run"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN] Would install"* ]]
    [[ "$output" == *"test-tool"* ]]
}

@test "ask_for_confirmation: dry-run does NOT execute the command" {
    export DOTFILES_DRY_RUN=true
    local outfile="${TEST_TMPDIR}/dryrun_marker.txt"
    run ask_for_confirmation "test-tool" "http://example.com" \
        touch "${outfile}"
    [ "$status" -eq 0 ]
    # The touch command should NOT have been executed
    [ ! -f "${outfile}" ]
}

@test "ask_for_confirmation: dry-run returns 0 regardless of command" {
    export DOTFILES_DRY_RUN=true
    # Even though 'false' would return 1, dry-run should return 0
    run ask_for_confirmation "test-tool" "http://example.com" false
    [ "$status" -eq 0 ]
}

# =============================================================================
# Output format validation (shared across modes)
# =============================================================================

@test "ask_for_confirmation: shows description in 'Trying to install' message" {
    export DOTFILES_CI=true
    run ask_for_confirmation "my-package" "http://example.com" true
    [ "$status" -eq 0 ]
    [[ "$output" == *"Trying to install my-package"* ]]
}

@test "ask_for_confirmation: shows the command in output" {
    export DOTFILES_CI=true
    run ask_for_confirmation "my-package" "http://example.com" echo "hello world"
    [ "$status" -eq 0 ]
    [[ "$output" == *"echo"* ]]
}

# =============================================================================
# Mode precedence: dry-run takes priority over CI
# =============================================================================

@test "ask_for_confirmation: dry-run takes precedence over CI mode" {
    export DOTFILES_DRY_RUN=true
    export DOTFILES_CI=true
    local outfile="${TEST_TMPDIR}/precedence_marker.txt"
    run ask_for_confirmation "test-tool" "http://example.com" \
        touch "${outfile}"
    [ "$status" -eq 0 ]
    # Dry-run should prevent execution even with CI=true
    [[ "$output" == *"[DRY RUN] Would install"* ]]
    [ ! -f "${outfile}" ]
}
