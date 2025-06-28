###############################################################
# ZSH Utilities and ANSI Color Management
# =======================================
# This file provides utility functions for dotfiles management
# and centralized ANSI escape code handling.
#
# SAFELOAD PATTERN
# ----------------
# To safely load this file in other "dotfiles" scripts, automatically sourced in the zshrc, use:
#   source "${HOME}/.zutils.zsh" || { echo "Failed to load zutils.zsh" >&2; exit 1; }
#
# To safely load this file in other setup scripts, meant to be run from this repo, use:
#   source "${0%/*}/zutils.zsh" || { echo "Failed to load zutils.zsh" >&2; exit 1; }
#
# Where ${0%/*} is parameter expansion that removes the shortest match
# of "/*" from the end of $0 (script name), giving us the script's directory.
# See: bash manual "Parameter Expansion" section
###############################################################

# This pattern would avoid multiple imports. However this might be required for scripts to work, so it's commented.
#[[ "${ZUTILS_SOURCED+x}" ]] && return 0
#export ZUTILS_SOURCED=true

# If this variable is set, the print_debug function will print output.
# export PRINT_DEBUG_ZSH=true

###############################################################
# ANSI Escape Codes and SGR Color Utilities
# -----------------------------------------
# This section provides general-purpose functions and variables
# for generating ANSI escape codes and colorizing text in the terminal.
#
# References:
#   - https://en.wikipedia.org/wiki/ANSI_escape_code
#   - https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
#
# Usage examples:
#   echo "$(colorize 'Success!' green)"
#   echo "$(colorize 'Warning!' yellow bold)"
#   echo "$(sgr 31 1)Error!$(sgr 0)"  # Red + bold, then reset
#
###############################################################

# The ESC character (octal 033, hex 0x1B)
# This is the ASCII escape character that starts all ANSI escape sequences
# $'\033' is ANSI-C quoting that expands to the escape character
ESC=$'\033'
# Control Sequence Introducer - the "[" character that follows ESC in ANSI sequences
CSI="["

# SGR (Select Graphic Rendition) color codes
# See: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
# Usage: get_sgr_color green yields 32
# Note: Using function-based approach for bash/zsh compatibility
get_sgr_color() {
    local color_name="${1}"
    case "${color_name}" in
        black) echo "30" ;;
        red) echo "31" ;;
        green) echo "32" ;;
        yellow) echo "33" ;;
        blue) echo "34" ;;
        magenta) echo "35" ;;
        cyan) echo "36" ;;
        white) echo "37" ;;
        reset) echo "0" ;;
        bold) echo "1" ;;
        underline) echo "4" ;;
        *) echo "${color_name}" ;;  # Return as-is if not recognized
    esac
}

# Generates an ANSI escape code for the given SGR effects
# Usage: sgr 32 1  # green + bold
# Parameters: Variable number of SGR codes to combine
# Returns: ANSI escape sequence string
# Note: printf with %s%sm format: ESC + CSI + codes + 'm'
sgr() {
  local codes=("${@}")
  # "${codes[*]}" - expands array elements joined by first character of IFS (space by default)
  printf "%s%sm" "${ESC}${CSI}" "${codes[*]}"
}

# Colorizes text with the given color name(s)
# Usage: colorize "hello" green bold
# Parameters: $1 = text to colorize, $2+ = color names or SGR codes
# Returns: Colorized text with reset at the end
# Note: Uses get_sgr_color function for bash/zsh compatibility
colorize() {
  local text="${1}"; shift
  local codes=()
  for name in "${@}"; do
    # Use get_sgr_color function to get the SGR code for the color name
    codes+=("$(get_sgr_color "${name}")")
  done
  printf "%s%s%s" "$(sgr ${codes[*]})" "${text}" "$(sgr $(get_sgr_color reset))"
}

###############################################################
# => File and Source Management
###############################################################

