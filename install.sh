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
PROFILE_FILE='./zprofile_custom.zsh'

PYTHON_VERSION='3.13.1'
SDK_JAVA_VERSION='20-open'
NVM_VERSION='0.40.3'
GOVERSION='1.24'
GOVERSION_EXACT='1.24.2'
OBSIDIAN_VERSION='1.8.10'
ZOOM_VERSION='5.17.0.1341'
SPOTIFY_VERSION='8.8.0.718'

NEOVIM_CONFIG_REPO='https://github.com/julianmateu/nvim-config.git'

###############################################################
# => Main function
###############################################################

# main - Main entry point for the installation script
# Usage: main [arguments...]
# Parameters: Command line arguments passed to the script
# Returns: 0 on success, 1 on error
# Note: Orchestrates the entire installation process for development tools
main() {
    init_profile_file

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

    # Misc tools
    ask_for_confirmation "useful tools" "more info in the command if you accept" setup_useful_tools

    # GIT & Python
    ask_for_confirmation "hub" "https://hub.github.com/" install_hub
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

    # Kubernetes
    ask_for_confirmation "kubernetes" "https://kubernetes.io/" install_kubernetes

    # IDEs
    setup_ides

    # Slack
    ask_for_confirmation "Reinstall slack" "Will delete the current version and reinstall using brew" setup_slack

    # Obsidian
    ask_for_confirmation "Obsidian" "https://obsidian.md/" install_obsidian

    # Additional Applications
    ask_for_confirmation "Zoom" "https://zoom.us/" install_zoom
    ask_for_confirmation "Spotify" "https://www.spotify.com/" install_spotify

    # Nerd Fonts
    ask_for_confirmation "Nerd Fonts" "https://www.nerdfonts.com/" install_nerd_fonts

    # Terminal Emulator
    if is_macos; then
        ask_for_confirmation "iTerm2" "https://iterm2.com/" install_iterm2
    fi

    # shellcheck disable=SC2016
    echo -e "$(colorize "Done!" green) you will have to run: $(fmt_code 'source "${HOME}/.zshrc"')"
}

###############################################################
# => Profile file initialization
###############################################################

# init_profile_file - Initialize the profile file with safeload pattern
# Usage: init_profile_file
# Returns: 0 on success, 1 on error
# Note: Creates zprofile_custom.zsh with safeload pattern for utility functions
#       Uses here-document with tab indentation for proper heredoc formatting
init_profile_file() {
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

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
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
    # shellcheck disable=SC2016
    ask_for_confirmation "brew" "https://brew.sh/" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    # Note that indentation with tabs is needed here! Using quotes to avoid interpolation.
    IFS='' read -r -d '' lines <<-"EOS" || true
		###############################################################
		# => Homebrew configuration
		###############################################################
		# Initialize Homebrew environment
		# See: https://brew.sh/
		eval "$(/opt/homebrew/bin/brew shellenv)"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"

    eval "$(/opt/homebrew/bin/brew shellenv)"
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
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    ask_for_confirmation "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" \
        git clone https://github.com/zsh-users/zsh-history-substring-search "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search"

    ask_for_confirmation "zsh nvm plugin" "https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nvm" \
        git clone https://github.com/ohmyzsh/ohmyzsh.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/nvm"
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
    )
    
    for tool_info in "${brew_tools[@]}"; do
        # Split tool_info into name and URL using parameter expansion
        # ${tool_info%%|*} removes the longest match of "|*" from the end (tool name)
        # ${tool_info#*|} removes the shortest match of "*|" from the beginning (URL)
        local tool_name="${tool_info%%|*}"
        local tool_url="${tool_info#*|}"
        
        # Handle special cases where package name differs from tool name
        local package_name="${tool_name}"
        case "${tool_name}" in
            "ripgrep") package_name="rg" ;;
            "gnu-sed") package_name="gsed" ;;
            "gnupg") package_name="gpg" ;;
        esac
        
        ask_for_confirmation "${tool_name}" "${tool_url}" brew install "${package_name}"
    done
}

###############################################################
# => Git and Python setup
###############################################################

# install_hub - Install GitHub CLI hub and configure aliases
# Usage: install_hub
# Returns: 0 on success, 1 on error
# Note: Installs hub and configures git aliases for GitHub integration
install_hub() {
    brew install hub

    # Note that indentation with tabs is needed here!
    IFS='' read -r -d '' lines <<-"EOS" || true
		# hub
		eval "$(hub alias -s)"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
}

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
		add_to_path "${PYENV_ROOT}/bin"
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

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"

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

