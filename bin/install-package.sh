#!/bin/bash
# install-package.sh

canonpath() {  # Don't "fix" this canonpath, it's not the standard flavor.
    type -t realpath.sh &>/dev/null && {
        realpath.sh -f "$@"
        return
    }
    # Ok for rough work only.  Prefer realpath.sh if it's on the path.
    ( cd -L -- "$(dirname -- $0)"; echo "$(pwd -P)/$(basename -- $0)" )
}

[[ -z $scriptName ]] && scriptName="$(canonpath $0)"
scriptDir=$(command dirname -- "${scriptName}")
PS4='\033[0;33m+(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

# Final ugly hack imposed by canonpath needs:  depending on the twisting dependencies around
# realpath.sh, which may or may not be installed, we have to probe twice to find shpm under
# some conditions:
[[ -z $sourceMe ]] && {
    if [[ -f ${scriptDir}/shpm ]]; then
        sourceMe=1 source  ${scriptDir}/shpm || die "Can't source shpm from install-package.sh(1)"
    elif [[ -f ${scriptDir}/shellkit-pm/shpm ]]; then
        scriptDir=${scriptDir}/shellkit-pm
        sourceMe=1 source  ${scriptDir}/shpm || die "Can't source shpm from install-package.sh(2)"
    else
        die "Can't find shpm from install-package.sh [$scriptDir]"
    fi
}

mode_direct=1
mode_indirect=2

_query_package() {
    ${scriptDir}/shellkit-query-package.sh "$@"
}
stub() {
    [[ -n $NoStubs ]] && return
    # Print debug output to stderr.  Call like this:
    #   stub ${FUNCNAME[0]}.$LINENO item item item
    #
    builtin echo -n "  <<< STUB" >&2
    for arg in "$@"; do
        echo -n "[${arg}] " >&2
    done
    echo " >>> " >&2
}

_parse_setupscript_uri() {
    local mode="$1"
    local pkgName="$2"
    local html_file="$3"
    case $mode in
        mode_direct)
            # Sometimes the release page contains the list of release assets embedded in it
            # (mode_direct):
            local tx1=$(command grep -Eo "\".*releases.*${pkgName}-setup-[^ ]+" ${html_file})
            [[ -n $tx1 ]] || {
                return $(echo "Can't parse setup script URL from $html_file" >&2; exit 1;)
            }
            builtin echo "$tx1" | command tr -d '"'
            return
            ;;
        mode_indirect)
            # Sometimes the release page is built async, and the actual list of assets requires
            # a separate curl fetch
            stub "${FUNCNAME[0]}.${LINENO}" "$@" "mode_indirect"
            local tx2=$(command grep -Eo 'https://.*github.*expanded_assets[^"]*' ${html_file})
            [[ -n $tx2 ]] || {
                echo "Can't parse expanded_assets URL from $html_file, fallback to mode_direct" >&2
                false; return
            }
            builtin echo "$tx2"
            return
            ;;
        *)
            die 209.2
            ;;
    esac
}

_get_base_url_from_canon_source() {
    local canon_source="$1"
    echo "${canon_source}" | command grep -Eo 'http[s]?://[^/]+'
}

curl_opts() {
    echo "-L"
    [[ -n $https_proxy ]] && echo " -k"
}

