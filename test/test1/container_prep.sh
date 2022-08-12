#!/bin/bash
# container_prep.sh runs as root before tests start

scriptName="$(command readlink -f $0)"
scriptDir=$(command dirname -- "${scriptName}")

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}
main() {
    apt-get install -y git
}

[[ -z ${sourceMe} ]] && main "$@"
