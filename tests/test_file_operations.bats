#!/usr/bin/env bats
load test_helper

###############################################################
# source_if_exists
###############################################################

@test "source_if_exists: sources existing file and exports its variable" {
    local testfile="${TEST_TMPDIR}/sourceme.sh"
    echo 'SOURCED_VAR="hello_from_source"' > "${testfile}"

    # Source the file (not via run, since we need the variable in this shell)
    source_if_exists "${testfile}"
    [[ "${SOURCED_VAR}" == "hello_from_source" ]]
}

@test "source_if_exists: returns 0 for existing file" {
    local testfile="${TEST_TMPDIR}/exists.sh"
    echo '# empty script' > "${testfile}"

    run source_if_exists "${testfile}"
    [[ "${status}" -eq 0 ]]
}

@test "source_if_exists: returns 1 for missing file" {
    run source_if_exists "${TEST_TMPDIR}/nonexistent.sh"
    [[ "${status}" -eq 1 ]]
}

@test "source_if_exists: returns 1 and prints error for empty argument" {
    run source_if_exists ""
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"No file path provided"* ]]
}

###############################################################
# append_lines_to_file_if_not_there
###############################################################

@test "append_lines_to_file_if_not_there: appends new block to existing file" {
    local testfile="${TEST_TMPDIR}/config.txt"
    echo "existing content" > "${testfile}"

    run append_lines_to_file_if_not_there "new block" "${testfile}"
    [[ "${status}" -eq 0 ]]

    local content
    content="$(< "${testfile}")"
    [[ "${content}" == *"existing content"* ]]
    [[ "${content}" == *"new block"* ]]
}

@test "append_lines_to_file_if_not_there: idempotent - running twice produces only one copy" {
    local testfile="${TEST_TMPDIR}/config.txt"
    echo "header" > "${testfile}"

    append_lines_to_file_if_not_there "unique block" "${testfile}"
    append_lines_to_file_if_not_there "unique block" "${testfile}"

    local count
    count="$(grep -c "unique block" "${testfile}")"
    [[ "${count}" -eq 1 ]]
}

@test "append_lines_to_file_if_not_there: creates file if missing" {
    local testfile="${TEST_TMPDIR}/newfile.txt"
    [[ ! -f "${testfile}" ]]

    run append_lines_to_file_if_not_there "first block" "${testfile}"
    [[ "${status}" -eq 0 ]]
    [[ -f "${testfile}" ]]

    local content
    content="$(< "${testfile}")"
    [[ "${content}" == *"first block"* ]]
}

@test "append_lines_to_file_if_not_there: returns 2 with wrong number of args (0 args)" {
    run append_lines_to_file_if_not_there
    [[ "${status}" -eq 2 ]]
    [[ "${output}" == *"Illegal number of parameters"* ]]
}

@test "append_lines_to_file_if_not_there: returns 2 with wrong number of args (1 arg)" {
    run append_lines_to_file_if_not_there "only one arg"
    [[ "${status}" -eq 2 ]]
    [[ "${output}" == *"Illegal number of parameters"* ]]
}

@test "append_lines_to_file_if_not_there: returns 2 with wrong number of args (3 args)" {
    run append_lines_to_file_if_not_there "one" "two" "three"
    [[ "${status}" -eq 2 ]]
    [[ "${output}" == *"Illegal number of parameters"* ]]
}

@test "append_lines_to_file_if_not_there: handles multiline blocks" {
    local testfile="${TEST_TMPDIR}/multiline.txt"
    local block=$'line one\nline two\nline three'

    append_lines_to_file_if_not_there "${block}" "${testfile}"
    append_lines_to_file_if_not_there "${block}" "${testfile}"

    # The block should appear exactly once: 3 lines from the block + 1 empty trailing line from echo
    local line_count
    line_count="$(wc -l < "${testfile}" | tr -d ' ')"
    [[ "${line_count}" -le 4 ]]

    local content
    content="$(< "${testfile}")"
    [[ "${content}" == *"line one"* ]]
    [[ "${content}" == *"line three"* ]]
}

