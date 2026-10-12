#!/bin/bash

# @see: https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_python.sh

## build ARGs
set -e
source ${Y_BUILD_CONF:-/etc/build.conf}

NCPUS=${NCPUS:--1}


# ---(colors)------------------------------------------------
C_OFF='\033[0m'
C_Green='\033[0;32m'
C_IGreen='\033[0;92m'
C_Blue='\033[0;34m'
C_BBlue='\033[1;34m'
C_UBlue='\033[4;34m'
C_On_Blue='\033[44m'
C_IBlue='\033[0;94m'
C_On_IBlue='\033[0;104m'
C_BIBlue='\033[1;94m'
C_BCyan='\033[1;36m'
C_ICyan='\033[0;96m'
C_UCyan='\033[4;36m'
C_BICyan='\033[1;96m'
C_BYellow='\033[1;33m'
C_IYellow='\033[0;93m'
C_BIYellow='\033[1;93m'
C_BRed='\033[1;31m'
C_IRed='\033[0;91m'
C_URed='\033[4;31m'
C_BIRed='\033[1;91m'
C_BWhite='\033[1;37m'
C_IWhite='\033[0;97m'
C_UWhite='\033[4;37m'
C_BIWhite='\033[1;97m'

# ---(logs)------------------------------------------------
CLOG=""
LCTX="-"
LOG_LOGGER="$(basename $0 .sh)"
LOG_WHO="${IMG_TYPE:-'----'}"
LOG_LEVEL=""
function _log() {

    local mess
    local llev
    lwho="$LOG_WHO"
    lcat="$LOG_LOGGER"
    llev=$(printf '%-5s' ${LOG_LEVEL:-'LOG'})
    mess="${C_IGreen}$(date '+%Y-%m-%d %H:%M:%S %s') ${C_OFF}${CLOG}| $lwho | $lcat | $llev | ${LCTX} | $$ | $* ${C_OFF}"

    echo -e ${mess}
    
}
debug() { LOG_LEVEL='DEBUG' CLOG="$C_Green"   _log $*; }
info()  { LOG_LEVEL='INFO.'  CLOG="$C_BICyan"  _log $*; }
warn()  { LOG_LEVEL='WARN.'  CLOG="$C_BYellow" _log $*; }
error() { LOG_LEVEL='ERROR' CLOG="$C_IRed"    _log $*; }
fatal() { LOG_LEVEL='FATAL' CLOG="$C_BIRed"   _log $*; }
log()   { LOG_LEVEL='_LOG_'   CLOG="$C_BBlue"   _log $*; }
die ()  { fatal $*; exit 1; }

# ---(env)------------------------------------------------
function env_dump() {
    
    [ "$Y_DEBUG_ENV" = 1 ] || return 0
    
    echo "+++> #ENV($0): $@"
    echo "+++: #ENV($0): set"
    set | grep '^Y_' | sort
    echo "+++: #ENV($0): env"
    env | sort
    echo "+++: #ENV($0): path"
    echo "PATH=$PATH"
    echo "+++<  #ENV($0)"
    
}

function setenv_rehash() {

    set +e
    env_dump "setenv_lang::pre"
    source /etc/profile
    #export PS1='# '; source /etc/bash.bashrc
    env_dump "setenv_lang::post"
    set -e
    
}


function install_reticulate() {
    
    [ "$Y_PY_RETICULATE_INSTALL" = 1 ] || return 0

#     eval "export X_ENV_PATH=$(bash --login -i -c 'printf \"%s\" "$PATH"' | tail -n1)"
#  #   eval "export X_ENV_VENV=$(poetry env info --path)"
    
#     sed -i '/PATH=/d' \
#         "${R_HOME}/etc/Renviron.site"

#     sed -i '/VIRTUAL_ENV=/d' \
#         "${R_HOME}/etc/Renviron.site"

#     cat <<EOR >>"${R_HOME}/etc/Renviron.site"
# PATH=${X_ENV_PATH}
# #VIRTUAL_ENV=${X_ENV_VENV}
# EOR

    
    ## R - python
    install2.r --error --skipmissing --skipinstalled -n $NCPUS \
               reticulate
    
}


function clean_up() {
    rm -rf /var/lib/apt/lists/*  2> /dev/null
}



 function main() {

    [ "$Y_PY_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@
    
    [ "$Y_PY_RETICULATE_INSTALL" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    setenv_rehash

    install_reticulate
    
    setenv_rehash

    clean_up

    info "> script($0) -- DONE."

}
    

main $@
