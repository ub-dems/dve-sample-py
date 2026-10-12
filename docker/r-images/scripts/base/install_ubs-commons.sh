#!/bin/bash

##
# install_ubs-commons.sh: install common tools and libraries
#

set -e

## build ARGs
source ${Y_BUILD_CONF:-/etc/build.conf}

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
debug() { LOG_LEVEL='DEBUG' CLOG="$C_Green" _log $*; }
info() { LOG_LEVEL='INFO.' CLOG="$C_BICyan" _log $*; }
warn() { LOG_LEVEL='WARN.' CLOG="$C_BYellow" _log $*; }
error() { LOG_LEVEL='ERROR' CLOG="$C_IRed" _log $*; }
fatal() { LOG_LEVEL='FATAL' CLOG="$C_BIRed" _log $*; }
log() { LOG_LEVEL='_LOG_' CLOG="$C_BBlue" _log $*; }
die() {
	fatal $*
	exit 1
}

# ---(env)------------------------------------------------
function env_dump() {

	[ "$Y_DEBUG_ENV" = 1 ] || return 0

	echo "+++> #ENV($0): " "$@"
	echo "+++: #ENV($0): set"
	set | grep '^Y_' | sort
	echo "+++: #ENV($0): env"
	env | sort
	echo "+++: #ENV($0): path"
	echo "PATH=$PATH"
	echo "+++<  #ENV($0): " "$@"

}

