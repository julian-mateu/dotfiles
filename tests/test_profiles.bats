#!/usr/bin/env bats
# Tests for lib/profiles.sh - built-in profile loading

load test_helper

setup() {
    export TEST_TMPDIR="$(mktemp -d)"
    source "${BATS_TEST_DIRNAME}/../zutils.zsh"
    source "${BATS_TEST_DIRNAME}/../lib/profiles.sh"
}

teardown() {
    rm -rf "${TEST_TMPDIR}"
}

###############################################################
# _reset_all_install_vars
###############################################################

@test "_reset_all_install_vars: sets all INSTALL_* vars to false" {
    # Pre-set some to true to verify they get reset
    INSTALL_HOMEBREW=true
    INSTALL_PYTHON=true
    INSTALL_VSCODE=true

    _reset_all_install_vars

    [[ "${INSTALL_HOMEBREW}" == "false" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "false" ]]
    [[ "${INSTALL_NVIM}" == "false" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "false" ]]
    [[ "${INSTALL_PYTHON}" == "false" ]]
    [[ "${INSTALL_GO}" == "false" ]]
    [[ "${INSTALL_RUST}" == "false" ]]
    [[ "${INSTALL_NODE}" == "false" ]]
    [[ "${INSTALL_JAVA}" == "false" ]]
    [[ "${INSTALL_DOTNET}" == "false" ]]
    [[ "${INSTALL_KUBERNETES}" == "false" ]]
    [[ "${INSTALL_DOCKER}" == "false" ]]
    [[ "${INSTALL_VSCODE}" == "false" ]]
    [[ "${INSTALL_SLACK}" == "false" ]]
    [[ "${INSTALL_OBSIDIAN}" == "false" ]]
    [[ "${INSTALL_ZOOM}" == "false" ]]
    [[ "${INSTALL_SPOTIFY}" == "false" ]]
    [[ "${INSTALL_CHROME}" == "false" ]]
    [[ "${INSTALL_NERD_FONTS}" == "false" ]]
    [[ "${INSTALL_ITERM2}" == "false" ]]
    [[ "${INSTALL_DISPLAYLINK}" == "false" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "false" ]]
    [[ "${INSTALL_DEVS_CLI}" == "false" ]]
}

@test "_reset_all_install_vars: idempotent - calling twice yields same result" {
    _reset_all_install_vars
    _reset_all_install_vars

    [[ "${INSTALL_HOMEBREW}" == "false" ]]
    [[ "${INSTALL_PYTHON}" == "false" ]]
    [[ "${INSTALL_VSCODE}" == "false" ]]
}

###############################################################
# load_profile minimal
###############################################################

@test "load_profile minimal: enables shell tools only" {
    load_profile minimal

    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "true" ]]
    [[ "${INSTALL_NVIM}" == "true" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "true" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "true" ]]
}

@test "load_profile minimal: disables languages, backend, and GUI tools" {
    load_profile minimal

    # Languages (NOT in minimal)
    [[ "${INSTALL_PYTHON}" == "false" ]]
    [[ "${INSTALL_GO}" == "false" ]]
    [[ "${INSTALL_RUST}" == "false" ]]
    [[ "${INSTALL_NODE}" == "false" ]]

    # Backend
    [[ "${INSTALL_JAVA}" == "false" ]]
    [[ "${INSTALL_DOTNET}" == "false" ]]
    [[ "${INSTALL_KUBERNETES}" == "false" ]]
    [[ "${INSTALL_DOCKER}" == "false" ]]

    # GUI
    [[ "${INSTALL_VSCODE}" == "false" ]]
    [[ "${INSTALL_SLACK}" == "false" ]]
    [[ "${INSTALL_OBSIDIAN}" == "false" ]]
    [[ "${INSTALL_ZOOM}" == "false" ]]
    [[ "${INSTALL_SPOTIFY}" == "false" ]]
    [[ "${INSTALL_CHROME}" == "false" ]]
    [[ "${INSTALL_NERD_FONTS}" == "false" ]]
    [[ "${INSTALL_ITERM2}" == "false" ]]
    [[ "${INSTALL_DISPLAYLINK}" == "false" ]]
    [[ "${INSTALL_DEVS_CLI}" == "false" ]]
}

