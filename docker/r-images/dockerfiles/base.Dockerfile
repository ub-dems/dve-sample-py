FROM ubdems/dve-sample-py.cuda
#FROM ubdems/dve-sample-py.anchor

LABEL org.opencontainers.image.vendor="ubdems" \
      org.opencontainers.image.base.name="ubdems/dve-sample-py.anchor" \
      org.opencontainers.image.title="ubdems/dve-sample-py.base" \
      org.opencontainers.image.source="https://gitlab.com/ub-dems/ds-labs/dve-sample-py" \
      org.opencontainers.image.authors="DEMS/datalab <dsuser.dems@gmail.com>" \
      org.opencontainers.image.description="TODO:description" \
      org.opencontainers.image.licenses="GPL-2.0-or-later" \
      it.unimib.datalab.type="project.base" \
      it.unimib.datalab.name="dve-sample-py" \
      it.unimib.datalab.group="ub-dems/ds-labs" \
      it.unimib.datalab.path="ub-dems/ds-labs/dve-sample-py" \
      it.unimib.datalab.schema="dve:1.0" \
      it.unimib.datalab.lang="R+Python" \
      it.unimib.datalab.from="2026-03-16" \
      it.unimib.datalab.until="2222-02-02" \
      it.unimib.datalab.owner="ab21010" \
      it.unimib.datalab.cdc="ds-101" \
      it.unimib.datalab.tags="none"

ENV IMG_TYPE base

# from makefile (autodetect) - no default

ARG  Y_WORK_DIR
ENV  X_WORK_DIR=$Y_WORK_DIR

ARG  Y_PY_MODE
ENV  X_PY_MODE=$Y_PY_MODE

ARG  Y_PY_PYTHON_VERSION
ENV  X_PY_PYTHON_VERSION=$Y_PY_PYTHON_VERSION


ARG DEBIAN_FRONTEND=noninteractive

ARG  Y_SHELL_SET=/bin/bash
ENV  SHELL=$Y_SHELL_SET



ARG  Y_EDITOR_SET=vim
ENV  EDITOR=$Y_EDITOR_SET
ARG  Y_VISUAL_SET=vim
ENV  VISUAL=$Y_VISUAL_SET
ARG  Y_PAGER_SET=less
ENV  PAGER=$Y_PAGER_SET




ARG  Y_TERM_SET=xterm-256color
#ENV  TERM=$Y_TERM_SET

ARG  Y_TZ_SET=Europe/Rome
ENV  TZ=$Y_TZ_SET
RUN  echo "$TZ" > /etc/timezone

ARG  Y_LANG=en_US.UTF-8
ENV LANG=$Y_LANG

ARG  Y_LANGUAGE=en_US:en
ENV LANGUAGE=$Y_LANGUAGE

#ARG  Y_LC_ALL=en_US.UTF-8
#ENV LC_ALL=$Y_LC_ALL

ARG  Y_LC_MESSAGE=en_US.UTF-8
ENV LC_MESSAGE=$Y_LC_MESSAGE

ARG  Y_LC_COLLATE=en_US.UTF-8
ENV LC_COLLATE=$Y_LC_COLLATE

ARG  Y_LC_TIME=en_IE.UTF-8
ENV LC_TIME=$Y_LC_TIME

ARG  Y_LC_NUMERIC=C.UTF-8
ENV LC_NUMERIC=$Y_LC_NUMERIC

ARG  Y_LC_MONETARY=it_IT.UTF-8
ENV LC_MONETARY=$Y_LC_MONETARY

ARG  Y_LC_MEASUREMENT=en_IE.UTF-8
ENV LC_MEASUREMENT=$Y_LC_MEASUREMENT

ARG  Y_LC_PAPER=en_IE.UTF-8
ENV LC_PAPER=$Y_LC_PAPER



ARG  Y_KBD_LAYOUT_SET=it

# apt-get/dpkg batch mode
ENV DEBIAN_FRONTEND noninteractive

COPY scripts/base /rocker_scripts
COPY build.conf   /etc/build.conf
ARG  Y_BUILD_CONF=/etc/build.conf
ENV  X_BUILD_CONF=$Y_BUILD_CONF

