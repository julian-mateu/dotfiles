###############################################################
# Author: Julian Mateu - julianmateu@gmail.com
#
# It's basically robbyrussell with the time bracket from crunch
# See the manual for symbols: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
#
# Sections:
#    -> Colors
#    -> Prompt symbols and indicators
#    -> Intermediate helper variables
#    -> Variables used by the ZSH *_prompt_info helpers
#    -> Final prompt variable :)
#
###############################################################

###############################################################
# => Colors
###############################################################
JULIANMATEU_SUCCESS_COLOR="%{$fg_bold[green]%}"
JULIANMATEU_ERROR_COLOR="%{$fg_bold[red]%}"

JULIANMATEU_TIME_WRAPPER_COLOR="%{$fg_bold[white]%}"
JULIANMATEU_TIME_COLOR="%{$fg_bold[yellow]%}"

JULIANMATEU_DIR_COLOR="%{$fg_bold[cyan]%}"

JULIANMATEU_GIT_BRANCH_WRAPPER_COLOR="%{$fg_bold[blue]%}"
JULIANMATEU_GIT_BRANCH_COLOR="%{$fg_bold[red]%}"
JULIANMATEU_GIT_CLEAN_COLOR="%{$fg_bold[green]%}"
JULIANMATEU_GIT_DIRTY_COLOR="%{$fg_bold[yellow]%}"

###############################################################
# => Prompt symbols and indicators
###############################################################
JULIANMATEU_SUCCESS_INDICATOR="➜"

JULIAN_MATEU_TIME_OPEN="["
JULIAN_MATEU_TIME_FORMAT="%D{%F}T%*%D{%z}"
JULIAN_MATEU_TIME_CLOSE="]"

JULIANMATEU_DIR_FORMAT="%c"
JULIANMATEU_GIT_OPEN="git:("
JULIANMATEU_GIT_CLOSE=")"
JULIANMATEU_GIT_DIRTY="✗"
JULIANMATEU_GIT_CLEAN=""

###############################################################
# => Intermediate helper variables
#    (should not need to change unless a different structure is desired)
###############################################################
JULIANMATEU_SUCCESS="%(?:${JULIANMATEU_SUCCESS_COLOR}:${JULIANMATEU_ERROR_COLOR})${JULIANMATEU_SUCCESS_INDICATOR}%{${reset_color}%}"

JULIAN_MATEU_TIME_OPEN_PROMPT="${JULIANMATEU_TIME_WRAPPER_COLOR}${JULIAN_MATEU_TIME_OPEN}"
JULIAN_MATEU_TIME_CLOSE_PROMPT="${JULIANMATEU_TIME_WRAPPER_COLOR}${JULIAN_MATEU_TIME_CLOSE}"
JULIANMATEU_TIME_INFO="${JULIANMATEU_TIME_COLOR}${JULIAN_MATEU_TIME_FORMAT}"
JULIANMATEU_TIME="${JULIAN_MATEU_TIME_OPEN_PROMPT}${JULIANMATEU_TIME_INFO}${JULIAN_MATEU_TIME_CLOSE_PROMPT}%{${reset_color}%}"

JULIANMATEU_DIR="${JULIANMATEU_DIR_COLOR}${JULIANMATEU_DIR_FORMAT}%{${reset_color}%}"

JULIANMATEU_GIT_OPEN_PROMPT="${JULIANMATEU_GIT_BRANCH_WRAPPER_COLOR}${JULIANMATEU_GIT_OPEN}"
JULIANMATEU_GIT_CLOSE_PROMPT="${JULIANMATEU_GIT_BRANCH_WRAPPER_COLOR}${JULIANMATEU_GIT_CLOSE}"

###############################################################
# => Variables used by the ZSH *_prompt_info helpers
###############################################################
ZSH_THEME_GIT_PROMPT_PREFIX="${JULIANMATEU_GIT_OPEN_PROMPT}${JULIANMATEU_GIT_BRANCH_COLOR}"
ZSH_THEME_GIT_PROMPT_DIRTY="${JULIANMATEU_GIT_CLOSE_PROMPT} ${JULIANMATEU_GIT_DIRTY_COLOR}${JULIANMATEU_GIT_DIRTY} "
ZSH_THEME_GIT_PROMPT_CLEAN="${JULIANMATEU_GIT_CLOSE_PROMPT} ${JULIANMATEU_GIT_CLEAN_COLOR}${JULIANMATEU_GIT_CLEAN}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{${reset_color}%}"

###############################################################
# => Final prompt variable :)
# Note the single qoutes to prevent variables to be evaluated when setting the variable
###############################################################
PROMPT='${JULIANMATEU_SUCCESS} ${JULIANMATEU_TIME} ${JULIANMATEU_DIR} $(git_prompt_info)%# '
