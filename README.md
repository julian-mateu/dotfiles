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

## Installation Modes

```bash
# Interactive (default) - prompts for each tool
./install.sh

# Config file - install exactly what's in the config
cp dotfiles.conf.example dotfiles.conf  # customize, then:
./install.sh --config dotfiles.conf

# Profile - use a built-in preset
./install.sh --profile minimal    # Core tools only
./install.sh --profile backend    # + Java, .NET, K8s, Docker
./install.sh --profile full       # + GUI apps, fonts, IDE

# Auto-config - uses ./dotfiles.conf if it exists, otherwise interactive
./install.sh

# Preview mode - works with all modes
./install.sh --dry-run
./install.sh --dry-run --profile full

# CI mode - auto-accepts all prompts, skips GUI apps
DOTFILES_CI=true ./install.sh
```

### Profiles

| Profile | Includes |
|---------|----------|
| `minimal` | Homebrew, Oh My Zsh, Neovim, useful tools, Python, Go, Rust, Node, Claude Code |
| `backend` | minimal + Java (SDKMAN), .NET, Kubernetes, Docker |
| `full` | backend + VS Code, Nerd Fonts, iTerm2, Devs CLI |

### Config File

Copy `dotfiles.conf.example` to `dotfiles.conf` and set `INSTALL_*` variables to `true`/`false`. Version overrides (`PYTHON_VERSION`, `NVM_VERSION`, etc.) are also supported.

## Other Commands

```bash
./setup.sh         # Create symlinks to home directory
./setup.sh -f      # Force overwrite existing symlinks
ZSH_PROFILE=true zsh -i -c ''  # Profile shell startup time
```

## Testing

```bash
# Unit tests (requires bats-core)
bats tests/test_*.bats

# Or install bats first
brew install bats-core  # macOS
sudo apt-get install bats  # Ubuntu
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
- **CLI**: ripgrep, fzf, lazygit, tmux, jq, bat, gh, GNU coreutils

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
| `install.sh` | Tool installation (interactive, config-driven, or profile-based) |
| `setup.sh` | Symlink creation (`-f` to force overwrite) |
| `lib/config.sh` | CLI argument parsing and config loading |
| `lib/profiles.sh` | Built-in profiles (minimal, backend, full) |
| `lib/registry.sh` | Tool registry pattern for config-driven installs |
| `dotfiles.conf.example` | Example config file with all `INSTALL_*` variables |

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

## Forking This Repo

This repo is designed to be forked and customized. Here's what you need to know:

### How install.sh Works

`install.sh` uses a **tool registry pattern** for config-driven installs:

1. `main()` parses CLI flags, creates `*_custom.zsh` files, then tries to load config
2. If config loads (via `--config`, `--profile`, or auto-detected `dotfiles.conf`), it runs in **config-driven mode**: registers all tools, then `run_registry()` iterates them in order
3. If no config is found and no flags were passed, it falls back to **interactive mode** where each tool prompts for confirmation

Each tool is registered with a key, install function, description, URL, dependencies, and platform:
```bash
register_tool "python" install_python "Python (pyenv)" "https://github.com/pyenv" "homebrew" "all"
```

The key maps to an `INSTALL_PYTHON` variable (uppercased). `run_registry()` checks each tool's platform, CI skip list, enabled state, and dependencies before calling its install function.

**Adding a new tool:**
1. Write the install function in `install.sh`
2. Register it in `register_all_tools()`
3. Add `INSTALL_<KEY>=false` to `_reset_all_install_vars()` in `lib/profiles.sh`
4. Enable in the appropriate profiles
5. Add to `dotfiles.conf.example`
6. Add `ask_for_confirmation` call in `run_interactive()` for interactive mode

### What to Customize

1. **`install.sh`** - See "How install.sh Works" above. Copy `dotfiles.conf.example` to `dotfiles.conf` to customize which tools are installed.
2. **`*_custom.zsh` files** - These are **gitignored** and machine-specific. They're generated by `install.sh` based on which tools you install. You can also add manual entries for tools not covered by `install.sh`.
3. **`setup.sh`** - Creates SSH keys with a personal/work split (`id_ed25519-personal` and `id_ed25519`). Modify the `ssh_config` function to match your key naming convention.
4. **`julianmateu.zsh-theme`** - Rename and customize the prompt theme.

### How `_custom.zsh` Files Work

```
install.sh installs tools and appends config blocks to *_custom.zsh files
   ├── zshenv_custom.zsh  ← Homebrew, pyenv, Go, .NET, Rust, SDKMAN paths
   ├── zshrc_custom.zsh   ← Homebrew PATH priority, tool completions
   └── zprofile_custom.zsh ← iTerm2, SSH agent
```

These files are the "state" of your `install.sh` runs plus any manual additions. They're reproducible by re-running `install.sh` (it's idempotent - it skips blocks that already exist).

### Security Notes

- `install.sh` uses `curl | bash` for nvm and SDKMAN (their official install methods). Review the scripts before accepting if this concerns you.
- `setup.sh` generates your `gitconfig` from user input - it's never committed.
- `global_gitignore` is symlinked as your global gitignore across all repos.

## External References

- [ZSH Manual](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh Wiki](https://github.com/ohmyzsh/ohmyzsh/wiki)
