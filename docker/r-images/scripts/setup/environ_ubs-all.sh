#!/bin/bash

## environ entry point
##

## build ARGs
# set -e
set -x
source ${X_BUILD_CONF:-$Y_BUILD_CONF}
set +x

NCPUS=${NCPUS:--1}

#set -x
# ------------------------------------------------------
[ -f /etc/profile ] && source /etc/profile
[ -f ~/.profile ] && source ~/.profile
# ------------------------------------------------------
#set +x


set -a
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

# ------------------------------------------------------
case "$0" in
    -*)
        X_SRC_NAME='environ_ubs-all.sh'
        X_SRC_SCRIPT="/rocker_scripts/environ_ubs-all.sh"
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
X_NAME="environ"

X_TEMP="/tmp/$(id -u)"
X_WORK="$(pwd)"
X_SAVB="./temp/_environ_"
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

echo "$XS -- illegal args: $*"    
echo ""    

cat <<EOF
 
Usage: $XS <command> [args] ...

where command is:

  --status: dump virtuaenv info
  --upgrade: force uv lock/renv snapshot
  --help: 

EOF

  exit 1
}


sl() {
    cat | sed 's/^/      %\t/' | sed 's/\t$//'
}

sk() {
    cat | sed 's/^/       %\t/' | sed 's/\t$//'
}




dump_header_status() {
    cat <<EOF
#vim: set foldmethod=marker:foldlevel=0
---
title: "environ status - user environment"
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
    cat <<EOF
# {{{ --- [setup-globals] ----------------------------------

##
# environ global status: ${args}.
#


- meta:
   version: 1.0.0
   script:
    name: "${X_SRC_NAME}"
    file: "$XS"  

- revision:
   source:
    info: |
$(env | grep ^REV_ | sl)

- workspce:
   paths:
    curr: "$(pwd)"
    work: "${X_WORK}"
    logs: "${X_LOGS}"
    temp: "${X_TEMP}"
   contents: |
$(ls -l pyproject.toml poetry.lock DESCRIPTION renv.lock package.json yarn.lock | sl)

- host:
   hostname: "$(hostname)"
   release: |
$(lsb_release -a 2>/dev/null | sl)
 
- user:
   userid: "${USER}"
   home: "${HOME}"
   shell: "${SHELL}"
   id: |
$(id | sl)

- system-env:
   path: |
$(echo "${PATH}" | tr ':' '\n' | sl)
   library_path: |
$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | sl)
   python: "$(which python)"
   python-version: "$(which python >/dev/null && python --version | head -n1)"

- mount:
   df: |
$(df -h | sl)


# }}} -----
   
EOF

}

dump_extras_status() {
    cat <<EOF
# {{{ --- [setup-extras] ----------------------------------

##
# setup extra languge and tools: ${args}
#

- julia:
   environ:
    JULIA_ROOT: "${JULIA_ROOT}"
    JULIA_HOME: "${JULIA_HOME}"
   binaries:
    julia:
     path: |
$(which julia  2>/dev/null || echo "NOCARGO" | sk)
     vers: |
$(julia --version || echo "NOCARGO" | sk)


- rust:
   environ:
    CARGO_HOME: "${CARGO_HOME}"
    RUSTUP_HOME: "${RUSTUP_HOME}"
   binaries:
    cargo:
     path: |
$(which cargo  2>/dev/null || echo "NOCARGO" | sk)
     vers: |
$(cargo --version || echo "NOCARGO" | sk)
    rustup:
     path: |
$(which rustup  2>/dev/null || echo "NOCARGO" | sk)
     vers: |
$(rustup --version || echo "NOCARGO" | sk)
    rustc:
     path: |
$(which rustc  2>/dev/null || echo "NOCARGO" | sk)
     vers: |
$(rustc --version || echo "NOCARGO" | sk)


- node:
   environ:
    NODE_VERSION: "${NODE_VERSION}"
    FNM_DIR: "${FNM_DIR}"
   binaries:
    fnm:
     path: |
$(which fnm  2>/dev/null || echo "NOFNM" | sk)
     vers: |
$(fnm --version || echo "NOFNM" | sk)
    node:
     path: |
$(which node  2>/dev/null || echo "NONODE" | sk)
     vers: |
$(node --version || echo "NONODE" | sk)
    npm:
     path: |
$(which npm 2>/dev/null || echo "NONPM" | sk)
     vers: |
$(npm --version || echo "NONPM" | sk)

 

# }}} -----
   
EOF

}


