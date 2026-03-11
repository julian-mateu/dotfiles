# tests/test_helper.bash
# Shared setup/teardown for bats tests against zutils.zsh

setup() {
    export TEST_TMPDIR="$(mktemp -d)"
    # Source zutils.zsh relative to test location
    source "${BATS_TEST_DIRNAME}/../zutils.zsh"
}

teardown() {
    rm -rf "${TEST_TMPDIR}"
}
