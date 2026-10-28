FROM ubdems/dve-sample-py.anchor

LABEL org.opencontainers.image.vendor="ubdems" \
      org.opencontainers.image.base.name="ubdems/dve-sample-py.cuda" \
      org.opencontainers.image.title="ubdems/dve-sample-py.cuda" \
      org.opencontainers.image.source="https://gitlab.com/ub-dems/ds-labs/dve-sample-py" \
      org.opencontainers.image.authors="DEMS/datalab <dsuser.dems@gmail.com>" \
      org.opencontainers.image.description="TODO:description" \
      org.opencontainers.image.licenses="GPL-2.0-or-later" \
      it.unimib.datalab.type="project.cuda" \
      it.unimib.datalab.name="dve-sample-py" \
      it.unimib.datalab.group="ub-dems/ds-labs" \
      it.unimib.datalab.path="ub-dems/ds-labs/dve-sample-py" \
      it.unimib.datalab.schema="dve:1.0" \
      it.unimib.datalab.lang="R" \
      it.unimib.datalab.from="2026-03-16" \
      it.unimib.datalab.until="2222-02-02" \
      it.unimib.datalab.owner="ab21010" \
      it.unimib.datalab.cdc="ds-101" \
      it.unimib.datalab.tags="none"

ENV IMG_TYPE cuda

# from makefile (autodetect) - no default

ARG  Y_WORK_DIR
ENV  X_WORK_DIR=$Y_WORK_DIR

ARG  Y_PY_MODE
ENV  X_PY_MODE=$Y_PY_MODE

ARG  Y_DEBUG_ENV=0
ENV  X_DEBUG_ENV=$Y_DEBUG_ENV


#ARG DEBIAN_FRONTEND=noninteractive



# ENV NV_TOOLKIT_VERSION 12-8.1

# ENV NV_TOOLKIT_PACKAGE_NAME "cuda-toolkit-12-8"
# ENV NV_TOOLKIT_PACKAGE_LIST "cuda-toolkit-12-8"

# ENV NV_TOOLKIT_PACKAGE "cuda-toolkit-12-8"



# ENV NV_CUDNN_VERSION 9.8.0.87

# ENV NV_CUDNN_PACKAGE_NAME "libcudnn9-cuda-12"
# ENV NV_CUDNN_PACKAGE_LIST "libcudnn9-cuda-12 libcudnn8-dev"

# ENV NV_CUDNN_PACKAGE "libcudnn9-cuda-12"
# ENV NV_CUDNN_PACKAGE_DEV "libcudnn9-dev-cuda-12"


# # ENV NV_NVINFER_VERSION 10.9.0.34
# # ENV NV_NVINFER_VER "$NV_NVINFER_VERSION-1+cuda12.8"

# ENV NV_NVINFER_PACKAGE_NAME "libnvinfer10"
# # ENV NV_NVINFER_PACKAGE_LIST "libnvinfer10 libnvinfer-dev libnvinfer-headers-dev libnvinfer-headers-plugin-dev libnvinfer-plugin8 libnvinfer-plugin-dev"


# ENV NV_NVINFER_PACKAGES "\
# libnvinfer-bin \
# libnvinfer-dev \
# libnvinfer-dispatch-dev \
# libnvinfer-dispatch10 \
# libnvinfer-headers-dev \
# libnvinfer-headers-plugin-dev \
# libnvinfer-lean-dev \
# libnvinfer-lean10 \
# libnvinfer-plugin-dev \
# libnvinfer-plugin10 \
# libnvinfer-samples \
# libnvinfer-vc-plugin-dev \
# libnvinfer-vc-plugin10 \
# libnvinfer10"

ENV NV_NVTOP_PACKAGES "nvtop nvitop"


# ENV NV_DRIVER_COMP 470
# ENV NV_DRIVER_DIST 520

# ENV NV_DRIVER_LINE "$NV_DRIVER_COMP"



ARG  Y_TERM_SET=xterm-256color
ENV  TERM $Y_TERM_SET

ARG  Y_TZ_SET=Europe/Rome
ENV  TZ $Y_TZ_SET
RUN  echo "$TZ" > /etc/timezone


ARG  Y_KBD_LAYOUT_SET=it

RUN  mkdir -p     /etc/ubs
COPY mamba/conda-cuda-env.yaml   /etc/ubs/conda-cuda-env.yaml
COPY scripts/cuda /rocker_scripts
COPY cuda.conf    /etc/ubs/cuda.conf
ARG  Y_CUDA_CONF=/etc/ubs/cuda.conf

ARG  Y_TERM_SET=xterm-256color
ENV  TERM $Y_TERM_SET


ENV MAMBA_VERSION     latest
ENV MAMBA_ARCH        linux-64
ENV MAMBA_INSTALL_URL https://micro.mamba.pm/api/micromamba/${MAMBA_ARCH}/${MAMBA_VERSION}
ENV MAMBA_BIN         /usr/local/bin/micromamba
ENV MAMBA_ROOT        /opt/mamba


ARG Y_NV_CONDA_ENV_NAME=cuda-base
ENV CONDA_ENV_NAME $Y_NV_CONDA_ENV_NAME

ARG Y_NV_CONDA_ENV_FILE=conda-cuda-env.yaml
ENV CONDA_ENV_FILE $Y_NV_CONDA_ENV_FILE

ENV CONDA_ENV_PREFIX=$MAMBA_ROOT/envs/${CONDA_ENV_NAME}

# cuda
#RUN /rocker_scripts/install_ubs-cuda-11-470.sh
#RUN /rocker_scripts/install_ubs-cuda-12-560.sh
RUN /rocker_scripts/install_ubs-cuda-mamba.sh
RUN /rocker_scripts/install_ubs-cuda-utils.sh


RUN echo "# +++ #cuda(post): PATH=${PATH}"
RUN echo "# +++ #cuda(bash): PATH=$(bash --login -i -c 'printf \"%s\" "$PATH"' | tail -n1)"

EXPOSE 8787

CMD ["/init"]
#CMD ["R"]
