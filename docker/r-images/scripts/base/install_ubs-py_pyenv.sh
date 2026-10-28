#!/bin/bash

## Install pyenv, to facilitate installation of different python versions
## Allows users to do things like:
##     pyenv install 3.7.9 # install python 3.7.9; e.g. for tensorflow 1.15.x
##     pyenv global 3.7.9  # activate as the default python
##

## @see: https://chatgpt.com/share/6737538e-a018-8012-9b4a-431603f1558a
## @see: https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/ml_devel.Dockerfile
## @see: https://rstudio.github.io/reticulate/articles/versions.html

## build ARGs
set -e
source ${Y_BUILD_CONF:-/etc/build.conf}

NCPUS=${NCPUS:--1}


set -a
# ------------------------------------------------------

: ${PYTHON_VERSION=${Y_PY_PYTHON_VERSION:-'3.12.3'}}
: ${PYENV_ROOT:="/opt/pyenv"}
: ${PIPX_GLOBAL_HOME:="/opt/pipx"}
: ${PIPX_GLOBAL_BIN_DIR:="${PIPX_GLOBAL_HOME}/bin"}
: ${PYVENVS_ROOT:="/opt/pyvenvs"}
: ${GLOBAL_VENV:="${PYVENVS_ROOT}/global"}
: ${APP_VENV:="/opt/app-python-env"}
: ${APP_DIR:="/opt/app"}

: ${PYTHON_CONFIGURE_OPTS:="--enable-shared"}

# ${VIRTUAL_ENV:="/opt/venv"}
# ${VIRTUAL_IMG:="/opt/venv.img"}

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



function debug_pyenv() {
    
    [ "$Y_PY_PYENV_DEBUG" = 1 ] || return 0


    echo "### >> PYENV::DEBUG($@)"
    
    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    echo "PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS}"
    
    set -x
    
    which python      || true
    which -a python3  || true

    python --version  || true

    which    pip      || true
    which -a pip3     || true

    pyenv --version   || true
    pyenv   versions  || true
    pyenv   version   || true

    which   pipx      || true
    pipx  --version   || true
    pipx    list      || true
    
    set +x
    
    echo "### << PYENV::DEBUG($@)"
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

PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS:-"--enable-shared"}

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* 2> /dev/null | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

##
# Python build dependencies:
#
function install_build_deps() {

    [ "$Y_PY_PYENV_INSTALL" = 1 ] || return 0

    debug "> install python build deps, ..."

    # @see: https://devguide.python.org/getting-started/setup-building/#build-dependencies
    apt_install \
         build-essential \
         gdb \
         lcov \
         pkg-config \
         libbz2-dev \
         libffi-dev \
         libgdbm-dev \
         libgdbm-compat-dev \
         liblzma-dev \
         libncurses5-dev \
         libreadline6-dev \
         libsqlite3-dev \
         libssl-dev \
         lzma \
         lzma-dev \
         tk-dev \
         uuid-dev \
         zlib1g-dev
    # Note that Debian 12 and Ubuntu 24.04 do not have the libmpdec-dev package.
    # You can safely remove it from the install list above and
    # the Python build will use a bundled version.    
    #    libmpdec-dev

    # @see: https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    apt_install \
         build-essential \
         libssl-dev \
         zlib1g-dev \
         libbz2-dev \
         libreadline-dev \
         libsqlite3-dev \
         curl \
         git \
         libncursesw5-dev \
         xz-utils \
         tk-dev \
         libxml2-dev \
         libxmlsec1-dev \
         libffi-dev \
         liblzma-dev

    # misc
    apt_install \
        make \
        wget \
        unzip \
        llvm \
        tcllib \
        tklib \
        python3-apt \
        python3-distlib \
        python3-openssl \
        ca-certificates
    
    # @see: mysql native
    apt_install \
         mysql-client \
         libmysqlclient-dev

    # @see: 0mq
    apt_install \
         libczmq-dev

    debug "< install python build deps, done."
    
}

function install_pyenv() {

    [ "$Y_PY_PYENV_INSTALL" = 1 ] || return 0

    [ -d "$PYENV_ROOT" ] && rm -rf $PYENV_ROOT
    
# consider a version-stable alternative for the installer?
    curl https://pyenv.run | \
        env PYENV_ROOT=${PYENV_ROOT} bash

    
}

