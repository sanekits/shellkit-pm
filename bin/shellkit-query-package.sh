#!/bin/bash
# shellkit-query-package.sh:  run queries against packages db
#

METADATA_SCHEMA_VERSION=1.0.0

get_meta() {
    cat <<EOF
METADATA_SCHEMA_VERSION=${METADATA_SCHEMA_VERSION}
scriptName=${scriptName}
dbDirname=$(_find_config)
EOF
}

# Defines bpoint():
[[ -n $DEBUG_SHELLKIT ]] && {
    echo "DEBUG_SHELLKIT enabled, sourceMeRun.taskrc is loading." >&2
    [[ -f ~/bin/sourceMeRun.taskrc ]] && source ~/bin/sourceMeRun.taskrc
}

do_help() {
    local sc="$(basename ${scriptName})"
    cat <<-EOF
--- Command examples: ---
${sc} --help
${sc} --meta
    - Print metadata for packages db
${sc} --all
    - Resolve properties by precedence and print all
${sc} --package-names
    - Print all package names
${sc} <package-name>
    - Print all properties of <package-name>. Fail if not exist
${sc} <package-name> <property-name>
    - Print given property of package.  Fail if not exist.

--- Package db search precedence: ---
  ( First directory found ends search )
   1.  \${SHELLKIT_META_DIR}:  user-definable
   2.  User-specific: ~/.config/shellkit-meta
   3.  Machine-wide: /etc/shellkit-meta
   4.  Regression testing (internal): /testdir
EOF
}

canonpath() {
    builtin type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    builtin type -t readlink &>/dev/null && {
        command readlink -f "$@"
        return
    }
    # Fallback: Ok for rough work only, does not handle some corner cases:
    ( builtin cd -L -- "$(command dirname -- $0)"; builtin echo "$(command pwd -P)/$(command basename -- $0)" )
}

scriptName="$(canonpath "$0")"
scriptDir=$(command dirname -- "${scriptName}")
scriptBase=$(basename ${scriptName})

die() {
    builtin echo "ERROR(${scriptBase}): $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

_find_config() {
    [[ -n ${SHELLKIT_META_DIR} ]] && {
        # User can customize the shellkit package dir with SHELLKIT_META_DIR
        [[ -f ${SHELLKIT_META_DIR}/packages ]] || die "Can't find 'packages' in \$SHELLKIT_META_DIR ($SHELLKIT_META_DIR)"
        echo ${SHELLKIT_META_DIR}
        return
    }
    local searchList=("~/.config/shellkit-meta" "/etc/shellkit-meta" "/test_dir")
    for path in "${searchList[@]}"; do
        path=$(eval "echo $path")
        [[ -f "${path}/packages" ]] && {
            echo "$(canonpath ${path})"
            return
        }
    done
    echo "ERROR: Can't find metadata in: ${searchList[@]}" >&2
}

_resolve_metadata() {
    # Create a temp dir which maps the aggregate metadata to a dir/file tree:
    # 1. Each package name becomes a subdir of [tmp]/
    # 2. Each record-type becomes a filename in [tmp]/<package>/
    #
    # We start with the <meta>/packages file, and then process each of the numbered
    # packages.nnn files in ascending order.  Thus higher-numbered metadata files
    # will overwrite the entry of lower-numbered files, allowing a precedence stack
    #
    # - Prints the tmpRoot path
    # - Caller is responsible for cleanup of this tree
    #
    local _f=_resolve_metadata
    local metaRoot=$(_find_config)
    [[ -d $metaRoot ]] || die $_f.2
    local tmpRoot=$(command mktemp --tmpdir -d shpm-meta.XXXXXX)
    [[ -d $tmpRoot ]] || die $_f.3
    local meta_file_list=$( command ls ${metaRoot}/packages ${metaRoot}/packages.??? 2>/dev/null | sort )
    (
        # Populate tmpRoot:
        builtin cd $tmpRoot || die $_f.33
        rawProps() {
            # Print all properties, stripping comments and blanks:
            command cat ${meta_file_list[*]}  \
            | command grep -vE '(^$)|(^\s*#)'
        }

        # Build dirs for each package:
        (
            rawProps | command awk '{print $1}'  # Just package names please
        )  | command sort \
        | command uniq \
        | command xargs mkdir

        # Create files for each property:
        while read pkg_name record_type value; do
            builtin echo "$value" > ${pkg_name}/${record_type}
        done < <(rawProps)

    ) >&2
    echo "${tmpRoot}"
}

_query_package_property() {
    # ---  Case 1 ---
    # When:
    #  $1 = package_name
    #
    # Then:
    #  - Print "{package}.{record-type} {value}" for all properties of package and return 0
    #  - Print "<no-package:$1>" to stderr if no such package,  return  non-zero
    #
    # ---  Case 2 ---
    # When:
    #   $1 = package-name.record-type
    # Then:
    #  - print "{package}.{record-type} {value}" of given property if found, return zero
    #  - print "<no-package:$1> to stderr if no such package, return non-zero
    #  - print "<no-property:$1> to stderr if property not valid, return non-zero
    #
    local _f=_query_package_property
    [[ -n $1 ]] || return $(die No arg in $_f.1)
    #stub "$_f $@"
    local packageName recordType

    IFS="." read packageName recordType <<< "$1"
    [[ -n ${recordType} ]] && {
        builtin echo -n "${packageName}.${recordType} "
        command cat "${packageName}/${recordType}"
        return
    } || {
        # No record-type, so just test for package name validity:
        [[ -n ${packageName} ]] || die "No package-name passed to $_f"
        [[ -d ${packageName} ]] || die "Unknown package: ${packageName}"
        # Print all properties:
        for file in ${packageName}/*; do
            builtin echo -n "$file " \
                | command tr '/' '.'
            command cat $file
        done
        return
    }
}

_detect_package() {
    local pkgName="$1"
    local detectCmd=$(_query_package_property "$pkgName" detect-command)
    [[ -n ${detectCmd} ]] || return
    ${detectCmd} 2>/dev/null
}

_run_query_function() {
    # When:
    #   - Caller provides a function which needs to run in a resolved-metadata
    #     context (i.e. the temp dir constructed by resolving meta files)
    # Then:
    #   - Wrap the caller's function in setup+teardown logic, as this is
    #     common to all query processing.
    #bpoint "$@"
    local inner_func="$1"
    shift
    local tmpDb=$(_resolve_metadata)
    (
        ok=true
        [[ -n $tmpDb ]] || die $_f.201
        builtin cd ${tmpDb} || die $_f.202
        $inner_func "$@" || ok=false
        builtin cd - &>/dev/null
        command rm -rf ${tmpDb} &>/dev/null
        $ok
    )
}

_query_package_properties() {
    # When:
    #   - A resolved metadata tree is $PWD
    # Then:
    #   - Query all properties passed as args
    for arg in ${args[*]}; do
        _query_package_property "${arg}"
        # arg=${arg} PS1="stub-post-query:${arg}> " bash  --norc || die $_f.stub
    done
    #
}

main() {
    local _f=main
    local args=()
    while [[ -n $1 ]]; do
        case $1 in
            -h|--help)
                shift
                do_help "$@"
                exit
                ;;
            --meta)
                shift
                get_meta "$@"
                exit
                ;;
            --package-names)
                shift
                get_package_names "$@"
                exit
                ;;
            *)
                args+=($1)
                ;;
        esac
        shift
    done
    _run_query_function _query_package_properties "${args[@]}"

}

[[ -z ${sourceMe} ]] && {
    #stub "$scriptBase $@"
    main "$@"
    builtin exit
}
command true
