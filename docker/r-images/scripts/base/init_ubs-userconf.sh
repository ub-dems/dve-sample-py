#!/bin/bash

##
# init_ubs-userconf.sh: modify rstudio config for podman compatibility
#

set -e

## build ARGs
source ${Y_BUILD_CONF:-/etc/build.conf}

## Set defaults for environmental variables in case they are undefined
DEFAULT_USER=${DEFAULT_USER:-rstudio}
USER=${USER:=${DEFAULT_USER}}
USERID=${USERID:=1000}
GROUPID=${GROUPID:=1000}
ROOT=${ROOT:=TRUE}
UMASK=${UMASK:=002}
LANG=${LANG:=en_US.UTF-8}
TZ=${TZ:=Etc/UTC}

bold=$(tput bold)
normal=$(tput sgr0)


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
debug() { LOG_LEVEL='DEBUG' CLOG="$C_Green"   _log $*; }
info()  { LOG_LEVEL='INFO.'  CLOG="$C_BICyan"  _log $*; }
warn()  { LOG_LEVEL='WARN.'  CLOG="$C_BYellow" _log $*; }
error() { LOG_LEVEL='ERROR' CLOG="$C_IRed"    _log $*; }
fatal() { LOG_LEVEL='FATAL' CLOG="$C_BIRed"   _log $*; }
log()   { LOG_LEVEL='_LOG_'   CLOG="$C_BBlue"   _log $*; }
die ()  { fatal $*; exit 1; }

# ---(env)------------------------------------------------
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


function init_userconf_data() {
    
    ##
    # add 'dsdata' access group
    #
    groupadd --gid 840 dsdata
    useradd -r -m -d /var/lib/dsdata -u 840 -g dsdata -s/bin/bash dsdata
    passwd -l dsdata
    chmod 750 /var/lib/dsdata

    usermod  -a -G dsdata root

}

function init_userconf() {
    
    [ "$Y_BASE_INIT_USERCONF" = 1 ] || return 0
    
    init_userconf_data

##
# set root equivalence
#

#usermod  -o --uid 0 --gid 0  rstudio-server
#groupmod -o         --gid 0  rstudio-server

#usermod  -o --uid 0 --gid 0  $USER
#groupmod -o         --gid 0  $USER
    
    
}

function init_profile() {


# source profile from bashrc (at end) if not included    
cat <<"EOR" >>/etc/bash.bashrc
if [ "$X_RC_SYSPROFILE_INCLUDED" != "1" ]; then
   if [ "$X_RC_SYSPROFILE_INCLUDING" != "1" ]; then
      export X_RC_SYSPROFILE_INCLUDING=1
      [ "$X_DEBUG_ENV" = 1 ] && \
        echo "+++ >> include /etc/profile: 0=$0, PS1=$PS1"
      . /etc/profile
      [ "$X_DEBUG_ENV" = 1 ] && \
        echo "+++ << include /etc/profile: 0=$0, PS1=$PS1"
  fi
fi
EOR

cat <<"EOF" >>/etc/profile.d/Z99-included.sh
export X_RC_SYSPROFILE_INCLUDED=1
EOF

}




function init_home_ssh() {
    
    [ "$Y_BASE_INIT_SSH" = 1 ] || return 0

    ###   ssh-config

    if [ -d ~/.ssh ]; then
        mkdir -p   ~/.ssh.bk/$T
        chmod 700  ~/.ssh.bk
        chmod 700  ~/.ssh.bk/$T
        cp -rpv    ~/.ssh ~/.ssh.bk/$T
        warn "backup existing ~/.ssh ~/ssh.bk/$T"
    fi

    if [ -f ~/.ssh/id_rsa ]; then
        warn "user:$USER, existing ssh key, skip"
    else
        echo 'y' | ssh-keygen -f ~/.ssh/id_rsa -P '' -t rsa -b 4096
    fi

    touch      ~/.ssh/config
    chmod 600  ~/.ssh/config
    echo "ServerAliveInterval = 10" >> ~/.ssh/config

    touch      ~/.ssh/authorized_keys
    chmod 600  ~/.ssh/authorized_keys
    
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    
    ssh-keyscan -H localhost >> ~/.ssh/known_hosts
    ssh localhost pwd
    
}

function init_home_git() {
    
    [ "$Y_BASE_INIT_GIT" = 1 ] || return 0

    git config --global

    git config --global user.name $Y_BASE_META_USER
    git config --global user.email $Y_BASE_META_MAIL
    git config --global push.default simple
    git config --global diff.ignoreSubmodules dirty
    git config --global credential.helper store
    git config --global alias.tree  "log --graph --decorate --pretty=oneline --abbrev-commit"
    git config --global core.pager 'less'
    git config --global core.eol lf
    git config --global core.autocrlf input
    #git config --global core.editor 'vim'
    #git config --global core.editor 'nano'
    git config -l
    

}

