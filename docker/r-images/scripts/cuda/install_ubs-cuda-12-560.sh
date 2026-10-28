#!/bin/bash

## Install NVIDIA CUDA 12 support on top of standard Rocker Image:
##     "rocker-org/geospatial:4.4.3" (ubuntu:latest)
## 
## Install nvidia extras
##    @see: https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=24.04&target_type=deb_network
##

## default NV from cuda.Dockerfile
## build ARGs
set -e
source ${Y_CUDA_CONF:-/etc/ubs/cuda.conf}

NCPUS=${NCPUS:--1}


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
    set | grep '^Y_' | sort
    echo "+++: #ENV($0): env"
    env | sort
    echo "+++: #ENV($0): path"
    echo "PATH=$PATH"
    echo "+++< #ENV($0): $@"
    
}

function setenv_rehash() {
    env_dump "setenv_rehash::pre"
    source /etc/profile
    #export PS1='# '; source /etc/bash.bashrc
    env_dump "setenv_rehash::post"
}


# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/*  2> /dev/null | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

function install_repo() {

    [ "$Y_NV_CUDA_REPO" = 1 ] || return 0

    debug "> install nvidia repo, ..."
    
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
    echo $distribution
    wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/$(uname -i)/cuda-keyring_1.1-1_all.deb
    dpkg -i cuda-keyring_1.1-1_all.deb
    rm      cuda-keyring_1.1-1_all.deb
    apt-get update

    debug "> install nvidia repo, done."
    
}

function install_toolkit() {

    [ "$Y_NV_CUDA_TOOLKIT" = 1 ] || return 0

    debug "> install cuda toolkit, ..."
    
    apt_install \
        $NV_TOOLKIT_PACKAGE

    # apt-mark hold ${NV_CUDNN_PACKAGE_LIST}

    dpkg -l -a $NV_TOOLKIT_PACKAGE_NAME

    debug "< install cuda toolkit, done."
    
}

function install_cudnn() {

    [ "$Y_NV_CUDA_CUDNN" = 1 ] || return 0

    debug "> install cudnn libs, ..."
    
    apt_install \
        $NV_CUDNN_PACKAGE \
        $NV_CUDNN_PACKAGE_DEV

    # apt-mark hold ${NV_CUDNN_PACKAGE_LIST}

    dpkg -l -a $NV_CUDNN_PACKAGE_NAME

    debug "< install cudnn libs, done."
    
}

function install_nvinfer() {

    [ "$Y_NV_CUDA_NVINFER" = 1 ] || return 0

    debug "> install tensor-rt libs, ..."
    
    apt_install \
        $NV_NVINFER_PACKAGES

    # apt-mark hold ${NV_NVINFER_PACKAGE_LIST}

    # ( cd /usr/lib/x86_64-linux-gnu ; \
    #   ln -s libnvinfer_plugin.so.8 libnvinfer_plugin.so.7; \
    #   ln -s libnvinfer.so.8 libnvinfer.so.7 \
    #   )

    dpkg -l $NV_NVINFER_PACKAGE_NAME

    debug "< install tensor-rt libs, done."
    
}



function install_nvtop() {

    [ "$Y_NV_CUDA_NVTOP" = 1 ] || return 0

    debug "> install nvtop utils, ..."
    
    apt_install \
        $NV_NVTOP_PACKAGES

    debug "< install nvtop utils, done."
    
}

function config_blas() {

    [ "$Y_NV_CUDA_BLAS" = 1 ] || return 0

    debug "> config blas libs, ..."
    
    # reset openblas setup
    # @see: https://csantill.github.io/RPerformanceWBLAS/

    update-alternatives --query   libblas.so.3-x86_64-linux-gnu
    update-alternatives --query   liblapack.so.3-x86_64-linux-gnu
    
    update-alternatives --auto    libblas.so.3-x86_64-linux-gnu
    update-alternatives --auto    liblapack.so.3-x86_64-linux-gnu

    update-alternatives --display libblas.so.3-x86_64-linux-gnu
    update-alternatives --display liblapack.so.3-x86_64-linux-gnu

    # for NVBLAS:
    # @see: ../../system/cuda/install_ubs-cuda-misc.sh#281 :
    # @see:https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/config_R_cuda.sh#L35     
    # @see:https://github.com/rocker-org/rocker-versioned2/issues/582

    debug "< config blas libs, done."
    
    
}





