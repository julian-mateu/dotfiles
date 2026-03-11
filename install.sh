#!/bin/bash
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

# Configuration variables
ZPROFILE_CUSTOM_FILE='./zprofile_custom.zsh'
ZSHENV_CUSTOM_FILE='./zshenv_custom.zsh'
ZSHRC_CUSTOM_FILE='./zshrc_custom.zsh'
DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-false}"

PYTHON_VERSION='3.13.1'
SDK_JAVA_VERSION='24-open'
NVM_VERSION='0.40.3'
OBSIDIAN_VERSION='1.8.10'
DISPLAYLINK_DATE="2025-06"
DISPLAYLINK_VERSION="1.12.4"
DOTNET_VERSION='8'

NEOVIM_CONFIG_REPO='https://github.com/julianmateu/nvim-config.git'

###############################################################
# => Main function
###############################################################

# main - Main entry point for the installation script
# Usage: main [--dry-run] [arguments...]
# Parameters: Command line arguments passed to the script
# Returns: 0 on success, 1 on error
# Note: Orchestrates the entire installation process for development tools
#       Use --dry-run to show what config blocks WOULD be written without installing anything
main() {
    # Parse --dry-run flag
    if [[ "${1:-}" == "--dry-run" ]]; then
        DOTFILES_DRY_RUN="true"
        shift
        print_warning "DRY RUN: showing config blocks that would be written (no installs)"
    fi

    init_custom_files

    # System setup - these run commands directly (not via ask_for_confirmation),
    # so they need an explicit dry-run guard
    if [[ "${DOTFILES_DRY_RUN}" != "true" ]]; then
        # Check OS and install dependencies
        if is_macos; then
            print_info "Installing macOS dependencies"
            setup_x_code
        else
            print_info "Installing Linux dependencies"
            setup_apt_get
        fi

        setup_homebrew

        # ZSH
        setup_oh_my_zsh_and_plugins

        # Nvim
        setup_nvim
    else
        print_warning "[DRY RUN] Skipping system setup (xcode/apt, homebrew, oh-my-zsh, nvim)"
        # Still write the homebrew config blocks in dry-run mode
        if is_macos; then
            if is_apple_silicon; then
                BREW_PATH="/opt/homebrew"
            else
                BREW_PATH="/usr/local"
            fi
            IFS='' read -r -d '' lines <<-"EOS" || true
				###############################################################
				# => Homebrew final configuration
				###############################################################
				# Need to ensure brew is at the top of the path to avoid using older version of binaries from the OS
				export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"
			EOS
            append_lines_to_file_if_not_there "${lines}" "${ZSHRC_CUSTOM_FILE}"

            IFS='' read -r -d '' lines <<-EOS || true
				###############################################################
				# => Homebrew configuration
				###############################################################
				# Initialize Homebrew environment
				# See: https://brew.sh/
				eval "\$(${BREW_PATH}/bin/brew shellenv)"
			EOS
        else
            IFS='' read -r -d '' lines <<-"EOS" || true
				###############################################################
				# => Homebrew configuration
				###############################################################
				# Initialize Homebrew environment
				# See: https://brew.sh/
				eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
			EOS
        fi
        append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"
    fi

    # Misc tools
    ask_for_confirmation "useful tools" "more info in the command if you accept" setup_useful_tools

    # Python
    ask_for_confirmation "pyenv-python" "https://github.com/pyenv/pyenv#installation" install_python

    # Go
    setup_go

    # Rust
    setup_rust

    # JS
    ask_for_confirmation "nvm" "https://github.com/nvm-sh/nvm/blob/master/README.md" install_nvm
    setup_node

    # Java
    ask_for_confirmation "sdk_man" "https://sdkman.io/install" install_sdk_man
    setup_java_openjdk

    # .NET
    setup_dotnet

    # Kubernetes
    ask_for_confirmation "kubernetes" "https://kubernetes.io/" install_kubernetes

    # GUI applications - skip in CI mode
    if [[ "${DOTFILES_CI:-false}" != "true" ]]; then
        # IDEs
        setup_ides

        # Slack
        ask_for_confirmation "Reinstall slack" "Will delete the current version and reinstall using brew" setup_slack

        # Obsidian
        ask_for_confirmation "Obsidian" "https://obsidian.md/" install_obsidian

        # Additional Applications
        ask_for_confirmation "Zoom" "https://zoom.us/" brew install --cask zoom
        ask_for_confirmation "Spotify" "https://www.spotify.com/" brew install --cask spotify
        ask_for_confirmation "Google Chrome" "https://www.google.com/chrome/" brew install --cask google-chrome

        # Nerd Fonts
        ask_for_confirmation "Nerd Fonts" "https://www.nerdfonts.com/" install_nerd_fonts

        # Terminal Emulator
        if is_macos; then
            ask_for_confirmation "iTerm2" "https://iterm2.com/" install_iterm2
            ask_for_confirmation "DisplayLink Manager" "https://www.synaptics.com/products/displaylink-graphics/downloads/macos" install_displaylink
        fi
    else
        print_info "CI mode: skipping GUI applications"
    fi

    # CLI tools with shell config
    setup_claude_code
    setup_devs_cli

    # shellcheck disable=SC2016
    echo -e "$(colorize "Done!" green) you will have to run: $(fmt_code 'source "${HOME}/.zshrc"')"
}

