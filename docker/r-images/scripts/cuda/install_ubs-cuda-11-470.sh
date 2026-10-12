#!/bin/bash

## Update base nvidia/cuda image:
##     "nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04"
## 
## Install nvidia extras
##    @see: https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_cuda-11.1.sh
##

## build ARGs
set -e
source ${Y_CUDA_CONF:-/etc/ubs/cuda.conf}

NCPUS=${NCPUS:--1}


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
        if [ "$(find /var/lib/apt/lists/* 2> /dev/null | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

function install_compiler() {

    [ "$Y_NV_CUDA_COMPILER" = 1 ] || return 0

    apt_install \
        build-essential \
        bzip2 \
        dpkg-dev \
        fakeroot \
        libalgorithm-diff-perl \
        libalgorithm-diff-xs-perl \
        libalgorithm-merge-perl \
        libfakeroot \
        lto-disabled-list \
        patch \
        xz-utils \
        $NV_NVCC_PACKAGE
    
    apt-mark hold ${NV_NVCC_PACKAGE_NAME}

    dpkg -l $NV_NVCC_PACKAGE_NAME

}

function install_cudnn() {

    [ "$Y_NV_CUDA_CUDNN" = 1 ] || return 0

    apt-get remove --allow-change-held-packages -y \
        $NV_CUDNN_PACKAGE_LIST

    apt_install \
        $NV_CUDNN_PACKAGE \
        $NV_CUDNN_PACKAGE_DEV

    apt-mark hold ${NV_CUDNN_PACKAGE_LIST}

    dpkg -l -a $NV_CUDNN_PACKAGE_NAME

}

function install_nvinfer() {

    [ "$Y_NV_CUDA_NVINFER" = 1 ] || return 0

    apt_install \
        $NV_NVINFER_PACKAGES

    apt-mark hold ${NV_NVINFER_PACKAGE_LIST}

    ( cd /usr/lib/x86_64-linux-gnu ; \
      ln -s libnvinfer_plugin.so.8 libnvinfer_plugin.so.7; \
      ln -s libnvinfer.so.8 libnvinfer.so.7 \
      )

    dpkg -l $NV_NVINFER_PACKAGE_NAME

}

function remove_driver() {

    [ "$Y_NV_CUDA_DRIVER" = 1 ] || return 0

    apt remove -y cuda-compat-11-8


}

function install_compat() {

    [ "$Y_NV_CUDA_COMPAT" = 1 ] || return 0

    mkdir -p /tmp/cuda-compat
    cd       /tmp/cuda-compat

    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-compat-11-4_470.182.03-1_amd64.deb

    ls -l

    dpkg -x cuda-compat* .

    cp -rpv ./usr/local/cuda-11.4 /usr/local/

    ln -s /usr/local/cuda-11.4 /usr/local/cuda-compat

    echo '/usr/local/cuda-compat/compat' > /etc/ld.so.conf.d/000_0_cuda-compat.conf

    ldconfig

    rm -rf /tmp/cuda-compat

}

function config_linker() {

    [ "$Y_NV_CUDA_LINKER" = 1 ] || return 0

    cat > /opt/nvidia/entrypoint.d/41-ldconfig.sh <<EOF

export NV_GPU_DETECTED=$(lspci | grep NVIDIA)

case "$NV_GPU_DETECTED" in

     *K80*) ldconfig
            NV_GPU_LDCONFIG=1 ;;

###     # always
###     *NVIDIA*) ldconfig
###            NV_GPU_LDCONFIG=1 ;;

     *) ;;
esac

echo "### {{{ libcuda:"
ldconfig -p | grep -e 'libcuda\.so.1' | head -n1 | cut -d'>' -f 2 | xargs -I{} realpath {}
mount | grep libcuda
echo "### }}}"


EOF


}

function install_tools() {

    [ "$Y_NV_CUDA_TOOLS" = 1 ] || return 0


}

function install_libraries() {

    [ "$Y_NV_CUDA_LIBRARIES" = 1 ] || return 0


}