function config_pyenv() {

    [ "$Y_PY_PYENV_CONFIG" = 1 ] || return 0

    sed -i 's!PATH="!PATH="/opt/pipx/bin:/opt/pyenv/bin:!' \
        "/etc/environment"

    cat <<"EOF" >>/etc/profile.d/Z93-pyenv.sh
##
# pyenv
#

PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS:-"--enable-shared"}

### -> inhrited from container ENV
### PYENV_ROOT=/opt/pyenv
### PATH=~/.local/bin:$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PYENV_ROOT/plugins/pyenv-virtualenv/shims:$PATH

eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

PATH=$(P=$(echo -n $PATH | awk -v RS=: -v ORS=: '!($0 in a) {a[$0]; print $0}'); echo -n ${P:0:-1})

export PYENV_ROOT
export PIPX_GLOBAL_HOME
export PIPX_GLOBAL_BIN_DIR
export PYTHON_CONFIGURE_OPTS
export PATH

export X_RC_Z93_PYENV=1
EOF

    cat <<"EOB" >>/etc/bash.bashrc
if [ "$X_RC_SYSPROFILE_INCLUDED" = "1" ]; then
   [ "$X_DEBUG_ENV" = 1 ] && echo "### /etc/bash.bashrc(pyenv) {"
   [ "$X_DEBUG_ENV" = 1 ] && echo $PATH
   [ "$X_DEBUG_ENV" = 1 ] && which pyenv
   eval "$(pyenv init --path)"
   eval "$(pyenv init -)"
   eval "$(pyenv virtualenv-init -)"
   [ "$X_DEBUG_ENV" = 1 ] && echo "### /etc/bash.bashrc(pyenv) }"
fi
EOB

    eval "export X_ENV_PATH=$(bash --login -i -c 'printf \"%s\" "$PATH"' | tail -n1)"
    
    sed -i '/PATH=/d' \
        "${R_HOME}/etc/Renviron.site"

    sed -i '/VIRTUAL_ENV=/d' \
        "${R_HOME}/etc/Renviron.site"

    cat <<EOR >>"${R_HOME}/etc/Renviron.site"
PYTHON_CONFIGURE_OPTS="${PYTHON_CONFIGURE_OPTS}"
PYENV_ROOT=${PYENV_ROOT}
PYENV_SHELL=bash
PIPX_GLOBAL_HOME=${PIPX_GLOBAL_HOME}
PIPX_GLOBAL_BIN_DIR=${PIPX_GLOBAL_BIN_DIR}
PATH=${X_ENV_PATH}
EOR
    
    echo "# +++ pyenv: PATH=${PATH}"

}




function install_pyenv_python() {

    [ "$Y_PY_PYENV_PYTHON" = 1 ] || return 0

    debug_pyenv "install_pyenv_python::pre"

    # python setup

    env PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS}  \
        pyenv install $Y_PY_PYTHON_VERSION

    pyenv global $Y_PY_PYTHON_VERSION

    debug_pyenv "install_pyenv_python::post"
    

}


function config_pyenv_python() {

    [ "$Y_PY_PYENV_PYTHON" = 1 ] || return 0

    debug_pyenv "config_pyenv_python::pre"

    eval "$(pyenv virtualenv-init -)"


    # python global default

    #Y_PY_PYTHON_REVISION="$(pyenv versions | grep $Y_PY_PYTHON_VERSION | cut -c3- | cut -d' ' -f1)"
    Y_PY_PYTHON_REVISION="$(pyenv versions --bare)"
    
    #pyenv virtualenv $Y_PY_PYTHON_VERSION global
    
    #pyenv activate global

    pyenv global $Y_PY_PYTHON_VERSION

    debug_pyenv "config_pyenv_python::post"

}

function upgrade_pyenv_python() {
    
    [ "$Y_PY_PYENV_UPGRADE" = 1 ] || return 0

    debug_pyenv "upgrade_pyenv_python::pre"
    
    python3 -m pip --no-cache-dir install --upgrade --ignore-installed \
            pip
    
    python3 -m pip --no-cache-dir install --upgrade --ignore-installed \
            setuptools \
            wheel \
            pipenv \
            numpy

    debug_pyenv "upgrade_pyenv_python::post"
    
}


