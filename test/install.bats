#!/usr/bin/env bats
# Tests for install.sh — run in a throwaway $HOME, never touch the real one.

setup() {
    INSTALL="$BATS_TEST_DIRNAME/../install.sh"
    export HOME="$BATS_TEST_TMPDIR/home"
    export SHELL=/bin/zsh
    unset ZDOTDIR
    mkdir -p "$HOME"
    PREFIX="$HOME/.local/bin"
}

@test "install links acab and adds the rc line with --yes" {
    run "$INSTALL" --yes
    [ "$status" -eq 0 ]
    [ -L "$PREFIX/acab" ]
    grep -q 'init zsh)"  # acab shell integration' "$HOME/.zshrc"
}

@test "linked acab runs" {
    "$INSTALL" --yes
    run "$PREFIX/acab" --version
    [ "$status" -eq 0 ]
    [[ "$output" == acab\ * ]]
}

@test "install is idempotent (one rc line after two runs)" {
    "$INSTALL" --yes
    "$INSTALL" --yes
    [ "$(grep -c 'acab shell integration' "$HOME/.zshrc")" -eq 1 ]
}

@test "without a terminal and without --yes, rc is left untouched" {
    run "$INSTALL" </dev/null
    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.zshrc" ]
    [[ "$output" == *"Add this line"* ]]
}

@test "refuses to overwrite a regular file at the link path" {
    mkdir -p "$PREFIX" && echo keep > "$PREFIX/acab"
    run "$INSTALL" --yes
    [ "$status" -ne 0 ]
    [ "$(cat "$PREFIX/acab")" = "keep" ]
}

@test "bash users get ~/.bashrc" {
    export SHELL=/bin/bash
    run "$INSTALL" --yes
    grep -q 'init bash)"' "$HOME/.bashrc"
}

@test "uninstall removes link and rc line, keeps other rc content" {
    echo 'export KEEP=1' > "$HOME/.zshrc"
    "$INSTALL" --yes
    run "$INSTALL" --uninstall --yes
    [ "$status" -eq 0 ]
    [ ! -e "$PREFIX/acab" ]
    ! grep -q 'acab shell integration' "$HOME/.zshrc"
    grep -q 'export KEEP=1' "$HOME/.zshrc"
}