###############################################################
# => Custom file initialization
###############################################################

# init_custom_files - Initialize the custom dotfiles .z{shenv,shrc,profile}_custom.zsh with safeload pattern
# Usage: init_custom_files
# Returns: 0 on success, 1 on error
# Note: Creates z{shenv,shrc,profile}_custom.zsh with safeload pattern for utility functions
#       Uses here-document with tab indentation for proper heredoc formatting
init_custom_files() {
    # Note that indentation with tabs is needed here!
    # The EOS is a here-document that ends with the string EOS. Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		# SAFELOAD PATTERN
		# ----------------
		# Load utility functions using the safeload pattern
		# ${0%/*} is parameter expansion that removes the shortest match of "/*" from the end of $0
		# See: bash manual "Parameter Expansion" section
		source "${HOME}/.zutils.zsh" || { 
		    echo "Failed to load zutils.zsh" >&2
		    return 1
		}
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZPROFILE_CUSTOM_FILE}"
    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"
    append_lines_to_file_if_not_there "${lines}" "${ZSHRC_CUSTOM_FILE}"

    for file in "${ZPROFILE_CUSTOM_FILE}" "${ZSHENV_CUSTOM_FILE}" "${ZSHRC_CUSTOM_FILE}"; do
      # ${parameter%%word} is a parameter expansion that removes the trailing "word" from the parameter.
      local file_basename
      file_basename="${file%%.zsh}"
      IFS='' read -r -d '' lines <<-EOS || true
			print_debug "sourcing ${file_basename}"
		EOS
      append_lines_to_file_if_not_there "${lines}" "${file}"
    done
}

###############################################################
# => System setup
###############################################################

# setup_x_code - Install XCode command line tools
# Usage: setup_x_code
# Returns: 0 on success, 1 on error
# Note: Prompts user to install XCode command line tools via xcode-select
setup_x_code() {
    print_info "Installing XCode command line tools, you might need to install XCode itself from the app store."
    print_error "If a pop up appears, click 'Install' and then 'Agree', and wait for it to finish before proceeding."
    ask_for_confirmation "xcode" "https://developer.apple.com/xcode/" xcode-select --install
}

