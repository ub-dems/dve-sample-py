#!/bin/bash
##{{{
# runtime.sh: interface to runtime environment
# ============================================= 
#
#  custom R, Rscript, RStudio (server) process control
#
#  "./runtime.sh help" for usage info
#

#set -x   # trace mode

# --------------------------------------------------------------

E_ROOT_DIR="$(dirname $0)"
E_MAKE_FILE="${E_ROOT_DIR}/Makefile"
E_DOCKER_BASE="${E_ROOT_DIR}/docker"

#-----------------------------------------------------------
set -a

: ${E_DOCKER_NAME:="r-images"}

: ${E_CONF_DIR:="${E_DOCKER_BASE}/${E_DOCKER_NAME}"}
    
: ${E_BUILD_FILE:="${E_CONF_DIR}/build.conf"}
: ${E_CUDA_FILE:="${E_CONF_DIR}/cuda.conf"}

: ${E_META_FILE:="${E_CONF_DIR}/project.conf"}
: ${E_CONF_FILE:="${E_CONF_DIR}/runtime.conf"}
: ${E_AUTO_FILE:="${E_CONF_DIR}/starter.conf"}

[ -r "${E_CUDA_FILE}" ] && source "${E_CUDA_FILE}" || true
[ -r "${E_BUILD_FILE}" ] && source "${E_BUILD_FILE}" || true

[ -r "${E_META_FILE}" ] && source "${E_META_FILE}" || true
[ -r "${E_CONF_FILE}" ] && source "${E_CONF_FILE}" || true
[ -r "${E_AUTO_FILE}" ] && source "${E_AUTO_FILE}" || true

#-----------------------------------------------------------

: ${X_PRJ_KIND:="${X_DEF_KIND}"}

if [ "${X_PRJ_KIND}" = 'auto' ]; then
    if [ -n "$(shopt -s nullglob; echo *.Rproj)" ]; then
        X_RUN_KIND='R'
    else    
        X_RUN_KIND='P'
    fi
else    
   X_RUN_KIND="${X_PRJ_KIND}"
fi    
    
case "$X_RUN_KIND" in
    R) X_DEF_RUN_COMMAND="$X_DEF_RUN_R_COMMAND" ;;
    *) X_DEF_RUN_COMMAND="$X_DEF_RUN_P_COMMAND" ;;
esac    
        
: ${X_RUN_COMMAND:="${X_DEF_RUN_COMMAND}"}

: ${X_DEBUG:="${X_DEF_DEBUG}"}
: ${X_DEBUG_ENV:="${X_DEF_DEBUG_ENV}"}

set +a
#-----------------------------------------------------------

. $(dirname $0)/functions.sh

#}}} \\\    
#{{{ [ DOCS ] /////////////////////////////////////////////////////////////////

# ---(usage)------------------------------------------------

exit_usage() {
export LESS="-Psman runtime.sh  (press h for help or q to quit)"
cat <<EOF | $PAGER

usage $0 [target] [args, ...]

runs commands in r runtime

where "target" is

  rstudio          : runs rstudio-server bound on port 28787
  jutyper          : runs jupyter lab bound on port 28888
  notebook         : runs jupyter notebook bound on port 28888
  code             : runs visual studio code server on port 28788
  dev              : runs interactive shell in virtual environment
  repl             : runs interactive R console
  rs ...           : runs Rscript with arguments
  python           : runs interactive ipython console
  pyrun            : runs Python script with arguments
  julia            : runs interactive Julia console
  jrun             : runs Julia script with arguments
  run              : runs default autoexec script
  cli ...          : runs executable script with arguments
  test             : runs all unit tests
  check            : runs project lint checks
  clear ...        : clear all virtual environmnet and packages
  upgrade ...      : runs poetry/renv lock/snapshot inside runtime
  setup ...        : runs poetry/renv install inside runtime
  status ...       : runs poetry/renv status inside runtime
  build ...        : runs ./build.sh with arguments inside runtime
  environ ...      : imports user environment
  profile ...      : edit user environment
  raw              : runs interactive shell prompt (no-virtualenv)
  shell            : runs interactive shell prompt
  bash args,...    : runs shell with args,...
  term             : attach interactive shell to running runtime
  xterm            : attach interactive shell to running runtime (X client)


Target aliases:

   rstudio  => ide, RStudio
   jupyter  => lab
   notebook => note
   code     => vs
   dev      => ed, edit
   repl     => r, R
   rs       => rscript, Rscript
   python   => ipython
   pyrun    => py
   julia    => ju
   jrun     => jx
   run      => auto
   cli      => exec
   upgrade  => lock, snapshot
   clear    => zap
   environ  => home
   profile  => rc
   setup    => lib, install
   status   => deps, show
   build    => bld, build.sh
   test     => pytest
   check    => validate
   raw      => base, bare
   shell    => sh, prompt
   bash     => do, command
   term     => in, attach
   xterm    => X, xattach


EXAMPLES
========

RStudio
-------

 ./runtime.sh ide
 ./runtime.sh rstudio
 ./runtime.sh RStudio

 then (depending on connection client),

 if X2Go,   
   chromium-browser http://localhost:28787

 if nomachine,
   firefox http://localhost:28787

 if remote (with ssh port forwarding) from remote PC
   ssh -L28787:localhost:28787 user@vm 
   then open in browser: http://localhost:28787

RStudio login with user root, and default user password as password

Jupyter lab
-----------

 ./runtime.sh jupyter
 ./runtime.sh lab


Jupyter notebook
----------------

 ./runtime.sh notebook
 ./runtime.sh note


Visual Studio Code Server
-------------------------

 ./runtime.sh code
 ./runtime.sh vs


Dev Container Shell
-------------------

 ./runtime.sh dev
 ./runtime.sh ed


R Console
---------

 ./runtime.sh repl
 ./runtime.sh r
 ./runtime.sh R

then check 'getwd()' and exit 'q()'


R Script
---------

 ./runtime.sh rs      exec/dummy/dummy_runner.R  --help
 ./runtime.sh rscript exec/dummy/dummy_runner.R  
 ./runtime.sh Rscript exec/dummy/dummy_runner.R  

to run scripts from ./exec directory

Python run
-----------

 ./runtime.sh py uv pip list
 ./runtime.sh py ruff --check
 ./runtime.sh py pytest
 ./runtime.sh py hello --help
 ./runtime.sh py python -m http.server 8000

Python repl
-----------

 ./runtime.sh python
 ./runtime.sh ipython


Autoexec (./starter.sh) run
--------------------------

 ./runtime.sh run ...

Exec (Rscript/poetry run) run script
------------------------------------

 ./runtime.sh cli exec/dummy/dummy_runner.R  --help



=====


Build
-----

 ./runtime.sh build all
 ./runtime.sh build test
 ./runtime.sh build docs

for ./build.sh execution inside runtime container


Shell Prompt
------------

 ./runtime.sh sh
 ./runtime.sh shell
 ./runtime.sh prompt

for interactive shell prompt

Shell Command
-------------

or with command args

 ./runtime.sh do bash -c 'echo "$$(date)" ; df -h ; ip a'
 ./runtime.sh do ( inxi -F | grep -i nvidia )
 ./runtime.sh do whoami

to run execute shell commands



VIRTUAL ENVIRONMENTS
===============================

Clear
-----

 ./runtime.sh clear

for ./setup.sh (clear all) execution inside runtime container


Upgrade
-----

 ./runtime.sh upgrade

for ./setup.sh (upgrade mode) execution inside runtime container


Setup
-----

 ./runtime.sh setup

for ./setup.sh execution inside runtime container


Status
-----

 ./runtime.sh status

for ./setup.sh status reporting inside runtime container




MAPPING
=======

default volume mapping:

 ~/work => ~/work
 ~/data => ~/data

user UID/GID => root:root (0:0)

path:
  ~ := /home/$USER => ~ := /root (volatile, not shared)

workdir: 
   /root/work/../....: current project directory

EOF

exit 0

}