dump_venv_status() {
    cat <<EOF
# {{{ --- [setup-venv] ----------------------------------
    
##
# setup python venv status: ${args}
#

#    poetry-venv: |
# $(poetry env info | sl)

- virtual-env:
   paths:
    path: |
$(echo "${PATH}" | tr ':' '\n' | sl)
    library_path: |
$(echo "${LD_LIBRARY_PATH}" | tr ':' '\n' | sl)
    python: "$(which python || echo NOPYTHON)"
    python-version: "$(python --version || echo NOPYTHON)"
    uv: "$(which uv || echo NOUV)"
    uv-version: "$(uv --version || echo NOUV)"
    poetry: "$(which poetry || echo NOPOETRY)"
    poetry-version: "$(poetry --version || echo NOPOETRY)"
    jupyter: "$(which jupyter || echo NOJUPYTER)"
    jupyter-version: "$(jupyter --version || echo NOJUPYTER)"

- r-bindings:
   config:
     reticulate: |
$(R -e "reticulate::py_config()" | sl)

- jupyter:
   paths:
    jupyter-version: "$(which jupyter 2>/dev/null && jupyter --version)"
   config:
     lab-extensions: |
$(jupyter labextension list || echo "NOJUPYTER" | sl)
     kernels: |
$(jupyter kernelspec list || echo "NOJUPYTER" | sl)

- python-deps
   list: |
$((uv pip list || poetry show) | sl)
   project: |
$(ls -l pyproject.toml poetry.lock uv.lock | sl)
 

# }}} -----
   
EOF

}

dump_renv_status() {
    cat <<EOF
# {{{ --- [setup-renv] ----------------------------------
    
##
# setup R renv status: ${args}
#

- renv:
   paths:
    path: |
$(echo "${PATH}" | tr ':' '\n' | sl)
    library_path: |
$(echo "${LD_LIBRARY_PATH" | tr ':' '\n' | sl)
    R: "$(which R)"
    R-version: "$(which R >/dev/null && R --version | tr '"' '\'' | head -n1)"

- rdeps
   project: |
$(ls -l DESCRIPTION renv.lock | sl)
 

# }}} -----
   
EOF

}





dump_status_full() {
    
    dump_header_status
    dump_global_status
    dump_extras_status
    
    if poetry env list > /dev/null; then
        ( source $(poetry env info --path)/bin/activate

            dump_venv_status
            dump_renv_status

            
          which python
          python --version

          R -q -e 'reticulate::py_discover_config(required_module = NULL, use_environment = NULL)'

          R -e "reticulate::py_config()"
          
          
        )
    else
        (
            dump_renv_status
        )
    fi
}

dump_status() {

    mkdir -p $X_LOGS
    X_DUMPFILE="${X_LOGS}/${X_NAME}-${X_TS}-$(id -u).yml"

    (dump_status_full) 2>&1 | tee -a $X_DUMPFILE 

    ls -l "$X_DUMPFILE"
    echo  "$X_DUMPFILE"
    
}

exit_status() {
    
    dump_status
    exit 0
}

# --------------------------------------------------------------

