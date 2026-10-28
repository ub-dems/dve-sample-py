#!/bin/bash

###
## Install rustup, cargo, rustc
##

## @see: https://doc.rust-lang.org/cargo/getting-started/installation.html

## build ARGs
set -e
source ${Y_BUILD_CONF:-/etc/build.conf}

NCPUS=${NCPUS:--1}


set -a
# ------------------------------------------------------
: "${RUST_ROOT:=/opt/rust}"
: "${CARGO_HOME:=/opt/cargo}"
: "${RUSTUP_HOME:=/opt/rust}"
: "${RUSTUP_URL:=https://sh.rustup.rs}"
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


function config_rust() {

    [ "$Y_RS_RUST_CONFIG" = 1 ] || return 0

    sed -i 's!PATH="!PATH="/opt/rust/bin:/opt/cargo/bin:!' \
        "/etc/environment"

    cat <<EOF >>"/etc/environment"
RUSTUP_HOME=/opt/rust
CARGO_HOME=/opt/cargo
EOF
    
    
    cat <<EOF >>"${R_HOME}/etc/Renviron.site"
RUSTUP_HOME=/opt/rust
CARGO_HOME=/opt/cargo
EOF
    

    cat <<"EOF" >>"/etc/profile.d/Z91-rust.sh"
##
# rust/cargo environmnet
#
set -a
# ------------------------------------------------------
: "${RUST_ROOT:=/opt/rust}"
: "${CARGO_HOME:=/opt/cargo}"
: "${RUSTUP_HOME:=/opt/rust}"
: "${RUSTUP_URL:=https://sh.rustup.rs}"
# ------------------------------------------------------
set +a

[ -f "${CARGO_HOME}/env" ] && source "${CARGO_HOME}/env"
EOF

    
    echo "# +++ rust: PATH=${PATH}"

}






function check_rust() {
    
    [ "$Y_RS_RUST_CHECK" = 1 ] || return 0

    echo "Verifying Rust and Cargo installation..."
    
    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    
    set -x

    which -a cargo  || true
    cargo --version  || true

    which -a rustup  || true
    rustup --version  || true

    which -a rustc  || true
    rustc --version  || true
    
    set +x
    
}

function install_apps() {
    
    [ "$Y_RS_RUST_APPS" = 1 ] || return 0

    echo "Instaling Rust applications ..."
    
    set -x

    # cargo install alacritty
    
    set +x
    
}



function install_rust() {

    [ "$Y_RS_RUST_INSTALL" = 1 ] || return 0

    curl --proto '=https' --tlsv1.2  -sSf "$RUSTUP_URL" | \
        sh -s -- \
           -y \
           --default-toolchain stable \
           --profile default \
           --no-modify-path


}



function clean_up() {
    :
}



function main() {
    
    [ "$Y_RS_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_RS_RUST_SUPPORT" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    install_rust $@
    config_rust $@

    setenv_rehash    
    
    check_rust $@

    clean_up

    info "> script($0) -- DONE."

}

main $@
