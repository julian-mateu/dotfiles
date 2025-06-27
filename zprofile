source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}
###############################################################
# => Environment variables
###############################################################
add_to_path "${HOME}/bin"

# Ignore duplicate entries in the history
export HISTCONTROL="ignoreboth"

###############################################################
# => Configurations for tools
###############################################################
source_if_exists "${HOME}/.zprofile_custom.zsh"