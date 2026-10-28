FROM ubdems/dve-sample-py.runtime

LABEL org.opencontainers.image.vendor="ubdems" \
      org.opencontainers.image.base.name="ubdems/dve-sample-py.runtime" \
      org.opencontainers.image.title="ubdems/dve-sample-py.worker" \
      org.opencontainers.image.source="https://gitlab.com/ub-dems/ds-labs/dve-sample-py" \
      org.opencontainers.image.authors="DEMS/datalab <dsuser.dems@gmail.com>" \
      org.opencontainers.image.description="TODO:description" \
      org.opencontainers.image.licenses="GPL-2.0-or-later" \
      it.unimib.datalab.type="project.worker" \
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

ENV IMG_TYPE work

ENV  DIRPATH=/worker
WORKDIR $DIRPATH


ENV RENV_VERSION 0.15.4
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

COPY renv.lock renv.lock
RUN R -e 'renv::restore()'

# @todo: add podman build cache
#RUN R -e 'renv::isolate()'

COPY . .


CMD exec ./worker.sh $WORKER_ARGS

