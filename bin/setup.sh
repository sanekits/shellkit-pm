#!/bin/bash
# setup.sh for <kitname>

canonpath() {
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
scriptName="$(canonpath  $0)"
scriptDir=$(command dirname -- "${scriptName}")

source ${scriptDir}/shellkit/setup-base.sh

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

main() {
    Script=${scriptName} main_base "$@"
    cd ${HOME}/.local/bin || die 208
    # TODO: kit-specific steps can be added here
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