function install_nvtop() {

    [ "$Y_NV_CUDA_NVTOP" = 1 ] || return 0

    [ -f /etc/default/keyboard ] || \
    cat <<EOK > /etc/default/keyboard
# Check /usr/share/doc/keyboard-configuration/README.Debian for
# documentation on what to do after having modified this file.

# The following variables describe your keyboard and can have the same
# values as the XkbModel, XkbLayout, XkbVariant and XkbOptions options
# in /etc/X11/xorg.conf.

XKBMODEL="pc105"
XKBLAYOUT="${Y_KBD_LAYOUT_SET:="us"}"
XKBVARIANT="intl"
XKBOPTIONS=""

# If you don't want to use the XKB layout on the console, you can
# specify an alternative keymap.  Make sure it will be accessible
# before /usr is mounted.
# KMAP=/etc/console-setup/defkeymap.kmap.gz
BACKSPACE="guess"

EOK

    apt_install \
        cmake \
        libdrm-dev \
        libudev-dev \
        libncurses5-dev \
        libncursesw5-dev \
        git

    mkdir -p /usr/local/src/
    cd       /usr/local/src/
    
    git clone https://github.com/Syllo/nvtop.git
    mkdir -p nvtop/build && cd nvtop/build
    
    cmake .. -DNVML_RETRIEVE_HEADER_ONLINE=True
    make
    make install

    cd

    rm -rf /usr/local/src/nvtop
    

}

function config_blas() {

    # reset openblas setup
    # @see: https://csantill.github.io/RPerformanceWBLAS/

    update-alternatives --query   libblas.so.3-x86_64-linux-gnu
    update-alternatives --query   liblapack.so.3-x86_64-linux-gnu
    
    update-alternatives --auto    libblas.so.3-x86_64-linux-gnu
    update-alternatives --auto    liblapack.so.3-x86_64-linux-gnu

    update-alternatives --display libblas.so.3-x86_64-linux-gnu
    update-alternatives --display liblapack.so.3-x86_64-linux-gnu
    

    [ "$Y_NV_CUDA_BLAS" = 1 ] || return 0

    
    cat <<'EOC' > /etc/nvblas.conf
NVBLAS_LOGFILE /var/log/nvblas.log
NVBLAS_CPU_BLAS_LIB /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
NVBLAS_GPU_LIST ALL
EOC



    # @see:https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/config_R_cuda.sh#L35     
    # @see:https://github.com/rocker-org/rocker-versioned2/issues/582

    # We don't want to set LD_PRELOAD globally
    #ENV LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so

    # Instead, we will set it before calling R, Rscript, or RStudio:
    
    mv /usr/local/bin/R /usr/local/bin/R_
    cat <<'EOR' > /usr/local/bin/R
#!/bin/bash
export NV_DETECTED=0
if [ "$NV_AUTODETECT_DISABLED" != '1' ] ; then
   command -v nvidia-smi >/dev/null && \
                nvidia-smi -L | grep 'GPU[[:space:]]\?[[:digit:]]\+' >/dev/null && \
                export NV_DETECTED=1
fi

case "$NV_DETECTED" in
     1)  LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so /usr/local/bin/R_ "$@"
     ;;
     *)  exec /usr/local/bin/R_ "$@"
     ;;
esac

EOR
    chmod +x /usr/local/bin/R
    
    mv /usr/local/bin/Rscript /usr/local/bin/Rscript_
    cat <<'EOR' > /usr/local/bin/Rscript
#!/bin/bash
export NV_DETECTED=0
if [ "$NV_AUTODETECT_DISABLED" != '1' ] ; then
   command -v nvidia-smi >/dev/null && \
                nvidia-smi -L | grep 'GPU[[:space:]]\?[[:digit:]]\+' >/dev/null && \
                export NV_DETECTED=1
fi

case "$NV_DETECTED" in
     1)  LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so /usr/local/bin/Rscript_ "$@"
     ;;
     *)  exec /usr/local/bin/Rscript_ "$@"
     ;;
esac

EOR
    chmod +x /usr/local/bin/Rscript

    cat <<'EOR' > /etc/services.d/rstudio/run
#!/usr/bin/with-contenv bash
## load /etc/environment vars first:
for line in $( cat /etc/environment ) ; do export $line ; done
export LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so
exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0
EOR
    
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


    which nvcc   || true
    nvcc -V      || true

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

    [ "$Y_NV_CUDA_SETUP" = '11.470' ] || return 0

    install_compiler
    install_cudnn
    install_nvinfer
    install_tools
    install_libraries
    # install_docs
    # install_demo
    # install_samples
    install_nvtop
    
    remove_driver
    install_compat
    config_linker
    
    config_blas
    
    check_cuda

    clean_up

}

main $@
