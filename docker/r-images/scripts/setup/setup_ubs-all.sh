#!/bin/bash
# shellcheck disable=1090,1091
## ========================================================================
## setup entry point
##
## -----------------------------------------------------------------------
## NOTE: check it 'shellcheck';
##
## `shellcheck setup_ubs-all.sh`
## ========================================================================
##


NCPUS=${NCPUS:--1}

#set -x
# ------------------------------------------------------
[ -f /etc/profile ] && source /etc/profile
[ -f ~/.profile ] && source ~/.profile
# ------------------------------------------------------
#set +x


#-----------------------------------------------------------
set -a

: ${X_CUDA_CONF:=${Y_CUDA_CONF}}
: ${X_BUILD_CONF:=${Y_BUILD_CONF}}
: ${X_META_CONF:=${Y_META_CONF}}
: ${X_RUNTIME_CONF:=${Y_RUNTIME_CONF}}
: ${X_AUTO_CONF:=${Y_AUTO_CONF}}

[ -r "${X_CUDA_CONF}" ] && source "${X_CUDA_CONF}" || true
[ -r "${X_BUILD_CONF}" ] && source "${X_BUILD_CONF}" || true
[ -r "${X_META_CONF}" ] && source "${X_META_CONF}" || true
[ -r "${X_RUNTIME_CONF}" ] && source "${X_RUNTIME_CONF}" || true
[ -r "${X_AUTO_CONF}" ] && source "${X_AUTO_CONF}" || true


# ------------------------------------------------------

: ${X_DRY:='0'}
: ${X_PID:=$$}
: ${X_SSH_OPTS:='-x'}
: ${APT_Y:='-y'}
: ${T:=$(date +%F-%H%M%S)}

: ${X_VERBOSE:=''}
: ${X_FULL_MODE:=''}
: ${X_CACHE_MODE:=''}
: ${X_DOTS_MODE:=''}
: ${X_ALL_MODE:=''}
: ${X_PYTHON_MODE:=''}
: ${X_R_MODE:=''}

: ${X_PY_MODE:='uv'}

# ------------------------------------------------------

: ${X_ENV_FILE:='.env'}
: ${X_ENV_DEFAULT:='.env.defaults'}
: ${X_ENV_STRICT:='.env.strict'}

# ------------------------------------------------------
: "${JULIA_ROOT:=~/.julia}"
# : "${JULIA_HOME:=$JULIA_ROOT}/bin"
: "${JULIA_URL:=https://julialang-s3.julialang.org}"
: "${JULIA_VERSION:=${X_JU_JULIA_VERSION:-latest}}"
: "${JULIA_CTL:=./etc/julia/juliactl.jl}"
: "${JULIA_RCALL_ENV:=./etc/julia/envs/rcall}"
# ------------------------------------------------------

: ${PYTHON_VERSION=${Y_PY_PYTHON_VERSION:-'3.14'}}
# : ${UV_ROOT:="/usr/local/bin"}
# : ${UV_INSTALL_DIR:="/usr/local/bin"}
# : ${UV_TOOL_BIN_DIR:="/usr/local/bin"}
# : ${UV_PYTHON_INSTALL_DIR:="/opt/uv/python"}
# : ${UV_CACHE_DIR:="/opt/uv/cache"}
if [ -z "$container" ]; then
: ${UV_PROJECT_ENVIRONMENT:=".venv"}
else
: ${UV_PROJECT_ENVIRONMENT:=".venv.cdk"}
fi    
: ${UV_PROJECT_ENVIRONMENT_EXT:=".venv"}
: ${UV_ENV_FILE:=$X_ENV_FILE}
: ${UV_NO_PROGRESS:="1"}


: ${PYTHON_CONFIGURE_OPTS:="--enable-shared"}

# ------------------------------------------------------

(type nvidia-smi && nvidia-smi -L) &> /dev/null \
    && X_HAS_GPU=1 || X_HAS_GPU=0;

case "$X_HAS_GPU" in
     1) export X_UV_EXTRA='gpu' ;;
     *) export X_UV_EXTRA='cpu' ;;
esac
export X_HAS_GPU

# ------------------------------------------------------

X_ENV_SCRIPT="docker/r-images/scripts/setup/environ_ubs-all.sh"

# ------------------------------------------------------
case "$0" in
    -*)
        X_SRC_NAME='setup_ubs-all.sh'
        X_SRC_SCRIPT="/rocker_scripts/setup_ubs-all.sh"
    ;;
    *)
        X_SRC_NAME="$(basename $0)"
        X_SRC_SCRIPT="$(realpath $0)"
    ;;
esac
XS=${X_SRC_SCRIPT}
# ------------------------------------------------------
X_LOC_NAME="$X_SRC_NAME"
X_LOC_SCRIPT="$X_SRC_SCRIPT"
# ------------------------------------------------------

export PAGER=cat

# ------------------------------------------------------


: ${B:=/var/lib/ans/box/init}

X_TIME="$(date '+%Y%m%d-%H%M%S.%N')"
X_TS="$(date '+%Y%m%d-%H%M')"
X_USER="$(whoami)"
X_HOST="$(hostname)"
X_PID="${X_HOST}_${BASHPID}"
X_TL="$(date '+%Y-%m-%d')"
X_TS="$(date '+%s')"
X_TM="$(date --rfc-3339=seconds)"

#X_NAME="$(basename $X_SRC_SCRIPT .sh)"
X_NAME="setup"

X_TEMP="/tmp/$(id -u)"
X_WORK="$(pwd)"
X_SAVB="./temp/_setup_"
X_SAVE="${X_SAVB}/${X_TL}"
X_LOGB="./logs/sys"
X_LOGS="${X_LOGB}/${X_TL}"
X_LOGFILE="${X_LOGS}/${X_NAME}-${X_TS}-$(id -u).log"
X_DUMPFILE="${X_LOGS}/${X_NAME}-${X_TS}-$(id -u).yml"



: ${LC_ALL:='en_US.UTF-8'}
: ${LANG:='en_US.UTF-8'}
: ${TZ:='Europe/Rome'}

# --------------------------------------------------------------
set +a

exit_usage() {

rc=0    
if [ -n "$1" ]; then
    echo "$XS -- illegal args: $*"
    echo ""
    rc=1
fi

cat <<EOF

Usage: $XS <command> [args] ...

where command is:

  --status: dump virtuaenv info
  --upgrade: force poetry lock/renv snapshot
  --help:

EOF

exit $rc

}


sl() {
    cat | sed 's/^/      %\t/' | sed 's/\t$//'
}

sl4() {
    cat | sed 's/^/           %\t/' | sed 's/\t$//'
}

sl1() {
    cat | sed -e '1d' | sed 's/^/      %\t/' | sed 's/\t$//'
}

sk() {
    cat | sed 's/^/       %\t/' | sed 's/\t$//'
}




dump_header_status() {
    cat << EOF
---
title: "setup status - project environment"
project: "${REV_ID_PROJECT}"
package: "${REV_ID_PACKAGE}"
branch: "${REV_BRANCH_NAME}"
commit: "${REV_TAG}"
hostname: "$(hostname)"
date: "$(date)"
---
EOF

}

dump_global_status() {
    cat << EOF
# {{{ --- [setup-globals] ----------------------------------

##
# setup global status: ${args}.
#
runtime:

  meta:
   version: 1.0.0
   script:
    name: "${X_SRC_NAME}"
    file: "$XS"

  revision:
   source:
    info: |
$(env | grep ^REV_ | sl)
    status: |
$(git --no-pager status | sl)

  workspce:
   paths:
    curr: "$(pwd)"
    work: "${X_WORK}"
    logs: "${X_LOGS}"
    temp: "${X_TEMP}"
   contents: |
$(ls -l pyproject.toml *.lock DESCRIPTION package.json | sl)

  host:
   hostname: "$(hostname)"
   release: |
$(lsb_release -a 2>/dev/null | sl)

  user:
   userid: "${USER}"
   home: "${HOME}"
   shell: "${SHELL}"
   id: |
$(id | sl)

  system-env:
   path: |
$(echo "${PATH}" | tr ':' '\n' | sl)
   library_path: |
$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | sl)
   python3: "$(which python3)"
   python3-version: "$(which python3 &>/dev/null && python3 --version | head -n1)"

  mount:
   df: |
$(df -h | sl)


  container:
   environ:
    mode: "${container}"
    podman: |
$( (which podman &>/dev/null && podman --version 2>&1   || echo NOOCIHOST) | sl)
    images: |
$( (which podman &>/dev/null && podman images 2>&1   || echo NOOCIIMAGES) | sl)


  gpu:
   environ:
    X_HAS_GPU: "${X_HAS_GPU}"
    pci: |
$( (lspci 2>&1  || echo NOPCI) | sl)
    nvidia: |
$( (which nvidia-smi &>/dev/null && nvidia-smi 2>&1   || echo NOGPU) | sl)


# }}} -----

EOF

}