###############################################################
# load_profile developer
###############################################################

@test "load_profile developer: enables minimal + languages" {
    load_profile developer

    # Inherited from minimal
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "true" ]]
    [[ "${INSTALL_NVIM}" == "true" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "true" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "true" ]]

    # Developer-specific languages
    [[ "${INSTALL_PYTHON}" == "true" ]]
    [[ "${INSTALL_GO}" == "true" ]]
    [[ "${INSTALL_RUST}" == "true" ]]
    [[ "${INSTALL_NODE}" == "true" ]]
}

@test "load_profile developer: disables backend and GUI tools" {
    load_profile developer

    [[ "${INSTALL_JAVA}" == "false" ]]
    [[ "${INSTALL_DOTNET}" == "false" ]]
    [[ "${INSTALL_KUBERNETES}" == "false" ]]
    [[ "${INSTALL_DOCKER}" == "false" ]]
    [[ "${INSTALL_VSCODE}" == "false" ]]
    [[ "${INSTALL_SLACK}" == "false" ]]
    [[ "${INSTALL_OBSIDIAN}" == "false" ]]
    [[ "${INSTALL_ZOOM}" == "false" ]]
    [[ "${INSTALL_SPOTIFY}" == "false" ]]
    [[ "${INSTALL_CHROME}" == "false" ]]
    [[ "${INSTALL_NERD_FONTS}" == "false" ]]
    [[ "${INSTALL_ITERM2}" == "false" ]]
    [[ "${INSTALL_DISPLAYLINK}" == "false" ]]
    [[ "${INSTALL_DEVS_CLI}" == "false" ]]
}

###############################################################
# load_profile backend
###############################################################

@test "load_profile backend: enables developer + backend tools" {
    load_profile backend

    # Inherited from minimal via developer
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "true" ]]
    [[ "${INSTALL_NVIM}" == "true" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "true" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "true" ]]

    # Inherited from developer
    [[ "${INSTALL_PYTHON}" == "true" ]]
    [[ "${INSTALL_GO}" == "true" ]]
    [[ "${INSTALL_RUST}" == "true" ]]
    [[ "${INSTALL_NODE}" == "true" ]]

    # Backend-specific
    [[ "${INSTALL_JAVA}" == "true" ]]
    [[ "${INSTALL_DOTNET}" == "true" ]]
    [[ "${INSTALL_KUBERNETES}" == "true" ]]
    [[ "${INSTALL_DOCKER}" == "true" ]]
}

@test "load_profile backend: disables GUI tools" {
    load_profile backend

    [[ "${INSTALL_VSCODE}" == "false" ]]
    [[ "${INSTALL_SLACK}" == "false" ]]
    [[ "${INSTALL_OBSIDIAN}" == "false" ]]
    [[ "${INSTALL_ZOOM}" == "false" ]]
    [[ "${INSTALL_SPOTIFY}" == "false" ]]
    [[ "${INSTALL_CHROME}" == "false" ]]
    [[ "${INSTALL_NERD_FONTS}" == "false" ]]
    [[ "${INSTALL_ITERM2}" == "false" ]]
    [[ "${INSTALL_DISPLAYLINK}" == "false" ]]
    [[ "${INSTALL_DEVS_CLI}" == "false" ]]
}

###############################################################
# load_profile full
###############################################################

