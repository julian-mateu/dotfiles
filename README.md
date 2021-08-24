## Install

If you're on a new computer, run the install script to install dependencies:
```
source ./install.sh
```

Now you can run the setup script. It will not override existing config files, just rename them as ```#{file}.backup```.
```
./setup.sh
```

There is configuration for `zsh` so switch your shell from the default `bash` to `zsh` on OS X:
```
chsh -s /bin/zsh
```

## Sources
This is based on https://github.com/afallou/dotfiles and https://github.com/amix/vimrc
