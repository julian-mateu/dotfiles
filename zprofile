source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}
###############################################################
# => Environment variables
###############################################################
export PATH="${HOME}/bin:${PATH}"
export HISTCONTROL="ignoreboth"

###############################################################
# => Configurations for tools
###############################################################
source_if_exists "${HOME}/.zprofile_custom.zsh"