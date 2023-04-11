## Install

There is configuration for `zsh` so first of all switch your shell from the default `bash` to `zsh` on OSX:
```bash
chsh -s /bin/zsh
```

Run the setup script. It will interactively prompt you to install dependencies. It will not override existing config files, just rename them as `#{file}.backup`.
```bash
./setup.sh
```

**NOTE**: `brew doctor` showed a warning:
> Warning: You have unlinked kegs in your Cellar

so I ran
`brew link kubernetes-cli`, and that failed because `/usr/local/bin/kubectl` already existed:
```bash
la /usr/local/bin/kubectl
lrwxr-xr-x  1 root  admin    55B 23 Aug 22:01 /usr/local/bin/kubectl -> /Applications/Docker.app/Contents/Resources/bin/kubectl
```

So I ran `brew link --overwrite --dry-run kubernetes-cli`

## Optional tricks


### Set up a case sensitive volume and symlink your source folder to it
See [this article](https://brianboyko.medium.com/a-case-sensitive-src-folder-for-mac-programmers-176cc82a3830), which basically involves
creating an `APFS Case Sensitive` volume with Mac's Disk Utility, and then creating a symlink, e.g.:
```bash
ln -s /Volumes/sourcecode ~/src
```

### Add shortcut to touchbar to toggle between dark and light modes

See [this article](https://appleinsider.com/articles/18/06/14/how-to-toggle-dark-mode-with-a-keyboard-shortcut-or-the-touch-barhttps://appleinsider.com/articles/18/06/14/how-to-toggle-dark-mode-with-a-keyboard-shortcut-or-the-touch-bar). The "Workflows" option was renamed to "Quick Actions", last version I tired is Big Sur 11.2.3

It essentially is copying this script into Automator -> Quick Action -> Run AppleScript:
```applescript
tell application "System Events"
	tell appearance preferences
		set dark mode to not dark mode
	end tell
end tell
```
Then save and go to System Preferences -> Extensions -> Touch Bar -> Customize Control Strip and drag the "Quick Actions" icon to the touchbar. 

## Sources
This is based on some other sources for [dot files](https://github.com/afallou/dotfiles), [vimrc](https://github.com/amix/vimrc) and [oh-my-zsh](https://www.youtube.com/watch?v=MSPu-lYF-A8).
