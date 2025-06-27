# SAFELOAD PATTERN
# ----------------
# Load utility functions using the safeload pattern
# ${0%/*} is parameter expansion that removes the shortest match of "/*" from the end of $0
# See: bash manual "Parameter Expansion" section
source "${0%/*}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}

# brew
eval "$(/opt/homebrew/bin/brew shellenv)"
# Monzo requires go 1.22, but brew will install the latest, so I need to manually add the old version to the path
#GOVERSION='1.22'
#GOVERSION_EXACT='1.22.7'
#export PATH="/opt/homebrew/opt/go@${GOVERSION}/bin:${PATH}"
#export GOROOT="/opt/homebrew/Cellar/go@${GOVERSION}/${GOVERSION_EXACT}/libexec/"
GOVERSION='1.24'
GOVERSION_EXACT='1.24.2'
export PATH="/opt/homebrew/opt/go@${GOVERSION}/bin:${PATH}"
export GOROOT="/opt/homebrew/Cellar/go/${GOVERSION_EXACT}/libexec"

# PyEnv
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
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