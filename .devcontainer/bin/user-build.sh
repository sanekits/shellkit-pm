#!/bin/bash
# user-build.sh
#
# When the image is built, we want to brand it with the user's name and
# profile stuff.
#
# Note that the actual linux username is always 'vscode' (default  UID 1000) but
# git is configured to present itself as the host username for convenience. The
# caller can do "--uid 1234" to set an alternate UID for vscode.
#

echo "user-build.sh running:" >&2
die() {
    echo "ERROR: $*" >&2
    exit 1
}

vscode_uid=$(sed -n "s/^.*--uid \([0-9]*\).*$/\1/p" <<< "$*")
[[ -n $vscode_uid ]] || vscode_uid=1000


[[ -f /.dockerenv ]] || {
    grep -sq docker /proc/1/cgroup  || die "Not running in a Docker container"
}

[[ $UID -eq 0 ]] || die "We're expecting to run as root in a container during image build"


grep -Eq vscode /etc/passwd || {
    adduser --home /home/vscode --uid $vscode_uid vscode 2>/dev/null || die "Failed adding vscode user"
    usermod -aG root vscode
    echo '%vscode ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
}

[[ -d /home/vscode ]] || echo "WARNING: no vscode user home dir has been created" >&2



