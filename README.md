# Julian Mateu's Dotfiles

Configuration scripts for setting up a macOS/Linux development environment.

Neovim config: [nvim-config repo](https://github.com/julianmateu/nvim-config)

## Quick Start

```bash
git clone https://github.com/julianmateu/dotfiles.git
cd dotfiles
./install.sh    # Install tools (interactive, pick what you need)
./setup.sh      # Create symlinks to home directory
source ~/.zshrc # Reload shell
```

## What's Included

### Shell
- **ZSH + Oh My Zsh** with plugins (autosuggestions, syntax-highlighting, history-substring-search)
- **Custom theme** with vim mode indicator, git status, kubecontext, timestamps
- **Utility library** (`zutils.zsh`) for colors, logging, file operations

### Languages
- **Python** - pyenv with brew wrapper
- **Node.js** - nvm with lazy loading
- **Go** - Homebrew (use `brew pin go` for version stability)
- **Rust** - rustup/cargo
- **Java** - SDKMAN
- **.NET** - Homebrew

### Tools
- **Editors**: Neovim, VS Code
- **Containers**: Docker, kubectl, k9s, helm
- **Terminal**: iTerm2 (macOS), Nerd Fonts
- **CLI**: ripgrep, fzf, lazygit, tmux, jq, bat, GNU coreutils

### Apps (optional)
Slack, Zoom, Spotify, Chrome, Obsidian

## Architecture

### Shell Loading Order

`zshenv` → `zprofile` → `zshrc`

| File | When | Purpose |
|------|------|---------|
| `zshenv` | All shells | Environment variables (PATH, etc.) |
| `zprofile` | Login shells | One-time login setup |
| `zshrc` | Interactive | Plugins, theme, aliases, keybindings |

### Customization

Machine-specific configs go in `*_custom.zsh` files (gitignored):
- `zshenv_custom.zsh` - Environment (Homebrew, pyenv, Go, etc.)
- `zshrc_custom.zsh` - Interactive shell customizations
- `zprofile_custom.zsh` - Login shell customizations
- `aliases_custom.zsh` - Personal aliases

These are created by `install.sh` and symlinked by `setup.sh`.

### Key Files

| File | Purpose |
|------|---------|
| `zutils.zsh` | Utility functions (colors, `add_to_path`, `source_if_exists`, etc.) |
| `aliases.zsh` | Command shortcuts |
| `julianmateu.zsh-theme` | Custom prompt theme |
| `install.sh` | Tool installation (interactive) |
| `setup.sh` | Symlink creation (`-f` to force overwrite) |

## Tips

### Prevent Homebrew Auto-Upgrades

```bash
brew pin go      # Pin a formula
brew unpin go    # Allow upgrades again
```

### Case-Sensitive Volume (macOS)

For projects requiring case-sensitivity, create an APFS Case Sensitive volume in Disk Utility and symlink:
```bash
ln -s /Volumes/sourcecode ~/src
```

## External References

- [ZSH Manual](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh Wiki](https://github.com/ohmyzsh/ohmyzsh/wiki)