# setup_apt_get - Install apt-get dependencies
# Usage: setup_apt_get
# Returns: 0 on success, 1 on error
# Note: Installs essential Linux dependencies for development
setup_apt_get() {
    print_info "Installing Linux dependencies"
    
    # Update package list first
    ask_for_confirmation "Update package list" "Update apt package database" sudo apt-get update -y
    
    # Install essential development tools with URLs
    # shellcheck disable=SC2034
    local apt_packages=(
        "git|https://git-scm.com/"
        "curl|https://curl.se/"
        "wget|https://www.gnu.org/software/wget/"
        "build-essential|https://packages.ubuntu.com/search?suite=all&section=all&arch=amd64&keywords=build-essential"
        "procps|https://launchpad.net/ubuntu/+source/procps"
        "file|https://launchpad.net/ubuntu/+source/file"
        "zsh|https://www.zsh.org/"
        "unzip|https://packages.ubuntu.com/search?keywords=unzip"
    )
    
    install_packages_with_urls "apt_packages" "sudo apt-get install -y {name}"
}

# setup_homebrew - Install and configure Homebrew
# Usage: setup_homebrew
# Returns: 0 on success, 1 on error
# Note: Installs Homebrew, configures shell environment, and sets up automatic updates
setup_homebrew() {

    if is_macos; then
        # shellcheck disable=SC2016
        ask_for_confirmation "brew" "https://brew.sh/" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

        # Determine Homebrew path based on architecture
        # Apple Silicon: /opt/homebrew, Intel: /usr/local
        if is_apple_silicon; then
            BREW_PATH="/opt/homebrew"
        else
            BREW_PATH="/usr/local"
        fi

        # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
        IFS='' read -r -d '' lines <<-"EOS" || true
				###############################################################
				# => Homebrew final configuration
				###############################################################
				# Need to ensure brew is at the top of the path to avoid using older version of binaries from the OS
				export PATH="${HOMEBREW_PREFIX}/bin:${PATH}"
			EOS

        append_lines_to_file_if_not_there "${lines}" "${ZSHRC_CUSTOM_FILE}"

        # Note that indentation with tabs is needed here! Not using quotes to force interpolation.
        IFS='' read -r -d '' lines <<-EOS || true
				###############################################################
				# => Homebrew configuration
				###############################################################
				# Initialize Homebrew environment
				# See: https://brew.sh/
				eval "\$(${BREW_PATH}/bin/brew shellenv)"
			EOS
    else
        # See https://docs.brew.sh/Homebrew-on-Linux and https://docs.brew.sh/Installation#alternative-installs
        sudo mkdir -p /home/linuxbrew/.linuxbrew && sudo git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew
        sudo chown -R "${USER}" /home/linuxbrew/.linuxbrew
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        brew update --force --quiet
        chmod -R go-w "$(brew --prefix)/share/zsh"
    
        # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
        IFS='' read -r -d '' lines <<-"EOS" || true
				###############################################################
				# => Homebrew configuration
				###############################################################
				# Initialize Homebrew environment
				# See: https://brew.sh/
				eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
			EOS
    fi


    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"

    # Make brew available in the current shell for the rest of the install script
    if is_macos; then
        eval "$(${BREW_PATH}/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

###############################################################
# => ZSH and plugins setup
###############################################################

# setup_oh_my_zsh_and_plugins - Install Oh My Zsh and essential plugins
# Usage: setup_oh_my_zsh_and_plugins
# Returns: 0 on success, 1 on error
# Note: Installs Oh My Zsh and clones essential plugins for enhanced shell experience
setup_oh_my_zsh_and_plugins() {
    # shellcheck disable=SC2016
    ask_for_confirmation "oh-my-zsh" "https://github.com/ohmyzsh/ohmyzsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    ask_for_confirmation "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh" \
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

    ask_for_confirmation "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md" \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    ask_for_confirmation "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" \
        git clone https://github.com/zsh-users/zsh-history-substring-search "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"

    ask_for_confirmation "zsh nvm plugin" "https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nvm" \
        git clone https://github.com/ohmyzsh/ohmyzsh "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/nvm"
}

###############################################################
# => Editor setup
###############################################################

# setup_nvim - Install Neovim and custom configuration
# Usage: setup_nvim
# Returns: 0 on success, 1 on error
# Note: Installs Neovim via Homebrew and clones/updates custom configuration
setup_nvim() {
    ask_for_confirmation "nvim" "https://neovim.io/" brew install neovim

    if [[ ! -d "${HOME}/.config/nvim" ]]; then
        ask_for_confirmation "nvim-config" "https://github.com/julianmateu/nvim-config" \
            git clone "${NEOVIM_CONFIG_REPO}" "${HOME}/.config/nvim"
    else 
        ask_for_confirmation "update nvim-config" "https://github.com/julianmateu/nvim-config" \
            git -C "${HOME}/.config/nvim" pull
    fi
}

###############################################################
# => Development tools setup
###############################################################

# setup_useful_tools - Install essential development and system tools
# Usage: setup_useful_tools
# Returns: 0 on success, 1 on error
# Note: Installs a comprehensive set of tools for development, system administration, and productivity
setup_useful_tools() {
    # Install useful tools with URLs
    local brew_tools=(
        "wget|https://www.gnu.org/software/wget/"
        "ripgrep|https://formulae.brew.sh/formula/ripgrep"
        "gnu-sed|https://formulae.brew.sh/formula/gnu-sed"
        "coreutils|https://www.gnu.org/software/coreutils/"
        "jq|https://stedolan.github.io/jq/"
        "gnupg|https://gnupg.org/"
        "tree|https://formulae.brew.sh/formula/tree"
        "lazygit|https://github.com/jesseduffield/lazygit"
        "tmux|https://github.com/tmux/tmux"
        "fzf|https://github.com/junegunn/fzf"
        "bat|https://github.com/sharkdp/bat"
        "gh|https://cli.github.com/"
    )
    
    for tool_info in "${brew_tools[@]}"; do
        # Split tool_info into name and URL using parameter expansion
        # ${tool_info%%|*} removes the longest match of "|*" from the end (tool name)
        # ${tool_info#*|} removes the shortest match of "*|" from the beginning (URL)
        local tool_name="${tool_info%%|*}"
        local tool_url="${tool_info#*|}"

        ask_for_confirmation "${tool_name}" "${tool_url}" brew install "${tool_name}"
    done
}

###############################################################
# => Git and Python setup
###############################################################

# install_python - Install Python with pyenv and configure environment
# Usage: install_python
# Returns: 0 on success, 1 on error
# Note: Installs pyenv, Python dependencies, and configures brew wrapper for pyenv compatibility
install_python() {
    brew install pyenv
    brew install openssl readline sqlite3 xz zlib
    brew install openblas

    # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => Python configuration
		###############################################################
		# PyEnv configuration
		# See: https://github.com/pyenv/pyenv#installation
		export PYENV_ROOT="${HOME}/.pyenv"
		add_to_path_if_exists "${PYENV_ROOT}/bin"
		eval "$(pyenv init --path)"

		# pyenv adds *-config scripts and produces a brew warning
		# This wrapper temporarily switches to system Python to avoid conflicts
		function brew_wrapper() {
		    current_version="$(pyenv global)"
		    pyenv global system
		    echo -e "$(colorize "Warning: changed pyenv version from ${current_version} to system" red)"
		    brew "${@}"
		    echo -e "$(colorize "Warning: changed pyenv version from system to ${current_version}" red)"
		    pyenv global "${current_version}"
		    echo -e "$(colorize "Warning: running brew update will update go version, make sure to go back to the desired one and update the minor exact version in the zprofile file" red)"
		}
		alias brew="brew_wrapper"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"

    pyenv install "${PYTHON_VERSION}"
    pyenv global "${PYTHON_VERSION}"

    export PYENV_ROOT="${HOME}/.pyenv"
    add_to_path "${PYENV_ROOT}/bin"
    eval "$(pyenv init --path)"

    pip install --upgrade pip setuptools
}

###############################################################
# => Go and Rust setup
###############################################################

# setup_go - Install Go via Homebrew
# Usage: setup_go
# Returns: 0 on success, 1 on error
# Note: Installs Go and configures environment. Use 'brew pin go' to prevent auto-upgrades.
setup_go() {
    ask_for_confirmation "go" "https://go.dev/doc/install" \
        brew install go

    # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => Go configuration
		###############################################################
		# Go environment using Homebrew's opt/ symlinks (version-agnostic)
		# The opt/go symlink always points to the active Go installation
		# TIP: Use 'brew pin go' to prevent auto-upgrades when you need version stability
		add_to_path_if_exists "${HOMEBREW_PREFIX}/opt/go/bin"
		# GOPATH and GOBIN default to ~/go and ~/go/bin if not set
		add_to_path_if_exists "${HOME}/go/bin"
		export GOROOT="${HOMEBREW_PREFIX}/opt/go/libexec"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"
}

# setup_rust - Install Rust and configure Cargo environment
# Usage: setup_rust
# Returns: 0 on success, 1 on error
# Note: Installs Rust via rustup and configures Cargo environment
setup_rust() {
    ask_for_confirmation "rust" "https://www.rust-lang.org/" \
        sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)"

    # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => Rust configuration
		###############################################################
		# Cargo environment
		source_if_exists "${HOME}/.cargo/env"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"
}

