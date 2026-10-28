#!/bin/bash

##
# install_ubs-utils.sh: install utility tools and libraries
#


set -e

## build ARGs
source /etc/build.conf

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
    echo "+++<  #ENV($0): $@"
    
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

function install_utils_sys() {

    [ "$Y_BASE_UTILS_SYS" = 1 ] || return 0
    
    apt_install \
        less \
        ssh \
        vim \
        zsh \
        mc \
        ranger \
        silversearcher-ag \
        atop \
        btop \
        bat \
        duf \
        eza \
        fd-find \
        glances \
        iputils-ping \
        iputils-tracepath \
        iputils-clockdiff \
        jq \
        lsd \
        ncdu \
        nmon \
        pv \
        pdfgrep \
        ripgrep \
        tig \
        tmux
    
}

function install_utils_cran() {
    
    [ "$Y_BASE_UTILS_CRAN" = 1 ] || return 0
    
    install2.r --error --skipmissing --skipinstalled -n $NCPUS \
               pak \
               ps \
               benchmarkme \
               benchmarkmeData \
               rbenchmark \
               microbenchmark \
               ragg \
               reprex \
               styler
    
}

function install_apps_starship() {

    [ "$Y_BASE_APPS_STARSHIP" = 1 ] || return 0

    curl -fsSL https://starship.rs/install.sh | bash --posix -s -- --yes
    
}


function install_apps_emacs() {

    [ "$Y_BASE_APPS_EMACS" = 1 ] || return 0
    
    apt_install \
        emacs \
        emacs-libvterm \
        elpa-pdf-tools \
        libvterm-dev \
        fonts-firacode
    
}

function install_apps_cursor() {

    [ "$Y_BASE_APPS_CURSOR" = 1 ] || return 0

    # Add Cursor's GPG key
    curl -fsSL https://downloads.cursor.com/keys/anysphere.asc \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/cursor.gpg > /dev/null

    chmod 644 /etc/apt/keyrings/cursor.gpg

    # Add the Cursor repository
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/cursor.gpg] https://downloads.cursor.com/aptrepo stable main" \
        | sudo tee /etc/apt/sources.list.d/cursor.list > /dev/null

    aq=" -qq -o=Dpkg::Use-Pty=0 "
    
    # Update and install
    apt-get update $aq
    
    
    apt_install \
        cursor

    
}

function install_apps_antigravity() {

    [ "$Y_BASE_APPS_ANTIGRAVITY" = 1 ] || return 0

    # Add Antigravity's GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
        gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
    
    # Add the Antigravity repository
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
        sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null    

    aq=" -qq -o=Dpkg::Use-Pty=0 "
    
    # Update and install
    apt-get update $aq
    
    apt_install \
        antigravity
    
}


function install_utils() {
    
    install_utils_sys
    install_utils_cran
    
}





function install_apps() {
    
    install_apps_starship
    install_apps_emacs
    install_apps_cursor
    install_apps_antigravity
    
}



function setenv_rehash() {

    set +e
    env_dump "setenv_utils::pre"
    export PS1='# '; source /etc/bash.bashrc
    env_dump "setenv_utils::post"
    set -e
    
}


function check_utils() {
    
    [ "$Y_BASE_UTILS_CHECK" = 1 ] || return 0
    
    ssh -V   || true
    
    
}


function clean_up() {
    :
}



function main() {

    env_dump $@
    
    [ "$Y_BASE_UTILS_INSTALL" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    setenv_rehash

    install_utils
    install_apps
    setenv_rehash

    check_utils

    clean_up

    info "> script($0) -- DONE."


}
    

main $@
 
