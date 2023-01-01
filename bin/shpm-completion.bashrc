# shpm-completion.bashrc
# Shell tab completion for `shpm` commands

# shpm-autocomplete
# vim: filetype=sh :

__SHPM_PACKAGE_NAMES=

_shpm() { # Shell completion for shpm.
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    [[ -z $__SHPM_PACKAGE_NAMES ]] \
        && __SHPM_PACKAGE_NAMES="$(shellkit-query-package.sh --package-names)"

    # The main job is usually to set 'opts' to the set of meaningful commands:
    case $prev in
        status|install)
            opts="$__SHPM_PACKAGE_NAMES";;
        list)
            opts="" ;;
        *)
            if [[ "$__SHPM_PACKAGE_NAMES" == *${prev}* ]]; then
                opts="$__SHPM_PACKAGE_NAMES"
            else
                opts="--help --version install status list"
            fi
            ;;
    esac
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}" ) )
    return 0
}

_shellkit_query_package() { # Completion for shellkit-query-package.sh

    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    [[ -z $__SHPM_PACKAGE_NAMES ]] \
        && __SHPM_PACKAGE_NAMES="$(shellkit-query-package.sh --package-names)"

    # The main job is usually to set 'opts' to the set of meaningful commands:
    case $prev in
        --meta|--help|-h|--all|--package-names)
            opts="";;
        --detect)
            opts="$__SHPM_PACKAGE_NAMES" ;;

        *)
            if [[ "$__SHPM_PACKAGE_NAMES" == *${prev}* ]]; then
                opts="$__SHPM_PACKAGE_NAMES"
            else
                opts="--help --meta --all --package-names --detect $__SHPM_PACKAGE_NAMES"
            fi
            ;;
    esac
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}" ) )
    return 0
}

complete -F _shpm shpm
complete -F _shellkit_query_package shellkit-query-package.sh
complete -F _shellkit_query_package shpm-query
