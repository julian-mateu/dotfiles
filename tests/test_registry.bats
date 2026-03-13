#!/usr/bin/env bats
# Tests for lib/registry.sh - tool registration, enablement, and execution

load test_helper

setup() {
    export TEST_TMPDIR="$(mktemp -d)"
    source "${BATS_TEST_DIRNAME}/../zutils.zsh"
    source "${BATS_TEST_DIRNAME}/../lib/profiles.sh"
    source "${BATS_TEST_DIRNAME}/../lib/registry.sh"
    # Reset registry to avoid pollution between tests
    TOOL_REGISTRY=()
}

teardown() {
    rm -rf "${TEST_TMPDIR}"
}

###############################################################
# register_tool
###############################################################

@test "register_tool: adds entry to TOOL_REGISTRY" {
    register_tool "python" setup_python "Python" "https://python.org" "" "all"

    [[ "${#TOOL_REGISTRY[@]}" -eq 1 ]]
    [[ "${TOOL_REGISTRY[0]}" == "python|setup_python|Python|https://python.org||all|false" ]]
}

@test "register_tool: multiple registrations append to array" {
    register_tool "python" setup_python "Python" "https://python.org" "" "all"
    register_tool "go" install_go "Go" "https://go.dev" "" "all"
    register_tool "rust" install_rust "Rust" "https://rustup.rs" "" "all"

    [[ "${#TOOL_REGISTRY[@]}" -eq 3 ]]
}

@test "register_tool: defaults platform to 'all' when omitted" {
    register_tool "python" setup_python "Python" "https://python.org" ""

    [[ "${TOOL_REGISTRY[0]}" == "python|setup_python|Python|https://python.org||all|false" ]]
}

@test "register_tool: defaults deps to empty when omitted" {
    register_tool "python" setup_python "Python" "https://python.org"

    [[ "${TOOL_REGISTRY[0]}" == "python|setup_python|Python|https://python.org||all|false" ]]
}

@test "register_tool: preserves dependency list" {
    register_tool "claude_code" install_claude "Claude Code" "" "node,homebrew" "all"

    [[ "${TOOL_REGISTRY[0]}" == "claude_code|install_claude|Claude Code||node,homebrew|all|false" ]]
}

@test "register_tool: preserves platform-specific value" {
    register_tool "iterm2" install_iterm "iTerm2" "" "" "macos"

    [[ "${TOOL_REGISTRY[0]}" == "iterm2|install_iterm|iTerm2|||macos|false" ]]
}

@test "register_tool: defaults gui to false when omitted" {
    register_tool "python" setup_python "Python" "https://python.org" "" "all"

    [[ "${TOOL_REGISTRY[0]}" == *"|false" ]]
}

@test "register_tool: preserves gui flag when set to true" {
    register_tool "vscode" install_vscode "VS Code" "" "" "all" "true"

    [[ "${TOOL_REGISTRY[0]}" == "vscode|install_vscode|VS Code|||all|true" ]]
}

###############################################################
# is_tool_enabled
###############################################################

@test "is_tool_enabled: returns 0 when INSTALL_KEY is true" {
    INSTALL_PYTHON=true
    run is_tool_enabled "python"
    [[ "${status}" -eq 0 ]]
}

@test "is_tool_enabled: returns 1 when INSTALL_KEY is false" {
    INSTALL_PYTHON=false
    run is_tool_enabled "python"
    [[ "${status}" -eq 1 ]]
}

@test "is_tool_enabled: returns 1 when INSTALL_KEY is unset" {
    unset INSTALL_NONEXISTENT
    run is_tool_enabled "nonexistent"
    [[ "${status}" -eq 1 ]]
}

@test "is_tool_enabled: handles uppercase key with underscores" {
    INSTALL_OH_MY_ZSH=true
    run is_tool_enabled "oh_my_zsh"
    [[ "${status}" -eq 0 ]]
}

@test "is_tool_enabled: returns 1 for empty string value" {
    INSTALL_EMPTY=""
    run is_tool_enabled "empty"
    [[ "${status}" -eq 1 ]]
}

@test "is_tool_enabled: returns 1 for non-true truthy value" {
    INSTALL_YES="yes"
    run is_tool_enabled "yes"
    [[ "${status}" -eq 1 ]]
}

###############################################################
# run_registry: enabled vs disabled tools
###############################################################

@test "run_registry: runs enabled tools and skips disabled" {
    mock_called=false
    mock_tool() { mock_called=true; }
    skip_called=false
    skip_tool() { skip_called=true; }

    INSTALL_MOCK=true
    INSTALL_SKIP=false

    register_tool "mock" mock_tool "Mock Tool" "" "" "all"
    register_tool "skip" skip_tool "Skip Tool" "" "" "all"

    run_registry

    [[ "${mock_called}" == "true" ]]
    [[ "${skip_called}" == "false" ]]
}

