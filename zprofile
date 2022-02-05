###############################################################
# => Environment variables
###############################################################

export PATH="${HOME}/bin:${PATH}"
export HISTCONTROL="ignoreboth"

###############################################################
# => Configurations for tools
###############################################################

[[ -f "${HOME}/.zprofile_custom.zsh" ]] && source "${HOME}/.zprofile_custom.zsh"
