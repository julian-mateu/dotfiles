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

# DOTFILES_DIR: script directory, used for resolving relative paths (e.g., dotfiles.conf)
DOTFILES_DIR="${0%/*}"

# shellcheck disable=SC1091
source "${0%/*}/lib/config.sh" || { echo "Failed to load lib/config.sh" >&2; exit 1; }
# shellcheck disable=SC1091
source "${0%/*}/lib/profiles.sh" || { echo "Failed to load lib/profiles.sh" >&2; exit 1; }
# shellcheck disable=SC1091
source "${0%/*}/lib/registry.sh" || { echo "Failed to load lib/registry.sh" >&2; exit 1; }

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
# => Composite functions for config-driven mode
###############################################################

# setup_node_full - Install NVM + Node.js LTS (combined for registry)
setup_node_full() {
    setup_nvm
    install_node
}

# setup_java_full - Install SDKMAN + Java OpenJDK (combined for registry)
setup_java_full() {
    setup_sdkman
    install_java_openjdk
}

# install_kubernetes_tools - Install kubectl, k9s, helm (Docker handled separately by registry)
install_kubernetes_tools() {
    brew install kubectl
    brew install k9s
    brew install helm
    if [[ "${DOTFILES_CI:-false}" != "true" ]]; then
        print_warning "You will need to have installed docker desktop, and change the memory to at least 4.1GB. Then run: $(fmt_code minikube start --cpus 4 --memory 4096)"
    fi
}

# Simple wrapper functions for GUI apps registered in the registry
install_zoom() {
    if is_macos; then
        brew install --cask zoom
    elif [[ "$(get_architecture)" == "aarch64" ]]; then
        print_warning "Zoom is not available for Linux arm64 (no snap/flatpak). Skipping."
        return 0
    else
        sudo snap install zoom-client
    fi
}
install_spotify() {
    if is_macos; then
        brew install --cask spotify
    elif [[ "$(get_architecture)" == "aarch64" ]]; then
        print_warning "Spotify is not available for Linux arm64 (no snap/flatpak). Skipping."
        return 0
    else
        sudo snap install spotify
    fi
}
install_chrome() {
    if is_macos; then
        brew install --cask google-chrome
    else
        sudo snap install chromium
    fi
}

###############################################################
# => Tool registry setup
###############################################################

# register_all_tools - Register all tools with the registry for config-driven mode
register_all_tools() {
    # Columns: key          function                      description        url                              deps       platform gui
    # System setup
    register_tool "homebrew"      setup_homebrew                "Homebrew"         "https://brew.sh/"               ""         "all"
    register_tool "oh_my_zsh"     install_oh_my_zsh_and_plugins   "Oh My Zsh"        "https://ohmyzsh.dev/"           "homebrew" "all"
    register_tool "nvim"          install_nvim                    "Neovim"           "https://neovim.io/"             "homebrew" "all"

    # Dev tools
    register_tool "useful_tools"  install_useful_tools            "Useful Tools"     ""                               "homebrew" "all"

    # Languages
    register_tool "python"        setup_python                "Python (pyenv)"   "https://github.com/pyenv"       "homebrew" "all"
    register_tool "go"            setup_go                      "Go"               "https://go.dev/"                "homebrew" "all"
    register_tool "rust"          setup_rust                    "Rust"             "https://rust-lang.org/"         ""         "all"
    register_tool "node"          setup_node_full               "Node.js (NVM)"    "https://nodejs.org/"            ""         "all"
    register_tool "java"          setup_java_full               "Java (SDKMAN)"    "https://sdkman.io/"             ""         "all"
    register_tool "dotnet"        setup_dotnet                  ".NET"             "https://dotnet.microsoft.com/"  "homebrew" "all"

    # Containers
    register_tool "docker"        install_docker                "Docker"           "https://docker.com/"            ""         "all"    "true"
    register_tool "kubernetes"    install_kubernetes_tools       "Kubernetes"       "https://kubernetes.io/"         "homebrew" "all"

    # GUI applications (gui=true: skipped in CI by run_registry)
    register_tool "vscode"        install_vscode                "VS Code"          "https://code.visualstudio.com/" ""         "all"    "true"
    register_tool "slack"         install_slack                   "Slack"            "https://www.slack.com"          ""         "all"    "true"
    register_tool "obsidian"      install_obsidian              "Obsidian"         "https://obsidian.md/"           ""         "all"    "true"
    register_tool "zoom"          install_zoom                  "Zoom"             "https://zoom.us/"               ""         "all"    "true"
    register_tool "spotify"       install_spotify               "Spotify"          "https://www.spotify.com/"       ""         "all"    "true"
    register_tool "chrome"        install_chrome                "Google Chrome"    "https://www.google.com/chrome/" ""         "all"    "true"
    register_tool "nerd_fonts"    install_nerd_fonts            "Nerd Fonts"       "https://www.nerdfonts.com/"     ""         "all"    "true"
    register_tool "iterm2"        setup_iterm2                "iTerm2"           "https://iterm2.com/"            ""         "macos"  "true"
    register_tool "displaylink"   install_displaylink           "DisplayLink"      "https://www.synaptics.com/"     ""         "macos"  "true"

    # CLI tools with shell config
    register_tool "claude_code"   setup_claude_code             "Claude Code"      "https://docs.anthropic.com/"              ""         "all"
    register_tool "devs_cli"      setup_devs_cli                "Devs CLI"         "https://github.com/julianmateu/devs-cli"  "homebrew" "all"
}

