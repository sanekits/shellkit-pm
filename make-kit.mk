# make-kit.mk.template for shellkit-pm
make-kit.mk: ;
#  This makefile is included by the root shellkit Makefile
#  It defines values that are kit-specific.
#  You should edit it and keep it source-controlled.

# The shellkit/ tooling naturally evolves out from under the dependent kits.  ShellkitSetupVers allows
# detecting the need for refresh of templates/* derived files.  To bump the root version, 
# zap all templates/* containing 'ShellkitTemplateVers' constants and changes to the corresponding dependent kits
# Note that within templates/* there may be diverse versions in upstream shellkit, they don't all have to match,
# but the derived copies should be sync'ed with upstream as needed.
ShellkitTemplateVers=3

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

.PHONY:  publish shellkit-meta code publish-draft

apply_version_extra_files:= bin/shellkit-bootstrap.sh README.md
version_depends=${apply_version_extra_files}
publish_extra_files:=bin/shellkit-bootstrap.sh ../shellkit-meta/packages

publish-common: conformity-check

shellkit-meta: ../shellkit-meta/packages ../shellkit-meta/Makefile
	./shellkit-meta-pre-publish.sh

publish: pre-publish shellkit-meta publish-common release-upload release-list
	cat tmp/draft-url
	@echo ">>>> publish complete OK. (FINAL)  <<<"

publish-draft: pre-publish publish-common release-draft-upload release-list
	cat tmp/draft-url
	@echo ">>>> publish complete OK. (DRAFT - you must manually publish it from github release page)  <<<"

.PHONY: show-bootstrap-path
show-bootstrap-path:
	@# Used by aggregation build processes to identify the path to our self-extracting output script
	@echo tmp/$(setup_script)


code:
	code .vscode/shellkit-pm.code-workspace
