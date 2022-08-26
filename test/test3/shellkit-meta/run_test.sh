#!/bin/bash
# run_test.sh for test/test3

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

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
queryScript=$(canonpath ${scriptDir}/../../../bin/shellkit-query-package.sh)

die() {
    builtin echo "ERROR($(basename ${scriptName})): $*" >&2
    builtin exit 1
}

main() {
    local _f=$scriptName.main
    export SHELLKIT_META_DIR=${scriptDir}
    stub "meta: $(${queryScript} --meta | tr '\n' ',' )"
    set -x
    ${queryScript} --package-names || die $_f --package-names
    ${queryScript} ps1-foo.desc gitsmart || die $_f qq
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    builtin exit
}
command true