# source_if_exists - Safely source a file if it exists
# Usage: source_if_exists <file_path>
# Parameters:
#   $1 - Path to the file to source
# Returns: 0 if file exists and was sourced, 1 if file doesn't exist
# Note: -f checks if file exists and is a regular file
#       -r checks if file exists and is readable
#       We use -f here since we want to source regular files only
source_if_exists() {
    local file_path="${1}"
    if [[ -z "${file_path}" ]]; then
        print_error "source_if_exists: No file path provided"
        return 1
    fi
    if [[ -f "${file_path}" ]]; then
        source "${file_path}"
        return 0
    else
        return 1
    fi
}

# append_lines_to_file_if_not_there - Append lines to file if not already present
# Usage: append_lines_to_file_if_not_there <lines> <file_path>
# Parameters:
#   $1 - Lines to append (can be multiline)
#   $2 - Target file path
# Returns: 0 on success, 2 on parameter error
# Note: This function preserves existing content and checks for entire blocks
#       Uses process substitution < <(command) to feed command output to while loop
#       Checks if the entire block exists before adding to prevent missing structural elements
append_lines_to_file_if_not_there() {
    if [[ "${#}" -ne 2 ]]; then
        print_error "append_lines_to_file_if_not_there: Illegal number of parameters ${0}: got ${#} but expected 2: ${*}"
        return 2
    fi
    local lines="${1}"
    local file="${2}"
    
    # Create file if it doesn't exist
    [[ ! -f "${file}" ]] && touch "${file}"
    
    # Check if the entire block already exists in the file
    # Use grep with -z to treat the entire file as one string for multiline matching
    # -q=quiet, -F=fixed string (no regex), -z=null-terminated strings
    if grep -qzF "${lines}" "${file}"; then
        print_info "Block already exists in ${file}, skipping"
        return 0
    fi
    
    # If block doesn't exist, append it
    echo "${lines}" >> "${file}"
    print_info "Added block to ${file}"
}

# backup_file - Create backup of existing file
# Usage: backup_file <file_path> [backup_suffix]
# Parameters:
#   $1 - Path to the file to backup
#   $2 - Optional backup suffix (default: .backup)
# Returns: 0 on success, 1 if file doesn't exist
# Note: ${2:-.backup} - parameter expansion with default value
backup_file() {
    local file_path="${1}"
    # ${2:-.backup} - use $2 if provided, otherwise use .backup
    local backup_suffix="${2:-.backup}"
    if [[ ! -e "${file_path}" ]]; then
        return 1
    fi
    local backup_path="${file_path}${backup_suffix}"
    mv "${file_path}" "${backup_path}"
    print_info "Backed up ${file_path} to ${backup_path}"
    return 0
}

# create_symlink - Create symbolic link with backup
# Usage: create_symlink <source> <target> [force]
# Parameters:
#   $1 - Source file/directory
#   $2 - Target location for symlink
#   $3 - Force flag (optional, any non-empty value)
# Returns: 0 on success, 1 on error
# Note: -L tests if path is a symbolic link
create_symlink() {
    local source="${1}"
    local target="${2}"
    local force="${3}"
    if [[ ! -e "${source}" ]]; then
        print_error "create_symlink: Source does not exist: ${source}"
        return 1
    fi
    # If target exists and is not a symlink, backup it
    if [[ -e "${target}" ]] && [[ ! -L "${target}" ]]; then
        backup_file "${target}"
    fi
    # Remove existing symlink if force is specified
    if [[ -n "${force}" ]] && [[ -L "${target}" ]]; then
        rm "${target}"
    fi
    # Create symlink if it doesn't exist
    if [[ ! -e "${target}" ]]; then
        ln -s "${source}" "${target}"
        print_success "Created symlink: ${target} -> ${source}"
        return 0
    fi
    return 0
}

###############################################################
# => User Interaction
###############################################################