# setup_go - Install Go with version management
# Usage: setup_go
# Returns: 0 on success, 1 on error
# Note: Installs specific Go version for Monzo compatibility and configures environment
setup_go() {
    ask_for_confirmation "go" "https://go.dev/doc/install" \
        brew install "go@${GOVERSION}"

    # Note that indentation with tabs is needed here! Not using quotes to force interpolation.
    IFS='' read -r -d '' lines <<-EOS || true
		###############################################################
		# => Go configuration
		###############################################################
		# Go version management
		# Monzo requires go 1.22, but brew will install the latest, so I need to manually add the old version to the path
		GOVERSION='${GOVERSION}'
		GOVERSION_EXACT='${GOVERSION_EXACT}'
		add_to_path "/opt/homebrew/opt/go@\${GOVERSION}/bin"
		export GOROOT="/opt/homebrew/Cellar/go/\${GOVERSION_EXACT}/libexec"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
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
		source "${HOME}/.cargo/env"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
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

        append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
    fi
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

    append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
}

# setup_java_openjdk - Install Java OpenJDK via SDKMAN
# Usage: setup_java_openjdk
# Returns: 0 on success, 1 on error
# Note: Installs Java OpenJDK using SDKMAN (may require manual execution in separate terminal)
setup_java_openjdk() {
    print_warning "sdk might not work inside a script so you might need to run the following command in a separate terminal..."
    ask_for_confirmation "java_20_openjdk" "https://sdkman.io/usage" \
        sdk install java "${SDK_JAVA_VERSION}"
}

###############################################################
# => Kubernetes setup
###############################################################

# install_kubernetes - Install Kubernetes development tools
# Usage: install_kubernetes
# Returns: 0 on success, 1 on error
# Note: Installs comprehensive set of Kubernetes tools including kubectl, minikube, helm, etc.
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
    print_info "Installing Docker Desktop"

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
        print_info "Installing Docker Desktop for Linux"
        local architecture
        architecture="$(get_architecture)"
        local docker_deb="docker-desktop-${architecture}.deb"
        
        # Download Docker Desktop for Linux
        curl -L "https://desktop.docker.com/linux/main/${architecture}/docker-desktop-${architecture}.deb" -o "${docker_deb}"
        
        # Install dependencies
        sudo apt-get update
        sudo apt-get install -y "./${docker_deb}"
        
        # Clean up
        rm -rf "${docker_deb}"
        
        print_success "Docker Desktop installed successfully"
        print_warning "You may need to log out and back in for Docker Desktop to work properly"
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
        
        print_success "Visual Studio Code installed successfully"
        
    else
        local architecture
        architecture="$(get_architecture)"
        local vscode_deb="vscode.deb"
        
        # Download VS Code for Linux
        curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-${architecture}" -o "${vscode_deb}"
        
        # Install VS Code
        sudo dpkg -i "${vscode_deb}"
        sudo apt-get install -f -y  # Fix any dependency issues
        rm -rf "${vscode_deb}"
        
        print_success "Visual Studio Code installed successfully"
    fi
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
        sudo cp -R "/Volumes/Obsidian\ ${OBSIDIAN_VERSION}-universal/Obsidian.app" "/Applications"
        sudo hdiutil unmount "/Volumes/Obsidian\ ${OBSIDIAN_VERSION}-universal"
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

# install_zoom - Install Zoom
# Usage: install_zoom
# Returns: 0 on success, 1 on error
# Note: Installs Zoom via Homebrew Cask
install_zoom() {
    print_info "Installing Zoom"
    brew install --cask zoom
    print_success "Zoom installed successfully"
}

# install_spotify - Install Spotify
# Usage: install_spotify
# Returns: 0 on success, 1 on error
# Note: Installs Spotify via Homebrew Cask
install_spotify() {
    print_info "Installing Spotify"
    brew install --cask spotify
    print_success "Spotify installed successfully"
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
        open -b com.apple.FontBook "${font_dir}/*.*tf"
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
        append_lines_to_file_if_not_there "${lines}" "${PROFILE_FILE}"
    fi

    ask_for_confirmation "iTerm2 profile" "" cp "${0%/*}/iterm2/iterm2_profile.json" "${HOME}/Library/Application Support/iTerm2/DynamicProfiles/iterm2_profile.json"

    print_info "You will need to make the profile the default in the preferences."
}

# Script execution guard
# ${BASH_SOURCE[0]} is the path to the current script
# ${0} is the name of the script as it was called
# This check ensures the script only runs when executed directly, not when sourced
# See: bash manual "Special Parameters" section
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
