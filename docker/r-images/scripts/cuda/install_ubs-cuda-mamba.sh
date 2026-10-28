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


set -a
# ------------------------------------------------------

# ${MAMBA_VERSION:="2.3.0-0"}
: ${MAMBA_VERSION:="latest"}
: ${MAMBA_ARCH:="linux-64"}
: ${MAMBA_INSTALL_URL:="https://micro.mamba.pm/api/micromamba/${MAMBA_ARCH}/${MAMBA_VERSION}"}
: ${MAMBA_BIN:="/usr/local/bin/micromamba"}
: ${MAMBA_ROOT:="/opt/mamba"}
: ${CONDA_ENV_NAME:="cuda-base"}
: ${CONDA_ENV_PREFIX:="${MAMBA_ROOT}/envs/${CONDA_ENV_NAME}"}
: ${CONDA_ENV_FILE:="conda-cuda-env.yaml"}


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
        aq=" -qq -o=Dpkg::Use-Pty=0 "
	if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/*  2> /dev/null | wc -l)" = "0" ]; then
			apt-get update $aq
		fi
		apt-get install $aq -y --no-install-recommends "$@"
	fi
}

function install_mamba() {

    [ "$Y_NV_MAMBA_INSTALL" = 1 ] || return 0

    debug "> install micro-mamba, ..."

    # ── 1. Install micromamba binary ─────────────────────────────────────────────
    debug  "[1/5] Downloading micromamba ${MAMBA_VERSION} (${MAMBA_ARCH})..."
    curl -fsSL "${MAMBA_INSTALL_URL}" \
        | tar -xj -C /tmp --strip-components=1 bin/micromamba
    install -m 0755 /tmp/micromamba "${MAMBA_BIN}"
    rm -f /tmp/micromamba

    # ── 2. Initialise the global mamba root ──────────────────────────────────────
    debug "[2/5] Initialising MAMBA_ROOT_PREFIX at ${MAMBA_ROOT}..."
    mkdir -p "${MAMBA_ROOT}"/{pkgs,etc,envs}

    # Provide a minimal .mambarc that is root-owned but world-readable.
    # MAMBA_ROOT_PREFIX is exported; no ~/.bashrc manipulation required.
    cat > ${MAMBA_ROOT}/.mambarc <<'EOF'
# System-wide micromamba configuration
# No user-home dependency — compatible with rootless Podman builds.
auto_activate_base: false
always_yes: true
EOF

    export MAMBA_ROOT_PREFIX="${MAMBA_ROOT}"

    debug "> install micro-mamba, done."
    
}


function environ_mamba() {

    [ "$Y_NV_MAMBA_ENVIRON" = 1 ] || return 0

    debug "> environ micro-mamba, ..."

    # ── 2. Initialise the global mamba root ──────────────────────────────────────
    debug "[2/5] Initialising MAMBA_ROOT_PREFIX at ${MAMBA_ROOT}, [etc]..."
    mkdir -p "${MAMBA_ROOT}"/{etc}

    export MAMBA_ROOT_PREFIX="${MAMBA_ROOT}"

    # ── 3. Create the CUDA environment from the spec file ────────────────────────
    debug "[3/5] Creating conda environment '${CONDA_ENV_NAME}' from ${CONDA_ENV_FILE}..."
    "${MAMBA_BIN}" env create \
                   --root-prefix "${MAMBA_ROOT}" \
                   --name "${CONDA_ENV_NAME}" \
                   --file "/etc/ubs/${CONDA_ENV_FILE}" \
                   --yes

    # ── 4. Export system-wide environment variables ───────────────────────────────
    debug  "[4/5] Writing ${MAMBA_ROOT}/etc/profile.d/cuda-base.sh ..."
    cat > "${MAMBA_ROOT}/etc/cuda-base.sh" <<EOF
# CUDA / micromamba system environment — sourced for all login shells.
export MAMBA_ROOT_PREFIX="${MAMBA_ROOT}"
export CONDA_ENV_PREFIX="${CONDA_ENV_PREFIX}"
export CUDA_HOME="${CONDA_ENV_PREFIX}"
export CUDA_ROOT="${CONDA_ENV_PREFIX}"
export PATH="${CONDA_ENV_PREFIX}/bin:\${PATH}"
export LD_LIBRARY_PATH="${CONDA_ENV_PREFIX}/lib:${CONDA_ENV_PREFIX}/lib/stubs:\${LD_LIBRARY_PATH:-}"
export NVBLAS_CONFIG_FILE="${CONDA_ENV_PREFIX}/etc/nvblas.conf"
#@(NVBLAS): export LD_PRELOAD=/opt/mamba/envs/cuda-base/lib/libnvblas.so
EOF
    chmod 0644 "${MAMBA_ROOT}/etc/cuda-base.sh"

    # Write the same variables to /etc/environment for non-login, non-interactive
    # shells (e.g. systemd units, container entrypoints without a login shell).
    # Note: /etc/environment does not support variable expansion — paths are literal.
    echo "[4/5] Writing ${MAMBA_ROOT}/etc/environment entries..."
    {
        echo "MAMBA_ROOT_PREFIX=${MAMBA_ROOT}"
        echo "CONDA_ENV_PREFIX=${CONDA_ENV_PREFIX}"
        echo "CUDA_HOME=${CONDA_ENV_PREFIX}"
        echo "CUDA_ROOT=${CONDA_ENV_PREFIX}"
        # PATH prepend is not honoured by all parsers of /etc/environment;
        # the profile.d entry above is the canonical PATH source.
        echo "LD_LIBRARY_PATH=${CONDA_ENV_PREFIX}/lib:${CONDA_ENV_PREFIX}/lib/stubs"
        echo "NVBLAS_CONFIG_FILE=${CONDA_ENV_PREFIX}/etc/nvblas.conf"
    } >> "${MAMBA_ROOT}/etc/environment"

    cat > "${MAMBA_ROOT}/etc/nvblas.conf" <<EOF
# CUDA nvBLAS config
NVBLAS_LOGFILE /tmp/nvblas.log
NVBLAS_CPU_BLAS_LIB /opt/mamba/envs/cuda-base/lib/libopenblas.so.0
NVBLAS_GPU_LIST ALL0
NVBLAS_TILE_DIM 2048
NVBLAS_AUTOPIN_MEM_ENABLEDEOF
EOF
    
    chmod 0644 "${MAMBA_ROOT}/etc/nvblas.conf"

    debug "> environ micro-mamba, done."
    
}

function enable_mamba() {

    [ "$Y_NV_MAMBA_ENABLE" = 1 ] || return 0

    debug "> enable micro-mamba, ..."


    # ── 4. Export system-wide environment variables ───────────────────────────────
    debug  "[4/5] Writing /etc/profile.d/cuda-base.sh ..."
    
    ln -s "${MAMBA_ROOT}/etc/cuda-base.sh" /etc/profile.d/cuda-base.sh 
    chmod 0644 /etc/profile.d/cuda-base.sh

    # Write the same variables to /etc/environment for non-login, non-interactive
    # shells (e.g. systemd units, container entrypoints without a login shell).
    # Note: /etc/environment does not support variable expansion — paths are literal.
    echo "[4/5] Writing /etc/environment entries..."
    cat "${MAMBA_ROOT}/etc/environment" >> /etc/environment

    debug "> enable micro-mamba, done."
    
}

function check_mamba() {

    [ "$Y_NV_MAMBA_CHECK" = 1 ] || return 0

    debug "> check micro-mamba, ..."

    # ── 5. Verify the CUDA toolkit is present ────────────────────────────────────
    echo "[5/5] Verifying installation..."
    "${CONDA_ENV_PREFIX}/bin/nvcc" --version
    echo "micromamba env '${CONDA_ENV_NAME}' ready at ${CONDA_ENV_PREFIX}"

    debug "> check micro-mamba, done."
    
}



function config_blas() {

    [ "$Y_NV_CUDA_BLAS" = 1 ] || return 0

    debug "> config blas libs, ..."

    # @see: https://www.perplexity.ai/search/mamba-blas-issue-on-cuda-envir-hHtQhk9QSCSxkjQ7JRb9Ww

    # in /etc/profile.d/cuda-base.sh

    # export NVBLAS_CONFIG_FILE=/opt/mamba/envs/cuda-base/nvblas.conf
    # export LD_PRELOAD=/opt/mamba/envs/cuda-base/lib/libnvblas.so    



    
    # reset openblas setup
    # @see: https://csantill.github.io/RPerformanceWBLAS/

    # update-alternatives --query   libblas.so.3-x86_64-linux-gnu
    # update-alternatives --query   liblapack.so.3-x86_64-linux-gnu
    
    # update-alternatives --auto    libblas.so.3-x86_64-linux-gnu
    # update-alternatives --auto    liblapack.so.3-x86_64-linux-gnu

    # update-alternatives --display libblas.so.3-x86_64-linux-gnu
    # update-alternatives --display liblapack.so.3-x86_64-linux-gnu

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

MAMBA_VERSION=$MAMBA_VERSION
MAMBA_ARCH=$MAMBA_ARCH
MAMBA_INSTALL_URL=$MAMBA_INSTALL_URL
MAMBA_BIN=$MAMBA_BIN
MAMBA_ROOT=$MAMBA_ROOT
CONDA_ENV_NAME=$CONDA_ENV_NAME
CONDA_ENV_FILE=$CONDA_ENV_FILE
CONDA_ENV_PREFIX=$CONDA_ENV_PREFIX

--
PATH=$PATH
LD_LIBRARY_PATH=$LD_LIBRARY_PATH
LIBRARY_PATH=$LIBRARY_PATH
--

nvidia-smi: $(which nvidia-smi)
nvidia-smi.v: $(nvidia-smi --version || true)
nvcc: $(which nvcc)
nvcc.v: $(nvcc --version || true)

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
    
    debug "> clean mamba cache, ..."
    
    "${MAMBA_BIN}" clean --all

    debug "< clean mamba cache, done."
    
}



function main() {
    
    [ "$Y_NV_ANY_SUPPORT" = 1 ] || return 0
    [ "$Y_NV_MAMBA_SUPPORT" = 1 ] || return 0

    env_dump $@

    ## [ "$Y_NV_CUDA_SUPPORT" = 1 ] || return 0

    [ "$Y_NV_CUDA_SETUP" = 'mamba' ] || return 0

    info "> script($0) -- STARTED, ..."

    install_mamba
    environ_mamba
    enable_mamba

    check_mamba
    
    config_blas
    
    setenv_rehash
    
    check_cuda

    clean_up

    info "> script($0) -- DONE."
}

main $@
