#!/bin/bash
# Run this from /workspace

scriptName=$PWD/bin/install-ps1-foo-test.sh
sourceMe=1 source ${PWD}/bin/install-package.sh

_do_install_single ps1-foo
echo $?