###############################################################
# backup_file
###############################################################

@test "backup_file: creates backup with default .backup suffix" {
    local testfile="${TEST_TMPDIR}/original.txt"
    echo "original content" > "${testfile}"

    run backup_file "${testfile}"
    [[ "${status}" -eq 0 ]]

    # Original should be moved (not exist anymore)
    [[ ! -e "${testfile}" ]]
    # Backup should exist with default suffix
    [[ -f "${testfile}.backup" ]]

    local content
    content="$(< "${testfile}.backup")"
    [[ "${content}" == *"original content"* ]]
}

@test "backup_file: creates backup with custom suffix" {
    local testfile="${TEST_TMPDIR}/myconfig.txt"
    echo "config data" > "${testfile}"

    run backup_file "${testfile}" ".bak"
    [[ "${status}" -eq 0 ]]

    [[ ! -e "${testfile}" ]]
    [[ -f "${testfile}.bak" ]]

    local content
    content="$(< "${testfile}.bak")"
    [[ "${content}" == *"config data"* ]]
}

@test "backup_file: returns 1 for missing file" {
    run backup_file "${TEST_TMPDIR}/nonexistent.txt"
    [[ "${status}" -eq 1 ]]
}

###############################################################
# create_symlink
###############################################################

@test "create_symlink: creates symlink to existing source" {
    local src="${TEST_TMPDIR}/source.txt"
    local target="${TEST_TMPDIR}/link.txt"
    echo "source content" > "${src}"

    run create_symlink "${src}" "${target}"
    [[ "${status}" -eq 0 ]]
    [[ -L "${target}" ]]

    local resolved
    resolved="$(readlink "${target}")"
    [[ "${resolved}" == "${src}" ]]
}

@test "create_symlink: backs up existing regular file before symlinking" {
    local src="${TEST_TMPDIR}/source.txt"
    local target="${TEST_TMPDIR}/existing.txt"
    echo "source content" > "${src}"
    echo "existing content" > "${target}"

    run create_symlink "${src}" "${target}"
    [[ "${status}" -eq 0 ]]

    # Target should now be a symlink
    [[ -L "${target}" ]]
    # Backup should exist
    [[ -f "${target}.backup" ]]

    local backup_content
    backup_content="$(< "${target}.backup")"
    [[ "${backup_content}" == *"existing content"* ]]
}

@test "create_symlink: force mode removes existing symlink" {
    local src1="${TEST_TMPDIR}/source1.txt"
    local src2="${TEST_TMPDIR}/source2.txt"
    local target="${TEST_TMPDIR}/link.txt"
    echo "first source" > "${src1}"
    echo "second source" > "${src2}"

    # Create initial symlink
    ln -s "${src1}" "${target}"
    [[ -L "${target}" ]]
    [[ "$(readlink "${target}")" == "${src1}" ]]

    # Force replace with new source
    run create_symlink "${src2}" "${target}" "force"
    [[ "${status}" -eq 0 ]]
    [[ -L "${target}" ]]
    [[ "$(readlink "${target}")" == "${src2}" ]]
}

@test "create_symlink: returns 1 for missing source" {
    local target="${TEST_TMPDIR}/link.txt"

    run create_symlink "${TEST_TMPDIR}/nonexistent.txt" "${target}"
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"Source does not exist"* ]]
    # Target should not have been created
    [[ ! -e "${target}" ]]
}

@test "create_symlink: without force, does not replace existing symlink" {
    local src1="${TEST_TMPDIR}/source1.txt"
    local src2="${TEST_TMPDIR}/source2.txt"
    local target="${TEST_TMPDIR}/link.txt"
    echo "first source" > "${src1}"
    echo "second source" > "${src2}"

    # Create initial symlink
    ln -s "${src1}" "${target}"

    # Try to create symlink without force - target already exists, so it's a no-op
    run create_symlink "${src2}" "${target}"
    [[ "${status}" -eq 0 ]]

    # Should still point to original source
    [[ "$(readlink "${target}")" == "${src1}" ]]
}
