#!/bin/bash
# run_tests.sh  Runs all test/*/run_test.sh scripts

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(command dirname -- ${1})"; echo "$(command pwd -P)/$(command basename -- ${1})" )
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
