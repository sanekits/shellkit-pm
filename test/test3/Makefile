# Makefile for test3

.PHONY: run


absdir:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))



run:
	_DEBUG_=1 shellkit-meta/run_test.sh
	@echo '<< run returns zero >>'

test:
	echo absdir=${absdir}
	#_DEBUG_=1 SHELLKIT_META_DIR=$
