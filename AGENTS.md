# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor, Copilot, …) and humans
working on acab. `CLAUDE.md` only imports this file — edit here.

## What acab is

A single bash script that switches between multiple AWS config files
(`~/.aws/config*`) and profiles using fzf. It prints `export` lines that a shell
function `eval`s, so `AWS_CONFIG_FILE` and `AWS_PROFILE` change in the user's
current shell.

## Layout

| Path | Purpose |
|---|---|
| `acab` | The whole tool. Bash, no build step. |
| `install.sh` | Symlinks `acab` into `~/.local/bin`, opt-in rc line, `--uninstall`. |
| `test/*.bats` | bats-core tests. `test/fixtures/aws/` holds fake AWS configs. |
| `test/stubs/fzf` | fzf stand-in so `test/interactive.bats` can drive pickers and previews. |
| `docs/demo.tape` | vhs script that renders `docs/demo.gif` (uses `docs/demo-aws/`, fake data). |
| `.github/workflows/ci.yml` | shellcheck + bats on macOS (bash 3.2) and Ubuntu (bash 5). |

## Hard rules

1. **stdout is only shell code.** Anything on stdout gets `eval`'d by the wrapper.
   Help, version, messages, warnings, errors → stderr. The only stdout producers are
   `emit_exports`, `init_shell` and the internal `__list-*` / `__preview` helpers.
2. **Quote everything that reaches eval with `printf %q`.** Profile names come
   from files and are untrusted.
3. **bash 3.2 compatible.** macOS ships it. No associative arrays, `mapfile`,
   `${var,,}`, `|&`, negative array indexes or `declare -n`.
4. **One parser.** Profile parsing lives in `profiles_tsv()`; everything (picker,
   lookup, completion via `acab __list-profiles`) goes through it. Only
   `[default]` and `[profile X]` are profiles.
5. **No interactive fzf when nobody can answer.** Use `pick_one`; it fails with a
   list of candidates when stdin/stderr are not a terminal.
6. **Never read the real `~/.aws` in tests or demos.** Use `AWS_CONFIG_DIR` with
   fixtures. Account IDs in fixtures are fake (`111122223333` style).

## Workflow

```bash
bats test/                 # all tests (must pass)
shellcheck acab install.sh # must be clean
./acab init zsh | zsh -n   # integration output must parse
```

- Bug fix or feature → write the failing bats test first, then the fix.
- New CLI flag → update `usage()`, `README.md`, and `CHANGELOG.md` (Unreleased).
- Release: bump `VERSION` in `acab`, move Unreleased in `CHANGELOG.md`, tag
  `vX.Y.Z`, then update `url`/`sha256` in the Homebrew formula
  (`5h3rr1ll/homebrew-tap`, `Formula/acab.rb`).
- Regenerate the GIF after UI changes: `vhs docs/demo.tape`.

## Not covered by tests

The real fzf UI (layout, keys). The stub covers picker logic and runs the preview
command, but look at it by hand after touching `select_*`:
`AWS_CONFIG_DIR=test/fixtures/aws ./acab`.