# ask_for_confirmation - Interactive confirmation prompt
# Usage: ask_for_confirmation <description> <info_url> <command> [args...]
# Parameters:
#   $1 - Description of what will be installed/configured
#   $2 - URL for more information
#   $3+ - Command and arguments to execute if confirmed
# Returns: 0 if confirmed and executed, 2 on parameter error
# Note: Uses regex matching to validate user input
ask_for_confirmation() {
    if [[ "${#}" -le 2 ]]; then
        print_error "ask_for_confirmation: Illegal number of parameters ${0}: got ${#} but expected at least 3: ${*}"
        return 2
    fi
    local description="${1}"
    local info_url="${2}"
    shift 2
    local command_args=("${@}")
    echo
    print_info "Trying to install ${description}..."
    echo -e " This will run: $(colorize "$(fmt_code "${command_args[*]}")" yellow)"
    echo -e " See $(fmt_underline "${info_url}")"
    
    # Loop until valid input is received
    while true; do
        print_info "Do you want to install ${description}? [y/n]"
        read -p "" -n 1 -r REPLY
        echo
        if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
            "${command_args[@]}"
            break
        elif [[ "${REPLY}" =~ ^[Nn]$ ]]; then
            print_info "Skipping ${description}"
            break
        else
            print_error "Invalid input. Please enter 'y' or 'n'."
        fi
    done
}

###############################################################
# => Output Formatting
###############################################################

# print_warning - Print colored warning message
# Usage: print_warning <message>
# Note: $* expands to all positional parameters as a single string
print_warning() {
    echo -e "$(colorize "$*" yellow)"
}

# print_success - Print colored success message
# Usage: print_success <message>
print_success() {
    echo -e "$(colorize "$*" green)"
}

# print_error - Print colored error message
# Usage: print_error <message>
print_error() {
    echo -e "$(colorize "$*" red)"
}

# print_info - Print colored info message
# Usage: print_info <message>
print_info() {
    echo -e "$(colorize "$*" blue)"
}

# print_debug - Print the message only if the DEBUG env variable is set
# Usage: print_debug <message>
print_debug() {
  # ${var+x} is a parameter expansion which evaluates to nothing if var is unset,
  # and substitutes the string x otherwise.
  if [[ "${PRINT_DEBUG_ZSH+x}" ]]; then
    print_info "$*"
  fi
}

# fmt_code - Format text as code with colors (gray)
# Usage: fmt_code <text>
# Note: 38;5;247 is a gray color in 256-color mode
#       \; escapes the semicolon in the sgr function
fmt_code() {
    printf '`%s%s%s`\n' "$(sgr 38\;5\;247)" "$*" "$(sgr 0)"
}

# fmt_underline - Format text with underline
# Usage: fmt_underline <text>
# Note: 24 is the SGR code to turn off underline
fmt_underline() {
    printf '%s%s%s\n' "$(sgr $(get_sgr_color underline))" "$*" "$(sgr 24)$(sgr 0)"
}

###############################################################
# => System Detection
###############################################################

# is_macos - Check if running on macOS
# Usage: is_macos
# Returns: 0 if macOS, 1 otherwise
# Note: uname returns "Darwin" on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# get_architecture - Get system architecture
# Usage: get_architecture
# Returns: Architecture string (arm64, x86_64, etc.)
get_architecture() {
    uname -m
}

# is_apple_silicon - Check if running on Apple Silicon
# Usage: is_apple_silicon
# Returns: 0 if Apple Silicon, 1 otherwise
# Note: uname -m returns "arm64" on Apple Silicon Macs
is_apple_silicon() {
    [[ "$(get_architecture)" == "arm64" ]]
}

# is_intel - Check if running on Intel Mac
# Usage: is_intel
# Returns: 0 if Intel, 1 otherwise
# Note: uname -m returns "x86_64" on Intel Macs
is_intel() {
    [[ "$(get_architecture)" == "x86_64" ]]
}

# get_macos_version - Get macOS version
# Usage: get_macos_version
# Returns: macOS version string (e.g., "13.0")
# Note: sw_vers is a macOS-specific command
get_macos_version() {
    if is_macos; then
        sw_vers -productVersion
    else
        echo "not_macos"
    fi
}

###############################################################
# => Validation Functions
###############################################################

# is_command_available - Check if a command is available
# Usage: is_command_available <command>
# Parameters:
#   $1 - Command to check
# Returns: 0 if command exists, 1 otherwise
# Note: command -v is POSIX compliant, unlike which
#       >/dev/null 2>&1 redirects both stdout and stderr to /dev/null
is_command_available() {
    local command="${1}"
    command -v "${command}" >/dev/null 2>&1
}

