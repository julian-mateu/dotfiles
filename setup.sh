#!/bin/bash

# set -e -o pipefail - are bash options that are set to ensure the script fails fast and with a clear error message. -e is for error handling, -o pipefail is for pipeline handling.
set -e -o pipefail

# SAFELOAD: Load utility functions - required for this script to work
# See: zutils.zsh for ANSI color utilities and other functions
# ${0%/*} is parameter expansion that removes the shortest match of "/*" from the end of $0
# See: bash manual "Parameter Expansion" section
# shellcheck disable=SC1091
source "${0%/*}/zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    echo "Please ensure the dotfiles repository is properly set up." >&2
    exit 1
}

# Global variables
FORCE_FLAG=""
ZPROFILE_CUSTOM_FILE='./zprofile_custom.zsh'

###############################################################
# => Main function
###############################################################

# main - Main entry point for the setup script
# Usage: main [arguments...]
# Parameters: Command line arguments passed to the script
# Returns: 0 on success, 1 on error
# Note: Orchestrates the entire setup process including dependency installation
main() {
    parse_arguments "${@}"

    print_info "Do you want to install dependencies (needed if setting up a new computer)? [y/n]"
    print_warning "Note that if the setup process fails because some command is not found, you might need to open a new shell and run ./install.sh again!"
    read -p "" -n 1 -r REPLY
    echo

    # =~ ^[Yy]$ - regex match for y or Y
    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        ./install.sh
    fi

    # -L is a test for a symbolic link
    if [[ ! -L "${HOME}/.gitconfig" ]]; then
        create_git_config
    fi

    ssh_config
    copy_files
}

###############################################################
# => Argument parsing
###############################################################

# parse_arguments - Parse command line arguments
# Usage: parse_arguments [arguments...]
# Parameters: Command line arguments to parse
# Returns: 0 on success, 1 on error
# Note: Uses getopts for argument parsing, supports -f (force) and -h (help)
parse_arguments() {
    # getopts is a built-in command that parses command line options
    # hf are the options that are supported, to pass with -f or -h. o is the variable that will store the option.
    while getopts "hf" o; do
        case "${o}" in
        f)
            FORCE_FLAG="force"
            ;;
        h)
            usage
            exit 0
            ;;
        # \? is a wildcard for any option that is not supported
        # * is a wildcard for any other option
        \? | *)
            usage
            exit 1
            ;;
        esac
    done

    # shift $((OPTIND - 1)) - remove processed options from argument list
    shift $((OPTIND - 1))

    if [[ "${#}" -ne 0 ]]; then
        print_error "Illegal number of parameters ${0}: got ${#} but expected exactly 0: ${*}"
        usage
        exit 1
    fi
}

