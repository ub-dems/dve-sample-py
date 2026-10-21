##
#{{{ Makefile: project global/standard actions
#
# @see: ./notes/usage/readme.md for usage info
#
#}}} \\\


#{{{ [ VARS.* ] /////////////////////////////////////////////////////////////////



# ---(base)------------------------------------------------

ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))


# ---(project)------------------------------------------------

PACKAGE := $(shell ls src | grep -v -e egg -e '\.py$$' | head -n 1)
PYMODULE ?= ${PACKAGE}

SRC := 'src'
TESTS := 'tests'

# ---(IMAGES)------------------------------------------------

IMG_MAKE_DIR ?= 'docker/r-images'


# ---(project.conf)----------------------------------------

X_BLD_R ?= 0
X_BLD_R_MAN_KNITR ?= 0

X_BLD_P ?= 0
X_BLD_P_MAN_SPHINIX ?= 0



# ---(DOCS)------------------------------------------------

DOC_MAKE_DIR ?= 'doc'


# ---(paths)------------------------------------------------

LOGS_DIR ?= ${ROOT_DIR}/logs
TEMP_DIR ?= ${ROOT_DIR}/temp

BUILD_DIRS = ${TEMP_DIR} ${LOGS_DIR}
CLEAN_DIRS = ${TEMP_DIR}

# ---(progs)------------------------------------------------

POETRY := $(shell command -v poetry 2> /dev/null)
UV := $(shell command -v uv 2> /dev/null)
PY_RUN := ${UV} run

SHELL := /bin/bash
RSCRIPT := ${PY_RUN} Rscript
#POETRY := poetry
JULIA := ${PY_RUN} julia

# ---(gpu)------------------------------------------------

X_HAS_GPU := $(shell (type nvidia-smi && nvidia-smi -L) &> /dev/null  && echo 1 || echo 0)

ifeq (${X_HAS_GPU},1)
X_UV_EXTRA := gpu
else
X_UV_EXTRA := cpu
endif


#}}} \\\

#{{{ [ COMMANDS.* ] /////////////////////////////////////////////////////////////////

# ---(commands)------------------------------------------------

.PHONY: all test check docs man vignettes readme format build install clean init


all: # @HELP/base make: "init,check,test,docs,build"  targets
all: init check test docs build

start: # @HELP/base runs: `uv run ./start.sh`
start:
	${PY_RUN}  './start.sh' 



test: # @HELP/base runs: `devtools::test()`
test: init
	${PY_RUN}  'pytest' || true
	command -v julia &> /dev/null && ${JULIA} --project=@. -e 'using Pkg; Pkg.test()'
	command -v R &> /dev/null && ${RSCRIPT} -e 'devtools::test()'


check: # @HELP/base runs: `devtools::check()`
check: init
	@echo "+++ {{{ CHECK /////////";
	@echo "+++ Showing UV sync .........."; echo "$(UV) sync --extra=$X_UV_EXTRA --all-groups  --no-progress" || true
	@echo "+++ Running REUSE lint........"; $(UV) run reuse lint || true
	@echo "+++ Running Pyright check....."; $(UV) run basedpyright || true
	@echo "+++ Running Ruff check........"; $(UV) run ruff check || true
	@command -v R &> /dev/null && echo "+++ Running renv::status......"; ${RSCRIPT} -e 'renv::status()'
	@command -v R &> /dev/null && echo "+++ Running devtools::doc....."; ${RSCRIPT} -e 'devtools::document()'
	@command -v R &> /dev/null && echo "+++ Running devtools::check..."; ${RSCRIPT} -e 'devtools::check()'
	@echo "+++ }}} CHECK \\\\\\\\\ ";

docs: # @HELP/base make: "man,readme,vignettes"  targets
docs: man readme vignettes

man: # @HELP/base runs: make sphinx
man: init
	@echo cd ${DOC_MAKE_DIR} && $(MAKE) $@

vignettes: # @HELP/base runs: `devtools::build_vignettes()`
vignettes: 
	${RSCRIPT} -e 'devtools::build_vignettes()'

README.md: README.Rmd
	@echo Rscript -e 'devtools::load_all(); knitr::knit("README.Rmd")'
	@echo sed -i.bak 's/[[:space:]]*$$//' $@
	@echo rm -f $@.bak

readme: # @HELP/base runs: `knitr::knit("README.Rmd")` 
readme: README.md

