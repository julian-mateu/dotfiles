#!/bin/bash
# Built-in profiles for dotfiles install
# Sourced by install.sh via lib/config.sh

# Set all INSTALL_* variables to false (baseline)
_reset_all_install_vars() {
    INSTALL_HOMEBREW=false
    INSTALL_OH_MY_ZSH=false
    INSTALL_NVIM=false
    INSTALL_USEFUL_TOOLS=false
    INSTALL_PYTHON=false
    INSTALL_GO=false
    INSTALL_RUST=false
    INSTALL_NODE=false
    INSTALL_JAVA=false
    INSTALL_DOTNET=false
    INSTALL_KUBERNETES=false
    INSTALL_DOCKER=false
    INSTALL_VSCODE=false
    INSTALL_SLACK=false
    INSTALL_OBSIDIAN=false
    INSTALL_ZOOM=false
    INSTALL_SPOTIFY=false
    INSTALL_CHROME=false
    INSTALL_NERD_FONTS=false
    INSTALL_ITERM2=false
    INSTALL_DISPLAYLINK=false
    INSTALL_CLAUDE_CODE=false
    INSTALL_DEVS_CLI=false
}

# Load a built-in profile by name
# Profiles are cumulative: backend includes minimal, full includes backend
# Parameters:
#   $1 - Profile name (minimal, backend, full)
# Returns: 0 on success, 1 if profile is unknown
load_profile() {
    local profile_name="${1}"
    case "${profile_name}" in
        minimal)
            _reset_all_install_vars
            INSTALL_HOMEBREW=true
            INSTALL_OH_MY_ZSH=true
            INSTALL_NVIM=true
            INSTALL_USEFUL_TOOLS=true
            INSTALL_PYTHON=true
            INSTALL_GO=true
            INSTALL_RUST=true
            INSTALL_NODE=true
            INSTALL_CLAUDE_CODE=true
            ;;
        backend)
            load_profile minimal
            INSTALL_JAVA=true
            INSTALL_DOTNET=true
            INSTALL_KUBERNETES=true
            INSTALL_DOCKER=true
            ;;
        full)
            load_profile backend
            INSTALL_VSCODE=true
            INSTALL_NERD_FONTS=true
            INSTALL_ITERM2=true
            INSTALL_DEVS_CLI=true
            ;;
        *)
            print_error "Unknown profile: ${profile_name}"
            print_info "Available profiles: minimal, backend, full"
            return 1
            ;;
    esac
}
