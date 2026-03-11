#!/bin/bash
# Configuration loading for dotfiles install
# Sourced by install.sh - not meant to be run standalone

# Parse command-line arguments for config/profile support
# Sets: CONFIG_FILE, PROFILE, DOTFILES_DRY_RUN
parse_arguments() {
    CONFIG_FILE=""
    PROFILE=""
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --dry-run)
                DOTFILES_DRY_RUN="true"
                print_warning "DRY RUN: showing config blocks that would be written (no installs)"
                shift
                ;;
            --config)
                if [[ -z "${2:-}" ]]; then
                    print_error "--config requires a file path argument"
                    return 1
                fi
                CONFIG_FILE="${2}"
                if [[ ! -f "${CONFIG_FILE}" ]]; then
                    print_error "Config file not found: ${CONFIG_FILE}"
                    return 1
                fi
                shift 2
                ;;
            --profile)
                if [[ -z "${2:-}" ]]; then
                    print_error "--profile requires a profile name argument"
                    return 1
                fi
                PROFILE="${2}"
                shift 2
                ;;
            *)
                print_error "Unknown argument: ${1}"
                print_info "Usage: install.sh [--dry-run] [--config <file>] [--profile <name>]"
                return 1
                ;;
        esac
    done

    # Validate mutually exclusive options
    if [[ -n "${CONFIG_FILE}" ]] && [[ -n "${PROFILE}" ]]; then
        print_error "--config and --profile are mutually exclusive"
        return 1
    fi
}

# Load configuration from file or profile
# Sets all INSTALL_* variables
# Returns: 0 if config was loaded, 1 if no config found (caller should fall back to interactive)
load_configuration() {
    if [[ -n "${CONFIG_FILE}" ]]; then
        print_info "Loading config from: ${CONFIG_FILE}"
        source "${CONFIG_FILE}"
    elif [[ -n "${PROFILE}" ]]; then
        print_info "Loading profile: ${PROFILE}"
        load_profile "${PROFILE}"
    elif [[ -f "./dotfiles.conf" ]]; then
        print_info "Loading config from: ./dotfiles.conf"
        source "./dotfiles.conf"
    else
        return 1  # No config found - caller should fall back to interactive
    fi
    return 0
}
