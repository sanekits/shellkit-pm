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


_query_package() {
    ${scriptDir}/shellkit-query-package.sh "$@"
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

_parse_setupscript_uri() {
    local pkgName="$1"
    local html_file="$2"
    local tx1=$(command grep -Eo "\".*releases.*${pkgName}-setup-[^ ]+" ${html_file})
    [[ -n $tx1 ]] || return $(die "Failed to parse setup script URL from $html_file")
    echo "$tx1" | command tr -d '"'
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
        cd ${tmpdir} || die "201.3"
        command curl $(curl_opts) "${canon_source}/releases/${version}" > rawpage.html
        [[ $? -eq 0 ]] || {
            echo "Failed to retrieve raw html" >&2; false;
            return;
        }
        uri=$(_parse_setupscript_uri ${pkgName} "$PWD/rawpage.html")
        [[ -n $uri ]] || return $(die "download failed 102.4")
        base_url=$( _get_base_url_from_canon_source "${canon_source}" )
        full_url="${base_url}${uri}"
        dest_file="${PWD}/${pkgName}-setup-${version}.sh"
        command curl $(curl_opts)  "$full_url" > "${dest_file}"
        [[ $? -eq 0 ]] || return $(die "Failed downloading $full_url")
        chmod +x "$dest_file"
        echo "$dest_file"
    )
}

_do_install_single() {
    local pkgName=${1}
    local canonUrl=$(_query_package ${pkgName}.canon-source | command awk '{print $2}' )
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
    die "Unimplemented path in _do_install_single"
}

_do_install() {
    local result=true
    for pkgName; do
        _do_install_single ${pkgName} || result=false
    done
    $result
}


[[ -z ${sourceMe} ]] && {
    _do_install "$@"
    exit
}

true
