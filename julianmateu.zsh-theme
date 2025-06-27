###############################################################
# Julian Mateu ZSH Theme
# =====================
# This is a custom zsh theme based on robbyrussell with time brackets from crunch.
# It displays: success indicator, timestamp, current directory, git status, and kubecontext.
#
# ZSH Theme System
# ----------------
# ZSH themes work by setting the PROMPT variable with special escape sequences.
# See: zsh manual "Prompt Expansion" section
# See: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
#
# Theme Components:
# - Success indicator (➜) - changes color based on last command exit status
# - Timestamp ([YYYY-MM-DD HH:MM:SS +TZ]) - current time with timezone
# - Current directory (%c) - shows current directory name
# - Git status - shows branch and dirty/clean state
# - Kubernetes context - shows current kubecontext (if available)
#
# Color System:
# - Uses zsh's built-in color system with $fg_bold[color] and $reset_color
# - Colors are applied using %{...%} to prevent cursor positioning issues
# - See: zsh manual "Visual Effects" section
#
###############################################################

###############################################################
# => Colors
###############################################################
# Color definitions using zsh's built-in color system
# $fg_bold[color] - bold foreground color
# $reset_color - reset all colors and effects
# %{...%} - non-printing escape sequences (prevents cursor positioning issues)
JM_SUCCESS_COLOR="%{$fg_bold[green]%}"
JM_ERROR_COLOR="%{$fg_bold[red]%}"

JM_TIME_WRAPPER_COLOR="%{$fg_bold[white]%}"
JM_TIME_COLOR="%{$fg_bold[yellow]%}"

JM_DIR_COLOR="%{$fg_bold[cyan]%}"

JM_GIT_BRANCH_WRAPPER_COLOR="%{$fg_bold[blue]%}"
JM_GIT_BRANCH_COLOR="%{$fg_bold[red]%}"
JM_GIT_CLEAN_COLOR="%{$fg_bold[green]%}"
JM_GIT_DIRTY_COLOR="%{$fg_bold[yellow]%}"

JM_KUBECONTEXT_COLOR="%{$fg_bold[magenta]%}"

###############################################################
# => Prompt symbols and indicators
###############################################################
# Success indicator - shows ➜ in green for success, red for failure
JM_SUCCESS_INDICATOR="➜"

# Time format - shows date, time, and timezone
# %D{%F} - date in YYYY-MM-DD format
# %T - time in HH:MM:SS format  
# %D{%z} - timezone offset (+0100)
JM_TIME_OPEN="["
JM_TIME_FORMAT="%D{%F}T%*%D{%z}"
JM_TIME_CLOSE="]"

# Directory format - %c shows current directory name
JM_DIR_FORMAT="%c"

# Git indicators
JM_GIT_OPEN="git:("
JM_GIT_CLOSE=")"
JM_GIT_DIRTY="✗"  # Shows when git repository has uncommitted changes
JM_GIT_CLEAN=""   # Shows nothing when git repository is clean

###############################################################
# => Intermediate helper variables
#    (should not need to change unless a different structure is desired)
###############################################################
# Success indicator with conditional coloring
# %(?:...) - conditional expansion based on exit status
# ?: means "if last command succeeded, use first color, otherwise use second"
JM_SUCCESS="%(?:${JM_SUCCESS_COLOR}:${JM_ERROR_COLOR})${JM_SUCCESS_INDICATOR}%{${reset_color}%}"

# Time component with wrapper colors
JM_TIME_OPEN_PROMPT="${JM_TIME_WRAPPER_COLOR}${JM_TIME_OPEN}"
JM_TIME_CLOSE_PROMPT="${JM_TIME_WRAPPER_COLOR}${JM_TIME_CLOSE}"
JM_TIME_INFO="${JM_TIME_COLOR}${JM_TIME_FORMAT}"
JM_TIME="${JM_TIME_OPEN_PROMPT}${JM_TIME_INFO}${JM_TIME_CLOSE_PROMPT}%{${reset_color}%}"

# Directory component
JM_DIR="${JM_DIR_COLOR}${JM_DIR_FORMAT}%{${reset_color}%}"

# Git wrapper colors
JM_GIT_OPEN_PROMPT="${JM_GIT_BRANCH_WRAPPER_COLOR}${JM_GIT_OPEN}"
JM_GIT_CLOSE_PROMPT="${JM_GIT_BRANCH_WRAPPER_COLOR}${JM_GIT_CLOSE}"

###############################################################
# => Variables used by the ZSH *_prompt_info helpers
###############################################################
# These variables are used by Oh My Zsh's git prompt functions
# ZSH_THEME_GIT_PROMPT_PREFIX - text before git branch name
# ZSH_THEME_GIT_PROMPT_DIRTY - text when repository has uncommitted changes
# ZSH_THEME_GIT_PROMPT_CLEAN - text when repository is clean
# ZSH_THEME_GIT_PROMPT_SUFFIX - text after git status
ZSH_THEME_GIT_PROMPT_PREFIX="${JM_GIT_OPEN_PROMPT}${JM_GIT_BRANCH_COLOR}"
ZSH_THEME_GIT_PROMPT_DIRTY="${JM_GIT_CLOSE_PROMPT} ${JM_GIT_DIRTY_COLOR}${JM_GIT_DIRTY} "
ZSH_THEME_GIT_PROMPT_CLEAN="${JM_GIT_CLOSE_PROMPT} ${JM_GIT_CLEAN_COLOR}${JM_GIT_CLEAN}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{${reset_color}%}"

###############################################################
# => Final prompt variable
# Note the single quotes to prevent variables to be evaluated when setting the variable
###############################################################
# Static part of the prompt (doesn't change)
JM_PROMPT_STATIC="${JM_SUCCESS} ${JM_TIME} ${JM_DIR} ${JM_KUBECONTEXT_COLOR}"

# Final prompt with dynamic components:
# ${current_kubecontext} - set by precmd function in zshrc
# $(git_prompt_info) - Oh My Zsh git prompt function
# %# - shows # for root, % for normal user
PROMPT='${JM_PROMPT_STATIC}${current_kubecontext} $(git_prompt_info)%# '
