#!/bin/bash

## update system python (/usr/bin/python symlink)
## install python3-dev for pip installation support
## install python3-numpy for reticulate autoconfig
##

set -e

source /etc/build.conf

function env_dump() {
    
    [ "$Y_DEBUG_ENV" = 1 ] || return 0
    
    echo "+++> #ENV($0): $@"
    echo "+++: #ENV($0): set"
    set | grep '^Y_' | sort
    echo "+++: #ENV($0): env"
    env | sort
    echo "+++: #ENV($0): path"
    echo "PATH=$PATH"
    echo "+++<  #ENV($0): $@"
    
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

function update_system_python() {

    [ "$Y_PY_SYSTEM_UPDATE" = 1 ] || return 0
    
    if [ -e /usr/bin/python ]; then
        return 0
    fi

    if [ -e /usr/bin/python3 ]; then
        ln -s /usr/bin/python3 /usr/bin/python
    fi
    
    if [ ! -L /usr/local/bin/python ]; then
        return 0
    fi

    if [ ! "/usr/bin/python3" = "$(readlink /usr/local/bin/python)" ]; then
        return 0
    fi

    rm /usr/local/bin/python

}


function install_system_python() {
    
    [ "$Y_PY_SYSTEM_UPGRADE" = 1 ] || return 0

    apt_install \
        python3-dev \
        python3-numpy \
        python3-pip

#    libmysqlclient-dev required for mysql native support
    
}

function upgrade_system_python() {
    
    [ "$Y_PY_SYSTEM_UPGRADE" = 1 ] || return 0

    python3 -m pip --no-cache-dir install --upgrade --ignore-installed \
            pip \
            setuptools \
            wheel \
            pipenv 


}

function check_system_python() {
    
    [ "$Y_PY_SYSTEM_CHECK" = 1 ] || return 0
    
    which python      || true
    which -a python3  || true

    python --version  || true

    which    pip      || true
    which -a pip3     || true

    pip --version     || true
    
    which    pipenv   || true
    which -a pipenv   || true

    pipenv --version  || true
    
}

function clean_up() {
    :
}


function main() {
    
    [ "$Y_PY_ANY_SUPPORT" = 1 ] || return 0

    env_dump $@

    [ "$Y_PY_SYSTEM_SUPPORT" = 1 ] || return 0
    
    update_system_python
    install_system_python
    upgrade_system_python
    
    check_system_python

    clean_up

}

main $@