# a function to install apt packages only if they are not installed
function apt_install() {
        aq=" -qq -o=Dpkg::Use-Pty=0 "
	if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/* 2> /dev/null | wc -l)" = "0" ]; then
			apt-get update $aq
		fi
		apt-get install $aq -y --no-install-recommends "$@"
	fi
}

function upgrade_commons_all() {

    [ "$Y_BASE_COMMONS_UPGRADE" = 1 ] || return 0

    aq=" -qq -o=Dpkg::Use-Pty=0 "
    
    # Update and install
    apt-get update $aq
    
    apt-get upgrade -y $aq
    apt-get autoremove -y $aq
    
    apt_install \
        ca-certificates

}

function unminimize_commons_man() {

    [ "$Y_BASE_COMMONS_UNMINIMIZE" = 1 ] || return 0

    aq=" -qq -o=Dpkg::Use-Pty=0 "
    
    yes | sudo unminimize
    
    # Update and install
    apt-get update $aq
    
    apt_install \
        man-db

}

function install_commons_locale() {

    [ "$Y_BASE_COMMONS_LOCALE" = 1 ] || return 0

    echo "# LOCALE: {"
    
    echo "- locale arguments:"
    env | grep -e '^Y_LANG' -e 'Y_LC' | sort

    locale-gen "$Y_LANG"
    # locale-gen "$Y_LC_ALL"
    # locale-gen "$Y_LC_MESSAGE"
    locale-gen "$Y_LC_COLLATE"
    locale-gen "$Y_LC_NUMERIC"
    locale-gen "$Y_LC_TIME"
    locale-gen "$Y_LC_MONETARY"
    # locale-gen "$Y_LC_MEASUREMENT"
    # locale-gen "$Y_LC_PAPER"

    update-locale \
        LC_MESSAGE="$Y_LC_MESSAGE" \
        LC_COLLATE="$Y_LC_COLLATE" \
        LC_NUMERIC="$Y_LC_NUMERIC" \
        LC_TIME="$Y_LC_TIME" \
        LC_MONETARY="$Y_LC_MONETARY" \
        LC_MEASUREMENT="$Y_LC_MEASUREMENT" \
        LC_PAPER="$Y_LC_PAPER" \
        LANG="$Y_LANG" \
        LANGUAGE="$Y_LANGUAGE"
    
    #   LC_ALL="$Y_LC_ALL" \

    dpkg-reconfigure locales

    echo "- locale available:"
    locale -a

    echo "- locale active:"
    ( bash --login -c 'locale' )
    
    echo "- locale test:"
    ( eval $(cat /etc/default/locale)
      locale
      printf "date: %s \n" "$(date)"
      awk '{ printf("float: %.3f \n", 1.61803398) }'
      awk '{ printf("money: %'"'"'.2f \n", 1234567.89) }'
    )

    echo "} # LOCALE //"
}

function install_commons_min() {

    [ "$Y_BASE_COMMONS_MIN" = 1 ] || return 0

	apt_install \
		curl \
		gpg \
                locales \
                apt-utils

}

function install_commons_dev() {

    [ "$Y_BASE_COMMONS_DEV" = 1 ] || return 0

	apt_install \
		libgsl-dev \
		libtbb-dev \
		libzmq3-dev \
		libglpk-dev \
		libncurses5-dev \
		libtinfo6 \
                libmagick++-dev \
	        default-libmysqlclient-dev \
                cmake \
                shellcheck

}

function install_commons_sys() {

    [ "$Y_BASE_COMMONS_SYS" = 1 ] || return 0

	apt_install \
		apt-file \
		parallel \
		hwloc \
		tasksel \
		numactl \
		inxi \
		htop

}

function install_commons_xwindow() {

	[ "$Y_BASE_COMMONS_X" = 1 ] || return 0

	apt_install \
		x11-apps \
		x11-utils \
		libx11-6 \
		libxext6 \
		libxrender1 \
                fuse \
                libfuse2 \
                libdbus-glib-1-2 \
                xserver-xephyr \
                openbox \
                xfonts-terminus \
	        xauth \
		xsel \
		xclip \
                qterminal \
                rxvt-unicode \
                xterm
        
        #       ghostty \
            
}

function install_commons_fonts() {

    [ "$Y_BASE_COMMONS_FONTS" = 1 ] || return 0

    apt_install \
        fonts-roboto \
        fonts-open-sans \
        fonts-cascadia-code \
        fonts-jetbrains-mono \
        fonts-firacode \
        fonts-inconsolata

    for f in \
        FiraCode \
            Inconsolata \
            JetBrainsMono ; do
        wget -nv https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/$f.zip
        mkdir -p /usr/local/share/fonts/z-nerd/$f
        unzip $f.zip -d /usr/local/share/fonts/z-nerd/$f
        rm $f.zip
    done
    fc-cache -fv

}



function install_commons_latex() {

	[ "$Y_BASE_COMMONS_LATEX" = 1 ] || return 0

	apt_install \
	    texlive \
	    texlive-fonts-recommended \
	    texlive-latex-recommended \
	    texlive-bibtex-extra \
	    texlive-lang-english \
	    texlive-lang-italian \
	    texlive-luatex \
	    texlive-xetex \
            pandoc \
            pandoc-plantuml-filter \
            fonts-jetbrains-mono

	apt_install \
            hunspell \
            hunspell-tools \
            hunspell-en-gb \
            hunspell-en-us \
            hunspell-fr \
            hunspell-es \
            hunspell-it \
            hyphen-en-us \
            hyphen-it \
            imagemagick

	apt_install \
            cups-pdf

        
        #       pandoc-filter-diagram \

	#    tlmgr install \
	#        unicode-math

	#    tlmgr update --self --all
}

function install_commons_cran() {

	[ "$Y_BASE_COMMONS_CRAN" = 1 ] || return 0

	install2.r --error --skipmissing --skipinstalled -n $NCPUS \
		remotes \
		renv \
		devtools \
		usethis \
		gitcreds \
		argparse \
		cffr \
		cli \
		here \
		logging \
		logger \
		microbenchmark

        Rscript -e 'remotes::install_github("cran4linux/rspm")'

}

function prepare_commons_mounts() {

    [ "$Y_BASE_COMMONS_MOUNTS" = 1 ] || return 0

    mkdir -p /data/opt/local
    ln -s    /data/opt/local /opt/local

    mkdir -p /usr/local/share/emacs
    ln -s    /usr/local/.import/share/emacs/emacs-share \
             /usr/local/share/emacs/emacs-share || true


}

function install_commons() {

	upgrade_commons_all
	unminimize_commons_man
	install_commons_min
	install_commons_locale
	install_commons_dev
	install_commons_sys
	install_commons_xwindow
	install_commons_fonts
	install_commons_latex
	install_commons_cran
	prepare_commons_mounts

}

function setenv_rehash() {

	set +e
	env_dump "setenv_commons::pre"
	export PS1='# '
	source /etc/bash.bashrc
	env_dump "setenv_commons::post"
	set -e

}

function check_commons() {

	[ "$Y_BASE_COMMONS_CHECK" = 1 ] || return 0

	inxi -v 1 || true
	numactl -H || true
	numactl -s || true

}

function clean_up() {
	:
}

function main() {

	env_dump "$@"

	[ "$Y_BASE_COMMONS_INSTALL" = 1 ] || return 0

	info "> script($0) -- STARTED, ..."

	setenv_rehash

	install_commons
	setenv_rehash

	check_commons

	clean_up

	info "> script($0) -- DONE."

}

main "$@"