function install_pyenv_extras() {
    
    [ "$Y_PY_PYENV_EXTRAS" = 1 ] || return 0

    debug_pyenv "install_pyenv_extras::pre"
    
    python3 -m pip --no-cache-dir install --upgrade --ignore-installed \
            ipython \
            cookiecutter

    debug_pyenv "install_pyenv_extras::post"
    
    

}

function install_pyenv_pipx() {
    
    [ "$Y_PY_PYENV_EXTRAS" = 1 ] || return 0

    debug_pyenv "install_pyenv_pipx::pre"

# optional environment variables:
#   PIPX_HOME              Overrides default pipx location. Virtual Environments will be installed to $PIPX_HOME/venvs.
#   PIPX_GLOBAL_HOME       Used instead of PIPX_HOME when the `--global` option is given.
#   PIPX_BIN_DIR           Overrides location of app installations. Apps are symlinked or copied here.
#   PIPX_GLOBAL_BIN_DIR    Used instead of PIPX_BIN_DIR when the `--global` option is given.
#   PIPX_MAN_DIR           Overrides location of manual pages installations. Manual pages are symlinked or copied here.
#   PIPX_GLOBAL_MAN_DIR    Used instead of PIPX_MAN_DIR when the `--global` option is given.
#   PIPX_DEFAULT_PYTHON    Overrides default python used for commands.
#   USE_EMOJI              Overrides emoji behavior. Default value varies based on platform.
#   PIPX_HOME_ALLOW_SPACE  Overrides default warning on spaces in the home path

    export PIP_REQUIRE_VIRTUALENV=false
    python3 -m pip --no-cache-dir install --upgrade --ignore-installed \
            pipx

    pyenv    rehash

    python3 -m pipx ensurepath --global

    debug_pyenv "install_pyenv_pipx::path"
    
    #setenv_rehash

    pipx reinstall-all
    pipx install --global --force pycowsay 
    pipx list
    pipx run pycowsay "moooo! -- pyenv=$(pyenv --version), python=$(python --version), pipx=$(pipx --version)"

    pycowsay 'moooo!'

    debug_pyenv "install_pyenv_pipx::post"
    

}

function define_pyenv_default() {
    
    [ "$Y_PY_PYENV_DEFAULT" = 1 ] || return 0

    debug_pyenv "define_pyenv_default::pre"

    pyenv virtualenv $Y_PY_PYTHON_VERSION default


    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -d "$VIRTUAL_ENV" ]; then
            mv "${VIRTUAL_ENV}" "${VIRTUAL_ENV}.img"
        fi

        debug_pyenv "define_pyenv_default::defined"

        ln -s ${PYENV_ROOT}/versions/$Y_PY_PYTHON_VERSION/envs/default "$VIRTUAL_ENV"
        
        ls -lda ${VIRTUAL_ENV}
        ls -lda ${VIRTUAL_ENV}/*

    fi    

    debug_pyenv "define_pyenv_default::post"
    
    

}



function check_pyenv() {
    
    [ "$Y_PY_PYENV_CHECK" = 1 ] || return 0

    set -x

    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    echo "PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS}"
    
    which python      || true
    which -a python3  || true

    python --version  || false

    which    pip      || true
    which -a pip3     || true
    pip    --version  || false

    pyenv --version   || false
    pyenv   versions  || true
    pyenv   version   || true

    which   pipx      || true
    pipx  --version   || false
    
    pipx    list \
          --global    || true
    
    set +x
    
}




function clean_up() {
    :
}



function main() {
    
    [ "$Y_PY_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_PY_PYENV_SUPPORT" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    install_build_deps

    install_pyenv    
    config_pyenv    
    setenv_rehash    

    install_pyenv_python
    config_pyenv_python

    upgrade_pyenv_python
    install_pyenv_extras
    install_pyenv_pipx

    define_pyenv_default
    
    check_pyenv

    clean_up

    info "> script($0) -- DONE."

}

main $@
