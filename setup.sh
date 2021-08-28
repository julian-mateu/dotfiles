#! /bin/bash
set -e -o pipefail

YELLOW='\033[33m'
NC='\033[m' # No Color

main() {

    parse_arguments "${@}"

    if [[ ! -L "${HOME}/.gitconfig" ]]; then
        create_git_config
    fi
    download_amix_vimrc
    copy_files

    echo -e "Do you want to install dependencies (needed if setting up a new computer)? [y/n]"
    echo -e " ${YELLOW}Warning: note that if the setup process fails because spme command is not found, you might need to open a new shell and run ./install.sh again!${NC}"
    read -p "" -n 1 -r REPLY
    echo

    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        ./install.sh
    fi
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
	EOF
}

download_amix_vimrc() {
    curl -fsSL https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim >amix.vim
}

copy_files() {
    for name in *; do
        if [[ ! -d "${name}" ]]; then
            target="${HOME}/.${name}"
            if ! [[ "${name}" =~ ^(install.sh|setup.sh|README.md)$ ]]; then

                if [[ -e "${target}" ]]; then             # Does the config file already exist?
                    if [[ ! -L "${target}" ]]; then       # as a pure file?
                        mv "${target}" "${target}.backup" # Then backup it
                        echo "-----> Moved your old ${target} config file to ${target}.backup"
                    fi
                fi

                if [[ ! -e "${target}" ]]; then
                    echo "-----> Symlinking your new ${target}"
                    ln -s ${FORCE_FLAG:+-f} "${PWD}/${name}" "${target}"
                fi
            fi
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${@}"
fi
