source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}

# Source custom zshenv if it exists
source_if_exists "${HOME}/.zshenv_custom.zsh"

# Source cargo environment if it exists
source_if_exists "${HOME}/.cargo/env"
