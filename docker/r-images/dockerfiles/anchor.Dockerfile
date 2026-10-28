# @see: https://rocker-project.org/images/
# @see: https://hub.docker.com/u/rocker

FROM rocker/geospatial:4.6.1

# FROM rocker/tidyverse:4.6.1
# FROM rocker/verse:4.6.1
# FROM rocker/geospatial:4.6.1
# FROM rocker/ml:4.6.1
# FROM rocker/ml-verse:4.6.1

# @see: https://github.com/rocker-org/rocker-versioned2/pkgs/container/verse/versions
# @see: https://hub.docker.com/r/rocker/verse/tags
# FROM rocker/verse:latest

LABEL org.opencontainers.image.vendor="ubdems" \
      org.opencontainers.image.base.name="rocker/geospatial:4.6.1" \
      org.opencontainers.image.title="ubdems/dve-sample-py.anchor" \
      org.opencontainers.image.source="https://gitlab.com/ub-dems/ds-labs/dve-sample-py" \
      org.opencontainers.image.authors="DEMS/datalab <dsuser.dems@gmail.com>" \
      org.opencontainers.image.description="TODO:description" \
      org.opencontainers.image.licenses="GPL-2.0-or-later" \
      it.unimib.datalab.type="project.anchor" \
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


# from makefile (autodetect) - no default

ARG  Y_WORK_DIR
ENV  X_WORK_DIR=$Y_WORK_DIR

ARG  Y_PY_MODE
ENV  X_PY_MODE=$Y_PY_MODE

ARG  Y_DEBUG_ENV=0
ENV  X_DEBUG_ENV=$Y_DEBUG_ENV