@test "load_profile full: enables all tools" {
    load_profile full

    # Inherited from minimal via developer via backend
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "true" ]]
    [[ "${INSTALL_NVIM}" == "true" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "true" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "true" ]]

    # Inherited from developer
    [[ "${INSTALL_PYTHON}" == "true" ]]
    [[ "${INSTALL_GO}" == "true" ]]
    [[ "${INSTALL_RUST}" == "true" ]]
    [[ "${INSTALL_NODE}" == "true" ]]

    # Inherited from backend
    [[ "${INSTALL_JAVA}" == "true" ]]
    [[ "${INSTALL_DOTNET}" == "true" ]]
    [[ "${INSTALL_KUBERNETES}" == "true" ]]
    [[ "${INSTALL_DOCKER}" == "true" ]]

    # Full-specific: ALL GUI apps
    [[ "${INSTALL_VSCODE}" == "true" ]]
    [[ "${INSTALL_NERD_FONTS}" == "true" ]]
    [[ "${INSTALL_ITERM2}" == "true" ]]
    [[ "${INSTALL_DEVS_CLI}" == "true" ]]
    [[ "${INSTALL_SLACK}" == "true" ]]
    [[ "${INSTALL_OBSIDIAN}" == "true" ]]
    [[ "${INSTALL_ZOOM}" == "true" ]]
    [[ "${INSTALL_SPOTIFY}" == "true" ]]
    [[ "${INSTALL_CHROME}" == "true" ]]
    [[ "${INSTALL_DISPLAYLINK}" == "true" ]]
}

###############################################################
# load_profile unknown
###############################################################

@test "load_profile unknown: returns 1 with error message" {
    run load_profile "nonexistent"
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"Unknown profile: nonexistent"* ]]
}

@test "load_profile unknown: shows available profiles" {
    run load_profile "badname"
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"Available profiles: minimal, developer, backend, full"* ]]
}

###############################################################
# Profile inheritance
###############################################################

@test "profile inheritance: developer inherits all minimal values" {
    load_profile developer

    # All minimal tools should be enabled
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "true" ]]
    [[ "${INSTALL_NVIM}" == "true" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "true" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "true" ]]
}

@test "profile inheritance: backend inherits all developer values" {
    load_profile backend

    # All minimal tools should be enabled
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_OH_MY_ZSH}" == "true" ]]
    [[ "${INSTALL_NVIM}" == "true" ]]
    [[ "${INSTALL_USEFUL_TOOLS}" == "true" ]]
    [[ "${INSTALL_CLAUDE_CODE}" == "true" ]]
    # All developer tools should be enabled
    [[ "${INSTALL_PYTHON}" == "true" ]]
    [[ "${INSTALL_GO}" == "true" ]]
    [[ "${INSTALL_RUST}" == "true" ]]
    [[ "${INSTALL_NODE}" == "true" ]]
}

@test "profile inheritance: full inherits all backend values" {
    load_profile full

    # All backend tools should be enabled
    [[ "${INSTALL_JAVA}" == "true" ]]
    [[ "${INSTALL_DOTNET}" == "true" ]]
    [[ "${INSTALL_KUBERNETES}" == "true" ]]
    [[ "${INSTALL_DOCKER}" == "true" ]]
    # Plus all developer + minimal (spot check)
    [[ "${INSTALL_HOMEBREW}" == "true" ]]
    [[ "${INSTALL_PYTHON}" == "true" ]]
}

@test "profile inheritance: loading minimal after full resets all non-minimal tools" {
    load_profile full
    [[ "${INSTALL_PYTHON}" == "true" ]]
    [[ "${INSTALL_JAVA}" == "true" ]]
    [[ "${INSTALL_VSCODE}" == "true" ]]
    [[ "${INSTALL_SLACK}" == "true" ]]

    load_profile minimal
    [[ "${INSTALL_PYTHON}" == "false" ]]
    [[ "${INSTALL_JAVA}" == "false" ]]
    [[ "${INSTALL_VSCODE}" == "false" ]]
    [[ "${INSTALL_SLACK}" == "false" ]]
}
