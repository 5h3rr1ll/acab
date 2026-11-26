# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-11-26

First standalone release (previously part of `5h3rr1ll/my_scripts`).

### Added
- `acab init zsh|bash` prints the shell wrapper and TAB completion: setup is one line.
- `acab --version`.
- `install.sh`: symlink into `~/.local/bin`, opt-in rc line, `--uninstall`.
- bash completion (via `acab init bash`).
- Account IDs from `role_arn` when `sso_account_id` is absent.
- `NO_COLOR` support; paths under `$HOME` are shown with `~`.
- bats test suite, shellcheck and CI on macOS (bash 3.2) and Ubuntu (bash 5).

### Fixed
- `[sso-session …]` and `[services …]` sections were listed and accepted as profiles.
- `--help` printed to stdout, so the `eval` wrapper tried to execute it.
- Profile names were single-quoted into `eval`; a crafted name could run code. Now `printf %q`.
- An ambiguous fuzzy match exported several profile names at once; now acab asks (or fails with the candidates).
- fzf preview was empty for `name (account-id)` entries (and failed outright: `ACAB_SELF: readonly variable`).

### Changed
- One awk pass parses a config file (was one awk call per profile).
- fzf is only required when a fuzzy or interactive step needs it.
- `completion.zsh` is kept for existing setups but reads its data from `acab` itself.

## [0.x] - before 2026-11-26

Developed inside `my_scripts`: interactive config/profile picking, account-ID search, zsh completion.

[Unreleased]: https://github.com/5h3rr1ll/acab/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/5h3rr1ll/acab/releases/tag/v1.0.0
