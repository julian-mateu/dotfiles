source_if_exists () {
  # TODO: what's the difference between -f and -r?
  # TODO: refactor to use this function
    if [[ -f "${1}" ]]; then
        source "${1}"
    fi
}

[[ -f "${HOME}/.zshenv_custom.zsh" ]] && source "${HOME}/.zshenv_custom.zsh"
. "$HOME/.cargo/env"
