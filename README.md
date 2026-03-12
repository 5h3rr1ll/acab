# ACAB – All Configs Are Beautiful

Switch between AWS config files and profiles using fzf. Supports multiple `config*` files in `~/.aws/`.

## Quick Start

```bash
# Clone and setup
# Use 755 (not just +x) - bash scripts need read permission to be interpreted
chmod 755 acab

# Add function to ~/.bashrc or ~/.zshrc
acab() {
    eval "$(/path/to/acab/acab "$@")"
}

# Optional: Enable shell completion (zsh only)
source /path/to/acab/completion.zsh

# At the END of ~/.zshrc (after all other tools):
autoload -Uz compinit && compinit
compdef _acab_completion acab 2>/dev/null

# Use it
acab                        # Interactive: select config and profile
acab config-work            # Select config, then choose profile
acab config-work prod       # Direct: set both immediately

# With completion enabled, use TAB:
acab <TAB>                  # Complete config files
acab config-work <TAB>      # Complete profiles
```

**Requires**: [fzf](https://github.com/junegunn/fzf)

## Shell Completion (zsh only)

The `completion.zsh` script provides TAB completion for zsh:

```bash
# Source in ~/.zshrc
source /path/to/acab/completion.zsh

# IMPORTANT: Add at the END of your shell config file (after all other tools)
autoload -Uz compinit && compinit
compdef _acab_completion acab 2>/dev/null

# Now you get completion:
acab <TAB>                  # List/complete config files
acab config-work <TAB>      # List/complete profiles from config-work
```

**Note**: If using other tools (Amazon Q, Oh My Zsh, etc.), the explicit registration must be at the very end to avoid being overridden.

## Usage

```bash
acab                    # Interactive mode
acab <config>           # Select config, fuzzy-find profile
acab <config> <profile> # Direct mode with fuzzy fallback
```

The tool:
- Scans `~/.aws/` for files matching `config*`
- Extracts profiles from `[profile name]` and `[default]` sections
- Sets `AWS_CONFIG_FILE` and `AWS_PROFILE` environment variables

## Example Setup

```
~/.aws/
├── config          # Personal account
├── config-work     # Work account
└── config-client   # Client account
```

```bash
$ acab config-work prod
✓ AWS configuration updated:
  Config file: config-work
  Profile: prod
```

---

