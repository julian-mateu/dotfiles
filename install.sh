#!/bin/bash
set -e -o pipefail -u

PROFILE_FILE='./zprofile_custom.zsh'
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NC='\033[m' # No Color

main() {
    # OSX stuffx
    setup_x_code
    setup_homebrew
    setup_homebrew_services

    # ZSH
    setup_oh_my_zsh_and_plugins

    # Misc tools
    ask_for_confirmation "useful tools" "more info in the command if you accept" setup_useful_tools

    # GIT & Python
    ask_for_confirmation "hub" "https://hub.github.com/" install_hub
    ask_for_confirmation "pyenv-python" "https://github.com/pyenv/pyenv#installation" install_python

    # JS
    ask_for_confirmation "nvm" "https://github.com/nvm-sh/nvm/blob/master/README.md" install_nvm
    setup_node
    setup_yarn
    setup_yalc

    # AWS
    ask_for_confirmation "aws_cli" "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" \
        setup_aws_cli
    setup_botoenv
    setup_testim
    setup_terraform

    # Java
    ask_for_confirmation "sdk_man" "https://sdkman.io/install" install_sdk_man
    setup_java_11_openjdk
    setup_gradle

    # Kubernetes
    ask_for_confirmation "kubernetes" "https://kubernetes.io/" install_kubernetes

    # Kafka
    ask_for_confirmation "librdkafka" "https://formulae.brew.sh/formula/librdkafka" brew install librdkafka
    setup_conduktor

    # Vagrant
    setup_vagrant_and_virtualbox

    # IDEs
    setup_ides

    # Slack
    ask_for_confirmation "Reinstall slack" "Will delete the current version and reinstall using brew" setup_slack

    # shellcheck disable=SC2016
    echo -e "${GREEN}Done!${NC} you will have to run: $(fmt_code 'source "${HOME}/.zshrc"')"
}

setup_x_code() {
    echo "Installing XCode command line tools, you might need to install XCode itself from the app store"
    ask_for_confirmation "xcode" "https://developer.apple.com/xcode/" xcode-select --install
}

setup_homebrew() {
    # shellcheck disable=SC2016
    ask_for_confirmation "brew" "https://brew.sh/" \
        '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'

# Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		# brew
		eval "$(/opt/homebrew/bin/brew shellenv)"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"

    eval "$(/opt/homebrew/bin/brew shellenv)"

    mkdir -p "${HOME}/Library/LaunchAgents"
    ask_for_confirmation "brew automatic updates" "https://docs.brew.sh/Manpage#autoupdate-subcommand-interval-options" \
        brew autoupdate start --upgrade
}

setup_homebrew_services() {
    ask_for_confirmation "homebrew services" "https://thoughtbot.com/blog/starting-and-stopping-background-services-with-homebrew" \
        brew tap homebrew/services
}

setup_oh_my_zsh_and_plugins() {
    # shellcheck disable=SC2016
    ask_for_confirmation "oh-my-zsh" "https://github.com/ohmyzsh/ohmyzsh" \
        'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

    ask_for_confirmation "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh" \
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

    ask_for_confirmation "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md" \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    ask_for_confirmation "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" \
        git clone https://github.com/zsh-users/zsh-history-substring-search "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"

    ask_for_confirmation "zsh-nvm" "https://github.com/lukechilds/zsh-nvm" \
        git clone https://github.com/lukechilds/zsh-nvm "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-nvm"

}

