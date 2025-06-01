## ANSI COLORS
ANSI_ESCAPE='\033'
ANSI_COLOR_RED='[31m'
ANSI_NO_COLOR='[m'

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

function print_red() {
  echo -e "${ANSI_ESCAPE}${ANSI_COLOR_RED}${@}${ANSI_ESCAPE}${ANSI_NO_COLOR}"
}

# pyenv adds *-config scripts and produces a brew warning
function brew_wrapper() {
    current_version="$(pyenv global)"
    pyenv global system
    print_red "Warning: changed pyenv version from ${current_version} to system\n"
    brew "${@}"
    print_red "Warning: changed pyenv version from system to ${current_version}\n"
    pyenv global "${current_version}"
    print_red "Warning: running brew update will update go version, make sure to go back to the desired one and update the minor exact version in the zprofile file"
}
alias brew="brew_wrapper"

# NVM
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion

