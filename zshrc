###############################################################
# Main zsh configuration file
# ==========================
# This file sets up the basic zsh environment including Oh My Zsh,
# plugins, theme, and custom functions.
#
# Sections:
#    -> Environment variables
#    -> Plugins
#    -> External files
#    -> Options
#    -> Functions
#    -> Aliases
#    -> Key bindings
#
###############################################################
source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}

###############################################################
# => Environment variables
###############################################################
# zmodload zsh/zprof - Load the zprof module for profiling zsh startup time
# See: zsh manual "The zsh/zprof Module" section
zmodload zsh/zprof

export ZSH="${HOME}/.oh-my-zsh"

ZSH_THEME="julianmateu"
# COMPLETION_WAITING_DOTS - Show dots while waiting for completion
COMPLETION_WAITING_DOTS="true"
# HIST_STAMPS - Format for history timestamps (yyyy-mm-dd)
HIST_STAMPS="yyyy-mm-dd"

###############################################################
# => Plugins
###############################################################
# Lazy load the NVM plugin to avoid slow startup
export NVM_LAZY_LOAD=true
plugins=(
    # git - Defines custom git aliases and functions
    # See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
    git
    # zsh-autosuggestions - Suggest commands as you type based on history
    # See: https://github.com/zsh-users/zsh-autosuggestions
    zsh-autosuggestions
    # nvm - Manages NVM, allows lazy loading to avoid slow startup
    # See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nvm
    nvm
    # zsh-history-substring-search - Better search on the history with arrow keys
    # See: https://github.com/zsh-users/zsh-history-substring-search
    zsh-history-substring-search
    # zsh-syntax-highlighting - Syntax highlighting in the terminal
    # See: https://github.com/zsh-users/zsh-syntax-highlighting
    zsh-syntax-highlighting
    # z - Jump around to commonly used directories
    # See: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/z
    z
)
# zstyle ':omz:plugins:nvm' lazy yes - Lazy load the NVM plugin to avoid slow startup
# See: https://github.com/lukechilds/zsh-nvm#lazy-loading
zstyle ':omz:plugins:nvm' lazy yes
# zstyle ':omz:plugins:nvm' autoload yes - Autoload the NVM plugin to avoid slow startup
# See: https://github.com/lukechilds/zsh-nvm#autoloading
zstyle ':omz:plugins:nvm' autoload yes

###############################################################
# => External files
###############################################################
# Load Oh My Zsh core functionality
source "${ZSH}/oh-my-zsh.sh"
# Load custom zshrc if it exists
source_if_exists "${HOME}/.zshrc_custom.zsh"

###############################################################
# => Options
###############################################################
# setopt correct - Enable automatic command correction
# See: zsh manual "Options" section, "CORRECT" option
setopt correct

###############################################################
# => Functions
###############################################################
function gcpr {
  # Create a PR in github for the current branch
  # $? is the exit status of the last command
  if [ $? -eq 0 ]; then
        # git remote -v shows all remotes, awk filters for 'fetch' lines
        # sed transforms git URLs to web URLs
        github_url=$(git remote -v | awk '/fetch/{print $2}' | sed -Ee 's#(git@|git://)#http://#' -e 's@com:@com/@' -e 's%\.git$%%')
        # git symbolic-ref HEAD gets the current branch name
        branch_name=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
        pr_url=${github_url}"/compare/master..."${branch_name}
        open ${pr_url}
    else
        echo 'failed to open a pull request.'
    fi
}

function grebase() {
  # Rebase current branch on main/master
  # git branch --show-current shows the current branch name
  PREVIOUS_BRANCH="$(git branch --show-current)"
  # git_main_branch is an Oh My Zsh function that returns 'main' or 'master'
  git checkout "$(git_main_branch)"
  git pull
  git checkout "${PREVIOUS_BRANCH}"
  git rebase "$(git_main_branch)"
}

bashman() {
    # Search bash manual for specific function
    # less -p "^       ${1} " - search for the function definition pattern
    man bash | less -p "^       ${1} "
}

# Special function that runs before each prompt in zsh
# See: https://github.com/rothgar/mastering-zsh/blob/master/docs/config/hooks.md
# precmd is called before each prompt is displayed
function precmd() {
  # Print the current kubecontext
  # which kubectl - check if kubectl is available
  if [[ "$(which kubectl)" ]]; then
    # kubectl config current-context - get current kubecontext
    # awk -F'/' '{print $NF}' - split by '/' and print the last field
    if kubectl config current-context >/dev/null 2>/dev/null; then
        current_kubecontext="$(kubectl config current-context | awk -F'/' '{print $NF}')"
    fi
  fi
}

###############################################################
# => Aliases
###############################################################
# Load aliases from external files
source_if_exists "${HOME}/.aliases.zsh"
source_if_exists "${HOME}/.aliases_custom.zsh"

###############################################################
# => Key bindings
###############################################################
# bind k and j for VI mode in command mode
# See: zsh manual "Keymaps" section
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# bind UP and DOWN arrow keys
# zmodload zsh/terminfo - Load terminal info for key codes
zmodload zsh/terminfo
# ${terminfo[kcuu1]} and ${terminfo[kcud1]} are terminal-specific up/down arrow codes
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# Enable vi mode:
# bindkey -v - Enable vi keymap
# set -o vi - Alternative way to enable vi mode
set -o vi

# Set the editor to nvim
export EDITOR=nvim
export VISUAL=nvim

# Edit current command in Vim
# bindkey '^xe' edit-command-line - Alternative binding
# zle -N edit-command-line - Define the edit-command-line widget
zle -N edit-command-line
# bindkey -M vicmd v edit-command-line - Bind 'v' in command mode to edit command line
bindkey -M vicmd v edit-command-line

# perform parameter expansion/command substitution in prompt
# setopt PROMPT_SUBST - Enable prompt substitution
# See: zsh manual "Options" section, "PROMPT_SUBST" option
setopt PROMPT_SUBST

# Vim mode indicator variables
vim_ins_mode="[INS]"
vim_cmd_mode="[CMD]"
vim_mode=$vim_ins_mode

# zle-keymap-select - Called when keymap changes (insert/command mode)
# See: zsh manual "Zle Widgets" section
function zle-keymap-select {
  # ${KEYMAP/vicmd/${vim_cmd_mode}} - substitute 'vicmd' with command mode indicator
  # ${KEYMAP/(main|viins)/${vim_ins_mode}} - substitute 'main' or 'viins' with insert mode indicator
  vim_mode="${${KEYMAP/vicmd/${vim_cmd_mode}}/(main|viins)/${vim_ins_mode}}"
  # zle reset-prompt - Redraw the prompt
  zle reset-prompt
}
zle -N zle-keymap-select

# zle-line-finish - Called when a line is finished (Enter pressed)
function zle-line-finish {
  vim_mode=$vim_ins_mode
}
zle -N zle-line-finish

# zle-line-init - Called when a new line is started
# This ensures real-time updates of vim mode indicator
function zle-line-init {
  vim_mode=$vim_ins_mode
  zle reset-prompt
}
zle -N zle-line-init

# Final prompt with vim mode indicator and newline
# The vim_mode variable will be updated by the zle widgets above
PROMPT="${PROMPT}"$'${vim_mode}\n'

# zprof - Print zsh startup profile
# See: zsh manual "The zsh/zprof Module" section
# Uncomment this line to print zsh startup profile:
# zprof