_download_github_release() {
    # Download self-extracting setup script into tmpdir.  Create
    # a 'setup.sh' symlink and return the tmpdir path
    local pkgName="${1}"
    local canon_source="${2}"
    local version="${3}"

    command which curl &>/dev/null || die "curl is not available on the PATH"
    local tmpdir=$(command mktemp -d)
    (
        set -u
        full_url=
        cd ${tmpdir} || die "201.3"
        stub "${FUNCNAME[0]}.${LINENO}" "$@" "download-prep"
        command curl $(curl_opts) "${canon_source}/releases/${version}" > rawpage.html
        [[ $? -eq 0 ]] || {
            echo "Failed to retrieve raw html" >&2; false;
            exit 1
        }
        # We should be looking for the expanded-assets URL ("mode_indirect")?
        stub "${FUNCNAME[0]}.${LINENO}" "Trying indirect asset list fetch for ${pkgName}"
        uri=$(_parse_setupscript_uri mode_indirect ${pkgName} "$PWD/rawpage.html")
        stub "${FUNCNAME[0]}.${LINENO}" "uri result" "$uri"
        [[ -z "$uri" ]] && {
            stub "${FUNCNAME[0]}.${LINENO}" "expanded-assets-fail-branch" "$PWD/rawpage.html" rawpage
            uri=$(_parse_setupscript_uri mode_direct ${pkgName} "$PWD/rawpage.html")
            stub "${FUNCNAME[0]}.${LINENO}" "$uri" post-parse
            full_url="$(_get_base_url_from_canon_source ${canon_source})${uri}"
            stub "${FUNCNAME[0]}.${LINENO}" $full_url full_url
        } || {
            # Now we've got a url for the expanded-assets chunk: this should end with the coveted actual version number:
            actual_version=$(basename $uri)
            stub "${FUNCNAME[0]}.${LINENO}" $actual_version $uri $canon_source
            command curl $(curl_opts) "$uri" > ${PWD}/expanded-assets.html || die 102.49

            # Find the path to the setup script within the expanded-assets chunk:
            scriptRelpath=$( command grep -Eo 'href=\"/[^"]*' ${PWD}/expanded-assets.html \
                |  command grep -E "${pkgName}-setup-[.0-9]+\.sh" \
                | command head -n 1 )
            [[ -n $scriptRelpath ]] || die "download failed 102.34"
            scriptRelpath=${scriptRelpath:6} # trim the leading [href="]
            stub "${FUNCNAME[0]}.${LINENO}" "$scriptRelpath"

            # https://github.com/sanekits/looper/releases/download/0.2.0/looper-setup-0.2.0.sh << Sample final url
            full_url="$(_get_base_url_from_canon_source ${canon_source})${scriptRelpath}"
            stub "${FUNCNAME[0]}.${LINENO}" full_url $full_url
        }
        dest_file="${PWD}/${pkgName}-setup-${version}.sh"
        stub "${FUNCNAME[0]}.${LINENO}" curl-args "$full_url" "$dest_file"
        command curl $(curl_opts)  "$full_url" > "${dest_file}"
        [[ $? -eq 0 ]] || die "Failed downloading $full_url"
        chmod +x "$dest_file" || die ${FUNCNAME[0]}.${LINENO}
        stub "${FUNCNAME[0]}.${LINENO}" "setup script downloaded" "$dest_file"
        echo "$dest_file"
        true
    ) || { false; return; }
}

_do_install_single() {
    local pkgName=${1}
    local canonUrl=$(_query_package ${pkgName}.canon-source | command awk '{print $2}' )
    stub "${FUNCNAME[0]}.${LINENO}" $pkgName $canonUrl
    [[ -n ${canonUrl} ]] || {
        echo "Can't get canon-source for $pkgName" >&2; false;
        return;
    }
    local install_source
    if [[ "${canonUrl}" =~ .*github.com.* ]]; then
        local install_source=$(_download_github_release "${pkgName}" "${canonUrl}" latest)
        [[ -n $install_source ]] || {
            echo "Failed to download: ${canonUrl}"; false
            return
        }
        ${install_source} || {
            echo "Failed to install ${install_source}"; false
            return
        }
        return
    fi
    die "Unimplemented path in _do_install_single: can't install from canon source like \"${canonUrl}\""
}

_do_install() {
    [[ $# -eq 0 ]] && {
        die "Expected one or more [package-name] args"
    }
    local result=true
    for pkgName; do
        _do_install_single ${pkgName} || result=false
    done
    $result
}


[[ -z ${sourceMe} ]] && {
    NoStubs=1
    _do_install "$@"
    exit
}

true