#}}} \\\
#{{{ [ MAIN ] /////////////////////////////////////////////////////////////////

# ---(make)------------------------------------------------

run_make() {
   make -f ${E_MAKE_FILE} $@
   rc=$?
   return $rc
}

do_make() {
    info "> make $target $@ -- ${E_MAKE_FILE}"
    export RUNTIME_ARGS="$@"
    run_make $target
    info "< make $target $@ (rc: $rc)"

}

# ---(main)------------------------------------------------

main() {
    
    target=''
    
    : ${command:=${1:-"${X_RUN_COMMAND}"}}

case "${command}" in
    repl|r|R)
        shift
        target=runtime-repl
        ;;
    rs|rscript|Rscript)
        shift
        target=runtime-rs
        ;;
    python|ipython)
        shift
        target=runtime-ipython
        ;;
    py|pyrun)
        shift
        target=runtime-pyrun
        ;;
    ju|julia)
        shift
        target=runtime-julia
        ;;
    jx|jrun)
        shift
        target=runtime-jrun
        ;;
    auto|run)
        shift
        target=runtime-auto
        ;;
    cli|exec)
        shift
        target=runtime-cli
        ;;
    bare|base|raw)
        shift
        target=runtime-raw
        ;;
    sh|shell|prompt)
        shift
        target=runtime-shell
        ;;
    bld|build|build.sh)
        shift
        target=runtime-build
        ;;
    test|pytest)
        shift
        target=runtime-test
        ;;
    check|validate)
        shift
        target=runtime-check
        ;;
    clear|zap)
        shift
        target=runtime-clear
        ;;
    lock|snapshot|upgrade)
        shift
        target=runtime-upgrade
        ;;
    lib|install|setup)
        shift
        target=runtime-setup
        ;;
    lib|install|setup)
        shift
        target=runtime-setup
        ;;
    home|environ)
        shift
        target=runtime-environ
        ;;
    rc|profile)
        shift
        target=runtime-profile
        ;;
    do|command)
        shift
        export LOG_ACTIVE='OFF'  
        target=runtime-command
        ;;
    in|term|attach)
        shift
        export LOG_ACTIVE='OFF'  
        target=runtime-term
        ;;
    X|xterm|xattach)
        shift
        export LOG_ACTIVE='OFF'  
        target=runtime-xterm
        ;;
    dev|edit|ed)
        shift
        target=runtime-dev
        ;;
    vs|code)
        shift
        target=runtime-code
        ;;
    cur|cursor)
        shift
        target=runtime-cursor
        ;;
    ag|antigravity)
        shift
        target=runtime-antigravity
        ;;
    lab|jupyter)
        shift
        target=runtime-lab
        ;;
    edit|notebook)
        shift
        target=runtime-notebook
        ;;
    ide|rstudio|RStudio)
        shift
        target=runtime-rstudio
        ;;
    
    -?|/h|-h|--help|help)
        exit_usage
        ;;
    *)
        target="runtime-${command}"
        ;;
esac

do_make $@
exit $rc

}

main $@

#}}} \\\

