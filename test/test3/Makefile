# Makefile for test3

.PHONY: run meta-test


# See https://stackoverflow.com/a/73509979/237059
absdir:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))


run:
	_DEBUG_=1 shellkit-meta/run_test.sh
	@echo '<< run returns zero >>'

meta-test:
	@echo absdir=${absdir}
	_DEBUG_=1 SHELLKIT_META_DIR=${absdir}/shellkit-meta shellkit-meta/run_test.sh
