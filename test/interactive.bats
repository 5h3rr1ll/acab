#!/usr/bin/env bats
# Interactive paths, driven by the fzf stub in test/stubs/fzf.

bats_require_minimum_version 1.5.0

setup() {
    ACAB="${ACAB_UNDER_TEST:-$BATS_TEST_DIRNAME/../acab}"
    export AWS_CONFIG_DIR="$BATS_TEST_DIRNAME/fixtures/aws"
    export NO_COLOR=1
    REAL_FZF="$(command -v fzf)"
    export REAL_FZF
    export PATH="$BATS_TEST_DIRNAME/stubs:$PATH"
    export FZF_STUB_PREVIEW_OUT="$BATS_TEST_TMPDIR/preview"
}

@test "picker preview shows the selected profile's section" {
    export FZF_STUB_PICK="prod (444455556666)"
    run --separate-stderr "$ACAB" work
    [ "$status" -eq 0 ]
    [[ "$stderr" != *"readonly"* ]]
    grep -q "sso_role_name = ReadOnly" "$FZF_STUB_PREVIEW_OUT"
}

@test "picking 'name (account)' exports just the name" {
    export FZF_STUB_PICK="dev (111122223333)"
    run --separate-stderr "$ACAB" work
    eval "$output"
    [ "$AWS_PROFILE" = "dev" ]
}

@test "fully interactive: config, then profile" {
    export FZF_STUB_PICKS="config-work,prod-admin" FZF_STUB_STATE="$BATS_TEST_TMPDIR/n"
    run --separate-stderr "$ACAB"
    [ "$status" -eq 0 ]
    eval "$output"
    [ "$AWS_CONFIG_FILE" = "$AWS_CONFIG_DIR/config-work" ]
    [ "$AWS_PROFILE" = "prod-admin" ]
}

@test "cancelling the picker exports nothing" {
    export FZF_STUB_PICK="no-such-line"
    run --separate-stderr "$ACAB" work
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "messages show paths under HOME with ~" {
    export HOME="$BATS_TEST_DIRNAME/fixtures"
    run --separate-stderr "$ACAB" work dev
    [[ "$stderr" == *"AWS_CONFIG_FILE=~/aws/config-work"* ]]
}
