#!/bin/bash
# shellkit-query-package.sh:  run queries against packages db
#

METADATA_SCHEMA_VERSION=1.0.1

# Defines bpoint():
_DEBUG_=${_DEBUG_:-0}
[[ $_DEBUG_ -eq 1 ]] && {
    echo "_DEBUG_ enabled, sourceMeRun.taskrc is loading." >&2
    [[ -f ~/bin/sourceMeRun.taskrc ]] && source ~/bin/sourceMeRun.taskrc
} || {
    bpoint() { : ;} # no-op
}


get_meta() {
    cat <<EOF
METADATA_SCHEMA_VERSION=${METADATA_SCHEMA_VERSION}
scriptName=${scriptName}
dbDirname=$(_find_config)
metafiles=$( __metafiles "$(_find_config)" )
installExtRoot=$(_find_config)/install-ext.d
EOF
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
${sc} --detect <package-name> ...
    - Run the detection command for package(s) and print result.

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
PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

die() {
    builtin echo "ERROR(${scriptBase}): $*" >&2
    builtin exit 1
}

stub() {
    # Print debug output to stderr.  Call like this:
    #   stub ${FUNCNAME[0]}.$LINENO item item item
    #
    builtin echo -n "  <<< STUB" >&2
    for arg in "$@"; do
        echo -n "[${arg}] " >&2
    done
    echo " >>> " >&2
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

__metafiles() {
    # Print the metafiles in precedence order
    local metaroot="$1"
    (
           command ls ${metaroot}/packages ${metaroot}/packages.[0-9][0-9][0-9] 2>/dev/null \
            | command sort | command tr '\n' ' '
    )
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
    local meta_file_list=$( __metafiles "${metaRoot}" )
    [[ -n "${meta_file_list[*]}" ]] && (

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
    local packageName recordType

    IFS="." read packageName recordType <<< "$1"
    [[ -n ${recordType} ]] && {
        builtin echo -n "${packageName}.${recordType} "
        command cat "${packageName}/${recordType}" 2>/dev/null || {
            return $(die "$1 not defined")
        }
        return
    } || {
        # No record-type, so just test for package name validity:
        [[ -n ${packageName} ]] || return $(die "No package-name passed to $_f")
        [[ -d ${packageName} ]] || return $(die "Unknown package: ${packageName}")
        # Print all properties:
        for file in ${packageName}/*; do
            builtin echo -n "$file " \
                | command tr '/' '.'
            command cat $file 2>/dev/null
        done
        return
    }
}

_get_property_value() {
    local key val
    read key val <<< $(_query_package_property "$1")
    echo "$val"
}

_detect_package() {
    local pkgName="$1"
    local detectCmd=$(_get_property_value "${pkgName}.detect-command")
    [[ -n ${detectCmd} ]] || return
    ${detectCmd} 2>/dev/null
    res=$?
    [[ $res -eq 0 ]]
}


_detect_packages() {
    for pkg_name in "$@"; do
        _detect_package "$pkg_name"
    done
}

detect_packages() {
    _run_query_function _detect_packages "$@"
}

get_all() {
    [[ $1 == inner ]] || {
        _run_query_function get_all inner
        return
    }
    _query_package_properties $(command find ./* -type f | command sed -e 's%^\./%%' -e 's%/%.%' )
}

_run_query_function() {
    # When:
    #   - Caller provides a function which needs to run in a resolved-metadata
    #     context (i.e. the temp dir constructed by resolving meta files)
    # Then:
    #   - Wrap the caller's function in setup+teardown logic, as this is
    #     common to all query processing.
    local _f=_run_query_function
    local inner_func="$1"
    shift
    local tmpDb=$(_resolve_metadata)
    (
        ok=true
        [[ -n $tmpDb ]] || die $_f.201
        builtin cd "${tmpDb}" || die $_f.202
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
    local ok=true
    for arg ; do
        _query_package_property "${arg}" || ok=false
    done
    $ok
}

_get_package_names() {
    # Print all package names
    __list_packages() {
        command ls -d * 2>/dev/null
    }
    _run_query_function __list_packages
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
            --all)
                shift
                get_all "$@"
                exit
                ;;
            --package-names)
                shift
                _get_package_names "$@"
                exit
                ;;
            --detect)
                shift
                detect_packages "$@"
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
    main "$@"
    builtin exit
}
command true