setup_useful_tools() {
    ask_for_confirmation "postgresql" "https://www.postgresql.org/" brew install postgresql
    ask_for_confirmation "rg" "https://formulae.brew.sh/formula/ripgrep" brew install ripgrep
    ask_for_confirmation "git lfs" "https://git-lfs.github.com/" brew install git-lfs
    ask_for_confirmation "trash" "https://hasseg.org/trash/" brew install trash
    ask_for_confirmation "coreutils" "https://www.gnu.org/software/coreutils/" brew install coreutils
    ask_for_confirmation "GNU parallel" "https://www.gnu.org/software/parallel/" brew install parallel
    ask_for_confirmation "gsed" "https://formulae.brew.sh/formula/gnu-sed" brew install gsed
    ask_for_confirmation "watch" "https://formulae.brew.sh/formula/watch" brew install watch
    ask_for_confirmation "pv" "https://formulae.brew.sh/formula/pv" brew install pv
    ask_for_confirmation "dnsmasq" "https://thekelleys.org.uk/dnsmasq/doc.html" brew install dnsmasq
    ask_for_confirmation "csvkit" "https://csvkit.readthedocs.io/en/latest/" brew install csvkit
    ask_for_confirmation "shellcheck" "https://github.com/koalaman/shellcheck#installing" brew install shellcheck
    ask_for_confirmation "jq" "https://stedolan.github.io/jq/" brew install jq
    ask_for_confirmation "httpie" "https://httpie.io/" brew install httpie
    ask_for_confirmation "pgcli" "https://www.pgcli.com/" brew install pgcli
    ask_for_confirmation "bloomrpc" "https://github.com/uw-labs/bloomrpc" brew install --cask bloomrpc
    ask_for_confirmation "tig" "https://jonas.github.io/tig/INSTALL.html" brew install tig
    ask_for_confirmation "wget" "https://www.gnu.org/software/wget/" brew install wget
    ask_for_confirmation "htop" "https://htop.dev/" brew install htop
    ask_for_confirmation "insomnia" "https://insomnia.rest/" brew install insomnia
    ask_for_confirmation "k6" "https://k6.io/docs/getting-started/installation/#macos" brew install k6
    ask_for_confirmation "GPG" "https://gnupg.org/" brew install gnupg

    ask_for_confirmation "re2" "for python toml packages in m1 mac" brew install re2

    ask_for_confirmation "git-secret" "https://formulae.brew.sh/formula/git-secret" brew install git-secret
    ask_for_confirmation "paperkey" "https://formulae.brew.sh/formula/paperkey" brew install paperkey

    ask_for_confirmation "aspell" "http://aspell.net/" brew install aspell
}

install_hub() {
    brew install hub

    # Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		# hub
		eval "$(hub alias -s)"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
}

install_python() {
    brew install pyenv
    brew install openssl readline sqlite3 xz zlib
    brew install openblas

    # Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		# PyEnv
		export PYENV_ROOT="${HOME}/.pyenv"
		export PATH="${PYENV_ROOT}/bin:${PATH}"
		eval "$(pyenv init --path)"

		# pyenv adds *-config scripts and produces a brew warning
		function brew_wrapper() {
		    current_version="$(pyenv global)"
		    pyenv global system
		    echo -e "\033[31mWarning: changed pyenv version from ${current_version} to system\033[m\n"
		    brew "${@}"
		    echo -e "\033[31mWarning: changed pyenv version from system to ${current_version} \033[m\n"
		    pyenv global "${current_version}"
		}
		alias brew="brew_wrapper"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"

    pyenv install 3.9.10
    pyenv global 3.9.10

    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init --path)"

    pip install --upgrade pip setuptools
}

setup_aws_cli() {
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg ./AWSCLIV2.pkg -target /
    rm -rf ./AWSCLIV2.pkg
}

setup_botoenv() {
    ask_for_confirmation "botoenv" "https://github.com/globality-corp/botoenv" \
        pip install botoenv
}