function check_cuda() {
    
    [ "$Y_NV_CUDA_CHECK" = 1 ] || return 0

    
    cat <<EOF || true
## //////////////////////////////////////////
##
# CUDA ENV
#

CUDA_HOME=$CUDA_HOME
CUDA_VERSION=$CUDA_VERSION
NVIDIA_REQUIRE_CUDA=$NVIDIA_REQUIRE_CUDA
NV_CUDNN_VERSION=$NV_CUDNN_VERSION
NV_CUDA_CUDART_VERSION=$NV_CUDA_CUDART_VERSION
NV_CUDA_COMPAT_PACKAGE=$NV_CUDA_COMPAT_PACKAGE
NV_LIBCUBLAS_VERSION=$NV_LIBCUBLAS_VERSION

NV_TOOLKIT_VERSION=$NV_TOOLKIT_VERSION
NV_TOOLKIT_PACKAGE_NAME=$NV_TOOLKIT_PACKAGE_NAME
NV_TOOLKIT_PACKAGE_LIST=$NV_TOOLKIT_PACKAGE_LIST
NV_TOOLKIT_PACKAGE=$NV_TOOLKIT_PACKAGE
NV_CUDNN_VERSION=$NV_CUDNN_VERSION
NV_CUDNN_PACKAGE_NAME=$NV_CUDNN_PACKAGE_NAME
NV_CUDNN_PACKAGE_LIST=$NV_CUDNN_PACKAGE_LIST
NV_CUDNN_PACKAGE=$NV_CUDNN_PACKAGE
NV_CUDNN_PACKAGE_DEV=$NV_CUDNN_PACKAGE_DEV
NV_NVINFER_VERSION=$NV_NVINFER_VERSION
NV_NVINFER_VER=$NV_NVINFER_VER
NV_NVINFER_PACKAGE_NAME=$NV_NVINFER_PACKAGE_NAME


--
PATH=$PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH
LIBRARY_PATH=$LIBRARY_PATH
--

nvidia-smi: $(which nvidia-smi)
nvcc: $(which nvcc)
nvtop: $(which nvtop)

## -------------------------------------------
EOF

set -x    
    update-alternatives --query   libblas.so.3-x86_64-linux-gnu
    update-alternatives --query   liblapack.so.3-x86_64-linux-gnu
    
    update-alternatives --display libblas.so.3-x86_64-linux-gnu
    update-alternatives --display liblapack.so.3-x86_64-linux-gnu
set +x    

#   Rscript -e 'sessionInfo()'   || true


    (ldconfig -p | \
        grep -i \
             -e 'lib..blas.*.so' \
             -e 'libcudnn.so' \
             -e 'libnvinfer.*.so' \
             -e 'libcudnn.*.so' \
             ) || true
    
    (ldconfig -p | grep -e 'libcuda.so') || true
    (ldconfig -p | grep -e 'libcuda.so.1' | head -n 1 | cut -d'>' -f2 | xargs -l1 ls -l) || true

    cat <<EOF || true

## //////////////////////////////////////////
EOF
    
}


function clean_up() {
    :
}



function main() {
    
    [ "$Y_NV_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_NV_CUDA_SUPPORT" = 1 ] || return 0

    [ "$Y_NV_CUDA_SETUP" = '12.560' ] || return 0

    info "> script($0) -- STARTED, ..."

    install_repo
    install_toolkit
    install_cudnn
    install_nvinfer
    install_nvtop
    
    config_blas
    
    check_cuda

    clean_up

    info "> script($0) -- DONE."
}

main $@
