#!/bin/bash

## build ARGs
NCPUS=${NCPUS:--1}

set -e
apt-get update -qq && apt-get -y --no-install-recommends install \
    libudunits2-dev \
    libreadline-dev \
    libssl-dev && \
  rm -rf /var/lib/apt/lists/*  2> /dev/null

## R dependencies
install2.r --error --skipmissing --skipinstalled -n $NCPUS \
    units \
    utils


 rm -rf /tmp/downloaded_packages
