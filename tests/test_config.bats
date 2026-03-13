#!/usr/bin/env bats

# Tests for lib/config.sh - CLI argument parsing and config loading

setup() {
    export TEST_TMPDIR="$(mktemp -d)"
    source "${BATS_TEST_DIRNAME}/../zutils.zsh"
    source "${BATS_TEST_DIRNAME}/../lib/profiles.sh"
    source "${BATS_TEST_DIRNAME}/../lib/config.sh"
    # Reset state
    CONFIG_FILE=""
    PROFILE=""
    DOTFILES_DRY_RUN="false"
}

teardown() {
    rm -rf "${TEST_TMPDIR}"
}

# --- parse_arguments ---

@test "parse_arguments: no args sets defaults" {
    parse_arguments
    [[ -z "${CONFIG_FILE}" ]]
    [[ -z "${PROFILE}" ]]
    [[ "${DOTFILES_DRY_RUN}" == "false" ]]
}

@test "parse_arguments: --dry-run sets DOTFILES_DRY_RUN" {
    parse_arguments --dry-run
    [[ "${DOTFILES_DRY_RUN}" == "true" ]]
}

@test "parse_arguments: --profile sets PROFILE" {
    parse_arguments --profile minimal
    [[ "${PROFILE}" == "minimal" ]]
}

@test "parse_arguments: --config sets CONFIG_FILE for existing file" {
    local conf="${TEST_TMPDIR}/test.conf"
    echo "INSTALL_GO=true" > "${conf}"
    parse_arguments --config "${conf}"
    [[ "${CONFIG_FILE}" == "${conf}" ]]
}

@test "parse_arguments: --config with missing file returns 1" {
    run parse_arguments --config /nonexistent/file.conf
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Config file not found"* ]]
}

@test "parse_arguments: --config without value returns 1" {
    run parse_arguments --config
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"requires a file path"* ]]
}

@test "parse_arguments: --profile without value returns 1" {
    run parse_arguments --profile
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"requires a profile name"* ]]
}

@test "parse_arguments: --config and --profile are mutually exclusive" {
    local conf="${TEST_TMPDIR}/test.conf"
    echo "INSTALL_GO=true" > "${conf}"
    run parse_arguments --config "${conf}" --profile minimal
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"mutually exclusive"* ]]
}

@test "parse_arguments: unknown argument returns 1" {
    run parse_arguments --bogus
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Unknown argument"* ]]
}

@test "parse_arguments: --dry-run combined with --profile" {
    parse_arguments --dry-run --profile backend
    [[ "${DOTFILES_DRY_RUN}" == "true" ]]
    [[ "${PROFILE}" == "backend" ]]
}

# --- load_configuration ---

@test "load_configuration: returns 1 when no config source available" {
    CONFIG_FILE=""
    PROFILE=""
    # Ensure no dotfiles.conf exists in DOTFILES_DIR
    DOTFILES_DIR="${TEST_TMPDIR}"
    run load_configuration
    [[ "${status}" -eq 1 ]]
}

@test "load_configuration: loads profile when PROFILE is set" {
    PROFILE="minimal"
    load_configuration
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_JAVA}" == "false" ]]
}

@test "load_configuration: loads config file when CONFIG_FILE is set" {
    local conf="${TEST_TMPDIR}/test.conf"
    echo 'INSTALL_GO=true' > "${conf}"
    echo 'INSTALL_RUST=false' >> "${conf}"
    CONFIG_FILE="${conf}"
    load_configuration
    [[ "${INSTALL_GO}" == "true" ]]
    [[ "${INSTALL_RUST}" == "false" ]]
}

@test "load_configuration: loads dotfiles.conf from DOTFILES_DIR" {
    echo 'INSTALL_PYTHON=true' > "${TEST_TMPDIR}/dotfiles.conf"
    DOTFILES_DIR="${TEST_TMPDIR}"
    CONFIG_FILE=""
    PROFILE=""
    load_configuration
    [[ "${INSTALL_PYTHON}" == "true" ]]
}

@test "load_configuration: returns error for unknown profile" {
    PROFILE="nonexistent"
    run load_configuration
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == *"Unknown profile"* ]]
}
