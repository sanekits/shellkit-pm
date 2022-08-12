#!/bin/bash

# Running {Kitname}-version.sh is the correct way to
# get the home install path for the tool
ShellkitPmVersion=0.1.0

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(command dirname -- ${1})"; echo "$(command pwd -P)/$(command basename -- ${1})" )
}

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")


if [ -z "$sourceMe" ]; then
    printf "%s\t%s\n" ${Scriptdir}/gitsmart ${ShellkitPmVersion}
fi
