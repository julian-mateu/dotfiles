#!/bin/bash
# Tool registry for config-driven installation
# Sourced by install.sh

# Tool registry - array of tool definitions
# Format: "key|function|description|url|depends_on|platform"
declare -a TOOL_REGISTRY=()

# Register a tool with the registry
# Parameters:
#   $1 - key: identifier matching INSTALL_<KEY> variable (lowercase)
#   $2 - function: install function name to call
#   $3 - description: human-readable name for log messages
#   $4 - url: reference URL for more information
#   $5 - dependencies: comma-separated keys this tool depends on (optional)
#   $6 - platform: "all", "macos", or "linux" (default: "all")
register_tool() {
    local key="${1}" fn="${2}" desc="${3}" url="${4}" deps="${5:-}" platform="${6:-all}"
    TOOL_REGISTRY+=("${key}|${fn}|${desc}|${url}|${deps}|${platform}")
}

# Check if a tool is enabled via its INSTALL_* variable
# Parameters:
#   $1 - key: tool identifier (lowercase, e.g. "python", "oh_my_zsh")
# Returns: 0 if enabled (true), 1 otherwise
is_tool_enabled() {
    local key="${1}"
    # Convert key to uppercase and prepend INSTALL_
    local var_name
    var_name="INSTALL_$(echo "${key}" | tr '[:lower:]' '[:upper:]')"
    local value="${!var_name:-}"
    [[ "${value}" == "true" ]]
}

# Run all registered tools that are enabled, respecting platform and dependencies
# Iterates through TOOL_REGISTRY in order, skipping tools that are:
#   - not enabled via INSTALL_* variable
#   - not applicable to the current platform
#   - GUI apps when running in CI mode
#   - missing required dependencies
# Returns: 0 if all enabled tools succeeded, 1 if any failed
run_registry() {
    local failed=0
    for entry in "${TOOL_REGISTRY[@]}"; do
        IFS='|' read -r key fn desc url deps platform <<< "${entry}"

        # Platform check
        if [[ "${platform}" == "macos" ]] && ! is_macos; then continue; fi
        if [[ "${platform}" == "linux" ]] && is_macos; then continue; fi

        # GUI apps: skip in CI mode
        case "${key}" in
            vscode|slack|obsidian|zoom|spotify|chrome|nerd_fonts|iterm2|displaylink|docker)
                if [[ "${DOTFILES_CI:-false}" == "true" ]]; then
                    print_info "CI mode: skipping ${desc}"
                    continue
                fi
                ;;
        esac

        # Skip if disabled
        if ! is_tool_enabled "${key}"; then
            print_info "Skipping ${desc} (disabled in config)"
            continue
        fi

        # Dependency check
        if [[ -n "${deps}" ]]; then
            IFS=',' read -ra dep_list <<< "${deps}"
            local dep_missing=false
            for dep in "${dep_list[@]}"; do
                if ! is_tool_enabled "${dep}"; then
                    print_warning "${desc} depends on ${dep} which is disabled - skipping"
                    dep_missing=true
                    break
                fi
            done
            if [[ "${dep_missing}" == "true" ]]; then continue; fi
        fi

        # Execute
        print_info "Installing ${desc}..."
        if ! "${fn}"; then
            print_warning "Failed to install ${desc} - continuing with remaining tools"
            failed=1
        fi
    done
    return ${failed}
}
