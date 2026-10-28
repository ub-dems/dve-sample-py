#!/bin/bash
##
# ./build.sh: build command script, 
# (for usage info, run: ./build.sh --help)
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

env | grep -e '^[EXY]_' 

. $(dirname $0)/functions.sh

# --------------------------------------------------------------



run_make() {
   make -f ${E_MAKE_FILE} $@
   rc=$?
   return $rc
}

run_self() {
   $0 $@
   rc=$?
   return $rc
}

do_make() {
    info "> make $@ -- ${E_MAKE_FILE}"
    run_make $@
    info "< make $@ (rc: $rc)"

}

do_self() {
    info "> exec $@ -- ${0}"
    run_self $@
    info "< exec $@ (rc: $rc)"

}

do_list() {
    info "> BUILD $@ -- ${E_MAKE_FILE}"
    cmds=("$@")
    for cmd in "${cmds[@]}";
    do
        do_self $cmd
        rc=$?
        [ $rc ] || die "exec cmd: $cmd failed! (rc=$rc)"
    done
    info "< BUILD $@ (rc: $rc)"

}



exit_usage() {

cat <<EOF    

usage $0 target[,target,target ...]

where "target" is one of:

$(run_make help/base | perl -ne 'print if /^TARGETS:/../EOF/' | sed '1d')


CONTAINERS (podman)
-------------------

$(run_make help/build | perl -ne 'print if /^TARGETS:/../EOF/' | sed '1d')


CUSTOMIZATION (once)
--------------------

$(run_make help/custom | perl -ne 'print if /^TARGETS:/../EOF/' | sed '1d')


EOF

cat <<'EOF'

BUILD EXAMPLES
--------------

# full build and tests
rt=0; F=/tmp/full-$(date -Isec).log; (./build.sh full) 2>&1 | tee $F ; echo "rc=$? -- press enter"; read  z; less -RX $F

# container image build
rt=1; F=/tmp/build-$(date -Isec).log; (./build.sh setup) 2>&1 | tee $F ; echo "rc=$? -- press enter ..."; read z; less -RX $F

# virtual environment library install
rt=2; F=/tmp/setup-$(date -Isec).log; (./runtime.sh setup) 2>&1 | tee $F ; echo "rc=$? -- press enter"; read  z; less -RX $F 

# user configuration
rt=3; F=/tmp/environ-$(date -Isec).log; (./runtime.sh environ) 2>&1 | tee $F ; echo "rc=$? -- press enter"; read  z; less -RX $F


EOF

exit 0

}


if [ $# = '0' ]; then
    exit_usage
fi

case "$1" in
    help|--help)
        exit_usage
        ;;
    *) ;;
esac
        

commands=(${1//,/ })

case "${#commands[@]}" in
    0)
        exit_usage
        ;;
    1)
        do_make $@
        ;;
    *)
        do_list "${commands[@]}"
        ;;
esac    

exit $rc

# vim: set foldmethod=marker :
