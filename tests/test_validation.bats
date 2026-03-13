#!/usr/bin/env bats
# Tests for validation functions in zutils.zsh

load test_helper

###############################################################
# is_command_available tests
###############################################################

@test "is_command_available finds ls" {
    run is_command_available "ls"
    [ "$status" -eq 0 ]
}

@test "is_command_available finds bash" {
    run is_command_available "bash"
    [ "$status" -eq 0 ]
}

@test "is_command_available rejects nonexistent command" {
    run is_command_available "nonexistent_command_xyz123"
    [ "$status" -ne 0 ]
}

@test "is_command_available rejects empty string" {
    run is_command_available ""
    [ "$status" -ne 0 ]
}

###############################################################
# is_file_readable tests
###############################################################

@test "is_file_readable returns 0 for a readable file" {
    local test_file="${TEST_TMPDIR}/readable_file.txt"
    echo "content" > "$test_file"
    chmod 644 "$test_file"
    run is_file_readable "$test_file"
    [ "$status" -eq 0 ]
}

@test "is_file_readable returns 1 for a nonexistent file" {
    run is_file_readable "${TEST_TMPDIR}/no_such_file.txt"
    [ "$status" -eq 1 ]
}

@test "is_file_readable returns 0 for zutils.zsh itself" {
    run is_file_readable "${BATS_TEST_DIRNAME}/../zutils.zsh"
    [ "$status" -eq 0 ]
}

###############################################################
# is_directory tests
###############################################################

@test "is_directory returns 0 for an existing directory" {
    run is_directory "${TEST_TMPDIR}"
    [ "$status" -eq 0 ]
}

@test "is_directory returns 1 for a regular file" {
    local test_file="${TEST_TMPDIR}/regular_file.txt"
    echo "content" > "$test_file"
    run is_directory "$test_file"
    [ "$status" -eq 1 ]
}

@test "is_directory returns 1 for a nonexistent path" {
    run is_directory "${TEST_TMPDIR}/no_such_dir"
    [ "$status" -eq 1 ]
}

@test "is_directory returns 0 for /tmp" {
    run is_directory "/tmp"
    [ "$status" -eq 0 ]
}
