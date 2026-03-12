# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for macOS/Linux development environments. It uses a **symlink-based approach** where configuration files are tracked in this repo and symlinked to `~/.{filename}`.

## Key Commands

```bash
# Full setup on a new machine
./install.sh                          # Interactive mode (prompts for each tool)
./install.sh --profile minimal        # Use built-in profile
./install.sh --config dotfiles.conf   # Use custom config file
./install.sh --dry-run --profile full # Preview what would be installed
./setup.sh                            # Create symlinks to home directory
./setup.sh -f                         # Overwrite existing symlinks
source ~/.zshrc                       # Reload shell configuration

# Run unit tests
bats tests/test_*.bats
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
| `lib/config.sh` | CLI argument parsing (`--config`, `--profile`, `--dry-run`) and config loading |
| `lib/profiles.sh` | Built-in profiles: minimal, backend, full (cumulative inheritance) |
| `lib/registry.sh` | Tool registry: `register_tool()`, `is_tool_enabled()`, `run_registry()` |
| `dotfiles.conf.example` | Example config with all `INSTALL_*` variables |
| `tests/` | bats-core unit tests for zutils.zsh, profiles, and registry |

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

### Install Architecture

`install.sh` supports three modes:
1. **Interactive** (default): each tool prompts via `ask_for_confirmation`
2. **Config-driven** (`--config` or `--profile`): tool registry pattern with `INSTALL_*` variables
3. **Auto-config**: if `dotfiles.conf` exists in repo root, uses it automatically

In config-driven mode, `register_all_tools()` in `install.sh` registers all tools with the registry. Each tool has: key (maps to `INSTALL_KEY`), install function, description, URL, dependencies, and platform. `run_registry()` iterates and runs enabled tools.

To add a new tool:
1. Write the install function in `install.sh`
2. Add `register_tool` call in `register_all_tools()`
3. Add `INSTALL_*` variable to `lib/profiles.sh` (`_reset_all_install_vars` + relevant profiles)
4. Add to `dotfiles.conf.example`

## Environment Variables

- `DOTFILES_DRY_RUN=true` - Preview config blocks without installing (also via `--dry-run` flag)
- `DOTFILES_CI=true` - Non-interactive mode: auto-accepts all prompts, skips GUI apps
- `DOTFILES_NON_INTERACTIVE=true` - Auto-accept prompts (set automatically in config-driven mode)
- `ZSH_PROFILE=true` - Enable zsh startup profiling (run `ZSH_PROFILE=true zsh -i -c ''`)

## Cross-Platform Patterns

- Use `${HOMEBREW_PREFIX}` for Homebrew paths (set by `brew shellenv`)
- Use `${HOMEBREW_PREFIX}/opt/<formula>` for version-agnostic paths (symlinks to active version)
- Use `brew pin <formula>` to prevent auto-upgrades when version stability is needed
- Platform detection: `is_macos`, `is_apple_silicon`, `is_intel` functions in `zutils.zsh`
- macOS Homebrew: `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel)
- Linux Homebrew: `/home/linuxbrew/.linuxbrew`
