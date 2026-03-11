# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for macOS/Linux development environments. It uses a **symlink-based approach** where configuration files are tracked in this repo and symlinked to `~/.{filename}`.

## Key Commands

```bash
# Full setup on a new machine
./install.sh    # Install tools (Homebrew, Oh My Zsh, pyenv, nvm, Go, Rust, etc.)
./setup.sh      # Create symlinks to home directory

# Setup with force overwrite
./setup.sh -f   # Overwrite existing symlinks

# After changes
source ~/.zshrc # Reload shell configuration
```

## Architecture

### Shell Configuration Loading Order

ZSH loads files in this order: `zshenv` → `zprofile` → `zshrc`

- **zshenv**: Environment variables needed by all shells (PATH, PYENV_ROOT, etc.)
- **zprofile**: Login shell setup (loaded once on login, rarely used in modern terminals)
- **zshrc**: Interactive shell config (Oh My Zsh, plugins, theme, key bindings)

### Core Files

| File | Purpose |
|------|---------|
| `zutils.zsh` | Utility library: ANSI colors, `print_*` functions, `source_if_exists`, `add_to_path`, system detection |
| `aliases.zsh` | Command shortcuts organized by category |
| `julianmateu.zsh-theme` | Custom ZSH theme with vim mode indicator, git status, kubecontext |

### Customization Layer (gitignored)

Machine-specific configs go in `*_custom.zsh` files which are:
- Created by `install.sh` with the safeload pattern
- Symlinked by `setup.sh`
- Sourced by their non-custom counterparts
- Never committed (gitignored)

Files: `zshrc_custom.zsh`, `zshenv_custom.zsh`, `zprofile_custom.zsh`, `aliases_custom.zsh`

### Safeload Pattern

All config files use error-checked sourcing:
```bash
source "${HOME}/.zutils.zsh" || {
    echo "Failed to load zutils.zsh" >&2
    return 1
}
```

### Key Utility Functions (zutils.zsh)

- `source_if_exists <path>` - Safely source a file if it exists
- `add_to_path <dir>` - Add directory to PATH if not already present (errors if missing)
- `add_to_path_if_exists <dir>` - Add to PATH if directory exists, silently skip otherwise
- `append_lines_to_file_if_not_there <lines> <file>` - Idempotent file appending
- `ask_for_confirmation <desc> <url> <cmd...>` - Interactive install prompts
- `colorize <text> <color> [style...]` - Terminal color output
- `print_info/warning/error/success/debug` - Colored output helpers
- `is_macos`, `is_apple_silicon`, `is_intel` - System detection

## Important Notes

- `sed` is aliased to `gsed` (GNU sed) - use this when writing shell scripts
- Neovim config is in a separate repo: https://github.com/julianmateu/nvim-config
- Scripts use `set -e -o pipefail` for fail-fast behavior
- The `${0%/*}` pattern extracts the script's directory for relative sourcing

## Environment Variables

- `DOTFILES_DRY_RUN=true` - Preview config blocks without installing (also via `--dry-run` flag)
- `DOTFILES_CI=true` - Non-interactive mode: auto-accepts all prompts, skips GUI apps
- `ZSH_PROFILE=true` - Enable zsh startup profiling (run `ZSH_PROFILE=true zsh -i -c ''`)

## Cross-Platform Patterns

- Use `${HOMEBREW_PREFIX}` for Homebrew paths (set by `brew shellenv`)
- Use `${HOMEBREW_PREFIX}/opt/<formula>` for version-agnostic paths (symlinks to active version)
- Use `brew pin <formula>` to prevent auto-upgrades when version stability is needed
- Platform detection: `is_macos`, `is_apple_silicon`, `is_intel` functions in `zutils.zsh`
- macOS Homebrew: `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel)
- Linux Homebrew: `/home/linuxbrew/.linuxbrew`
