# shellcheck disable=SC1091
source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}

###############################################################
# => Homebrew configuration
###############################################################
# Initialize Homebrew environment
# See: https://brew.sh/
eval "$(/opt/homebrew/bin/brew shellenv)"

###############################################################
# => Go configuration
###############################################################
# Go version management
# Monzo requires go 1.22, but brew will install the latest, so I need to manually add the old version to the path
#GOVERSION='1.22'
#GOVERSION_EXACT='1.22.7'
#export PATH="/opt/homebrew/opt/go@${GOVERSION}/bin:${PATH}"
#export GOROOT="/opt/homebrew/Cellar/go@${GOVERSION}/${GOVERSION_EXACT}/libexec/"

# Current Go version
GOVERSION='1.24'
GOVERSION_EXACT='1.24.2'
add_to_path "/opt/homebrew/opt/go@${GOVERSION}/bin"
export GOROOT="/opt/homebrew/Cellar/go/${GOVERSION_EXACT}/libexec"

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