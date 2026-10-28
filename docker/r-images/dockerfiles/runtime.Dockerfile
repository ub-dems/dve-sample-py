FROM ubdems/dve-sample-py.base

LABEL org.opencontainers.image.vendor="ubdems" \
      org.opencontainers.image.base.name="ubdems/dve-sample-py.base" \
      org.opencontainers.image.title="ubdems/dve-sample-py.runtime" \
      org.opencontainers.image.source="https://gitlab.com/ub-dems/ds-labs/dve-sample-py" \
      org.opencontainers.image.authors="DEMS/datalab <dsuser.dems@gmail.com>" \
      org.opencontainers.image.description="TODO:description" \
      org.opencontainers.image.licenses="GPL-2.0-or-later" \
      it.unimib.datalab.type="project.runtime" \
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

ENV IMG_TYPE run

COPY scripts/runtime /rocker_scripts
#COPY scripts/setup   /rocker_scripts
COPY runtime.conf   /etc/runtime.conf
ARG  Y_RUNTIME_CONF=/etc/runtime.conf
ENV  X_RUNTIME_CONF=$Y_RUNTIME_CONF


RUN /rocker_scripts/install_ubs-runtime.sh
