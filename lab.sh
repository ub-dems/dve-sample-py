#!/bin/bash
##{{{
# lab.sh: jupyter lab launcher
# ==================================
#
#  "./lab.sh.sh --help" for usage info
#

E_ROOT_DIR="$(dirname $0)"


#-----------------------------------------------------------

(type nvidia-smi && nvidia-smi -L) &> /dev/null \
    && X_HAS_GPU=1 || X_HAS_GPU=0;

case "$X_HAS_GPU" in
     1) export X_UV_EXTRA='gpu' ;;
     *) export X_UV_EXTRA='cpu' ;;
esac
export X_HAS_GPU

#-----------------------------------------------------------

if [ -n "$container" ]; then
    export X_CONT_ON=1
    export X_CONT_MODE="$container"
else    
    export X_CONT_ON=0
    export X_CONT_MODE=""
fi

#-----------------------------------------------------------

cd "$E_ROOT_DIR" || true

: ${X_ENV_FILE:=".env"}

if [ -z "$UV_ENV_FILE" ]; then
    if [ -r "$X_ENV_FILE" ]; then
        export UV_ENV_FILE="$X_ENV_FILE"
    fi
fi

#-----------------------------------------------------------
set -a

: ${E_CONF_DIR:="${E_ROOT_DIR}/docker/r-images"}
: ${E_META_FILE:="${E_CONF_DIR}/project.conf"}
: ${E_CONF_FILE:="${E_CONF_DIR}/runtime.conf"}
: ${E_AUTO_FILE:="${E_CONF_DIR}/starter.conf"}

[ -r "${E_META_FILE}" ] && source "${E_META_FILE}" || true
[ -r "${E_CONF_FILE}" ] && source "${E_CONF_FILE}" || true
[ -r "${E_AUTO_FILE}" ] && source "${E_AUTO_FILE}" || true

# ------------------------------------------------------

: ${JULIA_PYTHONCALL_EXE:="python"}
: ${JULIA_CONDAPKG_BACKEND:="Null"}


# ------------------------------------------------------

: ${X_PY_RUN:="uv run"}

: ${X_LAB_EXEC:="jupyter"}
: ${X_LAB_MODE:="lab"}
: ${X_LAB_ADDR:="0.0.0.0"}
: ${X_LAB_PORT:="8888"}
: ${X_LAB_BASE:="notebooks"}
: ${X_LAB_AUTH:="--ServerApp.allow_remote_access=true"}
: ${X_LAB_USER:="--allow-root"}
: ${X_LAB_AUTO:="--no-browser"}
: ${X_LAB_OPTS:=""}

if [ -z "$X_LAB_OPTIONS" ]; then
    X_LAB_OPTIONS="$X_LAB_OPTS --ip=$X_LAB_ADDR --port=$X_LAB_PORT --notebook-dir=$X_LAB_BASE $X_LAB_AUTO $X_LAB_AUTH $X_LAB_USER"
fi    

set +a
# ------------------------------------------------------



. $(dirname $0)/functions.sh

#}}} \\\    
#{{{ [ DOCS ] /////////////////////////////////////////////////////////////////

# ---(usage)------------------------------------------------

exit_usage() {

cat <<EOF | $PAGER   

usage ./lab.sh [options]

where option are:

--help: online documentation
--version: available languages and jupyter versions

... any other options passed to jupyter lab 

to override environment:

X_LAB_PORT=8889 ./lab.sh 


ENVIRONMENNT
============

- X_LAB_EXEC: jupyter
- X_LAB_MODE: lab
- X_LAB_ADDR: 0.0.0.0
- X_LAB_PORT: 8888
- X_LAB_BASE: notebooks
- X_LAB_AUTH: --ServerApp.allow_remote_access=true
- X_LAB_USER: --allow-root
- X_LAB_AUTO: --no-browser
- X_LAB_OPTS:

- X_LAB_OPTIONS: global override

- X_PY_RUN: uv run

- X_ENV_FILE: .env
- UV_ENV_FILE: X_ENV_FILE

- X_HAS_GPU: 0|1        (autodetect)
- X_UV_EXTRA: cpu|gpu   (autodetect)

EOF

exit 1

}

# ---(version)------------------------------------------------

exit_version() {

    if [ -z "$X_LAB_INNER" ]; then
        export X_LAB_INNER=1
        exec $X_PY_RUN $0 --version
    fi    

    which java
    which java      &> /dev/null && java      --version
    which scala
    which scala     &> /dev/null && scala     -version
    which gcc
    which gcc       &> /dev/null && gcc       --version
    which gfortran
    which gfortran  &> /dev/null && gfortran  --version
    which rustc
    which rustc     &> /dev/null && rustc     --version
    which node
    which node      &> /dev/null && node      --version
    which pandoc
    which pandoc    &> /dev/null && pandoc    --version
    which lualatex
    which lualatex  &> /dev/null && lualatex  --version
    which julia
    which julia     &> /dev/null && julia     --version
    which R
    which R         &> /dev/null && R         --version
    which python
    which python    &> /dev/null && python    --version
    
    which jupyter
    which jupyter   &> /dev/null && jupyter    --version
    which jupyter   &> /dev/null && jupyter    labextension list
    which jupyter   &> /dev/null && jupyter    kernelspec   list
    
    exit 0
}

#}}} \\\
#{{{ [ MAIN ] /////////////////////////////////////////////////////////////////

# ---(exec)------------------------------------------------

run_exec() {

   cd "$E_ROOT_DIR" || true
    
   echo "${X_PY_RUN} ${X_LAB_EXEC} ${X_LAB_MODE} ${X_LAB_OPTIONS} $*"
   
   ${X_PY_RUN} ${X_LAB_EXEC} ${X_LAB_MODE} ${X_LAB_OPTIONS} "$@"
   rc=$?
   #set +x
   return $rc
}

do_exec() {
    info "> exec::(${X_LAB_EXEC} ${X_LAB_MODE}) $* -- ${X_LAB_OPTIONS}"
    run_exec "$@"
    info "< exec::(${X_LAB_EXEC} ${X_LAB_MODE}) $*  (rc: $rc)"
}


# ---(args)------------------------------------------------

parse_args_start() {

    args="$@"
    log ">(args.run):" "$args"

    cmds=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                exit_usage "$@"
                ;;
            --version)
                exit_version "$@"
                ;;
            # -x|--exec)
            #     E_EXEC_RUNNER="$2"
            #     shift
            #     ;;
            *)
                cmds="$cmds $1" 
                ;;
        esac
        shift
    done

    : ${E_EXEC_ARGS:=$cmds}

    # log "<(args.sub):" "cmds: $cmds"
            
    
}




# ---(main)------------------------------------------------

main() {

    parse_args_start "$@"
    
    do_exec ${E_EXEC_ARGS}
    exit $rc

}

main "$@"

#}}} \\\





