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
PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

source ${scriptDir}/shellkit/setup-base.sh

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

main() {
    Script=${scriptName} main_base "$@"
    cd ${HOME}/.local/bin || die 208
    # TODO: kit-specific steps can be added here

    mkdir -p ${HOME}/.config/shellkit-meta
    touch ${HOME}/.config/shellkit-meta/packages
    # Installer extensions: we must init the extensions hook dir so that
    # installer extensions have a place to put their stuff:
    local metav=$(
        ${scriptDir}/shellkit-query-package.sh --meta | grep -sE '^installExtRoot'
        )
    IFS=$'='; read _ installExtRoot <<< "$metav"; unset IFS
    [[ -n $installExtRoot ]] || \
        die "Can't identify installer extensions root path: 1"
    mkdir -p "$installExtRoot"
    [[ -d $installExtRoot ]] || \
        die "Failed creating install extensions root: $installExtRoot"

    # FINALIZE: perms on ~/.local/bin/<Kitname>.  We want others/group to be
    # able to traverse dirs and exec scripts, so that a source installation can
    # be replicated to a dest from the same file system (e.g. docker containers,
    # nfs-mounted home nets, etc)
    command chmod og+rX ${HOME}/.local/bin/${Kitname} -R;
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
