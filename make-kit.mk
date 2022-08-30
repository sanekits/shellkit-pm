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

apply_version_extra_files:= bin/shellkit-bootstrap.sh
version_depends=${apply_version_extra_files}
publish_extra_files:=bin/shellkit-bootstrap.sh

shellkit-meta: ../shellkit-meta/packages ../shellkit-meta/Makefile
	./shellkit-meta-pre-publish.sh

publish: pre-publish
	make publish-common shellkit-meta release-draft-upload
	gh release list | sort -n
	@echo ">>>> publish complete OK.  <<<"
	@echo ">>>> Manually publish the release from this URL when satisfied, <<<<"
	@echo ">>>> and then change ./version to avoid accidental confusion. <<<<"
	cat tmp/draft-url

code:
	code .vscode/shellkit-pm.code-workspace
