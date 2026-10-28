#!/bin/bash

## build ARGs
NCPUS=${NCPUS:--1}

set -e

source ${Y_BUILD_CONF:-/etc/build.conf}

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

function upgrade_commons_all() {

    [ "$Y_BASE_COMMONS_UPGRADE" = 1 ] || return 0

    aq=" -qq -o=Dpkg::Use-Pty=0 "
    
    # Update and install
    apt-get update $aq
    
    apt-get upgrade -y $aq
    apt-get autoremove -y $aq
    
}


function clean_up() {
    rm -rf /var/lib/apt/lists/* 2> /dev/null
    rm -rf /tmp/downloaded_packages
}


function main() {

    env_dump $@
    
    [ "$Y_BASE_CLEAN_ALL" = 1 ] || return 0

    upgrade_commons_all
    clean_up

}
    

main $@
 