format: # @HELP/baseformat code with black
format: 
	${UV} run ruff format


build-p: # @HELP/base runs: `uv build`
build-p: 
	${UV} build

build-r: # @HELP/base runs: `devtools::build()`
build-r: 
	${RSCRIPT} -e 'devtools::build()'

ifeq ($(X_BLD_P),1)
	build_p: build-p
else
	build_p:
endif
ifeq ($(X_BLD_R),1)
	build_r: build-r
else
	build_r:
endif
build: # @HELP/base runs: build-py, build-r`
build: build_p build_r

install: # @HELP/base runs: `devtools::install()`
install:
	${RSCRIPT} -e 'devtools::install()'

uninstall: # @HELP/base runs: `devtools::uninstall()`
uninstall:
	${RSCRIPT} -e 'devtools::uninstall()'

status: # @HELP/base runs: `poetry show` and `renv::diagnostics()`
status:
	${UV} 'tree'
	${UV} 'pip' 'list'
	${RSCRIPT} -e 'reticulate::py_discover_config(required_module = NULL, use_environment = NULL)'
	${RSCRIPT} -e 'reticulate::py_config()'
	${RSCRIPT} -e 'renv::diagnostics()'

clean: # @HELP/base clean all files in .gitignore
	@echo "+++ {{{ CLEAN /////////";
	@echo "+++ Running  uv cache clean....."; $(UV) cache clean || true
	@echo "+++ Cleaning pytest cache......."; [ -d .pytest_cache ] && rm -rf .pytest_cache || true
	@echo "+++ NOT Cleaning build, dist ..."; echo "rm -rf ./build ./dist"  || true
	@echo "+++ NOT Running git clean ......"; echo "git clean -Xdf"  || true
	@echo "+++ }}} CLEAN \\\\\\\\\ ";

init: # @HELP/base initialize local (temp,logs) directories
	@mkdir -p ${LOGS_DIR}
	@mkdir -p ${TEMP_DIR}

#}}} \\\

#{{{ [ CUSTOMIZATION.* ] /////////////////////////////////////////////////////////////////

# ---(custom)------------------------------------------------

.PHONY: custom custom-help

custom: # @HELP/custom runs: ./etc/custom/custom.sh for initial project customization
custom: init
	bash ./etc/custom/custom.sh

custom-help: help/custom

#}}} \\\

#{{{ [ ENVIRONMENT.* ] /////////////////////////////////////////////////////////////////

# ---(build)------------------------------------------------

.PHONY: setup prepare update upgrade build-help

prepare: init

# @TODO: git/ssh initial sync

setup: # @HELP/build initial build of all podman images
setup:  init prepare build-setup build-validate

update: # @HELP/build rebuild of modified podman images
update: init prepare build-update

upgrade: # @HELP/build fresh rebuild of all podman images (pull)
upgrade: init prepare build-upgrade

build-help: help/build

#}}} \\\

#{{{ [ AUTO.* ] /////////////////////////////////////////////////////////////////

# ---(full)------------------------------------------------

.PHONY: full full-help

full: # @HELP/build project environment initializaion after checkout 
full:  init
full:  build-setup
full:  runtime-environ
full:  runtime-setup
full:  runtime-test
full:  runtime-status
full:  runtime-check

full-help: help/full

#}}} \\\

#{{{ [ CONTAINERS.* ] /////////////////////////////////////////////////////////////////

# ---(images)------------------------------------------------

.PHONY: build-setup build-update build-upgrade

build-setup:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

build-update:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

build-upgrade:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

build-environ:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

build-profile:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@


# ---(inner check)------------------------------------------------

.PHONY: build-validate

build-validate:
	@echo "TO COMPLETE RUNTIME SETUP, RUN COMMAND: ./runtime.sh setup"


# ---(run)------------------------------------------------

.PHONY: runtime-repl runtime-rs
.PHONY: runtime-pyrun runtime-ipython
.PHONY: runtime-jrun runtime-julia
.PHONY: runtime-auto runtime-cli runtime-shell  runtime-raw
.PHONY: runtime-upgrade runtime-setup runtime-clear
.PHONY: runtime-test runtime-check runtime-status
.PHONY: runtime-environ runtime-profile
.PHONY: runtime-build
.PHONY: runtime-dev runtime-code runtime-cursor runtime-antigravity
.PHONY: runtime-rstudio runtime-lab runtime-notebook
.PHONY: runtime-command runtime-term runtime-xterm runtime-help