install_nvm() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash

    # Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		# NVM
		export NVM_DIR="${HOME}/.nvm"
		[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm
		[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

setup_node() {
    ask_for_confirmation "node14.16.1" "https://nodejs.org/en/download/package-manager/#nvm" \
        nvm install 14.16.1
}

setup_yarn() {
    ask_for_confirmation "yarn" "https://classic.yarnpkg.com/en/docs/install/#mac-stable" \
        npm install -g yarn
}

setup_yalc() {
    ask_for_confirmation "yalc" "https://www.npmjs.com/package/yalc" \
        npm i yalc -g
}

setup_testim() {
    ask_for_confirmation "testim" "https://help.testim.io/docs" \
        npm install -g @testim/testim-cli
}

setup_terraform() {
    ask_for_confirmation "terraform" "https://www.terraform.io/intro/" \
        brew install terraform
}

setup_vagrant_and_virtualbox() {
    ask_for_confirmation "virtualbox" "https://www.virtualbox.org/" \
        brew install --cask virtualbox
    ask_for_confirmation "vagrant" "https://www.vagrantup.com/" \
        brew install --cask vagrant
    ask_for_confirmation "vagrant-manager" "https://www.vagrantmanager.com/" \
        brew install --cask vagrant-manager
}

install_sdk_man() {
    curl -s "https://get.sdkman.io" | bash

    # Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		# sdkman
		#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
		export SDKMAN_DIR="${HOME}/.sdkman"
		[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"

}

setup_java_11_openjdk() {
    print_warning "sdk might not work inside a script so you might need to run the following command in a separate terminal..."
    ask_for_confirmation "java_11_openjdk" "https://sdkman.io/usage" \
        sdk install java 11.0.2-open
}

setup_gradle() {
    ask_for_confirmation "gradle" "https://docs.gradle.org/current/userguide/installation.html" \
        brew install gradle
}

install_kubernetes() {
    print_warning "$(cat <<-EOS
		Before installing Kubernetes, it is advised to first install docker desktop: $(fmt_underline https://docs.docker.com/desktop/mac/install/)
		However, it is possible to use hyperkit $(fmt_underline https://minikube.sigs.k8s.io/docs/drivers/hyperkit/)
	EOS
    )"
    ask_for_confirmation "docker" "https://docs.docker.com/desktop" \
        install_docker
    ask_for_confirmation "hyperkit" "https://github.com/moby/hyperkit" \
        brew install hyperkit
    ask_for_confirmation "minikube" "https://minikube.sigs.k8s.io/docs/start/" \
        brew install minikube
    ask_for_confirmation "kubectl" "https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos" \
        brew install kubectl
    ask_for_confirmation "k9s" "https://k9scli.io/" \
        brew install k9s
    ask_for_confirmation "helm" "https://helm.sh/" \
        brew install helm
    ask_for_confirmation "skaffold" "https://skaffold.dev/" \
        brew install skaffold
    ask_for_confirmation "telepresence" "https://www.telepresence.io/" \
        brew install datawire/blackbird/telepresence
    ask_for_confirmation "lens" "https://k8slens.dev/" \
        brew install --cask lens
    print_warning "You will need to have installed docker desktop, and change the memory to at least 4.1GB. Then run: $(fmt_code minikube start --cpus 4 --memory 4096)"
}

install_docker() {
    architecture="$(uname -m)"

    if [[ "${architecture}" = "x86_64" ]]; then
        curl "https://desktop.docker.com/mac/main/amd64/Docker.dmg" -o "Docker.dmg"
    elif [[ "${architecture}" = "arm64" ]]; then
        curl "https://desktop.docker.com/mac/main/arm64/Docker.dmg" -o "Docker.dmg"
    else
        echo "unknown architecture ${architecture}. Please install docker manually."
    fi
    sudo hdiutil attach "./Docker.dmg"
    sudo cp -R "/Volumes/Docker/Docker.app" "/Applications"
    sudo hdiutil unmount "/Volumes/Docker"
    rm -rf "./Docker.dmg"
}

setup_conduktor() {
    ask_for_confirmation "conduktor" "https://www.conduktor.io/" \
        "brew tap conduktor/brew && brew install conduktor"
}

setup_ides() {
    ask_for_confirmation "IntelliJ IDEA CE" "https://www.jetbrains.com/idea/" \
        brew install --cask intellij-idea-ce
    ask_for_confirmation "Visual Studio Code" "https://code.visualstudio.com/" \
        brew install --cask visual-studio-code
    ask_for_confirmation "PyCharm" "https://www.jetbrains.com/pycharm/" \
        brew install --cask pycharm-ce
}

setup_slack() {
    ask_for_confirmation "Delete current slack version" "" \
        trash "/Applications/Slack.app"
    ask_for_confirmation "slack" "https://www.slack.com" \
        brew install slack
}

append_lines_to_file_if_not_there() {
    if [[ "${#}" -ne 2 ]]; then
        echo "Illegal number of parameters ${0}: got ${#} but expected 2: ${*}" >&2
        exit 2
    fi
    lines="${1}"
    file="${2}"
    while IFS= read -r line; do
        if [[ "${line}" == "" ]]; then
            echo "${line}" >>"${file}"
        fi
        grep -qxF "${line}" "${file}" || echo "${line}" >>"${file}"
    done < <(echo "${lines}")

}

ask_for_confirmation() {
    if [[ "${#}" -le 2 ]]; then
        echo "Illegal number of parameters ${0}: got ${#} but expected at least 3: ${*}" >&2
        return 2
    fi

    echo
    echo -e "Do you want to install ${YELLOW}${1}${NC}? [y/n]"
    echo -e " this will run: ${YELLOW}" "$(fmt_code "${@:3}")" "${NC}"
    echo -e " see $(fmt_underline "${2}")"
    read -p "" -n 1 -r REPLY
    echo

    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        "${@:3}"
    fi
}

print_warning() {
    echo -e "${RED}${*}${NC}"
    read -p "press any key to continue..." -n 1 -r REPLY
    echo
}

fmt_underline() {
    printf '\033[4m%s\033[24m\n' "$*"
}

fmt_code() {
    # shellcheck disable=SC2016 # backtic in single-quote
    printf '`\033[38;5;247m%s%s`\n' "$*" "${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
