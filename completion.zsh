#!/usr/bin/env zsh
#
# acab - legacy zsh completion
#
# Prefer the one-line setup instead of this file:
#     eval "$(acab init zsh)"
#
# Kept for setups that already do:
#     source /path/to/acab/completion.zsh
#     compdef _acab_completion acab
#
# Data comes from the acab script itself (`acab __list-*`), so completion and
# the tool always agree on what counts as a config file or profile.

[[ -n "${ZSH_VERSION-}" ]] || return 0

typeset -g _acab_bin="${${(%):-%x}:A:h}/acab"

_acab_completion() {
    local -a items
    case $CURRENT in
        2) items=("${(@f)$("$_acab_bin" __list-configs 2>/dev/null)}") ;;
        3) items=("${(@f)$("$_acab_bin" __list-profiles "${words[2]}" 2>/dev/null)}") ;;
        *) return 1 ;;
    esac
    compadd -a items
}

if (( $+functions[compdef] )); then
    compdef _acab_completion acab
fi
