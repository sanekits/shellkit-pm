# make-kit.mk.template for <kit-name>
#  This makefile is included by the root shellkit Makefile
#  It defines values that are kit-specific.
#  You should edit it and keep it source-controlled.

# TODO: update kit_depends to include anything which
#   might require the kit version to change as seen
#   by the user -- i.e. the files that get installed,
#   or anything which generates those files.
kit_depends := \
    bin/shpm \
    bin/install-package.sh \
	bin/setup.sh \
	bin/shellkit-pm-help \
	bin/shellkit-bootstrap.sh \

.PHONY:  shellkit-meta shellkit-meta-setup code


shellkit-meta: ../shellkit-meta/packages ../shellkit-meta/Makefile
	./shellkit-meta-pre-publish.sh

publish: publish-common shellkit-meta ${HOME}/downloads push-tag
	@echo "MANUAL STEP:  ~/downloads/packages and ~/downloads/shellkit-bootstrap.sh should be attached to release artifacts"
	@echo publish complete OK

code: 
	code .vscode/shellkit-pm.code-workspace
