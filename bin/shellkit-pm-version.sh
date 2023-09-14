#!/bin/bash

# Running shellkit-pm-version.sh is the correct way to
# get the home install path for the tool
KitVersion=0.9.1

canonpath() {
    # Like "readlink -f", but portable
    ( cd -L -- "$(command dirname -- ${1})"; echo "$(command pwd -P)/$(command basename -- ${1})" )
}

Script=$(canonpath "$0")
Scriptdir=$(dirname -- "$Script")


if [ -z "$sourceMe" ]; then
    printf "%s\t%s\n" ${Scriptdir} $KitVersion
fi