# usage - Display help information
# Usage: usage
# Returns: None (outputs to stderr)
# Note: Uses here-document for formatted help output
usage() {
    cat <<-EOF >&2
		Usage: ${0##*/} [-hf]
		Setup the configuration files by creating symbolic links. It will prompt the user interactively 
		in case it's required to install dependencies. It will prompt the user for git name and email
		in case ~/.gitconfig does not exist. It will automatically download the amix.vim file to keep it
		updated.
		
		-h          display this help and exit
		-f          force mode: this will overwrite existing symbolic links.
	EOF
}

###############################################################
# => Git configuration
###############################################################

# create_git_config - Create git configuration file
# Usage: create_git_config
# Returns: 0 on success, 1 on error
# Note: Prompts for git name and email if not provided via environment variables
#       Uses here-document to create the gitconfig file
create_git_config() {
    if [[ -z ${GIT_NAME+x} ]]; then
        read -p "Enter the name for your git commits and press [ENTER]: " -r GIT_NAME
    fi

    if [[ -z ${GIT_EMAIL+x} ]]; then
        read -p "Enter the email for your git commits and press [ENTER]: " -r GIT_EMAIL
    fi

    print_info "Will write the following to ${HOME}/.gitconfig:"

    # tee gitconfig - write to both stdout and the gitconfig file
    tee gitconfig <<-EOF
		[user]
		    email = ${GIT_EMAIL}
		    name = ${GIT_NAME}
		[push]
		    followTags = true
		[init]
		    defaultBranch = main
		[pull]
		    ff = only
		[core]
		    excludesFile = ~/.gitignore
		    editor = nvim -f
	EOF
}

# ssh_config - Create ssh configuration file
# Usage: ssh_config
# Returns: 0 on success, 1 on error
# Note: Prompts for ssh keys if not provided via environment variables
#       Uses here-document to create the sshconfig file
ssh_config() {
    if [[ ! -e "${HOME}/.ssh/config" ]]; then
        print_info "Creating ${HOME}/.ssh/config"
        mkdir -p "${HOME}/.ssh"
        touch "${HOME}/.ssh/config"

        tee "${HOME}/.ssh/config" <<-EOF
			Host github.com-personal
			  HostName github.com
			  AddKeysToAgent yes
			  UseKeychain yes
			  IdentityFile ~/.ssh/id_ed25519-personal
			
			Host *
			  AddKeysToAgent yes
			  UseKeychain yes
			  IdentityFile ~/.ssh/id_ed25519
		EOF
    fi

    if [[ ! -e "${HOME}/.ssh/id_ed25519-personal" ]]; then
        print_info "Creating ${HOME}/.ssh/id_ed25519-personal"
        if [[ -z ${GIT_EMAIL_PERSONAL+x} ]]; then
            read -p "Enter the email for your personal ssh key and press [ENTER]: " -r GIT_EMAIL_PERSONAL
        fi
        ssh-keygen -t ed25519 -C "${GIT_EMAIL_PERSONAL}" -f "${HOME}/.ssh/id_ed25519-personal"
    fi

    if [[ ! -e "${HOME}/.ssh/id_ed25519" ]]; then
        print_info "Creating ${HOME}/.ssh/id_ed25519"
        if [[ -z ${GIT_EMAIL_WORK+x} ]]; then
            read -p "Enter the email for your work ssh key and press [ENTER]: " -r GIT_EMAIL_WORK
        fi
        ssh-keygen -t ed25519 -C "${GIT_EMAIL_WORK}" -f "${HOME}/.ssh/id_ed25519"
    fi

    print_info "Adding the ssh keys to the agent"
    eval "$(ssh-agent -s)"
    ssh-add "${HOME}/.ssh/id_ed25519-personal"
    ssh-add "${HOME}/.ssh/id_ed25519"

    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => SSH configuration
		###############################################################
		print_debug "$(eval "$(ssh-agent -s)")"
		print_debug "$(ssh-add "${HOME}/.ssh/id_ed25519-personal")"
		print_debug "$(ssh-add "${HOME}/.ssh/id_ed25519")"
	EOS
    append_lines_to_file_if_not_there "${lines}" "${ZPROFILE_CUSTOM_FILE}"
}

###############################################################
# => File operations
###############################################################

# copy_files - Copy all configuration files to their target locations
# Usage: copy_files
# Returns: 0 on success, 1 on error
# Note: Iterates through all files in current directory and creates symlinks
#       Excludes certain files that shouldn't be symlinked
copy_files() {
    for name in *; do
        if [[ ! -d "${name}" ]]; then
            target="${HOME}/.${name}"
            # =~ ^(install.sh|setup.sh|README.md|julianmateu.zsh-theme)$ - regex match to exclude files
            if ! [[ "${name}" =~ ^(install.sh|setup.sh|README.md|julianmateu.zsh-theme)$ ]]; then
                copy_file "${PWD}/${name}" "${target}"
            fi
        fi
    done

    if [[ -n "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" ]]; then
        copy_file "${PWD}/julianmateu.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/julianmateu.zsh-theme"
    else
        print_warning "Did not copy the zsh theme as the zsh custom directory does not exist"
    fi
}

# copy_file - Create symbolic link for a single file with backup
# Usage: copy_file <source> <target>
# Parameters:
#   $1 - Source file path
#   $2 - Target symlink path
# Returns: 0 on success, 1 on error
# Note: Creates backup of existing files, handles symlinks appropriately
#       Uses create_symlink utility function for consistency
copy_file() {
    local source="${1}"
    local target="${2}"

    if [[ -e "${target}" ]]; then             # Does the config file already exist?
        if [[ ! -L "${target}" ]]; then       # as a pure file?
            backup_file "${target}"           # Then backup it using utility function
            print_info "Moved your old ${target} config file to ${target}.backup"
        fi
    fi

    if [[ ! -e "${target}" ]]; then
        print_info "Symlinking your new ${target}"
        # ${FORCE_FLAG:+-f} - parameter expansion: if FORCE_FLAG is set, add -f flag
        ln -s ${FORCE_FLAG:+-f} "${source}" "${target}"
    fi
}

# Script execution guard
# ${BASH_SOURCE[0]} is the path to the current script
# ${0} is the name of the script as it was called
# This check ensures the script only runs when executed directly, not when sourced
# See: bash manual "Special Parameters" section
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@}"
fi
