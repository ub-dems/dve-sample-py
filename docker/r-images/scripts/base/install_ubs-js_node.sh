#!/bin/bash

###
## Install fnm, node, npm
##

## @see: https://nodejs.org/en/download/package-manager

## build ARGs
set -e
source ${Y_BUILD_CONF:-/etc/build.conf}

NCPUS=${NCPUS:--1}


set -a
# ------------------------------------------------------
: "${Y_JS_NODE_VERSION:=22.12}"
: "${FNM_ROOT:=/opt/fnm}"
: "${NODE_ROOT:=/opt/nodejs}"
: "${FNM_DIR:=$NODE_ROOT/.fnm}"
: "${NODE_VERSION:=$Y_JS_NODE_VERSION}"
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
    set | grep -e '^Y_' | sort
    echo "+++: #ENV($0): env"
    env | sort
    echo "+++: #ENV($0): path"
    echo "PATH=$PATH"
    echo "+++< #ENV($0): $@"
    
}




function setenv_rehash() {
    
    set +e
    env_dump "setenv_rehash::pre"

    export PS1='# '

    case "${SHELL:-/bin/bash}" in
        */zsh)
            [ -f /etc/zprofile ] && source /etc/zprofile
            [ -f ~/.zprofile ] && source ~/.zprofile
            [ -f ~/.zshrc ] && source ~/.zshrc
            ;;
        */bash|*/sh|*)
            [ -f /etc/profile ] && source /etc/profile
            # [ -f ~/.profile ] && source ~/.profile
            # [ -f ~/.bashrc ] && source ~/.bashrc
            ;;
    esac    
    env_dump "setenv_rehash::post"
    set -e
    
}

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* 2> /dev/null | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}


function config_node() {

    [ "$Y_JS_NODE_CONFIG" = 1 ] || return 0

#    sed -i 's!PATH="!PATH="/opt/rust/bin:/opt/cargo/bin:!' \
#        "/etc/environment"

    cat <<EOF >>"/etc/environment"
NODE_VERSION=${NODE_VERSION}
FNM_DIR=${FNM_DIR}
EOF
    
    
    cat <<EOF >>"${R_HOME}/etc/Renviron.site"
NODE_VERSION=${NODE_VERSION}
FNM_DIR=${FNM_DIR}
EOF
    

    cat <<"EOF" >>"/etc/profile.d/Z92-node.sh"
##
# node/fnm
#

if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell=bash)"
fi
EOF
    
    echo "# +++ node: PATH=${PATH}"

}


function check_node() {
    
    [ "$Y_JS_NODE_CHECK" = 1 ] || return 0

    echo "Verifying node and npm installation..."

    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    
    set -x
    
    which -a node     || true
    node --version    || false

    which -a npm      || true
    npm --version     || false
    
    set +x
    
}


function purge_node() {

    [ "$Y_JS_NODE_PURGE" = 1 ] || return 0

    sudo apt-get purge -y \
         nodejs \
         libnode-dev || true

    sudo apt-get autoremove -y  || true
    

}


function install_node() {

    [ "$Y_JS_NODE_INSTALL" = 1 ] || return 0


    # installs fnm (Fast Node Manager)
    curl -fsSL https://fnm.vercel.app/install | \
        bash -s -- --install-dir "$FNM_ROOT" --skip-shell    

    # fnm
    FNM_PATH="$FNM_ROOT"
    ln -sf "$FNM_ROOT/fnm" /usr/local/bin/fnm

    export FNM_DIR=$NODE_ROOT/.fnm
    #export PATH=$NODE_ROOT/bin:$PATH
    
    
    if [ -d "$FNM_PATH" ]; then
        #export PATH="$FNM_PATH:$PATH"
        eval "$(fnm --fnm-dir ${FNM_DIR} env)"
    fi

    echo "export FNM_DIR=$NODE_ROOT/.fnm" >> /etc/environment
    # echo "export PATH=$NODE_ROOT/bin:\$PATH" >> /etc/environment
    source /etc/environment


    # download and install Node.js
    fnm use --fnm-dir ${FNM_DIR} --install-if-missing ${NODE_VERSION}
    fnm default ${NODE_VERSION}

    # ln -sf "$NODE_ROOT/.fnm/node-versions/$NODE_VERSION/installation/bin/node" /usr/local/bin/node
    # ln -sf "$NODE_ROOT/.fnm/node-versions/$NODE_VERSION/installation/bin/npm" /usr/local/bin/npm


}


function upgrade_node() {

    [ "$Y_JS_NODE_PKGS" = 1 ] || return 0


    # npm upgrades

    npm update -g npm

    npm update -g

}


function install_pkgs() {

    [ "$Y_JS_NODE_PKGS" = 1 ] || return 0


    # installs markdown linter

    npm install -g markdownlint-cli2


}



function clean_up() {
    :
}



function main() {
    
    [ "$Y_JS_ANY_SUPPORT" = 1 ] || return 0

    env_dump "$@"

    [ "$Y_JS_NODE_SUPPORT" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."
    
    purge_node "$@"
    install_node "$@"
    config_node "$@"

    setenv_rehash    
    
    upgrade_node "$@"
    install_pkgs "$@"
    check_node "$@"

    clean_up

    info "> script($0) -- DONE."

}

main $@
