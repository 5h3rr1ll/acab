#!/usr/bin/env bash
#
# acab installer — links acab into your PATH and (optionally) adds the
# one-line shell integration to your rc file.
#
#   ./install.sh                  # link to ~/.local/bin, ask before touching rc
#   ./install.sh --yes            # no questions, add the rc line
#   ./install.sh --prefix DIR     # link into DIR instead
#   ./install.sh --uninstall      # remove the link and the rc line
#
# The link points at this checkout, so `git pull` updates acab.
# Using Homebrew? `brew install 5h3rr1ll/tap/acab` instead of this script.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$HOME/.local/bin"
ASSUME_YES=""
ACTION="install"
MARKER="# acab shell integration"

say()  { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die()  { printf 'Error: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)    PREFIX="${2:?--prefix needs a directory}"; shift 2 ;;
        --yes|-y)    ASSUME_YES=1; shift ;;
        --uninstall) ACTION="uninstall"; shift ;;
        -h|--help)   sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)           die "Unknown option: $1 (see --help)" ;;
    esac
done

LINK="$PREFIX/acab"

detect_shell() {
    case "$(basename "${SHELL:-}")" in
        zsh)  echo zsh ;;
        bash) echo bash ;;
        *)    echo "" ;;
    esac
}

rc_file_for() {
    case "$1" in
        zsh)  echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
    esac
}

confirm() {
    [[ -n "$ASSUME_YES" ]] && return 0
    [[ -t 0 ]] || return 1
    local reply
    read -r -p "$1 [y/N] " reply
    [[ "$reply" == [yY]* ]]
}

do_install() {
    command -v fzf >/dev/null 2>&1 ||
        warn "fzf not found — acab needs it for interactive picking. Install: brew install fzf (macOS) or see https://github.com/junegunn/fzf#installation"

    mkdir -p "$PREFIX"
    if [[ -e "$LINK" && ! -L "$LINK" ]]; then
        die "$LINK exists and is not a symlink; refusing to overwrite it."
    fi
    ln -sfn "$SRC_DIR/acab" "$LINK"
    chmod 755 "$SRC_DIR/acab"
    say "✓ Linked $LINK -> $SRC_DIR/acab"

    case ":$PATH:" in
        *":$PREFIX:"*) ;;
        *) warn "$PREFIX is not in your PATH. Add: export PATH=\"$PREFIX:\$PATH\"" ;;
    esac

    local shell rc line
    shell=$(detect_shell)
    if [[ -z "$shell" ]]; then
        say "Add the integration for your shell manually:  eval \"\$(acab init zsh)\"  or  eval \"\$(acab init bash)\""
        return 0
    fi
    rc=$(rc_file_for "$shell")
    line="eval \"\$(\"$LINK\" init $shell)\"  $MARKER"

    if [[ -f "$rc" ]] && grep -qF "$MARKER" "$rc"; then
        say "✓ Shell integration already present in $rc"
    elif confirm "Add acab integration to $rc?"; then
        printf '\n%s\n' "$line" >> "$rc"
        say "✓ Added to $rc (zsh: keep it after compinit / Oh My Zsh for TAB completion)"
    else
        say "Add this line to $rc yourself:"
        say "    $line"
    fi
    say "Open a new shell (or: source $rc), then run: acab"
}

do_uninstall() {
    if [[ -L "$LINK" ]]; then
        rm -f "$LINK"
        say "✓ Removed $LINK"
    else
        say "No acab symlink at $LINK"
    fi

    local shell rc
    for shell in zsh bash; do
        rc=$(rc_file_for "$shell")
        if [[ ! -f "$rc" ]] || ! grep -qF "$MARKER" "$rc"; then continue; fi
        if confirm "Remove the acab line from $rc?"; then
            local tmp
            tmp=$(mktemp)
            grep -vF "$MARKER" "$rc" > "$tmp" || true
            cat "$tmp" > "$rc" && rm -f "$tmp"
            say "✓ Removed integration line from $rc"
        else
            say "Remove the line containing '$MARKER' from $rc yourself."
        fi
    done
}

"do_$ACTION"