dump_extras_status() {
    cat << EOF
# {{{ --- [setup-extras] ----------------------------------

##
# setup extra languge and tools: ${args}
#

  lang:
   summary: |
$( (./lab.sh --version) | sl)


  rust:
   environ:
    CARGO_HOME: "${CARGO_HOME}"
    RUSTUP_HOME: "${RUSTUP_HOME}"
   binaries:
    cargo:
     path: |
$( (which cargo  2>/dev/null || echo NOCARGO) | sl)
     vers: |
$( (cargo --version || echo NOCARGO) | sl)
    rustup:
     path: |
$( (which rustup  2>/dev/null || echo NORUSTUP) | sl)
     vers: |
$( (rustup --version 2>/dev/null || echo NORUSTUP) | sl)
    rustc:
     path: |
$( (which rustc  2>/dev/null || echo NORUSTC) | sl)
     vers: |
$( (rustc --version || echo NORUSTC) | sl)


  node:
   environ:
    NODE_VERSION: "${NODE_VERSION}"
    FNM_DIR: "${FNM_DIR}"
   binaries:
    fnm:
     path: |
$( (which fnm  2>/dev/null || echo NOFNM) | sl)
     vers: |
$( (fnm --version || echo NOFNM) | sl)
    node:
     path: |
$( (which node  2>/dev/null || echo NONODE) | sl)
     vers: |
$( (node --version || echo NONODE) | sl)
    npm:
     path: |
$( (which npm 2>/dev/null || echo NONPM) | sl)
     vers: |
$( (npm --version || echo NONPM) | sl)


  julia:
   environ:
    JULIA_ROOT: "${JULIA_ROOT}"
   binaries:
    julia:
     path: |
$( (which julia  2>/dev/null || echo NOJULIA) | sl)
     link: |
$( (ls -l $(which julia  2>/dev/null) || echo NOJULIA) | sl)
     vers: |
$( (which julia  &>/dev/null && julia --version || echo NOJULIA) | sl)
   envs:
     - none:
         status: |
$( (which julia  &>/dev/null && julia -e 'using Pkg; Pkg.status()' ) | sl4)
         project: |
$(find ~/.julia/environments -name Project.toml -exec ls -l {} \; | sl4)
     - base:
         status: |
$( (which julia  &>/dev/null && julia --project=@. -e 'using Pkg; Pkg.status()' ) | sl4)
         project: |
$(ls -l Project.toml | sl4)
     - rcall:
         status: |
$( (which julia  &>/dev/null && julia --project=etc/julia/envs/rcall -e 'using Pkg; Pkg.status()' ) | sl4)
         project: |
$(ls -l etc/julia/envs/rcall/*.toml | sl4)



# }}} -----

EOF

}


dump_venv_status() {
    cat << EOF

# {{{ --- [setup-venv] ----------------------------------

##
# setup python venv status: ${args}
#

  virtual-env:
   environ:
    VIRTUAL_ENV: "${VIRTUAL_ENV}"
    X_HAS_GPU: "${X_HAS_GPU}"
    X_UV_EXTRA: "${X_UV_EXTRA}"
   paths:
    path: |
$(echo "${PATH}" | tr ':' '\n' | sl)
    library_path: |
$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | sl)
   binaries:
    python: "$(which python 2>/dev/null || echo NOPYTHON )"
    python-version: "$(which python &>/dev/null && python --version || echo NOPYTHON)"
    python-mode: "${X_PY_MODE}"
    uv: "$(which uv 2>/dev/null || echo NOUV )"
    uv-version: "$(which uv &>/dev/null && uv --version || echo NOUV )"
    poetry: "$(which poetry 2>/dev/null || echo NOPOETRY )"
    poetry-version: "$(which poetry &>/dev/null && poetry --version || echo NOPOETRY )"
    uv-venv: |
$( (which uv &>/dev/null && uv python find   || echo NOUVVENV) | sl)
    poetry-venv: |
$( (which poetry &>/dev/null && poetry env info 2>/dev/null  || echo NOPOETRYVENV) | sl)

  r-bindings:
   config:
     reticulate: |
$(R -q -e 'reticulate::py_config()' | sl)

  jupyter:
   binaries:
    jupyter: "$(which jupyter 2>/dev/null || echo NOJUPYTER )"
    jupyter-version: |
$( (which jupyter &>/dev/null && jupyter --version 2>&1 || echo NOJUPYTER) | sl)
   config:
     lab-extensions: |
$( (which jupyter &>/dev/null && jupyter labextension list 2>&1 || echo NOJUPYTER) | sl)
     kernels: |
$( (which jupyter &>/dev/null && jupyter kernelspec list 2>&1 || echo NOJUPYTER) | sl)

  python-deps:
   list: |
$( (which uv &>/dev/null && uv pip list ) | sl)
   project: |
$(ls -l pyproject.toml *.lock | sl)


# }}} -----

EOF

}

dump_renv_status() {
    cat << EOF

# {{{ --- [setup-renv] ----------------------------------

##
# setup R renv status: ${args}
#

  renv:
   paths:
    path: |
$(echo "${PATH}" | tr ':' '\n' | sl)
    library_path: |
$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | sl)
   binaries:
    R: "$(which R)"
    R-version: "$(which R >/dev/null && R --version  | head -n1)"

  rdeps:
   project: |
$(ls -l DESCRIPTION renv.lock | sl)


# }}} -----

EOF

}





dump_status_full() {

    dump_header_status
    dump_global_status
    dump_extras_status

    # run in venv activated subshell

    ( activate

         dump_venv_status
         dump_renv_status
    )

}

dump_status() {

    mkdir -p $X_LOGS
    X_DUMPFILE="${X_LOGS}/${X_NAME}-${X_TS}-$(id -u).yml"

    (dump_status_full) 2>&1 | tee -a $X_DUMPFILE

    ls -l "$X_DUMPFILE"
    echo  "$X_DUMPFILE"

}

exit_status() {

    (./build.sh status)
   dump_status
   exit 0
}

# --------------------------------------------------------------

docs_renv_refs() {
    cat << 'EOF'
---
# R config

## R environment settings

* [Managing R with .Rprofile, .Renviron, Rprofile.site, Renviron.site, rsession.conf, and repos.conf](https://support.posit.co/hc/en-us/articles/360047157094-Managing-R-with-Rprofile-Renviron-Rprofile-site-Renviron-site-rsession-conf-and-repos-conf)

> R will source only one .Rprofile file.
> So if you have both a project-specific .Rprofile file and a user .Rprofile file
> that you want to use, you explicitly source the user-level .Rprofile
> at the top of your project-level .Rprofile with source("~/.Rprofile").


* [Setting same R library order in RStudio Server and command-line R](https://forum.posit.co/t/setting-same-r-library-order-in-rstudio-server-and-command-line-r/169545/3)

> Then R searches for the site-wide startup profile file of R code
> unless the command line option ‘--no-site-file’ was given.  The
> path of this file is taken from the value of the ‘R_PROFILE’
> environment variable (after tilde expansion).  If this variable is
> unset, the default is ‘R_HOME/etc/Rprofile.site’, which is used if
> it exists (which it does not in a ‘factory-fresh’ installation).

EOF

}



docs_refs() {
    docs_renv_refs
}

# --------------------------------------------------------------
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
C_Cyan='\033[0;36m'
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


exit_colors() {

    echo -e "${C_Green}  Green        ${C_OFF}"
    echo -e "${C_IGreen}  IGreen       ${C_OFF}"
    echo -e "${C_Blue}  Blue         ${C_OFF}"
    echo -e "${C_BBlue}  BBlue        ${C_OFF}"
    echo -e "${C_UBlue}  UBlue        ${C_OFF}"
    echo -e "${C_On_Blue}  On_Blue      ${C_OFF}"
    echo -e "${C_IBlue}  IBlue        ${C_OFF}"
    echo -e "${C_On_IBlue}  On_IBlue     ${C_OFF}"
    echo -e "${C_BIBlue}  BIBlue       ${C_OFF}"
    echo -e "${C_BCyan}  BCyan        ${C_OFF}"
    echo -e "${C_ICyan}  ICyan        ${C_OFF}"
    echo -e "${C_UCyan}  UCyan        ${C_OFF}"
    echo -e "${C_BICyan}  BICyan       ${C_OFF}"
    echo -e "${C_BYellow}  BYellow      ${C_OFF}"
    echo -e "${C_IYellow}  IYellow      ${C_OFF}"
    echo -e "${C_BIYellow}  BIYellow     ${C_OFF}"
    echo -e "${C_BRed}  BRed         ${C_OFF}"
    echo -e "${C_IRed}  IRed         ${C_OFF}"
    echo -e "${C_URed}  URed         ${C_OFF}"
    echo -e "${C_BIRed}  BIRed        ${C_OFF}"
    echo -e "${C_BWhite}  BWhite       ${C_OFF}"
    echo -e "${C_IWhite}  IWhite       ${C_OFF}"
    echo -e "${C_UWhite}  UWhite       ${C_OFF}"
    echo -e "${C_BIWhite}  BIWhite      ${C_OFF}"

    exit 0
    
}


CLOG=""
LCTX="-"
LOG_LEVEL=""
: ${X_ASK:="0"}

ask_exit() {
    if [ "$X_ASK" != "1" ]; then
        return 0
    fi
    printf "\n${C_BIYellow}+++ ??? $* ... [Y/n]${C_OFF}\n"
    read -t 10 z
    case "$z" in
        Y|y) return 0;;
        N|n) exit ${exit_rc:-1};;
    esac
    return 1
}
show() {
    if [ -z "${X_LOGFILE}" ]; then
        cat
    else
        cat | tee -a ${X_LOGFILE} 1>&2
    fi
}
_log() {
    local mess
    local llev
    local lwho
    llev=$(printf '%-5s' ${LOG_LEVEL:-'LOG'})
    lwho=$(printf '%s@%s' ${USER} $(hostname))
    mess="${CLOG}$(date '+%Y-%m-%d %H:%M:%S %s') | $lwho | $llev | ${LCTX} | $$ | $* ${C_OFF}"
    if [ -z "${X_LOGFILE}" ]; then
        echo -e "${mess}"
    else
        echo -e "${mess}" | tee -a ${X_LOGFILE} 1>&2
    fi
}
trace() { [ "${EX_TRACE}" = "1" ] && LOG_LEVEL='TRACE' CLOG="$C_Black" _log $*; }
dump()  { LOG_LEVEL='DUMP.' CLOG="$C_Cyan"     _log $*; }
debug() { LOG_LEVEL='DEBUG' CLOG="$C_Green"    _log $*; }
info()  { LOG_LEVEL='INFO.' CLOG="$C_BIBlue"   _log $*; }
warn()  { LOG_LEVEL='WARN.' CLOG="$C_BYellow"  _log $*; }
error() { LOG_LEVEL='ERROR' CLOG="$C_IRed"     _log $*; }
fatal() { LOG_LEVEL='FATAL' CLOG="$C_BIRed"    _log $*; }
log()   { LOG_LEVEL='_LOG_' CLOG="$C_BBlue"    _log $*; }
die ()  { fatal $*; ask_exit; }
fail () { fatal "$@"; } # halt ...
todo () { warn "#TODO: " $*; }
# --------------------------------------------------------------
rc_init() {
    exit_rc=0
}
rc_exit() {
    rc=$?
    : ${exit_rc:='0'}
    [ "${exit_rc}" = '0' ] && exit_rc=$rc

    if [ "${rc}" != '0' ]; then
        echo "$(date) - ERROR: rc=($rc) -- $*"
    fi
    return $exit_rc
}
arg_defined () {
        if [ -z "$1" ]; then
           shift
           fatal "ARG/NULL: $*"
           exit 1
        fi
}
arg_error () { fatal "ARG/ERROR: $*"; exit 1; }
env_defined () {
        name="$1"
        eval value="\$${name}"
        if [ -z "$value" ]; then
           shift
           fatal "ENV/NULL: ${name}"
           exit 1
        fi
}
env_error () { fatal "ENV/ERROR: $*"; exit 1; }
# --------------------------------------------------------------
env_dump() {

        echo "#- ARGS/SCRIPT: $XS" >> ${X_WORK}/env-args.txt
        echo -n "#- ARGS/ENV:\n"      >> ${X_WORK}/env-args.txt
        env | sed -e's/&sig=[^ &]*//' | sort >> ${X_WORK}/env-args.txt

}
check_is_root()  { [ "$(id -u)" == "0" ] || die "must run as root: $(whoami)"; }
check_not_root() { [ "$(id -u)" == "0" ] && die "caxnnot run as root: $(whoami)"; }
# --------------------------------------------------------------
mk_public_dir() {
    [ -z "$1" ] && return 1
    if [ ! -d "$1" ]; then
        mk_public_dir $(dirname $1)
        mkdir -p $1  || die "cannot create public dir: $1"
        chmod 777 $1 || die "cannot chmod public dir: $1"
    fi
}

wk_init() {
    [ -z "$X_WORK" ] && return 0
    mk_public_dir "$X_WORK"
    cd "$X_WORK"
}

wk_exit() {
    [ -z "$X_WORK" ] && return 0
}

open_logs() {
    [ -z "${X_LOGFILE}" ] && return 0
    mk_public_dir "$(dirname ${X_LOGFILE})"
    touch "${X_LOGFILE}"
}

close_logs() {
    [ -z "${X_LOGFILE}" ] && return 0
    return 0
}

_init() {
    rc_init
    wk_init
    open_logs
    _INIT_=1
}

_exit() {
    close_logs
    wk_exit
}

enter_main() {
   _init
   env_dump
}

exit_main() {
    case "$exit_rc" in
        0)
            info "+++[${X_NAME}]: OK($RC) done."
            ;;
        *)
            error "+++[${X_NAME}]: KO($RC) failed!"
            ;;
    esac
    _exit
}


# ////////////////////////////////////////////////////////////////////////


activate() {

    case "$X_PY_MODE" in
        uv)
            source ${UV_PROJECT_ENVIRONMENT}/bin/activate || \
            error "activate[uv] failed"
        ;;
        poetry)
            source $(poetry env info --path)/bin/activate || \
            error "activate[poetry] failed"

        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

}


