###############################################################
# Author: Julian Mateu - julianmateu@gmail.com
#
# Sections:
#    -> Misc
#    -> Filesystem Navigation
#    -> OSX Filesystem
#    -> Applications
#    -> Networking
#    -> Git
#    -> Npm
#    -> Yarn
#    -> Docker
#
###############################################################

###############################################################
# => Misc
###############################################################
alias zshrc="code ~/.zshrc"
alias update="source ~/.zshrc"
alias topten="history | commands | sort -rn | head"
alias dirs="dirs -v | head -10"
alias usage="du -h -d1"
alias runp="lsof -i "

###############################################################
# => Filesystem Navigation
###############################################################
alias ll="ls -1a"
alias md="mkdir "
alias ..="cd .."
alias ...="cd ../.."
alias ..l="cd ../ && ll"
alias sshdir="cd ~/.ssh"
alias de="cd ~/Desktop"
alias dd="cd ~/workplace"
alias d="cd ~/workplace && cd "
alias p="cd ~/projects"
alias pd="cd ~/projects && cd "

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

###############################################################
# => Networking
###############################################################
alias myip="curl http://ipecho.net/plain; echo"
alias pg="echo 'Pinging Google' && ping www.google.com";
alias flushdns="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder"
## IPv6 can mess up with connections, so these are shortcuts to disable/enable. See https://stackoverflow.com/a/51544596
alias disableipv6="networksetup -setv6off Ethernet && networksetup -setv6off Wi-Fi"
alias enableipv6="networksetup -setv6automatic Wi-Fi && networksetup -setv6automatic Ethernet"

###############################################################
# => Git
###############################################################
function gc { git commit -m "$@"; }
alias gcm="git checkout master"
alias gs="git status"
alias gpull="git pull"
alias gf="git fetch"
alias gfa="git fetch --all"
alias gf="git fetch origin"
alias gpush="git push"
alias gd="git diff"
alias ga="git add ."
alias gb="git branch"
alias gbr="git branch remote"
alias gfr="git remote update"
alias gbn="git checkout -B "
alias grf="git reflog"
alias grh="git reset HEAD~" # last commit
alias gac="git add . && git commit -a -m "
alias gsu="git gpush --set-upstream origin "
alias glog="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --branches"

###############################################################
# => Npm
###############################################################
alias ni="npm install"
alias nrs="npm run start -s --"
alias nrb="npm run build -s --"
alias nrd="npm run dev -s --"
alias nrt="npm run test -s --"
alias nrtw="npm run test:watch -s --"
alias nrv="npm run validate -s --"
alias rmn="rm -rf node_modules"
alias flush-npm="rm -rf node_modules && npm i && echo NPM is done"
alias npm-update="npx npm-check -u"

###############################################################
# => Yarn
###############################################################
alias yar="yarn run" # lists all the scripts we have available
alias yab="yarn build" # build dist directory for each package
alias yal="yarn lint:fix" # format source and auto-fix eslint issues
alias yac="yarn commit" # open a Q&A prompt to help construct valid commit messages
alias yas="yarn start"
alias yasb="yarn storybook:start" # start storybook
alias yat="yarn test" # run the unit tests*
alias yatw="yarn test:watch" #run the unit tests for files changed on save

###############################################################
# => Docker
###############################################################
alias dockerstop="docker-compose stop"
alias dockerrestart="docker-compose restart"
alias dockerup="docker-compose up -d"
alias dockerdown="docker-compose down --volumes --remove-orphans"
alias dockerrm="docker-compose rm --all"
