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
: "${VSCODE_SERVER_DIR:=/opt/vscode-server}"
: "${VSCODE_SERVER_VERSION:=latest}"
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
        aq=" -qq -o=Dpkg::Use-Pty=0 "
	if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/* 2> /dev/null | wc -l)" = "0" ]; then
			apt-get update $aq
		fi
		apt-get install $aq -y --no-install-recommends "$@"
	fi
}


function install_build_deps() {

    [ "$Y_PY_PYENV_INSTALL" = 1 ] || return 0

    apt_install \
        fonts-liberation \
        libsecret-1-dev \
        libgtk-3-dev \
        libatk1.0-0 \
        libcairo2-dev \
        libpango-1.0-0 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcursor-dev \
        libxcomposite-dev \
        libxdamage-dev \
        libxrandr-dev \
        libnss3-dev \
        libxss1 \
        libxtst6 \
        libgtk-3-0
    
}


function config_code() {

    [ "$Y_JS_CODE_CONFIG" = 1 ] || return 0

    # save example config.yaml

    if [ -f ~/.config/code-server ]; then
        mkdir -p /usr/local/doc
        mv ~/.config/code-server /usr/local/doc
    fi

    echo "# +++ code-server(config.yaml): /usr/local/doc/code-server/config.yaml"

}


function check_code() {
    
    [ "$Y_JS_CODE_CHECK" = 1 ] || return 0

    echo "Verifying node and npm installation..."

    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    
    set -x
    
    which -a code-server  || true
    code-server --version || false
    
    set +x
    
}


function install_code() {

    [ "$Y_JS_CODE_INSTALL" = 1 ] || return 0

    # Install Visual Studio Code Server
    echo "Installing Visual Studio Code Server..."

    curl -fsSL https://code-server.dev/install.sh | sh -s -- --prefix /usr/local
    
    # mkdir -p "$VSCODE_SERVER_DIR"
    # npm install -g code-server@"$VSCODE_SERVER_VERSION"

    # # Create symlink for global access
    # ln -sf "$(npm root -g)/code-server/dist/bin/code-server" /usr/local/bin/code-server


}



function clean_up() {
    :
}



function main() {
    
    [ "$Y_JS_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_JS_CODE_SUPPORT" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    install_code $@
    config_code $@

    setenv_rehash    
    
    check_code $@

    clean_up

    info "> script($0) -- DONE."
    
}

main $@
