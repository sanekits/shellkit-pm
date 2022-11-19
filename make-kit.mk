# make-kit.mk.template for shellkit-pm
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

.PHONY:  publish shellkit-meta code

apply_version_extra_files:= bin/shellkit-bootstrap.sh README.md
version_depends=${apply_version_extra_files}
publish_extra_files:=bin/shellkit-bootstrap.sh ../shellkit-meta/packages

# TODO: when all legacy kits are migrated, move this dependency
# into the main Makefile
#publish-common: conformity-check

shellkit-meta: ../shellkit-meta/packages ../shellkit-meta/Makefile
	./shellkit-meta-pre-publish.sh

publish: pre-publish shellkit-meta publish-common release-draft-upload release-list
	@echo ">>>> publish complete OK.  <<<"
	@echo ">>>> Manually publish the release from this URL when satisfied, <<<<"
	@echo ">>>> and then change ./version to avoid accidental confusion. <<<<"
	cat tmp/draft-url


.PHONY: show-bootstrap-path
show-bootstrap-path:
	@# Used by aggregation build processes to identify the path to our self-extracting output script
	@echo tmp/$(setup_script)


code:
	code .vscode/shellkit-pm.code-workspace
