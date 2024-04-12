#!/bin/bash
# shellkit-bootstrap.sh:  starting from pure scratch, install current shellkit-meta + shellkit-pm
#  Provides intro guidance on kit setup

shellkitpm_version=0.9.3  # Initial bootstrap version.  You can always do `shpm install shellkit-pm` to update it

canonpath() {
    ( cd -L -- "$(command dirname -- ${1})"; echo "$(command pwd -P)/$(command basename -- ${1})" )
}

[[ -n $scriptName ]] || scriptName=$(canonpath $0)
scriptDir=$(dirname -- ${scriptName})
PS4='\033[0;33m+$?(${BASH_SOURCE}:${LINENO}):\033[0m ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

[[ -n ${host_base} ]] || host_base=https://github.com/sanekits

die() {
    builtin echo "ERROR: $*" >&2
    builtin exit 1
}

stub() {
   builtin echo "  <<< STUB[$*] >>> " >&2
}

version_lt() {
    # Returns true if left < right for 3-tuple version numbers
    (
        IFS="." read  l0 l1 l2 <<< "$1"
        IFS="." read  r0 r1 r2 <<< "$2"
        (( $l0 < $r0 )) && exit
        (( $l0 == $r0 )) || exit
        (( $l1 < $r1 )) && exit
        (( $l1 == $r1 )) || exit
        (( $l2 < $r2 )) && exit
        false
    )
}

curl_opts() {
    echo "-L"
    [[ -n $https_proxy ]] && echo " -k"
}

main() {
    command curl --version &>/dev/null || die "Prerequisite 'curl' is not installed.  Use your package manager (e.g. apt-get or yum, etc) to resolve that."

    local pm_download_url="${host_base}/shellkit-pm/releases/download/${shellkitpm_version}/shellkit-pm-setup-${shellkitpm_version}.sh"
    local meta_download_url="${host_base}/shellkit-pm/releases/download/${shellkitpm_version}/packages"
    local tmpDir=$(mktemp -d)
    (
        cd $tmpDir || die "Can't cd to ${tmpDir}"
        setup_script=shellkit-pm-setup-${shellkitpm_version}.sh
        command curl $(curl_opts) "$pm_download_url" > ${setup_script} || die "Failed downloading $pm_download_url"
        command grep -Eq 'using Makeself' ${setup_script} || die "Bad setup script content in ${setup_script}"
        echo "OK: $pm_download_url"
        command curl $(curl_opts) "$meta_download_url" > packages || die "Failed downloading $meta_download_url"
        command grep -Eq 'canon-source' packages || die "Bad packages content in $PWD/packages"
        echo "OK: $meta_download_url => ${PWD}/packages"

        curPmVersion=$(command shellkit-pm-version.sh 2>/dev/null | command awk '{print $2}')
        [[ -z $curPmVersion ]] && {
            # Elaborately build a version string that "make apply-version"
            # won't replace:
            curPmVersion=$( echo 0 .0 .0  | tr -d ' ')
        }
        if version_lt "$shellkitpm_version" "$curPmVersion"; then
            builtin echo "Bootstrap version < currently installed version, skipping setup of shellkit-pm" >&2
        else
            command chmod +x ${setup_script}
            ./${setup_script} || die "${PWD}/${setup_script} failed"
            builtin echo "${setup_script}: OK"
        fi
        command mkdir -p ~/.config/shellkit-meta
        command cp ./packages ~/.config/shellkit-meta/packages || die "Failed copying 'packages' to ~/.config/shellkit-meta/ from $PWD"
        echo -e  $'\n' \
            " 1.  Restart your shell with \"bash -l\"" $'\n' \
            " 2.  To see the available packages, run \"shpm list\"" $'\n' \
            " 3.  To install a package, run \"shpm install <package-name>\"" $'\n' \
             | fold -s >&2
    ) || die "Failed: working tree is $PWD"

    [[ -n ${tmpDir} ]] && rm -rf ${tmpDir}
    true
}

[[ -z ${sourceMe} ]] && {
    main "$@"
    exit
}
true
