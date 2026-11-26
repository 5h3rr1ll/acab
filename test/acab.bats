#!/usr/bin/env bats
# Tests for acab. Run with: bats test/
# Interactive (fzf UI) paths are not covered; every test here is non-interactive.

bats_require_minimum_version 1.5.0

setup() {
    ACAB="$BATS_TEST_DIRNAME/../acab"
    export AWS_CONFIG_DIR="$BATS_TEST_DIRNAME/fixtures/aws"
    export NO_COLOR=1
}

# --- Contract: stdout is only ever shell code -----------------------------

@test "direct mode prints only export lines on stdout" {
    run --separate-stderr "$ACAB" work dev
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [[ "${lines[0]}" == export\ AWS_CONFIG_FILE=* ]]
    [[ "${lines[1]}" == export\ AWS_PROFILE=* ]]
}

@test "direct mode output evals to the right environment" {
    run --separate-stderr "$ACAB" work dev
    eval "$output"
    [ "$AWS_PROFILE" = "dev" ]
    [ "$AWS_CONFIG_FILE" = "$AWS_CONFIG_DIR/config-work" ]
}

# --- Bug 1: only [default] and [profile X] are profiles -------------------

@test "sso-session sections are not offered as profiles" {
    run --separate-stderr "$ACAB" __list-profiles config-work
    [ "$status" -eq 0 ]
    [[ "$output" != *"sso-session"* ]]
    [[ "$output" != *"services"* ]]
}

@test "profile list contains exactly default, dev, prod, prod-admin" {
    run --separate-stderr "$ACAB" __list-profiles config-work
    [ "$output" = "$(printf 'default\ndev\nprod\nprod-admin')" ]
}

@test "an sso-session name is rejected as a profile" {
    run --separate-stderr "$ACAB" work "sso-session corp"
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

# --- Bug 2: help never reaches stdout (it would be eval'd) ----------------

@test "--help prints to stderr, nothing to stdout" {
    run --separate-stderr "$ACAB" --help
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [[ "$stderr" == *"Usage:"* ]]
}

@test "-h prints to stderr, nothing to stdout" {
    run --separate-stderr "$ACAB" -h
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- Bug 3: profile names cannot inject code through eval -----------------

@test "malicious profile name is quoted, not executed" {
    export ACAB_PWNED="$BATS_TEST_TMPDIR/pwned"
    local evil="x'; touch \"\$ACAB_PWNED\"; '"
    run --separate-stderr "$ACAB" evil "$evil"
    [ "$status" -eq 0 ]
    eval "$output"
    [ ! -e "$ACAB_PWNED" ]
    [ "$AWS_PROFILE" = "$evil" ]
}

# --- Lookup behaviour ------------------------------------------------------

@test "unique account ID resolves to its profile" {
    run --separate-stderr "$ACAB" work 111122223333
    [ "$status" -eq 0 ]
    eval "$output"
    [ "$AWS_PROFILE" = "dev" ]
}

@test "composite 'name (account)' input is accepted" {
    run --separate-stderr "$ACAB" work "dev (111122223333)"
    eval "$output"
    [ "$AWS_PROFILE" = "dev" ]
}

@test "ambiguous fuzzy profile match fails non-interactively instead of exporting several names" {
    run --separate-stderr "$ACAB" work pro </dev/null
    [ "$status" -ne 0 ]
    [ -z "$output" ]
    [[ "$stderr" == *"prod-admin"* ]]
}

@test "unique fuzzy profile match is accepted" {
    run --separate-stderr "$ACAB" work adm </dev/null
    [ "$status" -eq 0 ]
    eval "$output"
    [ "$AWS_PROFILE" = "prod-admin" ]
}

@test "role_arn account ID is used when sso_account_id is absent" {
    run --separate-stderr "$ACAB" __list-profiles config-roles --accounts
    [ "$output" = "assumed (999988887777)" ]
}

@test "unknown profile fails with no stdout" {
    run --separate-stderr "$ACAB" work does-not-exist
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "unknown config fails with no stdout" {
    run --separate-stderr "$ACAB" nope dev
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}

@test "too many arguments fails" {
    run --separate-stderr "$ACAB" a b c
    [ "$status" -ne 0 ]
}

# --- Completion helpers ----------------------------------------------------

@test "__list-configs lists config file basenames" {
    run --separate-stderr "$ACAB" __list-configs
    [ "$output" = "$(printf 'config\nconfig-evil\nconfig-roles\nconfig-work')" ]
}

@test "__list-profiles shows account IDs with --accounts" {
    run --separate-stderr "$ACAB" __list-profiles config-work --accounts
    [[ "$output" == *"dev (111122223333)"* ]]
    [[ "$output" == *"default"* ]]
}

@test "__preview prints the profile section for a composite entry" {
    run --separate-stderr "$ACAB" __preview "$AWS_CONFIG_DIR/config-work" "prod (444455556666)"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sso_role_name = ReadOnly"* ]]
    [[ "$output" != *"prod-admin"* ]]
}

# --- Version & init --------------------------------------------------------

@test "--version prints the version on stderr" {
    run --separate-stderr "$ACAB" --version
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [[ "$stderr" =~ ^acab\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "init zsh emits a wrapper function and completion" {
    run --separate-stderr "$ACAB" init zsh
    [ "$status" -eq 0 ]
    [[ "$output" == *"acab()"* ]]
    [[ "$output" == *"compdef"* ]]
}

@test "init bash emits valid bash that defines acab" {
    run --separate-stderr "$ACAB" init bash
    [ "$status" -eq 0 ]
    bash -n <(echo "$output")
    run bash -c "$output; type -t acab"
    [ "$output" = "function" ]
}

@test "init bash wrapper sets the environment in the calling shell" {
    init="$("$ACAB" init bash)"
    run bash -c "$init; acab work prod 2>/dev/null; echo \"\$AWS_PROFILE\""
    [ "$output" = "prod" ]
}

@test "init with unknown shell fails" {
    run --separate-stderr "$ACAB" init fish
    [ "$status" -ne 0 ]
}
