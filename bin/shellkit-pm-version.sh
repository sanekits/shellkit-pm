#!/bin/bash

# Running {Kitname}-version.sh is the correct way to
# get the home install path for the tool
ShellkitPmVersion=0.2.3

canonpath() {
    type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    # Ok for rough work only.  Prefer realpath.sh if it's on the path.
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}


Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")


if [ -z "$sourceMe" ]; then
    printf "%s\t%s\n" ${Scriptdir}/shellkit-pm ${ShellkitPmVersion}
fi