COPY project.conf   /etc/project.conf
ARG  Y_META_CONF=/etc/project.conf
ENV  X_META_CONF=$Y_META_CONF

COPY starter.conf   /etc/starter.conf
ARG  Y_AUTO_CONF=/etc/starter.conf
ENV  X_AUTO_CONF=$Y_AUTO_CONF

# dynamic: Makefile, ENV placeholder

ARG  Y_HAS_GPU=nil
ENV  X_HAS_GPU=$Y_HAS_GPU


# dynamic: runtime.sh invocation

ARG  Y_DEBUG_ENV=0
ENV  X_DEBUG_ENV=$Y_DEBUG_ENV

# init user configuration 
RUN /rocker_scripts/init_ubs-userconf.sh

# commons
RUN /rocker_scripts/install_ubs-commons.sh
RUN /rocker_scripts/install_ubs-utils.sh

# emacs support

ENV NO_AT_BRIDGE=1

# cursor support

ENV CAN_LAUNCH_AS_ROOT=1

# dotfile

ARG  Y_ENV_FILE=.env
ENV  X_ENV_FILE=$Y_ENV_FILE

ENV UV_ENV_FILE=$Y_ENV_FILE

# julia support

ENV JULIAUP_ROOT=~/.juliaup
ENV JULIA_ROOT=~/.julia
ENV JULIA_PYTHONCALL_EXE=python
ENV JULIA_CONDAPKG_BACKEND=Null

# node support

ENV FNM_ROOT=/opt/fnm
ENV NODE_ROOT=/opt/nodejs
ENV FNM_DIR=$NODE_ROOT/.fnm

# rust support

ENV RUST_ROOT=/opt/rust
ENV RUSTUP_HOME=/opt/rust
ENV CARGO_HOME=/opt/cargo

# python support

ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT=.venv.cdk

ENV VIRTUAL_ENV=

# jupyter support

ENV X_LAB_EXEC=jupyter
ENV X_LAB_MODE=lab
ENV X_LAB_ADDR=0.0.0.0
ENV X_LAB_PORT=8888
ENV X_LAB_BASE=notebooks
ENV X_LAB_AUTH=--ServerApp.allow_remote_access=true
ENV X_LAB_USER=--allow-root
ENV X_LAB_AUTO=--no-browser
ENV X_LAB_OPTS=
ENV X_LAB_OPTIONS=


# xdg path

ENV PATH=~/.local/bin:${PATH}:${JULIAUP_ROOT}/bin:${NODE_ROOT}/bin:${CARGO_HOME}/bin:${RUSTUP_HOME}/bin:


# build calls

RUN echo "# +++ #base(pre): PATH=${PATH}"

RUN /rocker_scripts/install_ubs-rs_rust.sh
RUN /rocker_scripts/install_ubs-js_node.sh
RUN /rocker_scripts/install_ubs-js_code.sh

# RUN /rocker_scripts/install_ubs-ju_julia.sh

# RUN /rocker_scripts/install_ubs-py_base.sh
# RUN /rocker_scripts/install_ubs-py_system.sh
# RUN /rocker_scripts/install_ubs-py_uv.sh
# RUN /rocker_scripts/install_ubs-py_pyenv.sh
# RUN /rocker_scripts/install_ubs-py_poetry.sh

RUN /rocker_scripts/install_ubs-py_lang.sh
RUN /rocker_scripts/install_ubs-py_jupyter.sh

RUN /rocker_scripts/install_ubs-re_seal.sh

# clean up
RUN /rocker_scripts/install_ubs-clean.sh

RUN echo "# +++ #base(post): PATH=${PATH}"
RUN echo "# +++ #base(bash): PATH=$(bash --login -i -c 'printf \"%s\" "$PATH"' | tail -n1)"

EXPOSE 8888
EXPOSE 8787
EXPOSE 8686
EXPOSE 8080

#CMD ["/init"]
#CMD ["R"]

COPY scripts/start /etc/dsbox/runtime/
RUN  chmod -R a+x  /etc/dsbox/runtime/
ENTRYPOINT ["/etc/dsbox/runtime/runtime_entrypoint.sh"]