###############################################################
# => Main function
###############################################################

# install_system_dependencies - Install OS-level dependencies before any tools
# Usage: install_system_dependencies
# Returns: 0 on success, 1 on error
# Note: Installs XCode CLI tools on macOS or apt packages on Linux
install_system_dependencies() {
    if is_macos; then
        print_info "Installing macOS dependencies"
        install_xcode
    else
        print_info "Installing Linux dependencies"
        setup_apt_get
    fi
}

# main - Main entry point for the installation script
# Usage: main [--dry-run] [--config <file>] [--profile <name>]
# Parameters: Command line arguments passed to the script
# Returns: 0 on success, 1 on error
# Note: Supports three modes:
#   1. Config-driven: ./install.sh --config dotfiles.conf (or --profile minimal|developer|backend|full)
#   2. Auto-config: ./install.sh (with dotfiles.conf in repo root)
#   3. Interactive: ./install.sh (no config, current behavior preserved)
#   All modes support --dry-run to preview without installing
main() {
    parse_arguments "$@"
    init_custom_files

    if load_configuration; then
        # Config-driven mode: auto-accept all prompts since config specifies what to install
        DOTFILES_NON_INTERACTIVE="true"

        # System dependencies (required before registry tools)
        if [[ "${DOTFILES_DRY_RUN}" != "true" ]]; then
            install_system_dependencies
        fi

        register_all_tools
        run_registry
    elif [[ -n "${CONFIG_FILE:-}" ]] || [[ -n "${PROFILE:-}" ]]; then
        # User explicitly requested config/profile but loading failed - exit with error
        print_error "Failed to load configuration. Check the error above."
        return 1
    else
        # No config found - fall back to interactive mode (backwards compatible)
        run_interactive
    fi

    # shellcheck disable=SC2016
    echo -e "$(colorize "Done!" green) you will have to run: $(fmt_code 'source "${HOME}/.zshrc"')"
}

