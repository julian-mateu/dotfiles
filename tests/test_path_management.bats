#!/usr/bin/env bats
load test_helper

# Save and restore PATH around each test to prevent pollution
setup() {
    export TEST_TMPDIR="$(mktemp -d)"
    export SAVED_PATH="${PATH}"
    source "${BATS_TEST_DIRNAME}/../zutils.zsh"
}

teardown() {
    export PATH="${SAVED_PATH}"
    rm -rf "${TEST_TMPDIR}"
}

###############################################################
# add_to_path
###############################################################

@test "add_to_path: adds existing directory to PATH" {
    local testdir="${TEST_TMPDIR}/bin"
    mkdir -p "${testdir}"

    run add_to_path "${testdir}"
    [[ "${status}" -eq 0 ]]

    # run executes in a subshell, so we need to call directly to check PATH
    add_to_path "${testdir}"
    [[ ":${PATH}:" == *":${testdir}:"* ]]
}

@test "add_to_path: returns 1 for missing directory" {
    run add_to_path "${TEST_TMPDIR}/nonexistent"
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"Directory does not exist"* ]]
}

@test "add_to_path: idempotent - adding twice does not duplicate" {
    local testdir="${TEST_TMPDIR}/bin"
    mkdir -p "${testdir}"

    add_to_path "${testdir}"
    add_to_path "${testdir}"

    # Count occurrences of testdir in PATH
    local count
    count="$(echo "${PATH}" | tr ':' '\n' | grep -c "^${testdir}$")"
    [[ "${count}" -eq 1 ]]
}

###############################################################
# add_to_path_if_exists
###############################################################

@test "add_to_path_if_exists: adds existing directory to PATH" {
    local testdir="${TEST_TMPDIR}/optbin"
    mkdir -p "${testdir}"

    add_to_path_if_exists "${testdir}"
    [[ ":${PATH}:" == *":${testdir}:"* ]]
}

@test "add_to_path_if_exists: silently skips missing directory and returns 0" {
    run add_to_path_if_exists "${TEST_TMPDIR}/missing_dir"
    [[ "${status}" -eq 0 ]]

    # Should not be in PATH
    [[ ":${PATH}:" != *":${TEST_TMPDIR}/missing_dir:"* ]]
}

@test "add_to_path_if_exists: produces no error output for missing directory" {
    run add_to_path_if_exists "${TEST_TMPDIR}/not_here"
    [[ "${status}" -eq 0 ]]
    # Should have no output (no error message)
    [[ -z "${output}" ]]
}

###############################################################
# _prepend_to_path
###############################################################

@test "_prepend_to_path: prepends directory to front of PATH" {
    local testdir="${TEST_TMPDIR}/prepend_test"
    mkdir -p "${testdir}"

    _prepend_to_path "${testdir}"

    # Should be at the start of PATH
    [[ "${PATH}" == "${testdir}:"* ]]
}

@test "_prepend_to_path: does not duplicate existing entry" {
    local testdir="${TEST_TMPDIR}/no_dup"
    mkdir -p "${testdir}"

    _prepend_to_path "${testdir}"
    _prepend_to_path "${testdir}"

    local count
    count="$(echo "${PATH}" | tr ':' '\n' | grep -c "^${testdir}$")"
    [[ "${count}" -eq 1 ]]
}

@test "_prepend_to_path: returns 0 even if already present" {
    local testdir="${TEST_TMPDIR}/already"
    mkdir -p "${testdir}"

    _prepend_to_path "${testdir}"
    run _prepend_to_path "${testdir}"
    [[ "${status}" -eq 0 ]]
}

###############################################################
# remove_from_path
###############################################################

@test "remove_from_path: removes directory from middle of PATH" {
    local testdir="${TEST_TMPDIR}/middle"
    mkdir -p "${testdir}"

    # Inject testdir into the middle of PATH
    export PATH="/usr/bin:${testdir}:/usr/local/bin"

    remove_from_path "${testdir}"
    [[ ":${PATH}:" != *":${testdir}:"* ]]
    # The remaining entries should still be present
    [[ ":${PATH}:" == *":/usr/bin:"* ]]
    [[ ":${PATH}:" == *":/usr/local/bin:"* ]]
}

@test "remove_from_path: removes directory from start of PATH" {
    local testdir="${TEST_TMPDIR}/start"
    mkdir -p "${testdir}"

    export PATH="${testdir}:/usr/bin:/usr/local/bin"

    remove_from_path "${testdir}"
    [[ ":${PATH}:" != *":${testdir}:"* ]]
    # The remaining entries should still be present
    [[ ":${PATH}:" == *":/usr/bin:"* ]]
    [[ ":${PATH}:" == *":/usr/local/bin:"* ]]
}

@test "remove_from_path: returns 0 even if directory was not in PATH" {
    export PATH="/usr/bin:/usr/local/bin"

    run remove_from_path "${TEST_TMPDIR}/not_in_path"
    [[ "${status}" -eq 0 ]]
}

@test "remove_from_path: handles PATH with single entry" {
    local testdir="${TEST_TMPDIR}/only"
    mkdir -p "${testdir}"

    export PATH="${testdir}"

    remove_from_path "${testdir}"
    # PATH should be empty or not contain the directory
    [[ ":${PATH}:" != *":${testdir}:"* ]]
}
