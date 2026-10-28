#!/bin/bash

## 
## Install nvidia utils - Ubuntu distro
##

## default NV from cuda.Dockerfile
## build ARGs
set -e
source ${Y_CUDA_CONF:-/etc/ubs/cuda.conf}

NCPUS=${NCPUS:--1}


set -a
# ------------------------------------------------------

: ${NV_NVTOP_PACKAGES:="nvtop nvitop"}

# ------------------------------------------------------
set +a

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
    echo "+++< #ENV($0): $@"
    
}

function setenv_rehash() {
    env_dump "setenv_rehash::pre"
    source /etc/profile
    #export PS1='# '; source /etc/bash.bashrc
    env_dump "setenv_rehash::post"
}


# a function to install apt packages only if they are not installed
function apt_install() {
        aq=" -qq -o=Dpkg::Use-Pty=0 "
	if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/* 2> /dev/null | wc -l)" = "0" ]; then
			apt-get update $aq
		fi
		apt-get install $aq -y --no-install-recommends "$@"
	fi
}


function install_tools() {

    [ "$Y_NV_UTILS_TOOLS" = 1 ] || return 0

    debug "> install nvtop utils, ..."
    
    apt_install \
        $NV_NVTOP_PACKAGES

    debug "< install nvtop utils, done."
    
}



function check_utils() {
    
    [ "$Y_NV_UTILS_CHECK" = 1 ] || return 0

    
    cat <<EOF || true
## //////////////////////////////////////////
##
# CUDA UTILS
#

--

nvtop: $(which nvtop)
nvitop: $(which nvitop)

## -------------------------------------------
EOF

    cat <<EOF || true

## //////////////////////////////////////////
EOF
    
}


function clean_up() {
    
    debug "> clean utils cache, ..."

    :
    
    debug "< clean utils cache, done."
    
}



function main() {
    
    [ "$Y_NV_ANY_SUPPORT" = 1 ] || return 0
    [ "$Y_NV_UTILS_SUPPORT" = 1 ] || return 0

    env_dump $@

    info "> script($0) -- STARTED, ..."

    install_tools
    
    check_utils

    clean_up

    info "> script($0) -- DONE."
}

main $@
