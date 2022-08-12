#!/bin/bash
# run_test.sh

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
    # TEST_DIR gets mounted as /test_dir:ro.  If there's a container_prep.sh script there, it
    # will be run automatically as root

    TEST_DIR=${scriptDir} ${scriptDir}/../../shellkit/docker-test.sh || die docker-test.sh returned failure

    builtin echo "args:[$*]"
}

[[ -z ${sourceMe} ]] && main "$@"
