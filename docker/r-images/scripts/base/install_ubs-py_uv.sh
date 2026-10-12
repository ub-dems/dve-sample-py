#!/bin/bash

## Install uv, to facilitate installation of different python versions
## Allows users to do things like:
##     uv python install 3.7.9 # install python 3.7.9; e.g. for tensorflow 1.15.x
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

: ${PYTHON_VERSION=${Y_PY_PYTHON_VERSION:-'3.14.3'}}
: ${UV_ROOT:="/usr/local/bin"}
: ${UV_INSTALL_DIR:="/usr/local/bin"}
: ${UV_TOOL_BIN_DIR:="/usr/local/bin"}
: ${UV_PYTHON_INSTALL_DIR:="/opt/uv/python"}
: ${UV_CACHE_DIR:="/opt/uv/cache"}
: ${UV_PROJECT_ENVIRONMENT:=".venv.cdk"}

: ${PYTHON_CONFIGURE_OPTS:="--enable-shared"}

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

function debug_uv() {

    [ "$Y_PY_UV_DEBUG" = 1 ] || return 0


    echo "### >> UV::DEBUG($@)"

    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    echo "UV_PYTHON_INSTALL_DIR=${UV_PYTHON_INSTALL_DIR}"
    echo "PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS}"

    set -x

    which python      || true
    which -a python3  || true

    python --version  || true

    # which    pip      || true
    # which -a pip3     || true

    # pyenv --version   || true
    # pyenv   versions  || true
    # pyenv   version   || true

    which   pipx      || true
    pipx  --version   || true
    pipx    list      || true

    set +x

    echo "### << UV::DEBUG($@)"
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

function install_uv() {

    [ "$Y_PY_UV_INSTALL" = 1 ] || return 0

    debug_uv "install_uv_uv::pre"

    curl -LsSf https://astral.sh/uv/install.sh | \
        env UV_INSTALL_DIR="$UV_INSTALL_DIR" sh

    debug_uv "install_uv_uv::post"



}

function config_uv() {

    [ "$Y_PY_UV_CONFIG" = 1 ] || return 0


}




function install_uv_python() {

    [ "$Y_PY_UV_PYTHON" = 1 ] || return 0

    debug_uv "install_uv_python::pre"

    # python setup

    uv python install ${PYTHON_VERSION} \
       --python-preference managed \
       --preview

    ## --default

    debug_uv "install_uv_python::post"


}


function config_uv_python() {

    [ "$Y_PY_UV_PYTHON" = 1 ] || return 0

    debug_uv "config_uv_python::pre"

    ## uv python update-shell
    ## setenv_rehash
    
    ## uv python pin --global

    # ── Locate the binary directly - never trust `uv python find` ────────────────
    # uv installs to: $UV_PYTHON_INSTALL_DIR/cpython-<ver>-linux-<arch>/bin/python3
    PYTHON_BIN=$(find "$UV_PYTHON_INSTALL_DIR" \
                      -path "*/cpython-${PYTHON_VERSION}*/bin/python3" \
                      -not -type d \
                     | head -1)

    if [[ -z "$PYTHON_BIN" ]]; then
        error "ERROR: Could not locate python3 binary under ${UV_PYTHON_INSTALL_DIR}"
        error "Contents: $(find "$UV_PYTHON_INSTALL_DIR" -name "python*" | sort)"
        fatal "uv python setup failed"
    fi

    debug_uv "config_uv_python::==> Found managed binary: ${PYTHON_BIN}"
    "$PYTHON_BIN" --version   # smoke test before symlinking

    # ── System-wide symlinks ──────────────────────────────────────────────────────
    PYTHON_MINOR="${PYTHON_VERSION%.*}"   # "3.14" from "3.14.3"
    ln -sf "$PYTHON_BIN" /usr/local/bin/python
    ln -sf "$PYTHON_BIN" /usr/local/bin/python3
    ln -sf "$PYTHON_BIN" "/usr/local/bin/python${PYTHON_MINOR}"

    python --version
    python3 --version

    debug_uv "config_uv_python::==> Done: $(python --version) at $(which python)"

    debug_uv "config_uv_python::post"

}

function upgrade_uv_python() {

    [ "$Y_PY_UV_UPGRADE" = 1 ] || return 0

    debug_uv "upgrade_uv_python::pre"

    # @unsupportd
    # @see: https://claude.ai/share/c50dd24f-f3d1-4636-a989-7b5c04e361c3
    #
    # error (by design):
    # "This Python installation is managed by uv and should not be modified."
    #
    #  The core principle:
    #  in a uv-managed world, nothing installs into the base Python.
    #  The base Python is a clean interpreter;
    #  all packages live in venvs (per-project) or tool envs (uv tool).
    #
    
    
    # ── pip upgrade - explicitly pinned to managed binary ────────────────────────
    # Do NOT use --system: install pip into the managed python's own site-packages
    
    # uv pip install \
    #    --python "$PYTHON_BIN" \
    #    --upgrade \
    #    pip
    
    # uv pip install \
    #    --python "$PYTHON_BIN" \
    #    --upgrade \
    #    setuptools \
    #    wheel \
    #    pipenv \
    #    numpy

    debug_uv "upgrade_uv_python::post"

}


function install_uv_extras() {

    [ "$Y_PY_UV_EXTRAS" = 1 ] || return 0

    debug_uv "install_uv_extras::pre"

    uv tool install ipython
    uv tool install cookiecutter    

    debug_uv "install_uv_extras::post"



}

function install_uv_pipx() {

    [ "$Y_PY_UV_EXTRAS" = 1 ] || return 0

    debug_uv "install_uv_pipx::pre"

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


    debug_uv "install_uv_pipx::path"

    #setenv_rehash

    # ── Install system tools via `uv tool` (replaces pipx pattern) ───────────────
    # UV_TOOL_BIN_DIR=/usr/local/bin means shims are immediately on PATH,
    # no `pipx ensurepath` or PATH export needed.
    uv tool install pipx          # available if legacy pipx is still needed

    # ── Install pipx-style global tools via pipx (if truly needed) ───────────────
    # pipx itself is now a uv tool; use UV_TOOL_BIN_DIR instead of --global
    # pycowsay example:
    uv tool install pycowsay

    # ── Smoke tests ───────────────────────────────────────────────────────────────
    uv tool list
    python --version
    python3 --version
    which -a pipx
    which -a pycowsay
    
    uv run python -c "import sys; print('sys.prefix:', sys.prefix)"
    pycowsay "uv=$(uv --version), python=$(python --version)"
    
    pipx list

    pycowsay 'moooo!'

    debug_uv "install_uv_pipx::post"


}

function install_uv_poetry() {

    [ "$Y_PY_UV_EXTRAS" = 1 ] || return 0

    debug_uv "install_uv_poetry::pre"

    uv tool install poetry

    # ── Smoke tests ───────────────────────────────────────────────────────────────
    uv tool list
    python --version
    python3 --version
    which -a poetry   || true
    
    poetry --version  || true

    debug_uv "install_uv_poetry::post"


}


function define_uv_default() {

    [ "$Y_PY_UV_DEFAULT" = 1 ] || return 0

    debug_uv "define_uv_default::pre"

    debug_uv "define_uv_default::post"

}



function check_uv() {

    [ "$Y_PY_UV_CHECK" = 1 ] || return 0

    set -x

    echo "PATH=${PATH}"
    echo "SHELL=${SHELL}"
    echo "PYTHON_CONFIGURE_OPTS=${PYTHON_CONFIGURE_OPTS}"

    which   uv        || true
    uv    --version   || true
    uv    python list || true

    which   uvx       || true
    uvx   --version   || true
    
    which python      || true
    which -a python3  || true

    python3 --version || false

    # which    pip      || true
    # which -a pip3     || true
    # pip    --version  || false

    uv tool list      || true

    set +x

}




function clean_up() {
    :
}



function main() {

    [ "$Y_PY_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_PY_UV_SUPPORT" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    install_uv

    # config_uv
    # setenv_rehash

    # install_uv_python
    # config_uv_python

    # upgrade_uv_python
    # install_uv_extras
    # install_uv_pipx
    # install_uv_poetry

    # define_uv_default

    check_uv

    clean_up

    info "> script($0) -- DONE."

}

main $@