# run_interactive - Original interactive installation flow
# Usage: run_interactive (called by main when no config is found)
# Note: Preserves the original behavior where each tool prompts for confirmation
run_interactive() {
    if [[ "${DOTFILES_DRY_RUN}" != "true" ]]; then
        # System setup - these run commands directly (not via ask_for_confirmation),
        # so they need an explicit dry-run guard
        install_system_dependencies

        setup_homebrew

        # ZSH
        install_oh_my_zsh_and_plugins

        # Nvim
        install_nvim
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
    ask_for_confirmation "useful tools" "more info in the command if you accept" install_useful_tools

    # Python
    ask_for_confirmation "pyenv-python" "https://github.com/pyenv/pyenv#installation" setup_python

    # Go
    setup_go

    # Rust
    setup_rust

    # JS
    ask_for_confirmation "nvm" "https://github.com/nvm-sh/nvm/blob/master/README.md" setup_nvm
    install_node

    # Java
    ask_for_confirmation "sdkman" "https://sdkman.io/install" setup_sdkman
    install_java_openjdk

    # .NET
    setup_dotnet

    # Docker
    ask_for_confirmation "Docker" "https://docker.com/" install_docker

    # Kubernetes tools (kubectl, k9s, helm)
    ask_for_confirmation "Kubernetes tools" "https://kubernetes.io/" install_kubernetes_tools

    # GUI applications - skip in CI mode
    if [[ "${DOTFILES_CI:-false}" != "true" ]]; then
        # VS Code
        ask_for_confirmation "Visual Studio Code" "https://code.visualstudio.com/" install_vscode

        # Slack
        ask_for_confirmation "Reinstall slack" "Will delete the current version and reinstall using brew" install_slack

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
            ask_for_confirmation "iTerm2" "https://iterm2.com/" setup_iterm2
            ask_for_confirmation "DisplayLink Manager" "https://www.synaptics.com/products/displaylink-graphics/downloads/macos" install_displaylink
        fi
    else
        print_info "CI mode: skipping GUI applications"
    fi

    # CLI tools with shell config
    setup_claude_code
    setup_devs_cli
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
      # basename strips directory prefix and .zsh suffix → "zprofile_custom"
      local file_basename
      file_basename="$(basename "${file}" .zsh)"
      IFS='' read -r -d '' lines <<-EOS || true
			print_debug "sourcing ${file_basename}"
		EOS
      append_lines_to_file_if_not_there "${lines}" "${file}"
    done
}

###############################################################
# => System setup
###############################################################

# install_xcode - Install XCode command line tools
# Usage: install_xcode
# Returns: 0 on success, 1 on error
# Note: Prompts user to install XCode command line tools via xcode-select
install_xcode() {
    # Check if Xcode CLI tools are already installed (xcode-select -p returns 0 if installed)
    if xcode-select -p &>/dev/null; then
        print_success "XCode command line tools already installed"
        return 0
    fi
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
        "zip|https://packages.ubuntu.com/search?keywords=zip"
        "snapd|https://snapcraft.io/docs/installing-snapd"
    )
    
    install_packages_with_urls "apt_packages" "sudo apt-get install -y {name}"
}