docs_renv_refs() {
    cat <<'EOF'
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
fail () { fatal $@; } # halt ...
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
check_not_root() { [ "$(id -u)" == "0" ] && die "cannot run as root: $(whoami)"; }
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

do_us_init() {

    log ">(do_us_init):" "us - init directories, ..."

    [ -d ~/.local/bin ] || mkdir -p ~/.local/bin

    log "<(do_us_init):"  "us - init directories, ..."
    
}


do_us_xdg() {

    [ "$Y_US_HOME_XDG" = 1 ] || return 0
    
    log ">(do_us_xdg):" "us - xdg directories, ..."

    # # share XDG directories
    # xdg_dirs=("Desktop" "Documents" "Downloads" "Pictures")

    # for xdg_dir in "${xdg_dirs[@]}"; do
    #     [ -e ~/$xdg_dir ] || \
    #         [ -e ~/.import/$xdg_dir ] && \
    #             ln -sr  ~/.import/$xdg_dir ./$xdg_dir
    # done

    log "<(do_us_xdg):"  "us - xgd directories, done."
    
}


do_us_ssh() {

    [ "$Y_US_HOME_SSH" = 1 ] || return 0
    
    log ">(do_us_ssh):" "us - ssh config, ..."

    [ -d ~/.ssh ] && {
        log ">(do_us_ssh)." "us - ~/.ssh present, skip"
        return 0
    }

    echo 'y' | ssh-keygen -f ~/.ssh/id_rsa -P '' -t rsa -b 4096

    ssh_keys=(~/.import/.ssh/id*)

    for ssh_key in "${ssh_keys[@]}"; do
        cp -pv  $ssh_key ~/.ssh
    done
    
    ssh_files=(~/.import/.ssh/config ~/.import/.ssh/known_hosts)

    for ssh_file in "${ssh_files[@]}"; do
        [ -e $ssh_file ] && \
            cp -pv  $ssh_file ~/.ssh
    done
    
    log "<(do_us_ssh):"  "us - ssh config, done"
    
}

do_us_git() {

    [ "$Y_US_HOME_GIT" = 1 ] || return 0
    
    log ">(do_us_git):" "us - git config, ..."

    git_files=(".gitconfig" ".git-credentials")

    for git_file in "${git_files[@]}"; do
        [ -e ~/$git_file ] || { \
            [ -e ~/.import/$git_file ] && \
                cp -pv  ~/.import/$git_file ~/$git_file
        }
            
    done
    
    log "<(do_us_git):"  "us - git config, done"
    
}

do_us_bash() {

    [ "$Y_US_HOME_BASH" = 1 ] || return 0
    
    log ">(do_us_bash):" "us - bash config, ..."

    bash_files=(".bashrc" ".bash_aliases" ".aliases")

    for bash_file in "${bash_files[@]}"; do
        [ -e ~/$bash_file ] || { \
            [ -e ~/.import/$bash_file ] && \
                cp -pv  ~/.import/$bash_file ~/$bash_file
        }
    done
    
    log "<(do_us_bash):"  "us - bash config, done"
    
}

do_us_zsh() {

    [ "$Y_US_HOME_ZSH" = 1 ] || return 0
    
    log ">(do_us_zsh):" "us - zsh config, ..."

    [ -e ~/.oh-my-zsh ] || { \
        [ -e ~/.import/.oh-my-zsh ] && \
            cp -pv  ~/.import/.zsetup ~/.zsetup && \
            (zsh ~/.zsetup < /dev/null 2>&1 | tee /dev/null)
        }
        

    zsh_files=(".zprofile" ".zshrc" ".zshenv" ".zsh_aliases" ".zlogin" ".aliases")

    for zsh_file in "${zsh_files[@]}"; do
        [ -e ~/$zsh_file ] || { \
            [ -e ~/.import/$zsh_file ] && \
                cp -pv  ~/.import/$zsh_file ~/$zsh_file
        }
    done
    
    log "<(do_us_zsh):"  "us - zsh config, done"
    
}

do_us_emacs() {

    [ "$Y_US_HOME_EMACS" = 1 ] || return 0
    
    log ">(do_us_emacs):" "us - emacs config, ..."

    [ -e ~/.emacs-site ] || { \
        [ -e /usr/local/share/emacs/emacs-share/emacs-site ] && \
            ln -s /usr/local/share/emacs/emacs-share/emacs-site ~/.emacs-site
        }
            
    [ -e ~/.emacs ] || { \
        [ -e ~/.import/.emacs ] && \
            cp -p  ~/.import/.emacs ~/.emacs
        }
            
    [ -e ~/.emacs-start.el ]  || { \
        [ -e ~/.emacs-site/site-start.el ] && \
            ln -sr  ~/.emacs-site/site-start.el ~/.emacs-start.el 
        }
            
    [ -d ~/.emacs.d ] || { \
        [ -d ~/.import/.emacs.d ] && \
            cp -rp ~/.import/.emacs.d ~/.emacs.d 
        }

    log "<(do_us_emacs):"  "us - emacs config, done"
    
}

do_us_cursor() {

    [ "$Y_US_HOME_CURSOR" = 1 ] || return 0
    
    log ">(do_us_cursor):" "us - cursor config, ..."

    warn "?(do_us_cursor):" "us - TODO(cursor config), ..."

    log "<(do_us_cursor):"  "us - cursor config, done"
    
}

# ////////////////////////////////////////////////////////////////////////



# ////////////////////////////////////////////////////////////////////////

parse_args_run() {
    
    if [ $# -lt 1 ];then
        set -- $@ --status
    fi
    
    args="$@"
    log ">(args.run):" "$args"

    RUN_US_HOME_SSH=0
    RUN_US_HOME_GIT=0
    RUN_US_HOME_BASH=0
    RUN_US_HOME_ZSH=0
    RUN_US_HOME_EMACS=0
    RUN_US_HOME_CURSOR=0
    
    X_ALL_MODE=1
    X_US_MODE=0
    cmds=""

    while [ $# -gt 0 ]; do
        case "$1" in
            
            --clear)
                RUN_US_CLEAR=1
                cmds="$cmds --clear"
                ;;
            
            --upgrade)
                RUN_US_RESET=1
                cmds="$cmds --upgrade"
                ;;
            
            --all)
                RUN_US_HOME_SSH=1
                RUN_US_HOME_GIT=1
                RUN_US_HOME_BASH=1
                RUN_US_HOME_ZSH=1
                RUN_US_HOME_EMACS=1
                RUN_US_HOME_CURSOR=1
                cmds="$cmds --install --all"
                ;;
            
            --status|-s)
                RUN_STATUS=1
                RUN_US_SHOW=1
                cmds="$cmds --status"
                ;;
            
            --home)
                X_ALL_MODE:='0'
                X_US_MODE:='1'
                RUN_US_HOME_SSH=1
                RUN_US_HOME_GIT=1
                RUN_US_HOME_BASH=1
                RUN_US_HOME_ZSH=1
                RUN_US_HOME_EMACS=1
                RUN_US_HOME_CURSOR=1
                cmds="$cmds --home"
                ;;
            
            --verbose|-v)
                X_VERBOSE:='1'
                cmds="$cmds -v"
                ;;
            
            -vv)
                X_VERBOSE:='12'
                cmds="$cmds -vv"
                ;;
            
            -vvv)
                X_VERBOSE:='123'
                cmds="$cmds -vvv"
                ;;
            
            *)
                exit_usage $@
                ;;
        esac
        shift
    done

    US_OPTS=""
    US_OPTS="$US_OPTS:$Y_US_ANY_SUPPORT"
    
    case "$US_OPTS" in
        :0:*|:*:0:*|:*:*:0)
            RUN_US_HOME_SSH=0
            RUN_US_HOME_GIT=0
            RUN_US_HOME_BASH=0
            RUN_US_HOME_ZSH=0
            RUN_US_HOME_EMACS=0
            RUN_US_HOME_CURSOR=0
            ;;
        *)
            ;;
    esac

    case "$X_ALL_MODE" in
        1)
            X_US_MODE="1"
            ;;
        *)  ;;
    esac


    case "$X_US_MODE" in
        0)
            RUN_US_HOME_SSH=0
            RUN_US_HOME_GIT=0
            RUN_US_HOME_BASH=0
            RUN_US_HOME_ZSH=0
            RUN_US_HOME_EMACS=0
            RUN_US_HOME_CURSOR=0
            ;;
        *)  ;;
    esac

    debug "#(args): {\n $(set | sort | grep -e ^RUN_  -e ^X_  -e ^Y_ ) \n} ###"
    dump  "#(args): {\n $(set | sort | grep -e ^RUN_  -e ^X_  -e ^Y_ ) \n} ###"

    env_defined RUN_US_HOME_SSH
    env_defined RUN_US_HOME_GIT
    env_defined RUN_US_HOME_BASH
    env_defined RUN_US_HOME_ZSH
    env_defined RUN_US_HOME_EMACS
    env_defined RUN_US_HOME_CURSOR
    
    log "<(args):" "cmds: $cmds"
    
}