@test "run_registry: returns 0 when all enabled tools succeed" {
    success_tool() { return 0; }
    INSTALL_SUCCESS=true
    register_tool "success" success_tool "Success Tool" "" "" "all"

    run run_registry
    [[ "${status}" -eq 0 ]]
}

@test "run_registry: returns 1 when an enabled tool fails" {
    fail_tool() { return 1; }
    INSTALL_FAIL=true
    register_tool "fail" fail_tool "Fail Tool" "" "" "all"

    run run_registry
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"Failed to install Fail Tool"* ]]
}

###############################################################
# run_registry: empty registry
###############################################################

@test "run_registry: returns 0 with empty registry" {
    run run_registry
    [[ "${status}" -eq 0 ]]
}

###############################################################
# run_registry: all disabled
###############################################################

@test "run_registry: returns 0 when all tools are disabled" {
    noop_tool() { return 0; }
    INSTALL_A=false
    INSTALL_B=false
    register_tool "a" noop_tool "Tool A" "" "" "all"
    register_tool "b" noop_tool "Tool B" "" "" "all"

    run run_registry
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Skipping Tool A"* ]]
    [[ "${output}" == *"Skipping Tool B"* ]]
}

###############################################################
# run_registry: execution order
###############################################################

@test "run_registry: executes tools in registration order" {
    order=""
    tool_a() { order="${order}A"; }
    tool_b() { order="${order}B"; }
    tool_c() { order="${order}C"; }

    INSTALL_FIRST=true
    INSTALL_SECOND=true
    INSTALL_THIRD=true

    register_tool "first" tool_a "First" "" "" "all"
    register_tool "second" tool_b "Second" "" "" "all"
    register_tool "third" tool_c "Third" "" "" "all"

    run_registry

    [[ "${order}" == "ABC" ]]
}

###############################################################
# run_registry: platform filtering
###############################################################

# Helper: create a mock uname to control platform detection
create_mock_uname() {
    local kernel_name="${1}"
    cat > "${TEST_TMPDIR}/uname" <<SCRIPT
#!/bin/bash
if [[ "\$1" == "-m" ]]; then
    echo "x86_64"
else
    echo "${kernel_name}"
fi
SCRIPT
    chmod +x "${TEST_TMPDIR}/uname"
    export PATH="${TEST_TMPDIR}:${PATH}"
}

@test "run_registry: skips macos-only tool on Linux" {
    create_mock_uname "Linux"

    mac_called=false
    mac_tool() { mac_called=true; }
    INSTALL_MACTOOL=true
    register_tool "mactool" mac_tool "Mac Tool" "" "" "macos"

    run_registry

    [[ "${mac_called}" == "false" ]]
}

@test "run_registry: runs macos-only tool on macOS" {
    create_mock_uname "Darwin"

    mac_called=false
    mac_tool() { mac_called=true; }
    INSTALL_MACTOOL=true
    register_tool "mactool" mac_tool "Mac Tool" "" "" "macos"

    run_registry

    [[ "${mac_called}" == "true" ]]
}

@test "run_registry: skips linux-only tool on macOS" {
    create_mock_uname "Darwin"

    linux_called=false
    linux_tool() { linux_called=true; }
    INSTALL_LINUXTOOL=true
    register_tool "linuxtool" linux_tool "Linux Tool" "" "" "linux"

    run_registry

    [[ "${linux_called}" == "false" ]]
}

@test "run_registry: runs linux-only tool on Linux" {
    create_mock_uname "Linux"

    linux_called=false
    linux_tool() { linux_called=true; }
    INSTALL_LINUXTOOL=true
    register_tool "linuxtool" linux_tool "Linux Tool" "" "" "linux"

    run_registry

    [[ "${linux_called}" == "true" ]]
}

@test "run_registry: runs 'all' platform tool regardless of OS" {
    create_mock_uname "Linux"

    all_called=false
    all_tool() { all_called=true; }
    INSTALL_ALLTOOL=true
    register_tool "alltool" all_tool "All Platform Tool" "" "" "all"

    run_registry

    [[ "${all_called}" == "true" ]]
}

###############################################################
# run_registry: dependency checking
###############################################################

@test "run_registry: skips tool when dependency is disabled" {
    dep_called=false
    dep_tool() { dep_called=true; }
    INSTALL_CHILD=true
    INSTALL_PARENT=false

    register_tool "child" dep_tool "Child Tool" "" "parent" "all"

    run run_registry

    [[ "${dep_called}" == "false" ]]
    [[ "${output}" == *"depends on parent which is disabled"* ]]
}

