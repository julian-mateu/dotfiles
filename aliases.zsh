###############################################################
# ZSH Aliases Configuration
# ========================
# This file contains all shell aliases organized by category.
# Aliases are shortcuts that make common commands easier to type.
#
# Alias Categories:
# - Git aliases - shortcuts for common git operations
# - Directory navigation - quick cd commands and path shortcuts
# - Development tools - aliases for common dev workflows
# - System utilities - shortcuts for system commands
# - Docker/Kubernetes - container and orchestration shortcuts
# - Network utilities - networking and connectivity commands
# - File operations - file and directory management shortcuts
# - Python/Node.js - language-specific development aliases
#
# Usage:
# - Aliases are automatically loaded when zsh starts
# - Use 'alias' command to see all current aliases
# - Use 'unalias <name>' to remove a specific alias
# - Use 'alias <name>="command"' to create new aliases
#
###############################################################

source "${HOME}/.zutils.zsh" || { 
    echo "Failed to load zutils.zsh" >&2
    return 1
}
print_debug "sourcing aliases.zsh"


###############################################################
# => Misc
###############################################################
# OSX uses a different sed by default. See https://unix.stackexchange.com/a/131940
alias sed="gsed"
alias zshrc="code ~/.zshrc"
alias update="source ~/.zshrc"
alias dirs="dirs -v | head -10"
alias usage="du -h -d1"
alias runp="lsof -i "
alias uuid="python -c 'import uuid;print(uuid.uuid4())'"
alias randpwd="openssl rand -base64 32"
alias v="nvim"

###############################################################
# => Filesystem Navigation
###############################################################
alias ll="ls -la"
alias md="mkdir "
alias ..="cd .."
alias ...="cd ../.."
alias ..l="cd ../ && ll"


###############################################################
# => OSX Filesystem
###############################################################
alias showFiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app"
alias hideFiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app"
alias deleteDSFiles="find . -name '.DS_Store' -type f -delete"

###############################################################
# => Applications
###############################################################
alias chrome='open -a "Google Chrome"'
alias c="code ."
alias n="nvim ."

###############################################################
# => Networking
###############################################################
alias myip="curl http://ipecho.net/plain; echo"
alias pg="echo 'Pinging Google' && ping www.google.com"
alias flushdns="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder"
## IPv6 can mess up with connections, so these are shortcuts to disable/enable. See https://stackoverflow.com/a/51544596
alias disableipv6="networksetup -setv6off Ethernet && networksetup -setv6off Wi-Fi"
alias enableipv6="networksetup -setv6automatic Wi-Fi && networksetup -setv6automatic Ethernet"

###############################################################
# => Git
###############################################################
alias gsbs="git --no-pager branch"
alias glog="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches"
alias lg="lazygit"

###############################################################
# => Npm
###############################################################
alias ni="npm install"
alias nrs="npm run start"
alias nrb="npm run build"
alias nrd="npm run dev"
alias nrt="npm run test"
alias nrtw="npm run test:watch"
alias rmn="rm -rf node_modules"
alias flush-npm="rm -rf node_modules && npm i && echo NPM is done"
alias npm-update="npx npm-check -u"

###############################################################
# => Docker
###############################################################
alias dockerstop="docker-compose stop"
alias dockerrestart="docker-compose restart"
alias dockerup="docker-compose up -d"
alias dockerdown="docker-compose down --volumes --remove-orphans"
alias dockerrm="docker-compose rm --all"

###############################################################
# => Kubernetes
###############################################################
alias k="kubectl"
alias kc="kubectl config use-context"
alias kctx="kubectl config current-context"
alias kgp="kubectl get pods"
alias kgn="kubectl get nodes"
alias kgs="kubectl get services"
alias kd="kubectl describe"

