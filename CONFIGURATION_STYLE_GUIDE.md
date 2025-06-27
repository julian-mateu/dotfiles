# Configuration Style Guide

## Overview

This document outlines the configuration patterns and style guidelines used in this dotfiles repository. It provides clear guidance on when to use declarative vs imperative approaches and how to structure different types of configurations.

## Configuration Patterns

### 1. Declarative Configuration

**When to use**: For static configurations that describe the desired state without specifying how to achieve it.

**Examples**:

- ZSH options (`setopt`, `unsetopt`)
- Environment variables
- Aliases
- Theme configurations
- Plugin lists

**Pattern**:

```zsh
# Declarative: Describe what you want
setopt AUTO_CD              # Change directory without cd
setopt EXTENDED_HISTORY     # Record timestamp of command
export EDITOR="vim"         # Set default editor
alias ll='ls -alF'          # Define command shortcut
```

### 2. Imperative Configuration

**When to use**: For dynamic configurations that require runtime decisions or system-specific setup.

**Examples**:

- Conditional loading based on system detection
- Dynamic path construction
- Runtime environment setup
- Interactive user choices

**Pattern**:

```zsh
# Imperative: Specify how to achieve the goal
if [[ -d "/opt/homebrew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
fi
```

### 3. Hybrid Configuration

**When to use**: When you need both declarative and imperative elements, typically for complex setups.

**Examples**:

- Plugin management with conditional loading
- Theme setup with fallbacks
- Tool-specific configurations

**Pattern**:

```zsh
# Hybrid: Declarative structure with imperative logic
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Imperative: Load plugins conditionally
for plugin in "${plugins[@]}"; do
    if [[ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${plugin}/${plugin}.plugin.zsh" ]]; then
        source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${plugin}/${plugin}.plugin.zsh"
    fi
done
```

## File Organization Patterns

### 1. Core Configuration Files

**Purpose**: Essential configurations that should always be loaded.

**Files**:

- `zshrc` - Main ZSH configuration
- `zshenv` - Environment variables
- `zutils.zsh` - Utility functions

**Pattern**:

```zsh
# Load order: zshenv → zutils.zsh → zshrc
# Each file has a single responsibility
# Use safeload pattern for dependencies
```

### 2. Feature-Specific Files

**Purpose**: Group related configurations by functionality.

**Files**:

- `aliases.zsh` - Command shortcuts
- `julianmateu.zsh-theme` - Prompt customization
- `zprofile_custom.zsh` - System-specific setup

**Pattern**:

```zsh
# Each file focuses on one aspect
# Use clear section headers
# Document all non-obvious configurations
```

### 3. Installation and Setup Files

**Purpose**: Scripts for initial setup and maintenance.

**Files**:

- `install.sh` - Initial system setup
- `setup.sh` - Configuration setup

**Pattern**:

```bash
# Use utility functions for consistency
# Implement safeload pattern
# Provide clear error messages
# Support both interactive and automated modes
```

## Style Guidelines

### 1. Documentation Standards

**Required for all configurations**:

- Purpose and effect of each setting
- References to relevant documentation
- Examples of expected behavior
- Warnings about side effects

**Example**:

```zsh
# setopt AUTO_CD - Change directory without typing 'cd'
# See: zsh manual "Changing Directories" section
# Example: typing '/usr/local' changes to that directory
setopt AUTO_CD
```

### 2. Naming Conventions

**Variables**: Use UPPER_CASE for environment variables, camelCase for local variables
**Functions**: Use snake_case for function names
**Files**: Use lowercase with underscores for configuration files

**Example**:

```zsh
# Environment variables (UPPER_CASE)
export EDITOR="vim"
export PATH="/usr/local/bin:$PATH"

# Local variables (camelCase)
local currentDir=$(pwd)
local isGitRepo=$(git rev-parse --git-dir 2>/dev/null)

# Functions (snake_case)
function setup_python_environment() {
    # Function implementation
}
```

### 3. Error Handling

**Pattern**: Fail fast with clear error messages
**Use utility functions**: `print_warning()`, `ask_for_confirmation()`
**Provide recovery instructions**: Tell users how to fix issues

**Example**:

```zsh
# Good: Clear error with recovery instructions
if ! command -v pyenv >/dev/null 2>&1; then
    print_warning "pyenv not found. Install with: brew install pyenv"
    return 1
fi

# Bad: Silent failure
pyenv init --path 2>/dev/null
```

### 4. Conditional Loading

**Pattern**: Check for availability before loading
**Use utility functions**: `is_command_available()`, `is_file_readable()`
**Provide alternatives**: Suggest fallbacks when possible

**Example**:

```zsh
# Check for tool availability
if is_command_available "kubectl"; then
    source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/kubectl/kubectl.plugin.zsh"
else
    print_warning "kubectl not found. Install with: brew install kubectl"
fi
```

## Best Practices

### 1. Performance Considerations

**Lazy Loading**: Load heavy plugins only when needed
**Caching**: Cache expensive operations
**Minimal Dependencies**: Avoid unnecessary external tools

**Example**:

```zsh
# Lazy load nvm to avoid slow startup
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' autoload yes
```

### 2. Portability

**Cross-Platform**: Support both macOS and Linux
**Architecture-Aware**: Handle Intel vs Apple Silicon differences
**Version Compatibility**: Support multiple tool versions

**Example**:

```zsh
# Detect system architecture
if is_apple_silicon; then
    export BREW_PREFIX="/opt/homebrew"
else
    export BREW_PREFIX="/usr/local"
fi
```

### 3. Maintainability

**Modular Design**: Keep configurations focused and independent
**Clear Dependencies**: Document what each file requires
**Version Control**: Track changes and provide migration guides

**Example**:

```zsh
# Document dependencies at the top of each file
# Dependencies: zutils.zsh, oh-my-zsh
# Optional: kubectl, docker, aws-cli
```

## Migration Guidelines

### When Adding New Configurations

1. **Choose the right pattern**: Declarative for static configs, imperative for dynamic ones
2. **Document thoroughly**: Explain purpose, effects, and dependencies
3. **Test thoroughly**: Verify on clean systems
4. **Update this guide**: Add new patterns as they emerge

### When Refactoring Existing Configurations

1. **Preserve functionality**: Ensure no breaking changes
2. **Improve documentation**: Add missing explanations
3. **Follow style guidelines**: Apply consistent patterns
4. **Test compatibility**: Verify with existing setups

## Tools and Utilities

### Required Utilities (from zutils.zsh)

- `source_if_exists()` - Safely source files
- `print_warning()` - Display warnings
- `ask_for_confirmation()` - Interactive confirmations
- `is_macos()`, `is_linux()` - System detection
- `is_command_available()` - Tool availability checks

### Recommended External Tools

- `shellcheck` - Script validation
- `zsh -n` - Syntax checking
- `zprof` - Performance profiling

## Conclusion

This style guide ensures consistency, maintainability, and clarity across all configurations. Follow these patterns to create robust, well-documented, and portable dotfiles that work reliably across different environments.
