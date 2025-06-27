#! /bin/bash
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

main() {

    parse_arguments "${@}"

    echo -e "Do you want to install dependencies (needed if setting up a new computer)? [y/n]"
    echo -e " $(colorize "Warning: note that if the setup process fails because some command is not found, you might need to open a new shell and run ./install.sh again!" yellow)"
    read -p "" -n 1 -r REPLY
    echo

    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        ./install.sh
    fi

    if [[ ! -L "${HOME}/.gitconfig" ]]; then
        create_git_config
    fi
    copy_files
}

parse_arguments() {
    while getopts "hf" o; do
        case "${o}" in
        f)
            FORCE_FLAG="force"
            ;;
        h)
            usage
            exit 0
            ;;
        \? | *)
            usage
            exit 1
            ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ "${#}" -ne 0 ]]; then
        echo "Illegal number of parameters ${0}: got ${#} but expected exactly 0: ${*}" >&2
        usage
        exit 1
    fi
}

usage() {
    cat <<-EOF >&2
		Usage: ${0##*/} [-hf]
		Setup the configuration files by creating symboling links. It will promt the user interactivelly 
		in case it's required to install dependencies. It will prompt the user for git name and email
		in case ~/.gitconfig does not exist. It will automatically download the amix.vim file to keep it
		updated.
		
		-h          display this help and exit
		-f          force mode: this will overwrite existing symbolic links.
	EOF
}

create_git_config() {
    if [[ -z ${GIT_NAME+x} ]]; then
        read -p "Enter the name for your git commits and press [ENTER]: " -r GIT_NAME
    fi

    if [[ -z ${GIT_EMAIL+x} ]]; then
        read -p "Enter the email for your git commits and press [ENTER]: " -r GIT_EMAIL
    fi

    echo "will write the following to ${HOME}/.gitconfig: "

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

copy_files() {
    for name in *; do
        if [[ ! -d "${name}" ]]; then
            target="${HOME}/.${name}"
            if ! [[ "${name}" =~ ^(install.sh|setup.sh|README.md|julianmateu.zsh-theme)$ ]]; then
                copy_file "${PWD}/${name}" "${target}"
            fi
        fi
    done

    if [[ -n "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}" ]]; then
        copy_file "${PWD}/julianmateu.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/julianmateu.zsh-theme"
    else
        echo -e "$(colorize "Warning: did not copy the zsh theme as the zsh custom directory does not exist" yellow)"
    fi
}

copy_file() {
    source="${1}"
    target="${2}"

    if [[ -e "${target}" ]]; then             # Does the config file already exist?
        if [[ ! -L "${target}" ]]; then       # as a pure file?
            mv "${target}" "${target}.backup" # Then backup it
            echo "-----> Moved your old ${target} config file to ${target}.backup"
        fi
    fi

    if [[ ! -e "${target}" ]]; then
        echo "-----> Symlinking your new ${target}"
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