# is_file_readable - Check if file exists and is readable
# Usage: is_file_readable <file_path>
# Parameters:
#   $1 - File path to check
# Returns: 0 if file is readable, 1 otherwise
# Note: -r tests if file exists and is readable by current user
is_file_readable() {
    local file_path="${1}"
    [[ -r "${file_path}" ]]
}

# is_directory - Check if path is a directory
# Usage: is_directory <path>
# Parameters:
#   $1 - Path to check
# Returns: 0 if directory exists, 1 otherwise
# Note: -d tests if path exists and is a directory
is_directory() {
    local path="${1}"
    [[ -d "${path}" ]]
}

###############################################################
# => Path Management
###############################################################

# add_to_path - Add directory to PATH if not already present
# Usage: add_to_path <directory>
# Parameters:
#   $1 - Directory to add to PATH
# Returns: 0 on success, 1 if directory doesn't exist
# Note: Uses parameter expansion to check if directory is already in PATH
#       [[ ":$PATH:" != *":$directory:"* ]] - pattern matching with wildcards
add_to_path() {
    local directory="${1}"
    if [[ ! -d "${directory}" ]]; then
        print_error "add_to_path: Directory does not exist: ${directory}"
        return 1
    fi
    # [[ ":$PATH:" != *":$directory:"* ]] - check if directory is not already in PATH
    # * is a wildcard that matches any sequence of characters
    # The colons ensure we match complete path components, not partial matches
    if [[ ":${PATH}:" != *":${directory}:"* ]]; then
        export PATH="${directory}:${PATH}"
        print_debug "Added ${directory} to PATH"
    fi
    return 0
}

# remove_from_path - Remove directory from PATH
# Usage: remove_from_path <directory>
# Parameters:
#   $1 - Directory to remove from PATH
# Returns: 0 on success
# Note: Uses sed to remove directory from PATH, handling both start and middle positions
#       sed -E enables extended regex syntax
remove_from_path() {
    local directory="${1}"
    # sed -E "s|:$directory||g" - remove directory when it's in the middle
    # sed -E "s|^$directory:||g" - remove directory when it's at the start
    # | is used as delimiter instead of / to avoid conflicts with path separators
    export PATH=$(echo "${PATH}" | sed -E "s|:${directory}||g" | sed -E "s|^${directory}:||g")
    print_info "Removed ${directory} from PATH"
    return 0
}

###############################################################
# => Package Installation Helpers
###############################################################

# install_packages_with_urls - Install packages with confirmation and URLs
# Usage: install_packages_with_urls <package_array> <install_command>
# Parameters:
#   $1 - Array name containing packages in "name|url" format
#   $2 - Install command template (e.g., "brew install" or "sudo apt-get install -y")
# Returns: 0 on success
# Note: This function provides a reusable pattern for installing packages with URLs
#       Each package in the array should be in "name|url" format (using | as separator)
#       The install command should use {name} as a placeholder for the package name
install_packages_with_urls() {
    local package_array_name="${1}"
    local install_command_template="${2}"
    
    if [[ "${#}" -ne 2 ]]; then
        print_error "install_packages_with_urls: Illegal number of parameters ${0}: got ${#} but expected 2: ${*}"
        return 2
    fi
    
    # Use indirect expansion to get the array contents
    local -a packages
    eval "packages=(\"\${${package_array_name}[@]}\")"
    
    for package_info in "${packages[@]}"; do
        # Split package_info into name and URL using parameter expansion
        local package_name="${package_info%%|*}"
        local package_url="${package_info#*|}"
        
        # Replace {name} placeholder with actual package name
        local install_command="${install_command_template//\{name\}/${package_name}}"
        # Split the command into an array and pass as separate arguments
        local -a cmd_parts
        read -r -a cmd_parts <<< "${install_command}"
        ask_for_confirmation "${package_name}" "${package_url}" "${cmd_parts[@]}"
    done
} 

print_debug "sourcing zutils.zsh"