# setup_homebrew - Install and configure Homebrew
# Usage: setup_homebrew
# Returns: 0 on success, 1 on error
# Note: Installs Homebrew, configures shell environment, and sets up automatic updates
setup_homebrew() {

    if is_macos; then
        if command -v brew &>/dev/null; then
            print_success "Homebrew already installed"
        else
            # shellcheck disable=SC2016
            ask_for_confirmation "brew" "https://brew.sh/" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
        fi

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
        if [[ ! -d /home/linuxbrew/.linuxbrew/bin ]]; then
            sudo mkdir -p /home/linuxbrew/.linuxbrew && sudo git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew
            sudo chown -R "${USER}" /home/linuxbrew/.linuxbrew
        else
            print_success "Homebrew already installed on Linux"
        fi
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

# install_oh_my_zsh_and_plugins - Install Oh My Zsh and essential plugins
# Usage: install_oh_my_zsh_and_plugins
# Returns: 0 on success, 1 on error
# Note: Installs Oh My Zsh and clones essential plugins for enhanced shell experience
install_oh_my_zsh_and_plugins() {
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        print_success "Oh My Zsh already installed"
    else
        # shellcheck disable=SC2016
        ask_for_confirmation "oh-my-zsh" "https://github.com/ohmyzsh/ohmyzsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    if [[ -d "${plugin_dir}/zsh-autosuggestions" ]]; then
        print_success "zsh-autosuggestions already installed"
    else
        ask_for_confirmation "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh" \
            git clone https://github.com/zsh-users/zsh-autosuggestions "${plugin_dir}/zsh-autosuggestions"
    fi

    if [[ -d "${plugin_dir}/zsh-syntax-highlighting" ]]; then
        print_success "zsh-syntax-highlighting already installed"
    else
        ask_for_confirmation "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md" \
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "${plugin_dir}/zsh-syntax-highlighting"
    fi

    if [[ -d "${plugin_dir}/zsh-history-substring-search" ]]; then
        print_success "zsh-history-substring-search already installed"
    else
        ask_for_confirmation "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" \
            git clone https://github.com/zsh-users/zsh-history-substring-search "${plugin_dir}/zsh-history-substring-search"
    fi

    if [[ -d "${plugin_dir}/nvm" ]]; then
        print_success "zsh nvm plugin already installed"
    else
        ask_for_confirmation "zsh nvm plugin" "https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nvm" \
            git clone https://github.com/ohmyzsh/ohmyzsh "${plugin_dir}/nvm"
    fi
}

###############################################################
# => Editor setup
###############################################################

# install_nvim - Install Neovim and custom configuration
# Usage: install_nvim
# Returns: 0 on success, 1 on error
# Note: Installs Neovim via Homebrew and clones/updates custom configuration
install_nvim() {
    if command -v nvim &>/dev/null; then
        print_success "Neovim already installed"
    else
        ask_for_confirmation "nvim" "https://neovim.io/" brew install neovim
    fi

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

# install_useful_tools - Install essential development and system tools
# Usage: install_useful_tools
# Returns: 0 on success, 1 on error
# Note: Installs a comprehensive set of tools for development, system administration, and productivity
install_useful_tools() {
    # Install useful tools with URLs
    local brew_tools=(
        "wget|https://www.gnu.org/software/wget/"
        "ripgrep|https://formulae.brew.sh/formula/ripgrep"
        "jq|https://stedolan.github.io/jq/"
        "gnupg|https://gnupg.org/"
        "tree|https://formulae.brew.sh/formula/tree"
        "lazygit|https://github.com/jesseduffield/lazygit"
        "tmux|https://github.com/tmux/tmux"
        "fzf|https://github.com/junegunn/fzf"
        "bat|https://github.com/sharkdp/bat"
        "gh|https://cli.github.com/"
    )

    # gnu-sed and coreutils: install via Homebrew on macOS only.
    # On Linux these are already available natively (sed, coreutils package).
    # Compiling them from source via Linuxbrew can take 20+ minutes.
    if is_macos; then
        brew_tools+=(
            "gnu-sed|https://formulae.brew.sh/formula/gnu-sed"
            "coreutils|https://www.gnu.org/software/coreutils/"
        )
    fi
    
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

# setup_python - Install Python with pyenv and configure environment
# Usage: setup_python
# Returns: 0 on success, 1 on error
# Note: Installs pyenv, Python dependencies, and configures brew wrapper for pyenv compatibility
setup_python() {
    if command -v pyenv &>/dev/null; then
        print_success "pyenv already installed"
    else
        if is_macos; then
            brew install pyenv
            brew install openssl readline sqlite3 xz zlib
            brew install openblas
        else
            # On Linux, install pyenv via official installer (not brew) so it
            # links against system libraries instead of Homebrew's
            sudo apt-get install -y libssl-dev libreadline-dev libsqlite3-dev \
                libbz2-dev libffi-dev liblzma-dev zlib1g-dev tk-dev \
                libncursesw5-dev libxml2-dev libxmlsec1-dev
            curl https://pyenv.run | bash
        fi
    fi

    # Migration: remove old buggy brew_wrapper that used 'brew "${@}"' (infinite recursion).
    # The old block won't match the new one (exact match), so append_lines_to_file_if_not_there
    # would add the fixed version alongside the broken one. Remove the old block first.
    # We detect the old version by checking for 'brew "${@}"' without 'command' prefix.
    if [[ -f "${ZSHENV_CUSTOM_FILE}" ]] && grep -q '^\s*brew "\${@}"' "${ZSHENV_CUSTOM_FILE}" 2>/dev/null; then
        print_warning "Migrating old brew_wrapper in ${ZSHENV_CUSTOM_FILE} (was missing 'command' prefix)"
        gsed -i '/# => Python configuration/,/^alias brew="brew_wrapper"$/d' "${ZSHENV_CUSTOM_FILE}"
    fi

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
		# Uses 'command brew' to bypass the alias and avoid infinite recursion
		function brew_wrapper() {
		    local current_version
		    current_version="$(pyenv global)"
		    if [[ "${current_version}" != "system" ]]; then
		        pyenv global system
		        print_warning "Temporarily switched pyenv from ${current_version} to system for brew"
		    fi
		    command brew "${@}"
		    if [[ "${current_version}" != "system" ]]; then
		        pyenv global "${current_version}"
		        print_warning "Restored pyenv to ${current_version}"
		    fi
		}
		alias brew="brew_wrapper"
	EOS

    append_lines_to_file_if_not_there "${lines}" "${ZSHENV_CUSTOM_FILE}"

    if pyenv versions --bare 2>/dev/null | grep -q "^${PYTHON_VERSION}$"; then
        print_success "Python ${PYTHON_VERSION} already installed via pyenv"
    else
        pyenv install "${PYTHON_VERSION}"
    fi
    pyenv global "${PYTHON_VERSION}"

    export PYENV_ROOT="${HOME}/.pyenv"
    add_to_path_if_exists "${PYENV_ROOT}/bin"
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
    if command -v rustup &>/dev/null; then
        print_success "Rust already installed"
    else
        ask_for_confirmation "rust" "https://www.rust-lang.org/" \
            sh -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y
    fi

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

# setup_nvm - Install Node Version Manager
# Usage: setup_nvm
# Returns: 0 on success, 1 on error
# Note: Installs nvm and configures environment, skips if Oh My Zsh nvm plugin is installed
setup_nvm() {
    # Detect NVM directory: respect NVM_DIR if set, then check common locations
    local nvm_dir="${NVM_DIR:-}"
    if [[ -z "${nvm_dir}" ]]; then
        if [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
            nvm_dir="${HOME}/.nvm"
        elif [[ -s "${HOME}/.config/nvm/nvm.sh" ]]; then
            nvm_dir="${HOME}/.config/nvm"
        else
            nvm_dir="${HOME}/.nvm"
        fi
    fi

    if [[ -s "${nvm_dir}/nvm.sh" ]]; then
        print_success "NVM already installed"
    else
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
        # Re-detect: installer may choose ~/.config/nvm or ~/.nvm
        if [[ -s "${HOME}/.config/nvm/nvm.sh" ]]; then
            nvm_dir="${HOME}/.config/nvm"
        fi
    fi

    # Only add the nvm sourcing if the plugin is not installed
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/nvm" ]]; then
        # Note that indentation with tabs is needed here!
        IFS='' read -r -d '' lines <<-"EOS" || true
			###############################################################
			# => Node.js configuration
			###############################################################
			# NVM configuration
			# See: https://github.com/nvm-sh/nvm#installing-and-updating
			# Detect NVM directory (installer may use ~/.nvm or ~/.config/nvm)
			if [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
			    export NVM_DIR="${HOME}/.nvm"
			elif [[ -s "${HOME}/.config/nvm/nvm.sh" ]]; then
			    export NVM_DIR="${HOME}/.config/nvm"
			fi
			[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm
			[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
		EOS

        # Appending to the profile file, as this would be too slow on every shell
        append_lines_to_file_if_not_there "${lines}" "${ZPROFILE_CUSTOM_FILE}"
    fi

    export NVM_DIR="${nvm_dir}"
    [ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"  # This loads nvm
    [ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion
}

# install_node - Install Node.js LTS version
# Usage: install_node
# Returns: 0 on success, 1 on error
# Note: Installs the latest LTS version of Node.js via nvm
install_node() {
    ask_for_confirmation "Node LTS" "https://nodejs.org/en/download/package-manager/#nvm" \
        nvm install --lts
}

###############################################################
# => Java setup
###############################################################

# setup_sdkman - Install SDKMAN for JVM ecosystem management
# Usage: setup_sdkman
# Returns: 0 on success, 1 on error
# Note: Installs SDKMAN and configures environment for Java version management
setup_sdkman() {
    if [[ -d "${HOME}/.sdkman" ]]; then
        print_success "SDKMAN already installed"
    else
        curl -s "https://get.sdkman.io" | bash
    fi

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

# install_java_openjdk - Install Java OpenJDK via SDKMAN
# Usage: install_java_openjdk
# Returns: 0 on success, 1 on error
# Note: Installs Java OpenJDK using SDKMAN (may require manual execution in separate terminal)
install_java_openjdk() {
    print_warning "sdk might not work inside a script so you might need to run the following command in a separate terminal..."
    # Source sdkman-init.sh in the subprocess so the sdk function is available
    ask_for_confirmation "java_20_openjdk" "https://sdkman.io/usage" \
        /bin/zsh -c "source \"\${HOME}/.sdkman/bin/sdkman-init.sh\" && sdk install java ${SDK_JAVA_VERSION}"
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
# => Docker and Kubernetes setup
###############################################################

# install_docker - Install Docker Desktop
# Usage: install_docker
# Returns: 0 on success, 1 on error
# Note: Downloads and installs Docker Desktop for macOS and Linux based on system architecture
install_docker() {
    if command -v docker &>/dev/null; then
        print_success "Docker already installed"
        return 0
    fi

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

        # Detect distro (ubuntu or debian) for Docker repo URL
        local distro_id
        distro_id="$(. /etc/os-release && echo "${ID}")"

        # Add Docker's official GPG key:
        sudo apt-get update -y
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "https://download.docker.com/linux/${distro_id}/gpg" -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${distro_id} \
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

# install_vscode - Install Visual Studio Code
# Usage: install_vscode
# Returns: 0 on success, 1 on error
# Note: Installs Visual Studio Code via direct download for macOS and Linux
install_vscode() {
    if command -v code &>/dev/null; then
        print_success "VS Code already installed"
        return 0
    fi

    print_info "Installing Visual Studio Code"

    if is_macos; then
        brew install --cask visual-studio-code
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

# install_slack - Reinstall Slack via Homebrew
# Usage: install_slack
# Returns: 0 on success, 1 on error
# Note: Removes existing Slack installation and reinstalls via Homebrew for updates
install_slack() {
    if is_macos; then
        ask_for_confirmation "slack" "https://www.slack.com" \
            brew install --cask slack
    elif [[ "$(get_architecture)" == "aarch64" ]]; then
        print_warning "Slack is not available for Linux arm64 (no snap/flatpak). Skipping."
        return 0
    else
        ask_for_confirmation "slack" "https://www.slack.com" \
            sudo snap install slack --classic
    fi
}

# install_obsidian - Install Obsidian
# Usage: install_obsidian
# Returns: 0 on success, 1 on error
# Note: Installs Obsidian via DMG on macOS, flatpak on Linux
install_obsidian() {
    if is_macos && [[ -d "/Applications/Obsidian.app" ]]; then
        print_success "Obsidian already installed"
        return 0
    elif ! is_macos && flatpak info md.obsidian.Obsidian &>/dev/null; then
        print_success "Obsidian already installed (flatpak)"
        return 0
    fi

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
        # Install via flatpak (works on both amd64 and arm64)
        if ! command -v flatpak &>/dev/null; then
            sudo apt-get install -y flatpak
        fi
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak install -y flathub md.obsidian.Obsidian

        print_success "Obsidian installed successfully (flatpak)"
    fi
}

# install_nerd_fonts - Install Nerd Fonts
# Usage: install_nerd_fonts
# Returns: 0 on success, 1 on error
# Note: Installs Nerd Fonts via Homebrew Cask on macOS or direct download on Linux
install_nerd_fonts() {
    local font="0xProto"
    local version="3.4.0"
    local font_dir="${HOME}/.local/share/fonts"

    # Check if font is already installed
    if ls "${font_dir}"/0xProto*NerdFont*.ttf &>/dev/null 2>&1; then
        print_success "Nerd Fonts already installed"
        return 0
    fi

    print_info "Installing Nerd Fonts"
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

# setup_iterm2 - Install iTerm2
# Usage: setup_iterm2
# Returns: 0 on success, 1 on error
# Note: Installs iTerm2 via direct download for macOS and Linux
setup_iterm2() {
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

    # DynamicProfiles directory is created on first iTerm2 launch - ensure it exists
    mkdir -p "${HOME}/Library/Application Support/iTerm2/DynamicProfiles"
    ask_for_confirmation "iTerm2 profile" "" cp "${0%/*}/iterm2/iterm2_profile.json" "${HOME}/Library/Application Support/iTerm2/DynamicProfiles/iterm2_profile.json"

    print_info "You will need to make the profile the default in the preferences."
}

install_displaylink() {
  if [[ -d "/Applications/DisplayLink Manager.app" ]]; then
      print_success "DisplayLink Manager already installed"
      return 0
  fi

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

_install_devs_cli() {
    brew tap julianmateu/devs
    brew install devs
}

# setup_devs_cli - Install Devs CLI and configure completions
# Usage: setup_devs_cli
# Returns: 0 on success, 1 on error
# Note: Installs Devs CLI via Homebrew tap and adds dynamic completions to zshrc_custom
setup_devs_cli() {
    ask_for_confirmation "Devs CLI" "https://github.com/julianmateu/devs-cli" \
        _install_devs_cli

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
