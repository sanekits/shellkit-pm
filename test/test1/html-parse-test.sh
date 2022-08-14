#!/bin/bash
# Run this from /workspace

scriptName=$PWD/bin/html-parse-test.sh
sourceMe=1 source ${PWD}/bin/install-package.sh

#set -x
_parse_setupscript_uri ps1-foo /test_dir/rawpage-sample.html
echo $?