@test "run_registry: runs tool when dependency is enabled" {
    parent_called=false
    parent_tool() { parent_called=true; }
    child_called=false
    child_tool() { child_called=true; }

    INSTALL_PARENT=true
    INSTALL_CHILD=true

    register_tool "parent" parent_tool "Parent Tool" "" "" "all"
    register_tool "child" child_tool "Child Tool" "" "parent" "all"

    run_registry

    [[ "${parent_called}" == "true" ]]
    [[ "${child_called}" == "true" ]]
}

@test "run_registry: skips tool when any dependency in chain is disabled" {
    tool_called=false
    chained_tool() { tool_called=true; }

    INSTALL_CHAINED=true
    INSTALL_DEP_A=true
    INSTALL_DEP_B=false  # This one is disabled

    register_tool "chained" chained_tool "Chained Tool" "" "dep_a,dep_b" "all"

    run run_registry

    [[ "${tool_called}" == "false" ]]
    [[ "${output}" == *"depends on dep_b which is disabled"* ]]
}

@test "run_registry: runs tool when all multiple dependencies are enabled" {
    multi_called=false
    multi_tool() { multi_called=true; }

    INSTALL_MULTI=true
    INSTALL_DEP_X=true
    INSTALL_DEP_Y=true

    register_tool "multi" multi_tool "Multi Dep Tool" "" "dep_x,dep_y" "all"

    run_registry

    [[ "${multi_called}" == "true" ]]
}

###############################################################
# run_registry: CI mode skips GUI apps (gui field)
###############################################################

@test "run_registry: CI mode skips gui=true tools" {
    export DOTFILES_CI=true

    gui_called=false
    gui_tool() { gui_called=true; }
    INSTALL_GUITOOL=true
    register_tool "guitool" gui_tool "GUI Tool" "" "" "all" "true"

    run run_registry

    [[ "${gui_called}" == "false" ]]
    [[ "${output}" == *"CI mode: skipping GUI Tool"* ]]
}

@test "run_registry: CI mode runs gui=false tools" {
    export DOTFILES_CI=true

    cli_called=false
    cli_tool() { cli_called=true; }
    INSTALL_CLITOOL=true
    register_tool "clitool" cli_tool "CLI Tool" "" "" "all" "false"

    run_registry

    [[ "${cli_called}" == "true" ]]
}

@test "run_registry: CI mode does not skip tools with gui defaulting to false" {
    export DOTFILES_CI=true

    python_called=false
    python_tool() { python_called=true; }
    INSTALL_PYTHON=true
    register_tool "python" python_tool "Python" "" "" "all"

    run_registry

    [[ "${python_called}" == "true" ]]
}

@test "run_registry: non-CI mode runs gui=true tools" {
    export DOTFILES_CI=false

    gui_called=false
    gui_tool() { gui_called=true; }
    INSTALL_GUITOOL=true
    register_tool "guitool" gui_tool "GUI Tool" "" "" "all" "true"

    run_registry

    [[ "${gui_called}" == "true" ]]
}

###############################################################
# run_registry: mixed scenarios
###############################################################

@test "run_registry: mixed enabled/disabled/platform/deps" {
    create_mock_uname "Darwin"

    enabled_called=false
    enabled_tool() { enabled_called=true; }
    disabled_called=false
    disabled_tool() { disabled_called=true; }
    linux_called=false
    linux_tool() { linux_called=true; }
    dep_missing_called=false
    dep_missing_tool() { dep_missing_called=true; }

    INSTALL_ENABLED=true
    INSTALL_DISABLED=false
    INSTALL_LINONLY=true
    INSTALL_NEEDSDEP=true
    INSTALL_MISSINGDEP=false

    register_tool "enabled" enabled_tool "Enabled" "" "" "all"
    register_tool "disabled" disabled_tool "Disabled" "" "" "all"
    register_tool "linonly" linux_tool "Linux Only" "" "" "linux"
    register_tool "needsdep" dep_missing_tool "Needs Dep" "" "missingdep" "all"

    run_registry

    [[ "${enabled_called}" == "true" ]]
    [[ "${disabled_called}" == "false" ]]
    [[ "${linux_called}" == "false" ]]
    [[ "${dep_missing_called}" == "false" ]]
}

@test "run_registry: continues after a tool failure" {
    fail_tool() { return 1; }
    after_tool() { echo "after_was_called" > "${TEST_TMPDIR}/after_marker"; }

    INSTALL_FAIL=true
    INSTALL_AFTER=true

    register_tool "fail" fail_tool "Fail Tool" "" "" "all"
    register_tool "after" after_tool "After Tool" "" "" "all"

    # Capture return code without set -e aborting
    local registry_status=0
    run_registry || registry_status=$?

    [[ "${registry_status}" -eq 1 ]]
    # after_tool should have run despite fail_tool failing
    [[ -f "${TEST_TMPDIR}/after_marker" ]]
}
