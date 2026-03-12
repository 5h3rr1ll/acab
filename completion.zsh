#!/usr/bin/env zsh
#
# ACAB - Shell completion for zsh
#
# Source this file in your ~/.zshrc:
#   source /path/to/acab/completion.zsh

# Only run in zsh
[[ -n "${ZSH_VERSION-}" ]] || return 0

# Initialize zsh completion system if not already done
if ! type compdef &>/dev/null; then
    autoload -Uz compinit
    compinit
fi

# Configuration
_acab_aws_dir="${AWS_CONFIG_DIR:-$HOME/.aws}"

# Get list of config files
_acab_list_configs() {
    find "$_acab_aws_dir" -maxdepth 1 -type f -name "config*" 2>/dev/null | \
        xargs -n1 basename 2>/dev/null | \
        sort -u
}

# Get list of profiles from a config file
_acab_list_profiles() {
    local config_file="$1"
    local config_path

    # Resolve full path
    if [[ -f "$config_file" ]]; then
        config_path="$config_file"
    elif [[ -f "$_acab_aws_dir/$config_file" ]]; then
        config_path="$_acab_aws_dir/$config_file"
    else
        return 1
    fi

    # Extract profiles (without account IDs for performance)
    grep -E '^\[' "$config_path" 2>/dev/null | \
        sed -E 's/^\[(profile )?([^]]+)\]/\2/' | \
        sort -u
}

# Main completion function
_acab_completion() {
    local -a configs profiles
    local state

    _arguments -C \
        '1:config file:->configs' \
        '2:profile:->profiles' \
        && return 0

    case $state in
        configs)
            # If fzf is available, use it for interactive selection
            if command -v fzf &>/dev/null && [[ -t 0 ]]; then
                configs=(${(@f)"$(_acab_list_configs)"})
                _describe 'AWS config files' configs
            else
                configs=(${(@f)"$(_acab_list_configs)"})
                _describe 'AWS config files' configs
            fi
            ;;
        profiles)
            if [[ -n "${words[2]}" ]]; then
                profiles=(${(@f)"$(_acab_list_profiles "${words[2]}")"})
                _describe 'AWS profiles' profiles
            fi
            ;;
    esac
}

# Register the completion function
compdef _acab_completion acab
