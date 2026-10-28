#!/bin/bash
##{{{
# setup.sh: project virtual environment
# =============================================
#
#  (in-container) project virtual environment manager
#
#  "./setup.sh help" for usage info
#


#set -x   # trace mode

# --------------------------------------------------------------

E_ROOT_DIR="$(dirname $0)"
E_MAKE_FILE="${E_ROOT_DIR}/Makefile"
E_DOCKER_BASE="${E_ROOT_DIR}/docker"
E_SETUP_DIR="${E_ROOT_DIR}/docker/r-images/scripts/setup"
E_SETUP_RUNNER="${E_SETUP_DIR}/setup_ubs-all.sh"

export PATH=$E_SETUP_DIR:$PATH


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

( cat <<EOF

external setup usage:

  $0 --external | -E    : for non containerized setup


out-container usage:

  ./runtime.sh setup   : for virtual environment installation
  ./runtime.sh upgrade : for virtual environment additional resolution
  ./runtime.sh status  : for virtual environment status reporting


in-container usage:

  $0 --status|--all [--upgrade]

runs virtual enviroment install scripts inside runtime container

if '--upgrade' options, dependency upgrade is forced by removing

  ./uv.lock     : to force python dependency upgrade, with 'pyproject.toml' specification
  ./renv.lock   : to force R dependency upgrade, with 'DESCRIPTION' project specification


CONFIGURATION
==============

see ./docker/r-images/build.conf for setup scripts options
see ./docker/r-images/scripts/setup/*.sh for executable setup scripts


ENVIRONMENNT
============

- E_ROOT_DIR: project base directory (working directory)
- E_SETUP_DIR: executable scripts directory ( $E_ROOT_DIR'/exec' )
- E_SETUP_ARGS: script arguments

- PATH: $E_SETUP_DIR:$PATH

EOF

cat <<'EOF'

SETUP EXAMPLES
==============

# external (non containerized) setup
ex=0; F=/tmp/external-$(date -Isec).log; (./setup.sh -E) 2>&1 | tee $F ; echo "rc=$? -- press enter"; read  z; less -RX $F

# container setup, see:
./build.sh --help


EOF

) #  | $PAGER

exit 1

}


#}}} \\\
#{{{ [ MAIN ] /////////////////////////////////////////////////////////////////

# ---(external)------------------------------------------------

exec_external() {

    exec "$E_SETUP_RUNNER" "$@"

}

# ---(exec)------------------------------------------------

run_exec() {

    #set -x
    cd $E_ROOT_DIR
    
   ${E_SETUP_WRAP} ${E_SETUP_ARGS}
   rc=$?
   #set +x
   return $rc
}

do_exec() {
    info "> exec::($E_SETUP_NAME, $E_SETUP_ARGS) -- ${E_SETUP_FILE}"
    run_exec 
    info "< exec::($E_SETUP_NAME, $E_SETUP_ARGS) (rc: $rc)"
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
            --external|-E)
                exec_external "$@"
                ;;
            -x|--exec)
                E_SETUP_RUNNER="$2"
                shift
                ;;
            *)
                cmds="$cmds $1" 
                ;;
        esac
        shift
    done

: ${E_SETUP_WRAP:="$E_SETUP_RUNNER"}
: ${E_SETUP_ARGS:=$cmds}
export     

    log "<(args.sub):" "cmds: $cmds"
            
    
}




# ---(main)------------------------------------------------

main() {

    parse_args_start $@
    
    do_exec $@
    exit $rc

}

main $@

#}}} \\\





