#!/bin/bash
# shellkit-meta-pre-publish.sh

canonpath() {
    builtin type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    builtin type -t readlink &>/dev/null && {
        command readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( builtin cd -L -- "$(command dirname -- $0)"; builtin echo "$(command pwd -P)/$(command basename -- $0)" )
}

scriptName="$(canonpath "$0")"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR($(basename ${scriptName}): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
main() {
    [[ -d ../shellkit-meta ]] || die "../shellkit-meta/ dir not found"
    (
        builtin cd ../shellkit-meta
        make pre-publish
    )
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