deactivate () {
    # reset old environment variables
    if [ -n "${_OLD_VIRTUAL_PATH:-}" ] ; then
        PATH="${_OLD_VIRTUAL_PATH:-}"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi
    if [ -n "${_OLD_VIRTUAL_PYTHONHOME:-}" ] ; then
        PYTHONHOME="${_OLD_VIRTUAL_PYTHONHOME:-}"
        export PYTHONHOME
        unset _OLD_VIRTUAL_PYTHONHOME
    fi

    # This should detect bash and zsh, which have a hash command that must
    # be called to get it to forget past commands.  Without forgetting
    # past commands the $PATH changes we made may not be respected
    if [ -n "${BASH:-}" -o -n "${ZSH_VERSION:-}" ] ; then
        hash -r 2> /dev/null
    fi

    if [ -n "${_OLD_VIRTUAL_PS1:-}" ] ; then
        PS1="${_OLD_VIRTUAL_PS1:-}"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    if [ ! "${1:-}" = "nondestructive" ] ; then
    # Self destruct!
        unset -f deactivate
    fi
}

# ////////////////////////////////////////////////////////////////////////

exec_environ() {

    exec ${X_ENV_SCRIPT} "$@"

}

# ////////////////////////////////////////////////////////////////////////


do_ex_begin() {

    log ">(do_ex_begin):" "{{{ EXTERNAL:begin, ..."

    if [ -n "$container" ]; then
        die "!(do_ex_begin):" "??? EXTERNAL mode most be run outside of container=$container, fail"
    fi

    mkdir -p ~/.local/bin
    export PATH=~/.local/bin:$PATH

    export JULIA_ROOT=~/.local/share/julia
    export JULIA_HOME="$JULIA_ROOT"

    export UV_PROJECT_ENVIRONMENT="$UV_PROJECT_ENVIRONMENT_EXT"
    info "-(do_ex_begin):" "=== EXTERNAL: UV_PROJECT_ENVIRONMENT=${UV_PROJECT_ENVIRONMENT},  done."

    log "<(do_ex_begin):" "=== EXTERNAL:begin, done."

}

do_ex_end() {

    log ">(do_ex_end):" "{{{ EXTERNAL:end, ..."

    info ">(do_ex_end):" "--- run ./build.sh full to setup container runtime."
    info ">(do_ex_end):" "--- see ./build.sh --help"

    rc_ex_setup=0

    log "<(do_ex_end):" "--- EXTERNAL:end, done. }}}"

    return $rc_ex_setup

}

# ////////////////////////////////////////////////////////////////////////


do_sh_prompt() {

    log ">(do_sh_prompt):" "sh - prompt, ..."

    if ! command -v starship &> /dev/null; then
        warn "?(do_sh_prompt):" "sh - 'starship' NOTFOUND, skip"
    elif [ ! -f ~/.bashrc ]; then
        warn "?(do_sh_prompt):" "sh - ~/.bashrc NOTFOUND, skip"
    elif grep 'starship' ~/.bashrc &>/dev/null; then
        info "-(do_sh_prompt):" "sh - ~/.bashrc already configured, skip"
    else
        echo '[ "$TERM" = "dumb" ] || [ "$TERM" = "tramp" ]|| [ -n "$INSIDE_EMACS" ] || eval "$(starship init bash)"' >> ~/.bashrc
        info "-(do_sh_prompt):" "sh - 'starship' enabled in ~/.bashrc."

        # if [ ! -f ~/config/starship.toml ]; then
        #     : ${X_SH_ENV_PRESET:='no-runtime-versions'}
        #     starship preset --force ${X_SH_ENV_PRESET} -o ~/.config/starship.toml
        #     info "-(do_sh_prompt):" "sh - 'starship' preset: ${X_SH_ENV_PRESET}."
        # fi
    fi

    log "<(do_sh_prompt):" "sh - prompt, done."

}


# ////////////////////////////////////////////////////////////////////////


do_ev_dotenv() {

    log ">(do_ev_dotenv):" "ev - .env definition, ..."

    if [ -z "${X_ENV_FILE}" ]; then
        warn "?(do_ev_dotenv):" "ev - X_ENV_FILE undefined, skip"
    elif [ -f "${X_ENV_FILE}" ]; then
        info "-(do_ev_dotenv):" "ev - X_ENV_FILE=${X_ENV_FILE} found, skip"
    else
        cat "${X_ENV_DEFAULT}" | grep '^[a-zA-Z0-9_]' > "${X_ENV_STRICT}"
        cp -v "${X_ENV_STRICT}" "${X_ENV_FILE}"
        ls -l "${X_ENV_FILE}" "${X_ENV_STRICT}" "${X_ENV_DEFAULT}"
        info "-(do_ev_dotenv):" "ev - UV_ENV_FILE=${UV_ENV_FILE} created from ${X_ENV_DEFAULT}."
    fi

    log "<do_ev_dotenv):" "ev - .env definition,  done."

}



# ////////////////////////////////////////////////////////////////////////

do_py_init() {

    log ">(do_py_init):" "py - venv init, ..."

    if [ -n "$VIRTUAL_ENV" ]; then
        warn "+(do_py_init):" "py - venv active: VIRTUAL_ENV=$VIRTUAL_ENV, deactivating, ..."
        # unset irrelevant variables
        deactivate nondestructive
        warn "+(do_py_init):" "py - venv active: VIRTUAL_ENV=$VIRTUAL_ENV, deactivating, done."
    fi

    case "$X_PY_MODE" in
        uv)
            [ -n "${UV_PROJECT_ENVIRONMENT}" ] && \
                [ -d "./${UV_PROJECT_ENVIRONMENT}" ] && \
                ( ls -lda ./${UV_PROJECT_ENVIRONMENT}; \
                  log "+(do_py_init):" "py - venv detected: (rc:$?)" )
        ;;
        poetry)
            poetry env info
            poetry env list
            log "+(do_py_init):" "py - venv detected: (rc:$?)"
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    log "<(do_py_init):" "py - venv init,  done."

}


do_py_remove() {

    log ">(do_py_remove):" "py - venv remove, ..."

    case "$X_PY_MODE" in
        uv)
            [ -n "${UV_PROJECT_ENVIRONMENT}" ] && \
                [ -d "./${UV_PROJECT_ENVIRONMENT}" ] && \
                rm -rf "./${UV_PROJECT_ENVIRONMENT}"
        ;;
        poetry)
            if poetry env list > /dev/null; then
                poetry env remove $(poetry env list)
            else
                warn "venv  not found, skip"
            fi
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    log "<(do_py_remove):" "py - venv remove,  done."

}

do_py_dots() {

    log ">(do_py_dots):" "py - dots remove, ..."

    set -x

    [ -d ~/.ipython ] && rm -rf ~/.ipython
    [ -d ~/.jupyter ] && rm -rf ~/.jupyter

    set +x

    log "<(do_py_dots):" "py - dots remove,  done."

}