function init_home_sudo() {
    
    ##
    # avoid /etc/bash.bashrc message

    touch /root/.sudo_as_admin_successful

}

function init_home_xauth() {
    
  touch     ~/.Xauthority
  chmod 600 ~/.Xauthority

  # touch      ~/.nofinger
  # chmod 600  ~/.nofinger

}

function init_home() {
    
    [ "$Y_BASE_INIT_HOME" = 1 ] || return 0
    
    init_home_sudo
    init_home_xauth

    # mounted from ./home/user volume
    
    # init_home_ssh
    # init_home_git
    
}



function init_rstudio_config() {
    
    ##
    # launch with: 
    # 
    # podman run --rm --ulimit=host -p 8787:8787 -e PASSWORD=Sec3et -v ~/work:/root/work:Z  -e USER=root -e USERID=0 -e GROUPID=0 -e ROOT=true  "image-name"
    #

    sed -i '/auth-minimum-user-id/d'      /etc/rstudio/rserver.conf
    echo    'auth-minimum-user-id = 0' >> /etc/rstudio/rserver.conf

    sed -i '/auth-minimum-user-id/d'      /etc/rstudio/disable_auth_rserver.conf
    echo    'auth-minimum-user-id = 0' >> /etc/rstudio/disable_auth_rserver.conf
    
}

function init_rstudio_service() {

    # @deprecated: rootless mode supported in rocker images
    
    sed -i 's/"$USER" != "$DEFAULT_USER"/ "$USER" != "$DEFAULT_USER" -a "$USER" != "root"/g'      \
        /etc/cont-init.d/02_userconf

    check_user_id="$(grep '^auth-minimum-user-id' /etc/rstudio/rserver.conf | sed  's/^.*= *\([[:graph:]]*\).*/\1/')"
    if [[ "$check_user_id" = '0' ]]; then
        echo "root user already authorized in /etc/rstudio/rserver.conf: $check_user_id, not changed" 
    elif [[ -n $check_user_id ]]; then

        vim -es --ex /etc/cont-init.d/02_userconf \
            +"/check_user_id=.*auth-minimum-user-id/" \
            +"d2" \
            +"i" \
            +"check_user_id=${check_user_id}" \
            +"." \
            +"w!" \
            +"q"
    fi    

#     ex /etc/cont-init.d/02_userconf  << 'EOEX'
# /check_user_id=.*auth-minimum-user-id/
# d2
# i
#   check_user_id="$(grep '^auth-minimum-user-id' /etc/rstudio/rserver.conf | sed  's/^.*= *\([[:graph:]]*\).*/\1/')"
#   if [[ "$check_user_id" = '0' ]]; then
#      echo "root user already authorized in /etc/rstudio/rserver.conf: $check_user_id, not changed" 
#   elif [[ -n $check_user_id ]]; then
# .
# w!
# q
# EOEX

    
}

function init_rstudio_logging() {
    
     
##
# enable 'info' logging
#
cat > /etc/rstudio/logging.conf <<EOC
 
[*]
log-level=info
logger-type=syslog
 
[@rserver]
log-level=debug
logger-type=file
max-size-mb=10
 
[file-locking]
log-dir=/var/log/file-locking
log-file-mode=600

EOC

}

function init_rstudio_environ() {

    line="export PATH=$(bash --login -i -c 'printf \"%s\" "$PATH"' | tail -n1)"

    sed -i "/^exec/i $line" \
        "/etc/services.d/rstudio/run"
    
}


function init_rstudio() {
    
    [ "$Y_BASE_INIT_RSTUDIO" = 1 ] || return 0
    
    # init_rstudio_config
    # init_rstudio_service
    # init_rstudio_logging
    # init_rstudio_environ
    
}



function setenv_rehash() {

    set +e
    env_dump "setenv_userconf::pre"
    export PS1='# '; source /etc/bash.bashrc
    env_dump "setenv_userconf::post"
    set -e
}


function check_userconf() {
    
    [ "$Y_BASE_INIT_CHECK" = 1 ] || return 0
    
    
    
}


function clean_up() {
    :
}



function main() {

    env_dump $@
    
    [ "$Y_BASE_INIT_APPLY" = 1 ] || return 0

    info "> script($0) -- STARTED, ..."

    setenv_rehash

    init_userconf
    init_profile
    # init_rstudio
    init_home
    
    setenv_rehash

    check_userconf

    clean_up

    info "> script($0) -- DONE."

}
    

main $@
 