###############################################################
# => Node.js setup
###############################################################

# install_nvm - Install Node Version Manager
# Usage: install_nvm
# Returns: 0 on success, 1 on error
# Note: Installs nvm and configures environment, skips if Oh My Zsh nvm plugin is installed
install_nvm() {
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash

    # Only add the nvm sourcing if the plugin is not installed
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/nvm" ]]; then
        # Note that indentation with tabs is needed here!
        IFS='' read -r -d '' lines <<-"EOS" || true
			###############################################################
			# => Node.js configuration
			###############################################################
			# NVM configuration
			# See: https://github.com/nvm-sh/nvm#installing-and-updating
			export NVM_DIR="${HOME}/.nvm"
			[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm
			[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
		EOS
        
        # Appending to the profile file, as this would be too slow on every shell
        append_lines_to_file_if_not_there "${lines}" "${ZPROFILE_CUSTOM_FILE}"
    fi

    export NVM_DIR="${HOME}/.nvm"
    [ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"  # This loads nvm
    [ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
}

# setup_node - Install Node.js LTS version
# Usage: setup_node
# Returns: 0 on success, 1 on error
# Note: Installs the latest LTS version of Node.js via nvm
setup_node() {
    ask_for_confirmation "Node LTS" "https://nodejs.org/en/download/package-manager/#nvm" \
        nvm install --lts
}

###############################################################
# => Java setup
###############################################################

# install_sdk_man - Install SDKMAN for JVM ecosystem management
# Usage: install_sdk_man
# Returns: 0 on success, 1 on error
# Note: Installs SDKMAN and configures environment for Java version management
install_sdk_man() {
    curl -s "https://get.sdkman.io" | bash

    # Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => SDKMAN configuration
		###############################################################
		# This must be at the end of the file for SDKMAN to work!!!
		export SDKMAN_DIR="${HOME}/.sdkman"
		[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"

    export SDKMAN_DIR="${HOME}/.sdkman"
    [[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"
}

# setup_java_openjdk - Install Java OpenJDK via SDKMAN
# Usage: setup_java_openjdk
# Returns: 0 on success, 1 on error
# Note: Installs Java OpenJDK using SDKMAN (may require manual execution in separate terminal)
setup_java_openjdk() {
    print_warning "sdk might not work inside a script so you might need to run the following command in a separate terminal..."
    # Using zsh to ensure that the sdk command is defined.
    ask_for_confirmation "java_20_openjdk" "https://sdkman.io/usage" \
        /bin/zsh -c "sdk install java ${SDK_JAVA_VERSION}"
}

###############################################################
# => .NET setup
###############################################################

# setup_dotnet - Install .NET SDK via Homebrew
# Usage: setup_dotnet
# Returns: 0 on success, 1 on error
# Note: Installs .NET SDK and configures environment variables
setup_dotnet() {
    ask_for_confirmation "dotnet" "https://dotnet.microsoft.com/" \
        brew install "dotnet@${DOTNET_VERSION}"

    # Note that indentation with tabs is needed here! Not using quotes to force interpolation.
    IFS='' read -r -d '' lines <<-EOS || true
		###############################################################
		# => .NET configuration
		###############################################################
		# .NET SDK configuration
		# See: https://learn.microsoft.com/en-us/dotnet/core/install/
		# dotnet is keg-only, so we need to add it to PATH manually
		DOTNET_VERSION='${DOTNET_VERSION}'
		export DOTNET_ROOT="\${HOMEBREW_PREFIX}/opt/dotnet@\${DOTNET_VERSION}/libexec"
		add_to_path_if_exists "\${HOMEBREW_PREFIX}/opt/dotnet@\${DOTNET_VERSION}/bin"
		add_to_path_if_exists "${HOME}/.dotnet/tools"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"
}

###############################################################
# => Kubernetes setup
###############################################################

# install_kubernetes - Install Kubernetes development tools
# Usage: install_kubernetes
# Returns: 0 on success, 1 on error
# Note: Installs Docker, kubectl, k9s, and helm. Minikube can be added separately if needed.
install_kubernetes() {
    print_warning "$(cat <<-EOS
		Before installing Kubernetes, it is advised to first install docker desktop: $(fmt_underline https://docs.docker.com/desktop/mac/install/)
		However, it is possible to use hyperkit $(fmt_underline https://minikube.sigs.k8s.io/docs/drivers/hyperkit/)
	EOS
    )"
    ask_for_confirmation "docker" "https://docs.docker.com/desktop" \
        install_docker
    ask_for_confirmation "kubectl" "https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos" \
        brew install kubectl
    ask_for_confirmation "k9s" "https://k9scli.io/" \
        brew install k9s
    ask_for_confirmation "helm" "https://helm.sh/" \
        brew install helm
    print_warning "You will need to have installed docker desktop, and change the memory to at least 4.1GB. Then run: $(fmt_code minikube start --cpus 4 --memory 4096)"
}

# install_docker - Install Docker Desktop
# Usage: install_docker
# Returns: 0 on success, 1 on error
# Note: Downloads and installs Docker Desktop for macOS and Linux based on system architecture
install_docker() {
    print_info "Installing Docker"

    if is_macos; then
        print_info "Installing Docker Desktop for macOS"
        local docker_dmg="Docker.dmg"
        
        if is_intel; then
            curl -L "https://desktop.docker.com/mac/main/amd64/Docker.dmg" -o "${docker_dmg}"
        elif is_apple_silicon; then
            curl -L "https://desktop.docker.com/mac/main/arm64/Docker.dmg" -o "${docker_dmg}"
        else
            print_error "Unknown architecture $(get_architecture). Please install Docker manually."
            return 1
        fi
        
        # Install Docker Desktop
        sudo hdiutil attach "./${docker_dmg}"
        sudo cp -R "/Volumes/Docker/Docker.app" "/Applications"
        sudo hdiutil unmount "/Volumes/Docker"
        rm -rf "./${docker_dmg}"
        
        print_success "Docker Desktop installed successfully"
        
    else
        print_info "Installing Docker Engine for Linux"

        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y "${pkg}"; done

        # Add Docker's official GPG key:
        sudo apt-get update -y
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -y

        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        sudo usermod -aG docker "${USER}"

        print_info "Docker Engine installed successfully"
    fi
}

###############################################################
# => Additional tools setup
###############################################################

# setup_ides - Install development IDEs
# Usage: setup_ides
# Returns: 0 on success, 1 on error
# Note: Installs popular development IDEs via Homebrew Cask
setup_ides() {
    ask_for_confirmation "Visual Studio Code" "https://code.visualstudio.com/" \
        install_vscode
}

# install_vscode - Install Visual Studio Code
# Usage: install_vscode
# Returns: 0 on success, 1 on error
# Note: Installs Visual Studio Code via direct download for macOS and Linux
install_vscode() {
    print_info "Installing Visual Studio Code"
    
    if is_macos; then
        local vscode_zip="vscode.zip"
        local vscode_app="/Applications/Visual Studio Code.app"
        
        # Download VS Code for macOS
        curl -L "https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal" -o "${vscode_zip}"
        
        # Remove existing installation if present
        if [[ -d "${vscode_app}" ]]; then
            print_warning "Removing existing VS Code installation"
            sudo rm -rf "${vscode_app}"
        fi
        
        # Install VS Code
        sudo unzip -q "${vscode_zip}" -d "/Applications/"
        rm -rf "${vscode_zip}"
    
    else
        # See https://code.visualstudio.com/docs/setup/linux
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f packages.microsoft.gpg

        sudo apt install -y apt-transport-https
        sudo apt update
        sudo apt install -y code # or code-insiders
       
    fi
    print_success "Visual Studio Code installed successfully"
}

# setup_slack - Reinstall Slack via Homebrew
# Usage: setup_slack
# Returns: 0 on success, 1 on error
# Note: Removes existing Slack installation and reinstalls via Homebrew for updates
setup_slack() {
    ask_for_confirmation "slack" "https://www.slack.com" \
        brew install --cask slack
}

# install_obsidian - Install Obsidian
# Usage: install_obsidian
# Returns: 0 on success, 1 on error
# Note: Installs Obsidian via direct download for macOS and Linux
install_obsidian() {
    print_info "Installing Obsidian"
    
    if is_macos; then
        local obsidian_dmg="obsidian.dmg"
        local obsidian_app="/Applications/Obsidian.app"
        
        # Download Obsidian for macOS
        curl -L "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}.dmg" -o "${obsidian_dmg}"
        
        # Remove existing installation if present
        if [[ -d "${obsidian_app}" ]]; then
            print_warning "Removing existing Obsidian installation"
            sudo rm -rf "${obsidian_app}"
        fi
        
        # Install Obsidian
        sudo hdiutil attach "./${obsidian_dmg}"
        sudo cp -R "/Volumes/Obsidian ${OBSIDIAN_VERSION}-universal/Obsidian.app" "/Applications"
        sudo hdiutil unmount "/Volumes/Obsidian ${OBSIDIAN_VERSION}-universal"
        rm -rf "./${obsidian_dmg}"
        
        print_success "Obsidian installed successfully"
        
    else
        local architecture
        architecture="$(get_architecture)"
        local obsidian_deb="obsidian.deb"
        
        # Download Obsidian for Linux
        curl -L "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}-${architecture}.deb" -o "${obsidian_deb}"
        
        # Install Obsidian
        sudo dpkg -i "${obsidian_deb}"
        sudo apt-get install -f -y  # Fix any dependency issues
        rm -rf "${obsidian_deb}"
        
        print_success "Obsidian installed successfully"
    fi
}

# install_nerd_fonts - Install Nerd Fonts
# Usage: install_nerd_fonts
# Returns: 0 on success, 1 on error
# Note: Installs Nerd Fonts via Homebrew Cask on macOS or direct download on Linux
install_nerd_fonts() {
    local font="0xProto"
    local version="3.4.0"

    print_info "Installing Nerd Fonts"

    # Install via direct download on Linux
    local font_dir="${HOME}/.local/share/fonts"
    local font_zip="${font}.zip"
    
    # Create font directory if it doesn't exist
    mkdir -p "${font_dir}"
    
    # Download and install font
    curl -L "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${font}.zip" -o "${font_zip}"
    unzip -q "${font_zip}" -d "${font_dir}"
    
    if is_macos; then
        open -b com.apple.FontBook "${font_dir}"/*.*tf
    else
        # Update font cache
        fc-cache -fv
    fi
    
    # Clean up
    rm -rf "${font_zip}"
    
    print_success "Nerd Fonts installed successfully"
    print_info "Font cache updated. You may need to restart your terminal or applications to see the new fonts."
}

# install_iterm2 - Install iTerm2
# Usage: install_iterm2
# Returns: 0 on success, 1 on error
# Note: Installs iTerm2 via direct download for macOS and Linux
install_iterm2() {
    print_info "Installing iTerm2"
    ask_for_confirmation "iTerm2" "https://iterm2.com/" brew install --cask iterm2
    ask_for_confirmation "iTerm2 shell integration" "https://iterm2.com/shell_integration.html" curl -L https://iterm2.com/shell_integration/zsh -o "${HOME}/.iterm2_shell_integration.zsh"

    if [[ -f "${HOME}/.iterm2_shell_integration.zsh" ]]; then
        print_info "Sourcing the iTerm2 shell integration"
        # Note that indentation with tabs is needed here!
        IFS='' read -r -d '' lines <<-"EOS" || true
			###############################################################
			# => iTerm2 configuration
			###############################################################
			source_if_exists "${HOME}/.iterm2_shell_integration.zsh"
		EOS
        append_lines_to_file_if_not_there "${lines}" "${ZPROFILE_CUSTOM_FILE}"
    fi

    ask_for_confirmation "iTerm2 profile" "" cp "${0%/*}/iterm2/iterm2_profile.json" "${HOME}/Library/Application Support/iTerm2/DynamicProfiles/iterm2_profile.json"

    print_info "You will need to make the profile the default in the preferences."
}

install_displaylink() {
  print_info "Installing DisplayLink Manager..."
  local displaylink_file="./display-link.zip"
  curl -L -o "${displaylink_file}" "https://www.synaptics.com/sites/default/files/exe_files/${DISPLAYLINK_DATE}/DisplayLink%20Manager%20Graphics%20Connectivity${DISPLAYLINK_VERSION}-EXE.zip"

  unzip "${displaylink_file}"
  local display_link_pkg
  display_link_pkg="$(ls DisplayLinkManager-*.pkg)"

  sudo installer -verbose -pkg "${display_link_pkg}" -target /

  rm -rf "${display_link_pkg}"
  rm -rf "${displaylink_file}"

  print_success "DisplayLink Manager successfully installed"
}

###############################################################
# => CLI tools with shell configuration
###############################################################

# setup_claude_code - Install and configure Claude Code CLI
# Usage: setup_claude_code
# Returns: 0 on success, 1 on error
# Note: Installs via Homebrew cask (macOS) or curl installer (Linux), adds ~/.local/bin to PATH
setup_claude_code() {
    if is_macos; then
        ask_for_confirmation "Claude Code CLI" "https://docs.anthropic.com/en/docs/claude-code" \
            brew install --cask claude-code
    else
        # shellcheck disable=SC2016
        ask_for_confirmation "Claude Code CLI" "https://docs.anthropic.com/en/docs/claude-code" \
            bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
    fi

    # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => Claude Code configuration
		###############################################################
		# Claude Code CLI
		# See: https://docs.anthropic.com/en/docs/claude-code
		add_to_path_if_exists "${HOME}/.local/bin"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"
}

# setup_devs_cli - Configure Devs CLI completions
# Usage: setup_devs_cli
# Returns: 0 on success, 1 on error
# Note: Adds Devs CLI dynamic completions to zshrc_custom
setup_devs_cli() {
    ask_for_confirmation "Devs CLI completions" "Devs CLI dynamic zsh completions" \
        true  # No install command - just configure completions

    # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => Devs CLI dynamic completions
		###############################################################
		source <(COMPLETE=zsh devs)
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHRC_CUSTOM_FILE}"
}

# Script execution guard
# ${BASH_SOURCE[0]} is the path to the current script
# ${0} is the name of the script as it was called
# This check ensures the script only runs when executed directly, not when sourced
# See: bash manual "Special Parameters" section
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