main_run() {

    export X_MODE='run'

    parse_args_run $@

    #check_is_remote

    do_us_init
    
    log ">(main.run):" "args:$args -- cmds: $cmds, ..."

    if [ "$RUN_US_HOME_XDG" = '1' ]; then
        do_us_xdg $@
        rc_exit $?
    fi

    if [ "$RUN_US_HOME_SSH" = '1' ]; then
        do_us_ssh $@
        rc_exit $?
    fi

    if [ "$RUN_US_HOME_GIT" = '1' ]; then
        do_us_git $@
        rc_exit $?
    fi

    if [ "$RUN_US_HOME_BASH" = '1' ]; then
        do_us_bash $@
        rc_exit $?
    fi

    if [ "$RUN_US_HOME_ZSH" = '1' ]; then
        do_us_zsh $@
        rc_exit $?
    fi

    if [ "$RUN_US_HOME_EMACS" = '1' ]; then
        do_us_emacs $@
        rc_exit $?
    fi

    if [ "$RUN_US_HOME_CURSOR" = '1' ]; then
        do_us_cursor $@
        rc_exit $?
    fi

    if [ "$RUN_PY_CLEAR" = '1' ]; then
        do_py_clear $@
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
            exit_usage $@
            ;;
        --status|-s)
            shift
            exit_status $@
            ;;
        *)
            ;;
    esac
    

    enter_main
    
    args="$@"
    log ">(main):" "args: $args, ..."
    
    case "$1" in
        
        *)
            main_run $@
            ;;
    esac

    log "<(main):" "rc($exit_rc) -- args: $args, done."
    
    exit_main
    exit $exit_rc
    
}

case "${X_DRY}" in
    0) main $@ ;;
    *) echo "# skip: main $@"
esac       

