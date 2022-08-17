#!/bin/bash
# hello.sh

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
    builtin echo "Hello world, shellkit edition: args:[$*]"
}

[[ -z ${sourceMe} ]] && main "$@"
