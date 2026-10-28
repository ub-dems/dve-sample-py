#!/bin/bash

###
## Install julia, JuliaCall, JuliaConnectoR
##

## @see: https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_julia.sh

## build ARGs
set -e
source ${Y_BUILD_CONF:-/etc/build.conf}

NCPUS=${NCPUS:--1}


set -a
# ------------------------------------------------------
: "${JULIA_ROOT:=/opt/julia}"
: "${JULIA_HOME:=$JULIA_ROOT}"
: "${JULIA_URL:=https://julialang-s3.julialang.org}"
: "${JULIA_VERSION:=${Y_JU_JULIA_VERSION:-latest}}"
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



function resolve_julia() {

    [ "$Y_JU_JULIA_CONFIG" = 1 ] || return 0

    install2.r --error --skipmissing --skipinstalled -n "$NCPUS" \
               yaml

    # Get the latest Julia version by using R and the R yaml package.
    if [ "$JULIA_VERSION" = "latest" ]; then
        # shellcheck disable=SC2016
        JULIA_VERSION=$(Rscript -e '
js <- yaml::read_yaml("https://julialang-s3.julialang.org/bin/versions.json")
versions <- names(js)
is_stable <- unlist(Map(function(x) x$stable, js))
latest_version <- as.character(sort(numeric_version(versions[is_stable]), decreasing = TRUE)[1])
cat(latest_version)
')
    fi
    
    echo "# +++ julia: JULIA_VERSION=${JULIA_VERSION}"

}



function config_julia() {

    [ "$Y_JU_JULIA_CONFIG" = 1 ] || return 0

    sed -i 's!PATH="!PATH="/opt/julia/bin:/opt/cargo/bin:!' \
        "/etc/environment"

    cat <<EOF >>"/etc/environment"
JULIA_HOME=$JULIA_HOME
EOF
    
    
    cat <<EOF >>"${R_HOME}/etc/Renviron.site"
JULIA_HOME=$JULIA_HOME
EOF
    

    cat <<"EOF" >>"/etc/profile.d/Z91-julia.sh"
##
# julia/cargo environmnet
#
set -a
# ------------------------------------------------------
: "${JULIA_HOME:=/opt/julia}"
# ------------------------------------------------------
set +a

EOF

    
    echo "# +++ julia: PATH=${PATH}"

}






function check_julia() {
    
    [ "$Y_JU_JULIA_CHECK" = 1 ] || return 0

    echo "Verifying Julia installation..."
    
    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    
    set -x

    which -a julia  || true
    julia --version  || true
    
    set +x
    
}

function install_r_pkgs() {
    
    [ "$Y_JU_JULIA_R_PKGS" = 1 ] || return 0

    echo "Instaling Julia R packages ..."
    
    set -x

    install2.r --error --skipmissing --skipinstalled -n "$NCPUS" \
               JuliaCall \
               JuliaConnectoR
    
    set +x
    
}

function install_ju_kernel() {
    
    [ "$Y_JU_JULIA_KERNEL" = 1 ] || return 0

    echo "Instaling Julia Jupyter kernel, registered in setup ..."
    
    echo "in user environment, run : julia -e '
    using Pkg
    # Ensure IJulia is installed in the global/default environment
    Pkg.add(\"IJulia\")
    # Force rebuild to link the kernelspec to the JUPYTER path
    Pkg.build(\"IJulia\")
    '"
    
}

function install_apps() {
    
    [ "$Y_JU_JULIA_APPS" = 1 ] || return 0

    echo "Instaling Julia applications ..."
    
    set -x

    # cargo install alacritty
    
    set +x
    
}



function install_julia() {

    [ "$Y_JU_JULIA_INSTALL" = 1 ] || return 0

    echo "Instaling Julia ${JULIA_VERSION} ..."
    
    JULIA_MINOR_VERSION=${JULIA_VERSION%.*}

    ARCH_LONG=$(uname -p)
    ARCH_SHORT=$ARCH_LONG

    if [ "$ARCH_LONG" = "x86_64" ]; then
        ARCH_SHORT="x64"
    fi

    set -x

    mkdir -p /tmp/downloaded_packages
    cd /tmp/downloaded_packages


    # Download Julia and create a symbolic link.
    wget -nv "https://julialang-s3.julialang.org/bin/linux/${ARCH_SHORT}/${JULIA_MINOR_VERSION}/julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz"
    mkdir -p "${JULIA_ROOT}"
    tar zxf "julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz" -C "${JULIA_ROOT}" --strip-components 1 
    rm -f "julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz"
    ln -s "${JULIA_ROOT}/bin/julia" /usr/local/bin/julia

    cd -

    set +x

    echo "Instaling Julia ${JULIA_VERSION}, done."
    

}



function clean_up() {
    
    # Clean up
    rm -rf /var/lib/apt/lists/*
    rm -rf /tmp/downloaded_packages

    ## Strip binary installed lybraries from RSPM
    ## https://github.com/rocker-org/rocker-versioned2/issues/340
    strip /usr/local/lib/R/site-library/*/libs/*.so
}



function main() {
    
    [ "$Y_JU_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_JU_JULIA_SUPPORT" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    resolve_julia $@
    install_julia $@
    install_r_pkgs $@
    install_ju_kernel $@
    config_julia $@

    setenv_rehash    
    
    check_julia $@

    clean_up

    info "> script($0) -- DONE."

}

main $@
