#!/bin/bash
# Run this from /workspace

scriptName=$PWD/bin/html-parse-test.sh
sourceMe=1 source ${PWD}/bin/install-package.sh

#set -x
_download_github_release ps1-foo https://github.com/sanekits/ps1-foo latest
echo $?
