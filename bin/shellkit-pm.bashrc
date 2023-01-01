# shellkit-pm.bashrc - shell init file for shellkit-pm sourced from ~/.bashrc

shellkit-pm-semaphore() {
    [[ 1 -eq  1 ]]
}

alias shpm-query='shellkit-query-package.sh'

[[ -f ${HOME}/.local/bin/shellkit-pm/shpm-completion.bashrc ]] \
    && source ${HOME}/.local/bin/shellkit-pm/shpm-completion.bashrc