runtime-repl: # @HELP/runtime ...
runtime-repl:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-rs: # @HELP/runtime ...
runtime-rs:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-ipython: # @HELP/runtime ...
runtime-ipython:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-pyrun: # @HELP/runtime ...
runtime-pyrun:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-julia: # @HELP/runtime ...
runtime-julia:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-jrun: # @HELP/runtime ...
runtime-jrun:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-auto: # @HELP/runtime ...
runtime-auto:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-cli: # @HELP/runtime ...
runtime-cli:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-shell: # @HELP/runtime ...
runtime-shell:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-raw: # @HELP/runtime ...
runtime-raw:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-clear: # @HELP/runtime ...
runtime-clear:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-upgrade: # @HELP/runtime ...
runtime-upgrade:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-setup: # @HELP/runtime ...
runtime-setup:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-status: # @HELP/runtime ...
runtime-status:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-environ: # @HELP/runtime ...
runtime-environ:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-profile: # @HELP/runtime ...
runtime-profile:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-build: # @HELP/runtime ...
runtime-build:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-test: # @HELP/runtime ...
runtime-test:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-check: # @HELP/runtime ...
runtime-check:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-command: # @HELP/runtime ...
runtime-command:
	@cd ${IMG_MAKE_DIR} && $(MAKE) --silent $@

runtime-term: # @HELP/runtime ...
runtime-term:
	@cd ${IMG_MAKE_DIR} && $(MAKE) --silent $@

runtime-xterm: # @HELP/runtime ...
runtime-xterm:
	@cd ${IMG_MAKE_DIR} && $(MAKE) --silent $@

runtime-rstudio: # @HELP/runtime ...
runtime-rstudio:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-lab: # @HELP/runtime ...
runtime-lab:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-notebook: # @HELP/runtime ...
runtime-notebook:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-dev: # @HELP/runtime ...
runtime-dev:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-code: # @HELP/runtime ...
runtime-code:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-cursor: # @HELP/runtime ...
runtime-cursor:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-antigravity: # @HELP/runtime ...
runtime-antigravity:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

runtime-help: help/runtime

# ---(worker)------------------------------------------------

.PHONY: worker-pack worker-push worker-pull
.PHONY: worker-make worker-test worker-check worker-docs
.PHONY: worker-build worker-install
.PHONY: worker-exec worker-shell

worker-pack: # @HELP/worker ...
worker-pack:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-push: # @HELP/worker ...
worker-push:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-pull: # @HELP/worker ...
worker-pull:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-make: # @HELP/worker ...
worker-make:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-test: # @HELP/worker ...
worker-test:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-check: # @HELP/worker ...
worker-check:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-docs: # @HELP/worker ...
worker-docs:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-build: # @HELP/worker ...
worker-build:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-install: # @HELP/worker ...
worker-install:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-exec: # @HELP/worker ...
worker-exec:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-shell: # @HELP/worker ...
worker-shell:
	cd ${IMG_MAKE_DIR} && $(MAKE) $@

worker-help:  help/worker

#}}} \\\

#{{{ [ UTILS.* ] /////////////////////////////////////////////////////////////////

# ---(debug)------------------------------------------------

.PHONY: print-%

# Display the value.
# ex. $ make print-REPORT_SOURCE_DIR
# ex. $ make print-IMAGE_REVISION
print-%:
	@echo $* = $($*)

# ---(help)------------------------------------------------

.PHONY: help help%

help/%:
	@echo "NOTE: Use BUILDARCH/BUILDOS variables to override OS/ARCH"
	@echo
	@echo "VARIABLES:"
	@echo "  BINS = $(BINS)"
	@echo "  OS = $(OS)"
	@echo "  ARCH = $(ARCH)"
	@echo "  REGISTRY = $(REGISTRY)"
	@echo "  HOSTARCH = $(HOSTARCH)"
	@echo
	@echo "TARGETS:"
	@grep -E '^.*: *# *@HELP/$*' $(MAKEFILE_LIST) \
	    | awk '                                   \
	        BEGIN {FS = ": *# *@HELP/$*"};        \
	        { sub(/$*-/,"",$$1); printf "  %-30s %s\n", $$1, $$2 };  \
	    '

help: # @HELP/base prints this message
help:  help/base help/build 


#}}} \\\
# vim: set foldmethod=marker :
