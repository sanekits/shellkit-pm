#!/bin/bash
# run_tests.sh  Runs all test/*/run_test.sh scripts


canonpath() {
    type -t realpath.sh &>/dev/null && {
        realpath.sh "$@"
        return
    }
    # Ok for rough work only.  Prefer realpath.sh if it's on the path.
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

scriptName=$(canonpath $0)
scriptDir=$(dirname -- ${scriptName})

die() {
    echo "ERROR: $*" >&2
    exit 1
}

main() {
    cd ${scriptDir}/test || die 101
    for test_script in */run_test.sh; do
        (
            cd $(dirname ${test_script}) || die 102
            echo "Running tests in $PWD:"
            ./run_test.sh
            echo "${test_script} passed: OK"
        ) || die "Failed in $test_script"
    done
    echo "All tests passed."
}

[[ -z ${sourceMe} ]] && main "$@"
