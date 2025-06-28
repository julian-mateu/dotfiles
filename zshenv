source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}
print_debug "sourcing zshenv"

# Source custom zshenv if it exists
source_if_exists "${HOME}/.zshenv_custom.zsh"

