# acab — All Configs Are Beautiful

[![CI](https://github.com/5h3rr1ll/acab/actions/workflows/ci.yml/badge.svg)](https://github.com/5h3rr1ll/acab/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Switch between multiple AWS config files *and* their profiles in one fuzzy command, and find any profile by its account ID.**

![acab demo](docs/demo.gif)

Most AWS profile switchers assume one `~/.aws/config`. If you keep one config
file per company, client or organization (`config-work`, `config-client`, …),
acab lets you pick the file and the profile together, and sets
`AWS_CONFIG_FILE` + `AWS_PROFILE` in your current shell.

- Fuzzy picking with [fzf](https://github.com/junegunn/fzf), with a preview of each profile
- Search by **account ID** (`acab work 4444`), from `sso_account_id` or `role_arn`
- Direct mode for scripts and muscle memory: `acab work prod`
- TAB completion for zsh and bash
- One bash file, no runtime besides bash 3.2+ and fzf. Doesn't touch credentials.

## Install

**Homebrew** (macOS / Linux):

```bash
brew install 5h3rr1ll/tap/acab
```

**From source:**

```bash
git clone https://github.com/5h3rr1ll/acab.git ~/.acab
~/.acab/install.sh        # links acab into ~/.local/bin, asks before editing your rc file
```

Needs [fzf](https://github.com/junegunn/fzf#installation) (`brew install fzf`, `apt install fzf`, …).

### Shell setup (one line)

acab runs as a child process, which can't change your shell's environment.
A small shell function `eval`s acab's output instead. Add this to your rc file
(`install.sh` does it for you if you say yes):

```bash
# ~/.zshrc  (after compinit / Oh My Zsh, so TAB completion registers)
eval "$(acab init zsh)"

# ~/.bashrc
eval "$(acab init bash)"
```

## Usage

```bash
acab                        # pick a config file, then a profile
acab work                   # ~/.aws/config-work → pick a profile
acab work prod              # set it directly (fuzzy fallback: `acab work prd` works too)
acab work 444455556666      # pick the profile by account ID (partial IDs work)
acab <TAB>                  # complete config files; `acab work <TAB>` completes profiles
```

Config names resolve as: full path → `~/.aws/<name>` → `~/.aws/config-<name>` → fuzzy match.
If a fuzzy match is ambiguous, acab asks (or fails with the candidates when nobody can answer).

Example layout:

```
~/.aws/
├── config          # personal
├── config-work     # employer, SSO
└── config-client   # client, role_arn profiles
```

Only `[default]` and `[profile …]` sections count as profiles; `[sso-session …]`
and `[services …]` are skipped.

### Options & environment

| | |
|---|---|
| `acab init zsh\|bash` | Print the shell integration |
| `acab -V`, `--version` | Show the version |
| `acab -h`, `--help` | Show help |
| `AWS_CONFIG_DIR` | Where to look for `config*` files (default `~/.aws`) |
| `NO_COLOR` | Disable colors |

## Upgrading from the old setup

If your rc file has the old `acab() { eval "$(/path/to/acab "$@")"; }` function
plus `source …/completion.zsh` and `compdef _acab_completion acab`, it keeps working.
To simplify, replace all of it with `eval "$(acab init zsh)"`.

## Uninstall

```bash
brew uninstall acab                 # Homebrew
~/.acab/install.sh --uninstall      # from source (asks before editing your rc file)
```

## How it compares

[granted](https://github.com/common-fate/granted), [awsume](https://github.com/trek10inc/awsume)
and [aws-vault](https://github.com/99designs/aws-vault) handle credentials and role
assumption, and are great at it. acab does one smaller thing: choose among **several
config files** and their profiles quickly. It works alongside them, e.g. `acab work prod && aws sso login`.

## Contributing

Issues and PRs are welcome. Working on the code, with or without an AI agent?
Read [AGENTS.md](AGENTS.md) first: it has the rules (stdout is eval'd; bash 3.2) and the test commands.

```bash
bats test/ && shellcheck acab install.sh
```

## License

[MIT](LICENSE)