do_py_cache() {

    log ">(do_py_cache):" "py - cache remove, ..."

    set -x

    [ -d ~/.npm ] && rm -rf ~/.npm
    [ -d ~/.yarn ] && rm -rf ~/.yarn
    [ -d ~/.local/share/jupyter ] && rm -rf ~/.local/share/jupyter
    [ -d ~/.local/share/pipx ] && rm -rf ~/.local/share/pipx
    [ -d ~/.local/share/virtualenv ] && rm -rf ~/.local/share/virtualenv
    [ -d ~/.local/state/fnm_multishells ] && rm -rf ~/.local/state/fnm_multishells
    [ -d ~/.cache/pipx ] && rm -rf ~/.cache/pipx
    [ -d ~/.cache/pypoetry ] && rm -rf ~/.cache/pypoetry

    [ -d ./.yarn ] && rm -rf ./yarn
    [ -d ./node_modules ] && rm -rf ./node_modules/*

    set +x

    log "<(do_py_cache):" "py - cache remove,  done."

}


do_py_boot() {

    log ">(do_py_boot):" "py - boot, ..."

    case "$X_PY_MODE" in
        uv)
            if (command -v uv) > /dev/null; then
                log ":(do_py_boot):" "uv - found, skip."
            else
                log ":(do_py_boot):" "uv - not found => install uv, ..."

                curl -LsSf https://astral.sh/uv/install.sh | sh

                log ":(do_py_boot):" "uv - not found => install uv, done."
            fi

            which uv        || false
            which uvx       || false
            uv --version    || false

            : ${PYTHON_VERSION:=3.14}

            if [ -f .python-version ]; then
                PYTHON_VERSION="$(cat .python-version)"
                export PYTHON_VERSION
            fi

            if false; then # check uv python
                log ":(do_py_boot):" "uv - python found, skip."
                # uv python install --force --upgrade
            else
                log ":(do_py_boot):" "uv - python not found => install $PYTHON_VERSION, ..."

                uv python install ${PYTHON_VERSION} \
                   --python-preference managed \
                   --preview

                log ":(do_py_boot):" "uv - python not found => install $PYTHON_VERSION, done."
            fi

            which python3       || false
            python3 --version   || false


            uv tool dir
            uv tool list

            if false; then # check uv tools
                log ":(do_py_boot):" "uv - tools found, skip."
                # uv tool install --force --upgrade
            else
                log ":(do_py_boot):" "uv - tool not found => install tools, ..."

                uv tool install ipython    --no-progress
                uv tool install pipx       --no-progress
                uv tool install pycowsay   --no-progress
                uv tool install poetry     --no-progress
                uv tool install ruff       --no-progress

                log ":(do_py_boot):" "uv - python not found => install tools, done."
            fi

            uv tool dir
            uv tool list

            which ipython       || false

            # uv run python -c "import sys; print('sys.prefix:', sys.prefix)"
            py_msg="uv=$(uv --version), python=$(uv run python3 --version)"
            # py_msg="$(echo "$py_msg" | tr -d'\\')"
            pycowsay "$py_msg"
            pycowsay 'moooo!'

        ;;
        poetry)
            warn "pyenv/poetry install unsupported, skip"
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    log "<(do_py_boot):" "py - boot, done."

}


do_py_venv() {

    log ">(do_py_venv):" "py - venv define, ..."

    case "$X_PY_MODE" in
        uv)
            uv venv --clear "${UV_PROJECT_ENVIRONMENT}"
        ;;
        poetry)
            if ! poetry env list > /dev/null; then
                #poetry config virtualenvs.create true --local
                #poetry config virtualenvs.in-project false --local
                poetry env use $(which python)
                [ -L ./venv ] && rm ./venv
                #ln -s "~/$(realpath $(poetry  env info -p) --relative-to=$HOME -s)" ./venv
                info "venv $(poetry env list) defined."
                poetry env info | show
            else
                warn "venv $(poetry env list) already defined, skip"
            fi
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    log "<(do_py_venv):" "py - venv define,  done."

}


do_py_reset() {

    log ">(do_py_reset):" "py - unlock, ..."

    case "$X_PY_MODE" in
        uv)
            if [ -f ./uv.lock ]; then
                rm ./uv.lock
            else
                warn "./uv.lock not found, skip"
            fi
        ;;
        poetry)
            if [ -f ./poetry.lock ]; then
                rm ./poetry.lock
            else
                warn "./poetry.lock not found, skip"
            fi
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    do_py_remove

    log "<(do_py_reset):" "py - unlock,  done."

}

do_py_clear() {

    log ">(do_py_clear):" "py - clear($X_DOTS_MODE$X_CACHE_MODE), ..."

    do_py_remove

    if [ "$X_DOTS_MODE" = "1" ]; then
        do_py_dots
    fi

    if [ "$X_CACHE_MODE" = "1" ]; then
        do_py_cache
    fi

    log "<(do_py_clear):" "py clear($X_DOTS_MODE$X_CACHE_MODE), done."

}

do_py_lock() {

    log ">(do_py_lock):" "py - lock, ..."

    case "$X_PY_MODE" in
        uv)
            if [ ! -f ./uv.lock ]; then
                export PYTHON_KEYRING_BACKEND="keyring.backends.null.Keyring"
                uv lock --no-progress
                info "./uv.lock created."
                uv pip list
            else
                log "./uv.lock found, skip"
            fi
        ;;
        poetry)
            if [ ! -f ./poetry.lock ]; then
                export PYTHON_KEYRING_BACKEND="keyring.backends.null.Keyring"
                poetry lock
                info "./poetry.lock created."
                poetry show
            else
                log "./poetry.lock found, skip"
            fi
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    log "<(do_py_lock):" "py - lock,  done."

}

do_py_sync() {

    log ">(do_py_sync):" "py - install define, ..."

    case "$X_PY_MODE" in
        uv)
            export PYTHON_KEYRING_BACKEND="keyring.backends.null.Keyring"

            info "uv sync -- (extra: $X_UV_EXTRA) -- X_HAS_GPU=$X_HAS_GPU"

            uv sync --extra=$X_UV_EXTRA --all-groups  --no-progress

            info "uv sync -- (rc: $?) -- from $(ls -l uv.lock)"
        ;;
        poetry)
            export PYTHON_KEYRING_BACKEND="keyring.backends.null.Keyring"

            poetry install --no-interaction -vv

            info "poetry install -- (rc: $?) -- from $(ls -l poetry.lock)"
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac

    log "<(do_py_sync):" "py - install,  done."

}


do_py_reticulate() {

    log ">(do_py_reticulate):" "py - reticulate config, ..."

    # run in venv activated subshell

    ( activate

      which python
      python --version

      # @see: docker/r-images/scripts/base/install_ubs-py_lang.sh

      # R - python
      # install2.r --error --skipmissing --skipinstalled -n $NCPUS  reticulate

      case "$X_PY_MODE" in
          uv)
              eval "export X_ENV_VENV=$(realpath "./${UV_PROJECT_ENVIRONMENT}")"
          ;;
          poetry)
              eval "export X_ENV_VENV=$(poetry env info --path)"
          ;;
          *)
              error "undefined X_PY_MODE=$X_PY_MODE"
              ;;
      esac

      # @see: https://rstudio.github.io/reticulate/articles/versions.html#order-of-discovery

      eval "export X_ENV_PATH=$(bash --login -i -c 'printf \"%s\" "$PATH"' | tail -n1)"

      export RETICULATE_PYTHON_ENV="${X_ENV_VENV}"
      # RETICULATE_PYTHON_ENV=${RETICULATE_PYTHON_ENV#"$HOME"/\${HOME}}


      touch ~/.Rsession
      touch ~/.Renviron

      sed -i '/PATH=/d' \
          ~/.Renviron

      sed -i '/VIRTUAL_ENV=/d' \
          ~/.Renviron

      sed -i '/RETICULATE_PYTHON_ENV=/d' \
          ~/.Renviron

      cat <<EOR >> ~/.Renviron
PATH=${X_ENV_PATH}
#X_ENV_VENV=${X_ENV_VENV}
#VIRTUAL_ENV=${VIRTUAL_ENV}
RETICULATE_PYTHON_ENV=${RETICULATE_PYTHON_ENV}
_R_CHECK_SYSTEM_CLOCK_=0
EOR

      R -q -e 'reticulate::py_discover_config(required_module = NULL, use_environment = NULL)'

      R -e "reticulate::py_config()"

    )

    log "<(do_py_reticulate):" "py - reticulate config, done."

}

do_py_show() {

    log ">(do_py_show):" "py - show config, ..."

    case "$X_PY_MODE" in
        uv)
            # TODO(uv)
        ;;
        poetry)
        ;;
        *)
            error "undefined X_PY_MODE=$X_PY_MODE"
        ;;
    esac


    # run in venv activated subshell

    ( activate

      which python
      python --version

      case "$X_PY_MODE" in
          uv)
              case "$X_VERBOSE" in
                  1*)
                      uv pip list
                      ;;
                  12*)
                      uv tree --no-dedupe --all-groups
                      ;;
                  *)
                      ;;
              esac
          ;;
          poetry)
              case "$X_VERBOSE" in
                  1*)
                      poetry show
                      ;;
                  12*)
                      poetry show --tree
                      ;;
                  *)
                      ;;
              esac
              ;;
          *)
              error "undefined X_PY_MODE=$X_PY_MODE"
              ;;
      esac

    )

    log "<(do_py_show):" "py - show config, done."

}

# ////////////////////////////////////////////////////////////////////////


do_pj_jupyter_build() {

    log ">(do_pj_jupyter):" "pj - jupyter prepare, ..."

    # run in venv activated subshell

    ( activate

      [ -f ~/.jupyter/jupyter_server_config.py ] || \
          jupyter server --generate-config

      jupyter labextension disable "@jupyterlab/apputils-extension:announcements"


      log "-(do_pj_jupyter):" "pj - jupyter node check, ..."
      set -x
      which -a node
      node --version
      which -a jlpm
      jlpm --version
      set +x
      log "-(do_pj_jupyter):" "pj - jupyter node check (node version: $(node --version)), don"

      if [ ! -f ./.yarnrc.yml ] ; then
          warn "jupyter ./.yarnrc.yml not found, ..."
          echo "nodeLinker: node-modules"  > ./.yarnrc.yml
          info "jupyter ./.yarnrc.yml created"
      fi

      if [ ! -f ./package.json ] ; then

          warn "jupyter ./package.json not found, ..."

          jlpm init

          jlpm add --dev  \
               bash-language-server \
               dockerfile-language-server-nodejs \
               pyright \
               sql-language-server \
               typescript-language-server \
               vscode-langservers-extracted \
               yaml-language-server

          info "jupyter ./package.json created"
      fi

      if [ ! -f ./yarn.lock ] ; then

          warn "jupyter ./yarn.lock not found, ..."

          jlpm up

          info "jupyter ./yarn.lock created"
      fi

      jlpm install

      jupyter lab clean --all
      jupyter lab build
      # jupyter lab build --debug


    )

    log "<(do_pj_jupyter):" "pj - jupyter prepare,  done."

}

do_pj_irkernel_reg() {

    log ">(do_pj_irkernel):" "pj - irkernel install, ..."

    # run in venv activated subshell

    ( activate

      # @see: https://github.com/IRkernel/IRkernel

      R --quiet   -e 'IRkernel::installspec()'

      # jupyter labextension install @techrah/text-shortcuts  # for RStudio’s shortcuts

    )

    log "<(do_pj_irkernel):" "pj - irkernel install,  done."

}

do_pj_ijulia_reg() {

    log ">(do_pj_ijulia):" "pj - ijulia install, ..."

    # run in venv activated subshell

    ( activate

      # @see: https://github.com/IRkernel/IRkernel

      (command -v julia) &> /dev/null && \

          # julia -e '
          # using Pkg
          # # Ensure IJulia is installed in the global/default environment
          # Pkg.add("IJulia"; io=devnull)
          # # Force rebuild to link the kernelspec to the $JUPYTER path
          # Pkg.build("IJulia")
          # '
          
          julia_project="$(realpath ".")"
      
          julia --project \
                -e "
using IJulia;
IJulia.installkernel(
    \"Julia—Project\",
    \"--project=$julia_project\",
)"
          
          # TODO(julia) - add support for multiple external projects

    )

    log "<(do_pj_ijulia):" "pj - ijulia install,  done."

}

do_pj_ijulia_rcall_reg() {

    log ">(do_pj_ijulia_rcall):" "pj - ijulia(rcall) install, ..."

    # run in venv activated subshell

    ( activate

      # @see: https://github.com/IRkernel/IRkernel

      (command -v julia) &> /dev/null && \

          # julia -e '
          # using Pkg
          # # Ensure IJulia is installed in the global/default environment
          # Pkg.add("IJulia"; io=devnull)
          # # Force rebuild to link the kernelspec to the $JUPYTER path
          # Pkg.build("IJulia")
          # '
          
          julia_project="$(realpath "$JULIA_RCALL_ENV")"
      
          julia --project="$JULIA_RCALL_ENV" \
                -e "
using IJulia;
IJulia.installkernel(
    \"Julia—RCall\",
    \"--project=$julia_project\",
)"


    )

    log "<(do_pj_ijulia_rcall):" "pj - ijulia(rcall) install,  done."

}



do_pj_jupyter_show() {

    log ">(do_pj_jupyter_show):" "pj - jupyter show, ..."

    # run in venv activated subshell

    ( activate

      which python
      which jupyter

      python --version
      jupyter --version

      jupyter --paths

      jupyter labextension list
      jupyter kernelspec list

    )

    log "<(do_pj_jupyter_show):" "pj - jupyter show,  done."

}




# ////////////////////////////////////////////////////////////////////////

do_re_remove() {

    log ">(do_re_remove):" "re - renv packages remove, ..."

    if [ -d ~/.cache/R/renv ]; then
        chmod -R a+w ~/.cache/R/renv
        rm -rf       ~/.cache/R/renv
    else
        warn "renv not found, skip"
    fi

    log "<(do_re_remove):" "re - renv packages remove, done."

}

do_re_dots() {

    log ">(do_re_dots):" "re - dots remove, ..."

    set -x

    [ -f ~/.Renviron ] && rm -rf ~/.Renviron

    # [ -f ./renv/activate.R ] && rm -rf ./renv/activate.R

    set +x

    log "<(do_re_dots):" "re - dots remove,  done."

}

do_re_cache() {

    log ">(do_re_cache):" "re - cache remove, ..."

    set -x

    [ -d ./renv/sandbox ] && rm -rf ./renv/sandbox
    [ -d ./renv/library ] && rm -rf ./renv/library
    [ -d ./renv/local ] && rm -rf ./renv/local
    [ -d ./renv/cellar ] && rm -rf ./renv/cellar
    [ -d ./renv/lock ] && rm -rf ./renv/lock
    [ -d ./renv/python ] && rm -rf ./renv/python
    [ -d ./renv/staging ] && rm -rf ./renv/staging

    set +x

    log "<(do_re_cache):" "re - cache remove,  done."

}




do_re_clear() {

    log ">(do_re_clear):" "re - clear($X_DOTS_MODE$X_CACHE_MODE), ..."

    do_re_remove

    if [ "$X_DOTS_MODE" = "1" ]; then
        do_re_dots
    fi

    if [ "$X_CACHE_MODE" = "1" ]; then
        do_re_cache
    fi

    log "<(do_re_clear):" "re clear($X_DOTS_MODE$X_CACHE_MODE), done."

}


do_renv_init() {

    log ">(do_renv_init):" "renv - init, ..."

    # run in poetry shell -- venv activated

    if [ -f ./renv/activate.R ]; then
        log "-(do_renv_init):" "renv - init, ./renv/activate.R found: skip"
        return 0
    fi


    X_SAVE_RENV="${X_SAVE}/renv"
    X_SAVE_RENV_PRE="${X_SAVE_RENV}/init-pre"
    X_SAVE_RENV_POST="${X_SAVE_RENV}/init-post"

    mkdir -p $X_SAVE_RENV_PRE
    mkdir -p $X_SAVE_RENV_POST

    [ -f ./.Rprofile ]          && mv ./.Rprofile          $X_SAVE_RENV_PRE
    [ -f ./renv.lock ]          && mv ./renv.lock          $X_SAVE_RENV_PRE
    [ -f ./renv/settings.json ] && mv ./renv/settings.json $X_SAVE_RENV_PRE
    [ -f ./renv/activate.R ]    && mv ./renv/activate.R    $X_SAVE_RENV_PRE

    #R -q -e 'renv::init(bare=TRUE, load=FALSE)' ; rc_renv_init=$?
    R -q -e 'rspm::renv_init(bare=TRUE, load=FALSE)' ; rc_renv_init=$?

    case "$rc_renv_init" in
        0) info "=(do_renv_init):" "renv - init => ok" ;;
        *) error "#(do_renv_init):" "renv - init => KO -- (rc:$rc_renv_init)" ;;
    esac

    [ -f ./.Rprofile ]          && cp ./.Rprofile          $X_SAVE_RENV_POST
    [ -f ./renv.lock ]          && cp ./renv.lock          $X_SAVE_RENV_POST
    [ -f ./renv/settings.json ] && cp ./renv/settings.json $X_SAVE_RENV_POST
    [ -f ./renv/activate.R ]    && cp ./renv/activate.R    $X_SAVE_RENV_POST

    cp -pv $X_SAVE_RENV_PRE/.Rprofile      ./.Rprofile
    # cp -pv $X_SAVE_RENV_PRE/renv.lock    ./renv.lock
    cp -pv $X_SAVE_RENV_PRE/settings.json  ./renv/settings.json
    cp -pv $X_SAVE_RENV_POST/activate.R    ./renv/activate.R

    set -x

    [ -f $X_SAVE_RENV_PRE/.Rprofile ] && [ -f $X_SAVE_RENV_POST/.Rprofile ] && \
        diff $X_SAVE_RENV_PRE/.Rprofile $X_SAVE_RENV_POST/.Rprofile

    [ -f $X_SAVE_RENV_PRE/settings.json ] && [ -f $X_SAVE_RENV_POST/settings.json ] && \
        diff $X_SAVE_RENV_PRE/settings.json $X_SAVE_RENV_POST/settings.json


    set +x

    log "<(do_renv_sync):" "renv - install, done."

    return $rc_renv_sync
}


do_renv_sync() {

    log ">(do_renv_sync):" "renv - install, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'renv::install(dependencies = TRUE)' ; rc_renv_sync=$?

      case "$rc_renv_sync" in
          0) info "=(do_renv_sync):" "renv - install => ok" ;;
          *) error "#(do_renv_sync):" "renv - install => KO -- (rc:$rc_renv_sync)" ;;
      esac

    )

    log "<(do_renv_sync):" "renv - install, done."

    return $rc_renv_sync
}

do_renv_upgrade() {

    log ">(do_renv_upgrade):" "renv - upgrade, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'renv::upgrade()' ; rc_renv_upgrade=$?

      case "$rc_renv_upgrade" in
          0) info "=(do_renv_upgrade):" "renv - upgrade => ok" ;;
          *) error "#(do_renv_upgrade):" "renv - upgrade => KO -- (rc:$rc_renv_upgrade)" ;;
      esac

    )

    log "<(do_renv_upgrade):" "renv - upgrade, done."

    return $rc_renv_upgrade
}

do_renv_snapshot() {

    log ">(do_renv_snapshot):" "renv - snapshot, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'renv::snapshot()' ; rc_renv_snapshot=$?

      case "$rc_renv_snapshot" in
          0) info "=(do_renv_snapshot):" "renv - snapshot => ok" ;;
          *) error "#(do_renv_snapshot):" "renv - snapshot => KO -- (rc:$rc_renv_snapshot)" ;;
      esac

    )

    log "<(do_renv_snapshot):" "renv - snapshot, done."

    return $rc_renv_snapshot
}

do_renv_restore() {

    log ">(do_renv_restore):" "renv - restore, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'renv::restore()' ; rc_renv_restore=$?

      case "$rc_renv_restore" in
          0) info "=(do_renv_restore):" "renv - restore => ok" ;;
          *) error "#(do_renv_restore):" "renv - restore => KO -- (rc:$rc_renv_restore)" ;;
      esac

    )

    log "<(do_renv_restore):" "renv - restore, done."

    return $rc_renv_restore

}

do_renv_show() {

    log ">(do_renv_show):" "renv - show status, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'renv::status()'

      log ":(do_renv_show):" "Project::DESCRIPTION: $(ls -l DESCRIPTION)"
      log ":(do_renv_show):" "Project::renv.lock:   $(ls -l renv.lock)"

    )

    log "<(do_renv_show):" "renv - show status, done."

}


do_renv_reset() {

    log ">(do_renv_reset):" "renv - reset, ..."

    # run in venv activated subshell

    ( activate

      if [ -f ./renv.lock ]; then
          rm ./renv.lock
      else
          warn "./renv.lock not found, skip"
      fi

    )

    log "<(do_renv_reset):" "renv - reset, done."

}

do_cffr_citation() {

    log ">(do_cffr_citation):" "cffr - CITATION, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'cffr::cff_write_citation(cffr::cff_read("CITATION.cff"), file = "inst/CITATION")'
      rc_cffr_citation=$?

      case "$rc_cffr_citation" in
          0) info "=(do_cffr_citation):" "cffr - citation => ok" ;;
          *) error "#(do_cffr_citation):" "cffr - citation => KO -- (rc:$rc_cffr_citation)" ;;
      esac

    )

    log "<(do_cffr_citation):" "cffr - CITATION, done."

    return $rc_cffr_citation

}

do_rdev_document() {

    log ">(do_rdev_document):" "devtools::document, ..."

    # run in venv activated subshell

    ( activate

      R -q -e 'devtools::document()'
      rc_rdev_document=$?

      case "$rc_rdev_document" in
          0) info "=(do_rdev_document):" "devtools::document => ok" ;;
          *) error "#(do_rdev_document):" "devtools::document => KO -- (rc:$rc_rdev_document)" ;;
      esac

    )

    log "<(do_rdev_document):" "devtools::document, done."

    return $rc_rdev_document

}



do_re_setup() {

    log ">(do_re_setup):" "renv - setup, ..."

    do_renv_init
    do_renv_show

    if [ "$RUN_RE_RESTORE" = "1" ] && \
           [ -f ./renv.lock ]; then

        do_renv_restore ; rc_renv_restore=$?

        case "$rc_renv_restore" in
            0) ;;
            *) return $rc_renv_restore
               ;;
        esac

    else

        do_renv_sync ; rc_renv_sync=$?

        case "$rc_renv_sync" in
            0) ;;
            *) return $rc_renv_sync
               ;;
        esac

        if [ "$RUN_RE_UPGRADE" = "-1" ] ; then

            do_renv_upgrade ; rc_renv_upgrade=$?

            case "$rc_renv_upgrade" in
                0) ;;
                *) return $rc_renv_upgrade
                   ;;
            esac

        fi

        do_renv_snapshot

    fi
    do_renv_show

    log "<(do_re_setup):" "renv - setup, done."

}

do_re_force() {

    log ">(do_re_upgrade):" "renv - upgrade, ..."

    do_renv_reset
    do_renv_setup

    log "<(do_re_upgrade):" "renv - upgrade, done."

}

do_re_cffr() {

    log ">(do_re_cffr):" "cffr - setup, ..."

    do_cffr_citation

    log "<(do_re_cffr):" "cffr - setup, done."

}

do_re_doc() {

    log ">(do_re_doc):" "rdev - doc, ..."

    do_rdev_document

    log "<(do_re_doc):" "rdev - doc, done."

}

# ////////////////////////////////////////////////////////////////////////


do_ju_remove() {

    log ">(do_ju_remove):" "ju - uninstall julia, ..."


    [ -L ~/.local/bin/julia ] && rm -f ~/.local/bin/julia
    
    if [ -d "${JULIA_ROOT}" ]; then
        rm -rf       ${JULIA_ROOT}
        [ -L ~/.local/bin/julia ] && rm -f ~/.local/bin/julia
        info "julia removed from ${JULIA_ROOT}, skip"
    else
        warn "julia not found in ${JULIA_ROOT}, skip"
    fi

    log "<(do_ju_remove):" "ju - uninstall julia, done."

}

do_ju_dots() {

    log ">(do_ju_dots):" "ju - dots remove, ..."

    set -x

    [ -d ~/.julia ] && rm -rf ~/.julia

    set +x

    log "<(do_ju_dots):" "ju - dots remove,  done."

}


do_ju_cache() {

    log ">(do_ju_cache):" "ju - cache remove, ..."

    set -x

    [ -d ~/.julia/compiled ] && rm -rf ./.julia/compiled
    # [ -d ~/.julia/artifacts ] && rm -rf ./.julia/artifacts
    # [ -d ~/.julia/packages ] && rm -rf ./.julia/packages

    set +x

    log "<(do_ju_cache):" "ju - cache remove,  done."

}



ex_ju_boot() {

    log ">(do_ju_boot):" "ju - Julia install, ..."

    export JULIA_VERSION=$(python3 - <<'EOF'
import urllib.request
import json

url = "https://julialang-s3.julialang.org/bin/versions.json"
with urllib.request.urlopen(url) as response:
    js = json.loads(response.read().decode('utf-8'))

stable_versions = [v for v, d in js.items() if d.get('stable')]
print(sorted(stable_versions, key=lambda x: tuple(map(int, x.split('.'))), reverse=True)[0])
EOF
           )

    # Verify it was set correctly
    info "Latest stable Julia version is: $JULIA_VERSION"

    if [ -d "${JULIA_ROOT}" ]; then
        info "<(do_ju_boot):" "ju - Julia: $(julia --version) found in ${JULIA_ROOT}, skip."
    else

        info "Instaling Julia ${JULIA_VERSION} ..."
        
        JULIA_MINOR_VERSION=${JULIA_VERSION%.*}

        ARCH_LONG=$(uname -p)
        ARCH_SHORT=$ARCH_LONG

        if [ "$ARCH_LONG" = "x86_64" ]; then
            ARCH_SHORT="x64"
        fi

        mkdir -p /tmp/downloaded_packages
        cd /tmp/downloaded_packages

        set -x

        # Download Julia and create a symbolic link.
        wget -nv "https://julialang-s3.julialang.org/bin/linux/${ARCH_SHORT}/${JULIA_MINOR_VERSION}/julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz"
        mkdir -p "${JULIA_ROOT}"
        tar zxf "julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz" -C "${JULIA_ROOT}" --strip-components 1
        rm -f "julia-${JULIA_VERSION}-linux-${ARCH_LONG}.tar.gz"
        [ -L ~/.local/bin/julia ] && rm -f ~/.local/bin/julia
        ln -s ${JULIA_ROOT}/bin/julia ~/.local/bin/julia

        set +x

        cd -

        ls -l ~/.local/bin/julia

        info "<(do_ju_boot):" "ju - Julia: $(julia --version)."

        do_ju_cache

    fi    

    log "<(do_ju_boot):" "ju - Julia install, done."

}


do_ju_boot() {

    log ">(do_ju_boot):" "py - boot, ..."

    if (command -v juliaup) > /dev/null; then
        log ":(do_ju_boot):" "juliaup - found, skip."
    else
        log ":(do_ju_boot):" "juliaup - not found => install juliaup, ..."

        curl -fsSL https://install.julialang.org | sh -s -- \
           --yes \
           --add-to-path=no \
           --startup-selfupdate=1

        # curl -fsSL https://install.julialang.org | sh -s -- \
        #    --path "$JULIAUP_DEPOT_PATH" \
        #    --yes \
        #    --add-to-path=no \
        #    --background-selfupdate=0 \
        #    --startup-selfupdate=0
        
        log ":(do_ju_boot):" "juliaup - not found => install juliaup, done."
    fi

    log ":(do_ju_boot):" "juliaup - config path, ..."
    export PATH=~/.juliaup/bin:$PATH

    for f in "$HOME/.profile" "$HOME/.bashrc"; do
        if [ ! -f "$f" ]; then
            warn "?(do_ju_boot):" "sh - $f NOTFOUND, skip"
        elif grep '.juliaup' "$f" &>/dev/null; then
            info "-(do_ju_boot):" "sh - $f already configured, skip"
        else
            echo '[ -d ~/.juliaup/bin ] && export PATH=~/.juliaup/bin:$PATH' >> "$f"
            info "-(do_ju_boot):" "sh - '~/.juliaup/bin' added to PATH in enabled in $f."
        fi
    done    
    log ":(do_ju_boot):" "juliaup - config path, done."
    
    which juliaup   || false
    juliaup --version    || false
    
    log ":(do_ju_boot):" "juliaup - found => self update, ..."

    juliaup self update

    log ":(do_ju_boot):" "juliaup - found => self update, done."

    which juliaup   || false
    juliaup --version    || false
    
    log ":(do_ju_boot):" "juliaup - found => config, ..."
    
    juliaup config manifestversiondetect true

    log ":(do_ju_boot):" "juliaup - found => config, done."

    : ${JULIA_CHANNEL:=${JULIAUP_CHANNEL:-release}}

    if [ -f .juliaup-channel ]; then
        JULIA_CHANNEL="$(cat .juliaup-channel)"
        export JULIA_CHANNEL
    fi

    log ":(do_ju_boot):" "juliaup - channel=${JULIA_CHANNEL}"
    
    if [ "${JULIA_CHANNEL}" != "release" ]; then
        juliaup add "${JULIA_CHANNEL}"
    else
        juliaup add "${JULIA_CHANNEL}"
    fi
    juliaup default "${JULIA_CHANNEL}"
    juliaup list | grep -e "${JULIA_CHANNEL}"
    juliaup status

    if false; then # check julia
        log ":(do_ju_boot):" "juliaup - julia found, skip."
        # uv python install --force --upgrade
    else
        log ":(do_ju_boot):" "juliaup - install => update channels, ..."
        
        juliaup update

        juliaup status
        
        log ":(do_ju_boot):" "juliaup - install => update channels, done."
    fi

    which julia               || false
    realpath $(which julia)   || false
    julia --version           || false

    if false; then # check uv tools
        log ":(do_ju_boot):" "julia - tools found, skip."
        # uv tool install --force --upgrade
    else
        log ":(do_ju_boot):" "julia - tool not found => install tools, ..."

        julia -e '
using Pkg;

Pkg.add("IJulia");
Pkg.add("LanguageServer");
Pkg.add("JuliaWorkspaces");
Pkg.build("IJulia");
Pkg.build("LanguageServer");
Pkg.build("JuliaWorkspaces");

'


        log ":(do_ju_boot):" "julia - tool not found => install tools, done."
    fi

        julia -e "
using Pkg;

Pkg.status()

"

    log "<(do_ju_boot):" "ju - boot, done."

}




do_ju_venv() {

    log ">(do_ju_venv):" "ju - venv check, ..."

    if [ -f './Project.toml' ]; then
        export X_JULIA_VENV=1
        info ">(do_ju_venv):" "ju - venv defined: Project.toml found, ..."
    else
        export X_JULIA_VENV=0
        info ">(do_ju_venv):" "ju - venv undefined: Project.toml not found, ..."
    fi

    log "<(do_ju_venv):" "py - venv chech,  done."

}


do_ju_rcall_reset() {

    log ">(do_ju_reset):" "ju - unlock(rcall), ..."

    if [ -f "${JULIA_RCALL_ENV}/Manifest.toml" ]; then
        rm "${JULIA_RCALL_ENV}/Manifest.toml"
    else
        warn "${JULIA_RCALL_ENV}/Manifest.toml not found, skip"
    fi

    # do_ju_remove

    log "<(do_ju_reset):" "ju - unlock(rcall),  done."

}

do_ju_reset() {

    log ">(do_ju_reset):" "ju - unlock, ..."

    if [ -f ./Manifest.toml ]; then
        rm ./Manifest.toml
    else
        warn "./Manifest.toml not found, skip"
    fi

    do_ju_rcall_reset
    
    # do_ju_remove

    log "<(do_ju_reset):" "ju - unlock,  done."

}

do_ju_clear() {

    log ">(do_ju_clear):" "ju - clear($X_DOTS_MODE$X_CACHE_MODE), ..."

    do_ju_remove
    do_ju_cache

    # if [ "$X_DOTS_MODE" = "1" ]; then
    #     do_ju_dots
    # fi

    # if [ "$X_CACHE_MODE" = "1" ]; then
    #     do_ju_cache
    # fi

    log "<(do_ju_clear):" "ju clear($X_DOTS_MODE$X_CACHE_MODE), done."

}

do_ju_lock() {

    log ">(do_ju_lock):" "ju - lock, ..."

    rc_ju_lock=0

    juliactl="$(realpath "$JULIA_CTL")"

    if [ ! -f './Project.toml' ]; then
        info ">(do_ju_lock):" "ju - venv undefined: Project.toml not found, skip ..."
    elif [ -f './Manifest.toml' ]; then
        info ">(do_ju_lock):" "ju - lock defined: Manifest.toml found, skip ..."
    elif [ ! -x "$juliactl" ]; then
        warn ">(do_ju_lock):" "ju - juliactl missing: $juliactl not found, skip ..."
        rc_ju_lock=2
    else
        # run in venv activated subshell

        ( activate
          export JULIA_PYTHONCALL_EXE='python'
          export JULIA_CONDAPKG_BACKEND='Null'

          info "+(do_ju_lock):" "ju - juliactl lock for ./Project.toml ..."
          
          "$juliactl" lock ; rc_ju_lock=$?

          case "$rc_ju_lock" in
              0) info "juliactl sync -- (rc: $?) -- $(ls -l Manifest.toml)" ;;
              *) error "juliactl sync -- (rc: $?) -- $(ls -l Manifest.toml)" ;;
          esac

        )
    fi

    log "<(do_ju_lock):" "ju - lock,  done."

    return $rc_ju_lock

}

do_ju_sync() {

    log ">(do_ju_sync):" "ju - sync, ..."

    rc_ju_sync=0

    juliactl="$(realpath "$JULIA_CTL")"

    if [ ! -f './Project.toml' ]; then
        info ">(do_ju_sync):" "ju - venv undefined: Project.toml not found, skip ..."
    elif [ ! -f './Manifest.toml' ]; then
        warn ">(do_ju_sync):" "ju - sync defined: Manifest.toml not found, skip ..."
    elif [ ! -x "$juliactl" ]; then
        warn ">(do_ju_sync):" "ju - juliactl missing: $juliactl not found, skip ..."
        rc_ju_sync=2
    else
        # run in venv activated subshell

        ( activate
          export JULIA_PYTHONCALL_EXE='python'
          export JULIA_CONDAPKG_BACKEND='Null'

          info "+(do_ju_sync):" "ju - juliactl sync for ./Project.toml ..."
          
          "$juliactl" sync ; rc_ju_sync=$?

          case "$rc_ju_sync" in
              0) info "juliactl sync -- (rc: $?) -- $(ls -l Manifest.toml)" ;;
              *) error "juliactl sync -- (rc: $?) -- $(ls -l Manifest.toml)" ;;
          esac

        )
    fi

    log "<(do_ju_sync):" "ju - sync,  done."

    return $rc_ju_sync


}

do_ju_rcall_lock() {

    log ">(do_ju_rcall_lock):" "ju - rcall lock, ..."

    rc_ju_rcall_lock=0

    juliactl="$(realpath "$JULIA_CTL")"

    if [ ! -f "$JULIA_RCALL_ENV/Project.toml" ]; then
        info ">(do_ju_rcall_lock):" "ju - venv undefined: $JULIA_RCALL_ENV/Project.toml not found, skip ..."
    elif [ -f "$JULIA_RCALL_ENV/Manifest.toml" ]; then
        info ">(do_ju_rcall_lock):" "ju - lock defined: $JULIA_RCALL_ENV/Manifest.toml found, skip ..."
    elif [ ! -x "$juliactl" ]; then
        warn ">(do_ju_rcall_lock):" "ju - juliactl missing: $juliactl not found, skip ..."
        rc_ju_rcall_lock=2
    else
        # run in venv activated subshell

        ( activate
          export JULIA_PYTHONCALL_EXE='python'
          export JULIA_CONDAPKG_BACKEND='Null'

          info "+(do_ju_rcall_lock):" "ju - juliactl lock for $JULIA_RCALL_ENV/Project.toml ..."
          
          (  cd "$JULIA_RCALL_ENV" && \
              "$juliactl" lock ; rc_ju_rcall_lock=$?
          )

          case "$rc_ju_rcall_lock" in
              0) info "juliactl(rcall) sync -- (rc: $?) -- $(ls -l Manifest.toml)" ;;
              *) error "juliactl(rcall) sync -- (rc: $?) -- $(ls -l Manifest.toml)" ;;
          esac

        )
    fi

    log "<(do_ju_rcall_lock):" "ju - rcall lock,  done."

    return $rc_ju_rcall_lock

}

do_ju_rcall_sync() {

    log ">(do_ju_rcall_sync):" "ju - sync, ..."

    rc_ju_rcall_sync=0

    juliactl="$(realpath "$JULIA_CTL")"

    if [ ! -f "$JULIA_RCALL_ENV/Project.toml" ]; then
        info ">(do_ju_rcall_sync):" "ju - venv undefined: $JULIA_RCALL_ENV/Project.toml not found, skip ..."
    elif [ ! -f "$JULIA_RCALL_ENV/Manifest.toml" ]; then
        warn ">(do_ju_rcall_sync):" "ju - sync defined: $JULIA_RCALL_ENV/Manifest.toml not found, skip ..."
    elif [ ! -x "$juliactl" ]; then
        warn ">(do_ju_rcall_sync):" "ju - juliactl missing: $juliactl not found, skip ..."
        rc_ju_rcall_sync=2
    else
        # run in venv activated subshell

        ( activate
          export JULIA_PYTHONCALL_EXE='python'
          export JULIA_CONDAPKG_BACKEND='Null'

          info "+(do_ju_rcall_sync):" "ju - juliactl sync for $JULIA_RCALL_ENV/Project.toml ..."
          
          (  cd "$JULIA_RCALL_ENV" && \
              "$juliactl" sync ; rc_ju_rcall_sync=$?
          )

          case "$rc_ju_rcall_sync" in
              0) info "juliactl(rcall) sync -- (rc: $?) -- $(ls -l $JULIA_RCALL_ENV/Manifest.toml)" ;;
              *) error "juliactl(rcall) sync -- (rc: $?) -- $(ls -l $JULIA_RCALL_ENV/Manifest.toml)" ;;
          esac

        )
    fi

    log "<(do_ju_rcall_sync):" "ju - rcall sync,  done."

    return $rc_ju_rcall_sync


}


do_ju_connector() {

    log ">(do_ju_connector):" "ju - connector config, ..."

    # run in venv activated subshell

    ( activate

      # @see: docker/r-images/scripts/base/install_ubs-julia.sh

      # R - python
      # install2.r --error --skipmissing --skipinstalled -n $NCPUS  JuliaCall  JuliaConnectoR

      touch ~/.Rsession
      touch ~/.Renviron

      # sed -i '/JULIA_BINDIR=/d' \
      #     ~/.Renviron
      # sed -i '/JULIA_HOME=/d' \
      #     ~/.Renviron

      # julia_bindir="$(dirname "$(realpath "$(command -v julia)")")"

      # case "$julia_bindir" in
      #     "$HOME"/*)
      #         # path inside $HOME -> make it HOME-relative, expanded by R at startup
      #         julia_bindir_rel="${julia_bindir#"$HOME"/}"
      #         julia_bindir_line="JULIA_BINDIR=\"\${HOME}/${julia_bindir_rel}\""
      #         julia_home_line="JULIA_HOME=\"\${HOME}/${julia_bindir_rel}\""
      #         ;;
      #     *)
      #         # outside $HOME (e.g. /usr/bin) -> no portable form exists, keep absolute
      #         julia_bindir_line="JULIA_BINDIR=${julia_bindir}"
      #         julia_home_line="JULIA_HOME=${julia_bindir}"
      #         ;;
      # esac

      # printf '%s\n' "$julia_bindir_line" >> ~/.Renviron
      # printf '%s\n' "$julia_home_line" >> ~/.Renviron

      sed -i '/JULIA_PROJECT=/d' \
          ~/.Renviron

      julia_project="$(realpath "$JULIA_RCALL_ENV")"

      case "$julia_project" in
          "$HOME"/*)
              # path inside $HOME -> make it HOME-relative, expanded by R at startup
              julia_project_rel="${julia_project#"$HOME"/}"
              julia_project_line="JULIA_PROJECT=\"\${HOME}/${julia_project_rel}\""
              ;;
          *)
              # outside $HOME (e.g. /usr/bin) -> no portable form exists, keep absolute
              julia_project_line="JULIA_PROJECT=${julia_project}"
              ;;
      esac

      printf '%s\n' "$julia_project_line" >> ~/.Renviron
      

      sed -i '/JULIA_PYTHONCALL_EXE=/d' \
          ~/.Renviron
      sed -i '/JULIA_CONDAPKG_BACKEND=/d' \
          ~/.Renviron

      cat <<EOF >> ~/.Renviron
JULIA_PYTHONCALL_EXE=python
JULIA_CONDAPKG_BACKEND=Null
EOF

    )

    log "<(do_ju_connector):" "py - reticulate config, done."

}



do_ju_show() {

    log ">(do_ju_show):" "ju - show config, ..."

    # run in venv activated subshell

    ( activate
      export JULIA_PYTHONCALL_EXE='python'
      export JULIA_CONDAPKG_BACKEND='Null'

      which julia
      julia --version

      # Step 1: Capture the path with clean nested double quotes
      raw_julia_bindir="$(dirname "$(realpath "$(command -v julia)")")"

      # Step 2: Replace leading $HOME with ~ (using standard parameter expansion)
      julia_bindir="${raw_julia_bindir/#"$HOME"/~}"

      # julia_bindir="$(dirname "$(realpath "$(command -v julia)")")" | \
      #                         sed "s|^$HOME|~|"

      echo "JULIA_BINDIR=$julia_bindir"
      env | grep ^JULIA | sort

      julia --project -e 'using Pkg;Pkg.status()'

      # if [ -f "etc/julia/envs/rcall/Project.toml" ]; then
      #     julia --project='etc/julia/envs/rcall' -e 'using Pkg;Pkg.status()'
      # fi

    )

    log "<(do_ju_show):" "py - show config, done."

}

do_ju_rcall_show() {

    log ">(do_ju_rcall_show):" "ju - show config, ..."

    # run in venv activated subshell

    ( activate
      export JULIA_PYTHONCALL_EXE='python'
      export JULIA_CONDAPKG_BACKEND='Null'

      which julia
      julia --version

      # Step 1: Capture the path with clean nested double quotes
      raw_julia_bindir="$(dirname "$(realpath "$(command -v julia)")")"

      # Step 2: Replace leading $HOME with ~ (using standard parameter expansion)
      julia_bindir="${raw_julia_bindir/#"$HOME"/~}"

      # julia_bindir="$(dirname "$(realpath "$(command -v julia)")")" | \
      #                         sed "s|^$HOME|~|"

      echo "JULIA_BINDIR=$julia_bindir"
      env | grep ^JULIA | sort

      julia --project="$JULIA_RCALL_ENV" -e 'using Pkg;Pkg.status()'

      # if [ -f "etc/julia/envs/rcall/Project.toml" ]; then
      #     julia --project='etc/julia/envs/rcall' -e 'using Pkg;Pkg.status()'
      # fi

    )

    log "<(do_ju_rcall_show):" "py - show config, done."

}





# ////////////////////////////////////////////////////////////////////////


do_js_nvm() {

    log ">(do_js_nvm):" "js - node-js nvm install, ..."

    # Download and install nvm:
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash

    # in lieu of restarting the shell
    \. "$HOME/.nvm/nvm.sh"

    # Download and install Node.js:
    nvm install 24

    # Verify the Node.js version:
    node -v # Should print "v24.21.0".

    # Verify npm version:
    npm -v # Should print "11.19.0".

    log "<(do_js_nvm):" "js - node-js nvm , done."

}


do_js_node() {

    log ">(do_js_node):" "js - node modules install, ..."

    npm install -g markdownlint-cli2

    log "<(do_js_node):" "js - node modules install, done."

}

do_js_code() {

    log ">(do_js_code):" "js - code server config, ..."

    if [ -f ~/.config/code-server/config.yaml ] && \
       grep -q '#@setup:' ~/.config/code-server/config.yaml; then
        log ".(do_js_code):" "js - code server already configured, skip."
    else

        X_SAVE_CODE="${X_SAVE}/code"
        X_SAVE_CODE_PRE="${X_SAVE_CODE}/init-pre"
        X_SAVE_CODE_POST="${X_SAVE_CODE}/init-post"

        mkdir -p $X_SAVE_CODE_PRE
        mkdir -p $X_SAVE_CODE_POST



        [ -f ~/.config/code-server/config.yaml ] && \
            mv ~/.config/code-server/config.yaml    $X_SAVE_CODE_PRE

        if [ -f ~/.config/code-server/custom.yaml ]; then
            cp -pv ~/.config/code-server/custom.yaml ~/.config/code-server/config.yaml
        else

            mkdir -p    ~/.config/code-server
            cat <<EOF > ~/.config/code-server/config.yaml
#@setup: $(date)
bind-addr: 127.0.0.1:8686
auth: password
password: ${PASSWORD}
cert: false
EOF

        fi

        [ -f ~/.config/code-server/config.yaml ] && \
            cp ~/.config/code-server/config.yaml    $X_SAVE_CODE_POST
    fi

    log "<(do_js_code):" "js - code server config, done."

}



# ////////////////////////////////////////////////////////////////////////

parse_args_run() {

    if [ $# -lt 1 ];then
        set -- "$@" --status
    fi

    args="$@"
    log ">(args.run):" "$args"

    set -x

    RUN_EX_SETUP=0
    RUN_EV_DOTENV=0
    RUN_SH_PROMPT=0
    RUN_PY_BOOT=0
    RUN_PY_CLEAR=0
    RUN_PY_RESET=0
    RUN_PY_VENV=0
    RUN_PY_SYNC=0
    RUN_PJ_JUPYTER=0
    RUN_PY_SHOW=0
    RUN_JS_NVM=0
    RUN_JS_CODE=0
    RUN_RE_CLEAR=0
    RUN_RE_RESET=0
    RUN_RE_SETUP=0
    RUN_RE_UPGRADE=0
    RUN_RE_RESTORE=0
    RUN_RE_JUPYTER=0
    RUN_RE_SHOW=0
    RUN_RE_DOC=0
    RUN_RE_CFFR=0
    RUN_JU_BOOT=0
    RUN_JU_CLEAR=0
    RUN_JU_RESET=0
    RUN_JU_VENV=0
    RUN_JU_SYNC=0
    RUN_JU_BIND=0
    RUN_JU_SHOW=0
    RUN_JU_JUPYTER=0

    X_ALL_MODE=1
    X_EXTERNAL_MODE=0
    X_SHELL_MODE=0
    X_DOTENV_MODE=0
    X_JULIA_MODE=0
    X_PYTHON_MODE=0
    X_R_MODE=0
    X_CODE_MODE=0
    X_NVM_MODE=0
    X_NODE_MODE=0
    cmds=""

    while [ $# -gt 0 ]; do
        case "$1" in

            --external|-E)
                X_ALL_MODE='0'
                X_EXTERNAL_MODE='1'
                X_SHELL_MODE='1'
                X_DOTENV_MODE='1'
                X_PYTHON_MODE='1'
                X_JULIA_MODE='1'
                X_NVM_MODE='1'
                X_NODE_MODE='1'
                RUN_EX_SETUP=1
                RUN_SH_PROMPT=1
                RUN_EV_DOTENV=1
                RUN_PY_BOOT=1
                RUN_PY_VENV=1
                RUN_PY_SYNC=1
                RUN_PJ_JUPYTER=1
                RUN_PY_SHOW=1
                RUN_JU_BOOT=1
                RUN_JU_VENV=1
                RUN_JU_SYNC=1
                RUN_JU_SHOW=1
                RUN_JU_JUPYTER=1
                RUN_JS_NVM=1
                RUN_JS_NODE=1
                cmds="$cmds --external"
                ;;

            --dotenv)
                RUN_EV_DOTENV=1
                cmds="$cmds --dotenv"
                ;;

            --boot)
                RUN_PY_BOOT=1
                cmds="$cmds --boot"
                ;;

            --clear)
                RUN_PY_CLEAR=1
                RUN_RE_CLEAR=1
                RUN_JU_CLEAR=1
                cmds="$cmds --clear"
                ;;

            --upgrade)
                RUN_PY_RESET=1
                RUN_RE_RESET=1
                RUN_JU_RESET=1
                RUN_RE_UPGRADE="$Y_RE_RENV_UPGRADE"
                RUN_RE_RESTORE="$Y_RE_RENV_RESTORE"
                cmds="$cmds --upgrade"
                ;;

            --all)
                RUN_EV_DOTENV=1
                RUN_PY_BOOT=1
                RUN_PY_VENV=1
                RUN_PY_SYNC=1
                RUN_PY_BIND=1
                RUN_PJ_JUPYTER=1
                RUN_PY_SHOW=1
                RUN_JS_CODE=1
                RUN_JS_NODE=1
                RUN_JU_BOOT=1
                RUN_JU_VENV=1
                RUN_JU_SYNC=1
                RUN_JU_BIND=1
                RUN_JU_SHOW=1
                RUN_JU_JUPYTER=1
                RUN_RE_SETUP=1
                RUN_RE_JUPYTER=1
                RUN_RE_DOC=1
                RUN_RE_CFFR=1
                RUN_RE_UPGRADE="$Y_RE_RENV_UPGRADE"
                RUN_RE_RESTORE="$Y_RE_RENV_RESTORE"
                cmds="$cmds --install --all"
                ;;

            # --status|-s)
            #     RUN_STATUS=1
            #     RUN_PY_SHOW=1
            #     RUN_RE_SHOW=1
            #     cmds="$cmds --status"
            #     ;;

            --python|-P)
                X_ALL_MODE='0'
                X_PYTHON_MODE='1'
                cmds="$cmds -P"
                ;;

            --r|-R)
                X_ALL_MODE='0'
                X_R_MODE='1'
                cmds="$cmds -R"
                ;;

            --julia|-J)
                X_ALL_MODE='0'
                X_JULIA_MODE='1'
                cmds="$cmds -J"
                ;;

            --nvm|-N)
                X_ALL_MODE='0'
                X_NODE_MODE='1'
                RUN_JS_NVM=1
                cmds="$cmds -J"
                ;;

            --node|-JS)
                X_ALL_MODE='0'
                X_NODE_MODE='1'
                cmds="$cmds -JS"
                ;;

            --full|-F)
                X_FULL_MODE='1'
                X_CACHE_MODE='1'
                X_DOTS_MODE='1'
                cmds="$cmds -F"
                ;;

            --dots|-D)
                X_DOTS_MODE='1'
                cmds="$cmds -D"
                ;;

            --cache|-C)
                X_CACHE_MODE='1'
                cmds="$cmds -C"
                ;;

            --verbose|-v)
                X_VERBOSE='1'
                cmds="$cmds -v"
                ;;

            -vv)
                X_VERBOSE='12'
                cmds="$cmds -vv"
                ;;

            -vvv)
                X_VERBOSE='123'
                cmds="$cmds -vvv"
                ;;

            *)
                exit_usage "$@"
                ;;
        esac
        shift
    done

    PY_OPTS=""
    PY_OPTS="$PY_OPTS:$Y_PY_SYSTEM_SUPPORT"
    PY_OPTS="$PY_OPTS:$Y_PY_UV_SUPPORT"
    PY_OPTS="$PY_OPTS:$Y_PY_PYENV_SUPPORT"
    PY_OPTS="$PY_OPTS:$Y_PY_POETRY_SUPPORT"

    case "$PY_OPTS" in
        :1:*|:*:0:0:0*)
            RUN_PY_CLEAR=0
            RUN_PY_RESET=0
            RUN_PY_VENV=0
            RUN_PY_SYNC=0
            RUN_PY_SHOW=0
            ;;
        *)
            ;;
    esac

    RE_OPTS=""
    RE_OPTS="$RE_OPTS:$Y_RE_ANY_SUPPORT"
    RE_OPTS="$RE_OPTS:$Y_RE_RENV_SUPPORT"
    RE_OPTS="$RE_OPTS:$Y_RE_RENV_SYNC"

    case "$RE_OPTS" in
        :0:*|:*:0:*|:*:*:0)
            RUN_RE_CLEAR=0
            RUN_RE_RESET=0
            RUN_RE_SETUP=0
            RUN_RE_RESTORE=0
            RUN_RE_UPGRADE=0
            RUN_RE_DOC=0
            RUN_RE_CFFR=0
            RUN_RE_SHOW=0
            ;;
        *)
            ;;
    esac

    JU_OPTS=""
    JU_OPTS="$JU_OPTS:$Y_JU_ANY_SUPPORT"
    JU_OPTS="$JU_OPTS:$Y_JU_JULIA_SUPPORT"

    case "$JU_OPTS" in
        :0:*|:*:0*)
            RUN_JU_CLEAR=0
            RUN_JU_RESET=0

            RUN_JU_VENV=0
            RUN_JU_SYNC=0
            RUN_JU_SHOW=0
            ;;
        *)
            ;;
    esac

    case "$X_ALL_MODE" in
        1)
            X_DOTENV_MODE="1"
            X_PYTHON_MODE="1"
            X_R_MODE="1"
            X_JULIA_MODE="1"
            X_CODE_MODE="1"
            X_NODE_MODE="1"
            ;;
        *)  ;;
    esac


    case "$X_PYTHON_MODE" in
        0)
            RUN_PY_CLEAR=0
            RUN_PY_RESET=0
            RUN_PY_VENV=0
            RUN_PY_SYNC=0
            RUN_PY_SHOW=0
            ;;
        *)  ;;
    esac

    case "$X_R_MODE" in
        0)
            RUN_RE_CLEAR=0
            RUN_RE_RESET=0
            RUN_RE_SETUP=0
            RUN_RE_RESTORE=0
            RUN_RE_UPGRADE=0
            RUN_RE_JUPYTER=0
            RUN_RE_DOC=0
            RUN_RE_CFFR=0
            RUN_RE_SHOW=0
            ;;
        *)  ;;
    esac

    case "$X_JULIA_MODE" in
        0)
            RUN_JU_BOOT=0
            RUN_JU_CLEAR=0
            RUN_JU_RESET=0
            RUN_JU_VENV=0
            RUN_JU_SYNC=0
            RUN_JU_BIND=0
            RUN_JU_SHOW=0
            RUN_JU_JUPYTER=0
            ;;
        *)  ;;
    esac

    case "$X_CODE_MODE" in
        0)
            RUN_JS_CODE=0
            ;;
        *)  ;;
    esac

    case "$X_NODE_MODE" in
        0)
            RUN_JS_NODE=0
            ;;
        *)  ;;
    esac

    set +x

    debug "#(args): {\n $(set | sort | grep -e ^PY_OPTS -e ^RE_OPTS -e ^RUN_  -e ^X_  -e ^Y_ ) \n} ###"
    dump  "#(args): {\n $(set | sort | grep -e ^PY_OPTS -e ^RE_OPTS -e ^RUN_  -e ^X_  -e ^Y_ ) \n} ###"

    env_defined RUN_EX_SETUP
    env_defined RUN_EV_DOTENV
    env_defined RUN_SH_PROMPT

    env_defined RUN_PY_BOOT
    env_defined RUN_PY_CLEAR
    env_defined RUN_PY_RESET
    env_defined RUN_PY_SYNC
    env_defined RUN_PY_VENV
    env_defined RUN_PY_SHOW

    env_defined RUN_RE_CLEAR
    env_defined RUN_RE_RESET
    env_defined RUN_RE_SETUP
    env_defined RUN_RE_RESTORE
    env_defined RUN_RE_UPGRADE
    env_defined RUN_RE_JUPYTER
    env_defined RUN_RE_DOC
    env_defined RUN_RE_CFFR
    env_defined RUN_RE_SHOW

    env_defined RUN_JU_BOOT
    env_defined RUN_JU_CLEAR
    env_defined RUN_JU_RESET
    env_defined RUN_JU_SYNC
    env_defined RUN_JU_VENV
    env_defined RUN_JU_SHOW
    env_defined RUN_JU_BIND
    env_defined RUN_JU_JUPYTER

    env_defined RUN_JS_CODE
    env_defined RUN_JS_NVM
    env_defined RUN_JS_NODE

    log "<(args):" "cmds: $cmds"

}

main_run() {

    export X_MODE='run'

    parse_args_run "$@"

    #check_is_remote

    do_py_init
    do_renv_init

    log ">(main.run):" "args:$args -- cmds: $cmds, ..."

    if [ "$RUN_EX_SETUP" = '1' ]; then
        do_ex_begin "$@"
        rc_exit $?
    fi

    if [ "$RUN_SH_PROMPT" = '1' ]; then
        do_sh_prompt "$@"
        rc_exit $?
    fi

    if [ "$RUN_EV_DOTENV" = '1' ]; then
        do_ev_dotenv "$@"
        rc_exit $?
    fi

    if [ "$RUN_JS_NVM" = '1' ]; then
        do_js_nvm "$@"
        rc_exit $?
    fi

    if [ "$RUN_JS_NODE" = '1' ]; then
        do_js_node "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_BOOT" = '1' ]; then
        do_py_boot "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_CLEAR" = '1' ]; then
        do_py_clear "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_RESET" = '1' ]; then
        do_py_reset "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_VENV" = '1' ]; then
        do_py_venv "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_SYNC" = '1' ]; then
        do_py_lock "$@"
        do_py_sync "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_BIND" = '1' ]; then
        do_py_reticulate "$@"
        rc_exit $?
    fi

    if [ "$RUN_PY_SHOW" = '1' ]; then
        do_py_show "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_BOOT" = '1' ]; then
        do_ju_boot "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_CLEAR" = '1' ]; then
        do_ju_clear "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_RESET" = '1' ]; then
        do_ju_reset "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_VENV" = '1' ]; then
        do_ju_venv "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_SYNC" = '1' ]; then
        do_ju_lock "$@"
        do_ju_sync "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_BIND" = '1' ]; then
        do_ju_rcall_lock "$@"
        do_ju_rcall_sync "$@"
        do_ju_connector "$@"
        rc_exit $?
    fi

    if [ "$RUN_JU_SHOW" = '1' ]; then
        do_ju_show "$@"
        if [ "$RUN_JU_BIND" = '1' ]; then
            do_ju_rcall_show "$@"
        fi
        rc_exit $?
    fi

    if [ "$RUN_RE_CLEAR" = '1' ]; then
        do_re_clear "$@"
        rc_exit $?
    fi

    if [ "$RUN_RE_RESET" = '1' ]; then
        do_re_force "$@"
        rc_exit $?
    fi

    if [ "$RUN_RE_SETUP" = '1' ]; then
        do_re_setup "$@"
        rc_exit $?
    fi

    if [ "$RUN_RE_CFFR" = '1' ]; then
        do_re_cffr "$@"
        rc_exit $?
    fi

    if [ "$RUN_RE_DOC" = '1' ]; then
        do_re_doc "$@"
        rc_exit $?
    fi

    if [ "$RUN_RE_SHOW" = '1' ]; then
        do_re_show "$@"
        rc_exit $?
    fi

    if [ "$RUN_PJ_JUPYTER" = '1' ]; then
        do_pj_jupyter_build "$@"

        if [ "$RUN_JU_JUPYTER" = '1' ]; then
            do_pj_ijulia_reg "$@"
            if [ "$RUN_JU_BIND" = '1' ]; then
                do_pj_ijulia_rcall_reg "$@"
            fi
        fi

        if [ "$RUN_RE_JUPYTER" = '1' ]; then
            do_pj_irkernel_reg "$@"
        fi

        do_pj_jupyter_show "$@"
        rc_exit $?
    fi

    if [ "$RUN_JS_CODE" = '1' ]; then
        do_js_code "$@"
        rc_exit $?
    fi

    if [ "$RUN_EX_SETUP" = '1' ]; then
        do_ex_end "$@"
        rc_exit $?
    fi

    log "<(main.run):" "rc($exit_rc) -- cmds: $cmds, done."
    return $exit_rc
}



# ////////////////////////////////////////////////////////////////////////

main() {

    case "$1" in

        --help|-h)
            shift
            exit_usage "$@"
            ;;
        --colors)
            shift
            exit_colors "$@"
            ;;
        --status|-s|status)
            shift
            exit_status "$@"
            ;;
        --environ)
            shift
            exec_environ "$@"
            ;;
        *)
            ;;
    esac

    enter_main

    args="$@"
    log ">(main):" "args: $args, ..."

    case "$1" in

        *)
            main_run "$@"
            ;;
    esac

    log "<(main):" "rc($exit_rc) -- args: $args, done."

    exit_main
    exit $exit_rc

}

case "${X_DRY}" in
    0) main "$@" ;;
    *) echo "# skip: main $*"
esac
