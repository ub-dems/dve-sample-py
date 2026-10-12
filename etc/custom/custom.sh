#!/bin/bash
# Script Head
# #+NAME: script-heading

# [[file:../../notes/custom/README.org::script-heading][script-heading]]
##
# ./etc/custom/custom.sh: initial project template customization
# 
# @see: ./notes/custom/README.org

# run from project root:
#
if [ ! -d ./etc/custom ]; then
    echo '

   custom.sh: initial project template customization


   Usage:
           ./build.sh custom

   from project root

   Config:

    before customization, project informantion must be set in config:

     nano ./etc/custom/custom-target.conf

'
    exit 1
fi

mkdir -p ./logs/custom
LOGFILE=./logs/custom/custom-$(date -Isec).log
exec &> >(tee $LOGFILE)
#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>$LOGFILE 2>&1

#--------------------------------------------------------------------

LS="--color=none"
#E_ROOT_DIR="$(dirname $0)"
E_ROOT_DIR="$(pwd)"


#-----------------------------------------------------------

(type nvidia-smi && nvidia-smi -L) &> /dev/null \
    && X_HAS_GPU=1 || X_HAS_GPU=0;

case "$X_HAS_GPU" in
     1) export X_UV_EXTRA='gpu' ;;
     *) export X_UV_EXTRA='cpu' ;;
esac
export X_HAS_GPU

#-----------------------------------------------------------

if [ -n "$container" ]; then
    export X_CONT_ON=1
    export X_CONT_MODE="$container"
else    
    export X_CONT_ON=0
    export X_CONT_MODE=""
fi

#-----------------------------------------------------------

: ${X_ENV_FILE:='.env'}
: ${X_ENV_DEFAULT:='.env.defaults'}
: ${X_ENV_STRICT:='.env.strict'}

#-----------------------------------------------------------
set -a

: ${E_CONF_DIR:="${E_ROOT_DIR}/docker/r-images"}
: ${E_META_FILE:="${E_CONF_DIR}/project.conf"}
: ${E_CONF_FILE:="${E_CONF_DIR}/runtime.conf"}
: ${E_AUTO_FILE:="${E_CONF_DIR}/starter.conf"}

[ -r "${E_META_FILE}" ] && source "${E_META_FILE}" || true
[ -r "${E_CONF_FILE}" ] && source "${E_CONF_FILE}" || true
[ -r "${E_AUTO_FILE}" ] && source "${E_AUTO_FILE}" || true

# ------------------------------------------------------

: ${X_PY_RUN:="uv run"}


set +a
# ------------------------------------------------------

exit_store() {

echo "Store Check Errors: $*"

(cat <<'EOF'

Verify System Store Configuration (as 'root'):


# --(access)---------------------------

##
# global
#

getent group dsdata
getent passwd dsdata

groups dsdata

grep dsdata /etc/group
grep dsdata /etc/passwd

# ---

groupadd --gid 840 dsdata
useradd -r -m -d /var/lib/dsdata -u 840 -g dsdata -Gstaff,users,dsuser -s/bin/bash dsdatapasswd -l dsdata
chmod 750 /var/lib/dsdata

##
# user
#

# unset X_USER

: "${X_USER:=dsuser}"
echo "X_USER=${X_USER}"

getent group "${X_USER}"
getent passwd "${X_USER}"

groups "${X_USER}"

grep "${X_USER}" /etc/group
grep "${X_USER}" /etc/passwd

# ---

usermod -a -G dsdata "${X_USER}"

# ---

getent group "${X_USER}"
getent passwd "${X_USER}"

groups "${X_USER}"

grep "${X_USER}" /etc/group
grep "${X_USER}" /etc/passwd


# --(store)---------------------------

##
# /data
#

ls -ld /data /data/store /data/opt/local
ls -l  /data /data/store /data/opt/local

[ -d /data ] || mkdir -p /data
[ -d /data/store ] || mkdir -p /data/store
[ -d /data/opt/local ] || mkdir -p /data/opt/local

ls -ld /data /data/store /data/opt/local
ls -l  /data /data/store /data/opt/local

##
# /vol/share
#

ls $LS -ld /vol
ls $LS -ld /vol/*

df -h | grep '/vol'
mount | grep '/vol'
cat /etc/fstab | grep '/vol'
ls -l /etc/smbcredentials

[ -d /vol ]          || mkdir -p /vol

ls $LS -ld /vol
ls $LS -ld /vol/*

##
# /vol/share
#

ls $LS -ld /vol/share/d1   /vol/share/d1/data/dd
ls $LS -ld /vol/share/d1/* /vol/share/d1/data/dd/*

[ -d /vol/share ]    || mkdir -p /vol/share
[ -d /vol/share/d1 ] || mkdir -p /vol/share/d1

[ -d /vol/share/d1/data/dd ] || mkdir -p /vol/share/d1/data/dd

# chown root:users /vol/share/d1 # mount options

ls $LS -ld /vol/share/d1   /vol/share/d1/data/dd
ls $LS -ld /vol/share/d1/* /vol/share/d1/data/dd/*


##
# /user
#

ls $LS -ld /user   /user/"${X_USER:-dsuser}"
ls $LS -ld /user/* /user/"${X_USER:-dsuser}"/*

[ -d /user/"${X_USER:-dsuser}" ] || mkdir -p /user/"${X_USER:-dsuser}"

# chown root:users /vol/share/d1 # mount options

ls $LS -ld /user   /user/"${X_USER:-dsuser}"
ls $LS -ld /user/* /user/"${X_USER:-dsuser}"/*



##
# /vol/data
#

ls $LS -ld /vol/data   /vol/data/*    /vol/data/*/*
ls $LS -ld /vol/data/* /vol/data/*/*/ /vol/data/*/*/*

df -h | grep '/vol/data'
mount | grep '/vol/data'
cat /etc/fstab | grep '/vol/data'
ls -l /etc/smbcredentials

[ -d /vol/data ] || mkdir -p /vol/data
# chown dsdata:dsdata /vol/data # mount options

ls $LS -ld /vol/data   /vol/data/*    /vol/data/*/*
ls $LS -ld /vol/data/* /vol/data/*/*/ /vol/data/*/*/*

##
# /store
#

ls  $LS -ld  /store
ls  $LS -ld  /store/*

[ -L /store ] || ln -s /data/store /store

[ -d /store/local ] || mkdir -p /store/local
[ -d /store/share ] || mkdir -p /store/share

ls  $LS -ld  /store
ls  $LS -ld  /store/*



##
# /store/local/dd
#

ls $LS -ld  /store/local/dd
ls $LS -ld  /store/local/dd/*

mkdir -p /store/local/dd

chown -R dsdata:dsdata /store/local/dd
chmod -R g+rw          /store/local/dd

find /store/local/dd -type d -exec chmod -R 2775  {} \;
find /store/local/dd -type f -exec chmod -R 664   {} \;

ls  $LS -ld  /store/local/dd
ls  $LS -ld  /store/local/dd/*

##
# /store/share/dd
#

ls $LS -ld  /store/share/lib   /store/share/lib/dd*/* /store/share/lib/dd*/*/*
ls $LS -ld  /store/share/lib/* /store/share/lib/dd*/* /store/share/lib/dd*/*/*

mkdir -p /store/share
mkdir -p /store/share/lib

chown -R dsdata:dsdata /store/share
chmod -R g+rw          /store/share

[ -e /store/share/lab ]        || ln -s /vol/share/d1            /store/share/lab
[ -e /store/share/lib/dd.lab ] || ln -s /store/share/lab/data/dd /store/share/lib/dd.lab
[ -e /store/share/lib/dd ]     || ln -s /store/share/lib/dd.lab  /store/share/lib/dd

find /store/share/lib -type d -exec chmod -R 2775  {} \;
find /store/share/lab -type f -exec chmod -R 664   {} \;

ls $LS -ld  /store/share/lib   /store/share/lib/dd*/* /store/share/lib/dd*/*/*
ls $LS -ld  /store/share/lib/* /store/share/lib/dd*/* /store/share/lib/dd*/*/*


EOF
) | "${PAGER:-less -SRX}"

  exit 1
}


# ------------------------------------------------------

echo ">>> project customization, ..."
# script-heading ends here

# Info Session
# #+NAME: session-info-haed

# [[file:../../notes/custom/README.org::session-info-haed][session-info-haed]]
echo "#:> (session-info)"
echo "--------------------------------"
# session-info-haed ends here



# #+NAME: user-info

# [[file:../../notes/custom/README.org::user-info][user-info]]
whoami
# user-info ends here



# #+NAME: host-info

# [[file:../../notes/custom/README.org::host-info][host-info]]
hostnamectl | \
    perl -p -e 's/([^ :])\s+(\S)/\1_\2/g' | sed -e 's/:/\t/'
# host-info ends here




# #+NAME: net-info

# [[file:../../notes/custom/README.org::net-info][net-info]]
ip -br -4 a | grep -v lo
# net-info ends here




# #+NAME: project-info

# [[file:../../notes/custom/README.org::project-info][project-info]]
pwd
# project-info ends here



# #+NAME: repo-info

# [[file:../../notes/custom/README.org::repo-info][repo-info]]
git remote -v
# repo-info ends here



# #+NAME: repo-status

# [[file:../../notes/custom/README.org::repo-status][repo-status]]
git -c color.ui=false status | \
    sed -e 's/^/> /'
# repo-status ends here



# #+NAME: session-info-tail

# [[file:../../notes/custom/README.org::session-info-tail][session-info-tail]]
echo "--------------------------------"
echo ""
echo "#:< (session-info)"
# session-info-tail ends here

# System Check
# #+NAME: system-check-haed

# [[file:../../notes/custom/README.org::system-check-haed][system-check-haed]]
echo "#:> (system-check)"
echo "--------------------------------"
# system-check-haed ends here



# #+NAME: store-check

# [[file:../../notes/custom/README.org::store-check][store-check]]
# ---(store)-------------------------------------------------------
echo "#:> store check, ..."

store_fail=0

if [ ! -d ~/work ]; then
    store_fail=1; echo "! FAIL: ~/work NOTFOUND "
fi
if [ ! -d ~/data ]; then
    store_fail=1; echo "! FAIL: ~/data NOTFOUND "
fi
if [ ! -d /vol ]; then
    store_fail=1; echo "! FAIL: /vol NOTFOUND "
fi
if [ ! -d /user ]; then
    store_fail=1; echo "! FAIL: /user NOTFOUND "
fi
if [ ! -d /data/opt/local ]; then
    store_fail=1; echo "! FAIL: /data/opt/local NOTFOUND "
fi
if [ ! -d /store/local ]; then
    store_fail=1; echo "! FAIL: /store/local NOTFOUND "
fi
if [ ! -d /store/share ]; then
    store_fail=1; echo "! FAIL: /store/share NOTFOUND "
fi
if [ ! -d /store/share/lib ]; then
    store_fail=1; echo "! FAIL: /store/share/lib NOTFOUND "
fi

case "$store_fail" in
    0) echo "= store check passed."
       ;;
    *) echo "= store check FAILED!"; exit_store "STORE FAILED"
       ;;
esac

echo "#:< store check, done."
# ----------------------------------------------------------------

# ---(write)-------------------------------------------------------
echo "#:> write check, ..."

write_fail=0

if [ -d /store/local ] && ! touch -c /store/local; then
    write_fail=1; echo "! FAIL: /store/local NOACCESS "
fi
if [ -d /store/local/dd ] && ! touch -c /store/local/dd ; then
    write_fail=1; echo "! FAIL: /store/local/dd NOACCESS "
fi
if [ -d /store/share/lib ] && ! touch -c /store/share/lib ; then
    write_fail=1; echo "! FAIL: /store/share/lib NOACCESS "
fi
if [ -d /store/share/lib/dd ] && ! touch -c /store/share/lib/dd ; then
    write_fail=1; echo "! FAIL: /store/share/lib/dd NOACCESS "
fi
if [ -d /user/$USER ] && ! touch -c /user/$USER ; then
    write_fail=1; echo "! FAIL: /user/$USER NOACCESS "
fi


case "$write_fail" in
    0) echo "= write check passed."
       ;;
    *) echo "= write check FAILED!"; exit_store "WRITE FAILED"
       ;;
esac

echo "#:< write check, done."
# ----------------------------------------------------------------
# store-check ends here



# #+NAME: system-check-tail

# [[file:../../notes/custom/README.org::system-check-tail][system-check-tail]]
echo "--------------------------------"
echo ""
echo "#:< (system-check)"
# system-check-tail ends here

# Source Config

# #+NAME: naming-config-head

# [[file:../../notes/custom/README.org::naming-config-head][naming-config-head]]
  echo "#:> (naming-config)"
  echo "--------------------------------"
# naming-config-head ends here



# #+NAME: conf-custom

# [[file:../../notes/custom/README.org::conf-custom][conf-custom]]
[ -f ./etc/custom/custom.conf ] || sed 's/^ *//' >> ./etc/custom/custom.conf <<-EOF
# project customization config
set -a
#  
CUST_X_CUSTOMIZED=0
#  
. ./etc/custom/custom-source.conf  
. ./etc/custom/custom-target.conf  
#  
set +a
EOF
# conf-custom ends here



# #+RESULTS: conf-custom

# #+NAME: custom-source.conf

# [[file:../../notes/custom/README.org::custom-source.conf][custom-source.conf]]
[ -f ./etc/custom/custom-source.conf ] || sed 's/^ *//' >> ./etc/custom/custom-source.conf <<'EOF'
##
# customization: project source consts
#
# ---(project)---
CUST_S_PROJECT_NAME='dve-sample-r'
# ---(package)---
CUST_S_R_PACKAGE_NAME='dvesimpler'
CUST_S_PY_PACKAGE_NAME='dve_sample_r'
# ---(source repository)---
CUST_S_REPO_PATH='ub-dems/ds-labs'
CUST_S_CICD_PATH='ub-dems/vs-base'
CUST_S_REPO_HOST='https://gitlab.com/'
# ---(image registry)---
CUST_S_REGS_PATH='ubdems'
CUST_S_REGS_HOST='docker.io'
# ---(environment versions)---
CUST_S_IMAGE_ANCHOR='rocker/geospatial:4.6.1'
CUST_S_VERS_BASE='(>= 4.6.0)'
CUST_S_VERS_ROXY='8.1.0'
# ---(data import links)---
CUST_S_DATA_LINK='dve-ds'
CUST_S_DATA_DEMO='1'
# ---(renv support options)---
CUST_S_RENV_OPTS='enable,auto'
# ---(project description)---
CUST_S_INFO_AUTH_NAME='dsuser'
CUST_S_INFO_AUTH_SURNAME='ub-dems'
CUST_S_INFO_AUTH_EMAIL='dsuser@campus.unimib.it'
CUST_S_INFO_TITLE='TODO(title): TITLE OF THE RESEARCH WORK'
CUST_S_INFO_DESC='TODO(desc): SHORT DESCRIPTION OF THE RESEARCH WORK'
# ---(image labels)---
CUST_S_INFO_OWNER='ab21010'
CUST_S_INFO_USER_EMAIL='dsuser.dems@gmail.com'
CUST_S_INFO_AUTHORS="${CUST_S_INFO_AUTH_SURNAME}/${CUST_S_INFO_AUTH_NAME} <${CUST_S_INFO_USER_EMAIL}>"
CUST_S_INFO_FROM='2026-03-16'
CUST_S_INFO_CDC='ds-101'
CUST_S_INFO_TAGS='none'
EOF
# custom-source.conf ends here

# Target Config

# #+NAME: custom-target.conf

# [[file:../../notes/custom/README.org::custom-target.conf][custom-target.conf]]
[ -f ./etc/custom/custom-target.conf ] || sed 's/^ *//' >> ./etc/custom/custom-target.conf <<"EOF"
##
# customization: project target consts
#
# ---(project)---
CUST_T_PROJECT_NAME='us-proto-r'
# ---(package)---
CUST_T_R_PACKAGE_NAME='USprotoR'
CUST_T_PY_PACKAGE_NAME='us_proto_r'
# ---(source repository)---
CUST_T_REPO_PATH='ub-dems/cs-labs/user-dsuser'
CUST_T_CICD_PATH="${CUST_T_REPO_PATH}"
CUST_T_REPO_HOST='https://gitlab.com/'
# ---(image registry)---
CUST_T_REGS_PATH='ubdems'
CUST_T_REGS_HOST='docker.io'
# ---(environment versions)---
CUST_T_IMAGE_ANCHOR='rocker/geospatial:4.6.1'
CUST_T_VERS_BASE='(>= 4.6.0)'
CUST_T_VERS_ROXY='8.1.0'
# ---(data import links)---
CUST_T_DATA_LINK='dat-ds'
CUST_T_DATA_DEMO='1'
# ---(renv support options)---
CUST_T_RENV_OPTS='enable,auto'
# ---(project description)---
CUST_T_INFO_AUTH_NAME='_GivenName_'
CUST_T_INFO_AUTH_SURNAME='_SurName_'
CUST_T_INFO_AUTH_EMAIL='nil@campus.unimib.it'
CUST_T_INFO_TITLE='TODO(title): TITLE OF THE WORK'
CUST_T_INFO_DESC='TODO(desc): SHORT DESCRIPTION OF THE WORK'
# ---(image labels)---
CUST_T_INFO_OWNER="$USER"
CUST_T_INFO_USER_EMAIL="${CUST_T_INFO_AUTH_EMAIL}"
CUST_T_INFO_AUTHORS="${CUST_T_INFO_AUTH_SURNAME}/${CUST_T_INFO_AUTH_NAME} <${CUST_T_INFO_USER_EMAIL}>"
CUST_T_INFO_FROM="$(date +%Y-%m-%d)"
CUST_T_INFO_CDC='es-620'
CUST_T_INFO_TAGS="ds.user=${CUST_T_INFO_OWNER},ds.task=${CUST_T_INFO_OWNER}.1"
EOF
# custom-target.conf ends here



# #+RESULTS: custom-target.conf

# #+NAME: conf-show

# [[file:../../notes/custom/README.org::conf-show][conf-show]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
env | grep ^CUST_ | tr '=' '\t' | sort
# conf-show ends here



# #+RESULTS: conf-show
# | CUST_S_PACKAGE_NAME | dvesimpler                  |
# | CUST_S_PROJECT_NAME | dve-sample-r                |
# | CUST_S_REPO_HOST    | https://gitlab.com/         |
# | CUST_S_REPO_PATH    | ub-dems/ds-labs      |
# | CUST_T_PACKAGE_NAME | USprotoR                    |
# | CUST_T_PROJECT_NAME | us-proto-r                  |
# | CUST_T_REPO_HOST    | https://gitlab.com/         |
# | CUST_T_REPO_PATH    | ub-dems/cs-labs/user-dsuser |
# | CUST_X_CUSTOMIZED   | 0                           |

# #+NAME: conf-check

# [[file:../../notes/custom/README.org::conf-check][conf-check]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
if [ ! "${CUST_X_CUSTOMIZED}" = '0' ] ; then
    echo '

      WARNING: project already customized, exiting ...

      To re-enable customization, set

      CUST_X_CUSTOMIZED=0

      in ./etc/custom/custom.conf,

      update new target customization

      in ./etc/custom/custom-target.conf,

      and re-execute customization with:

      ./build.sh custom

'
    exit 1
fi

[ -z "$CUST_S_PROJECT_NAME" ] && { echo "config error: CUST_S_PROJECT_NAME"; exit 1; }
[ -z "$CUST_S_R_PACKAGE_NAME" ] && { echo "config error: CUST_S_R_PACKAGE_NAME"; exit 1; }
[ -z "$CUST_S_PY_PACKAGE_NAME" ] && { echo "config error: CUST_S_PY_PACKAGE_NAME"; exit 1; }
[ -z "$CUST_S_REPO_PATH" ] && { echo "config error: CUST_S_REPO_PATH"; exit 1; }
[ -z "$CUST_S_CICD_PATH" ] && { echo "config error: CUST_S_CICD_PATH"; exit 1; }
[ -z "$CUST_S_REPO_HOST" ] && { echo "config error: CUST_S_REPO_HOST"; exit 1; }
[ -z "$CUST_S_REGS_PATH" ] && { echo "config error: CUST_S_REGS_PATH"; exit 1; }
[ -z "$CUST_S_REGS_HOST" ] && { echo "config error: CUST_S_REGS_HOST"; exit 1; }
[ -z "$CUST_S_IMAGE_ANCHOR" ] && { echo "config error: CUST_S_IMAGE_ANCHOR"; exit 1; }
[ -z "$CUST_S_VERS_BASE" ] && { echo "config error: CUST_S_VERS_BASE"; exit 1; }
[ -z "$CUST_S_VERS_ROXY" ] && { echo "config error: CUST_S_VERS_ROXY"; exit 1; }
[ -z "$CUST_S_DATA_LINK" ] && { echo "config error: CUST_S_DATA_LINK"; exit 1; }
[ -z "$CUST_S_RENV_OPTS" ] && { echo "config error: CUST_S_RENV_OPTS"; exit 1; }
[ -z "$CUST_S_INFO_AUTH_NAME" ] && { echo "config error: CUST_S_INFO_AUTH_NAME"; exit 1; }
[ -z "$CUST_S_INFO_AUTH_SURNAME" ] && { echo "config error: CUST_S_INFO_AUTH_SURNAME"; exit 1; }
[ -z "$CUST_S_INFO_AUTH_EMAIL" ] && { echo "config error: CUST_S_INFO_AUTH_EMAIL"; exit 1; }
[ -z "$CUST_S_INFO_DESC" ] && { echo "config error: CUST_S_INFO_DESC"; exit 1; }
[ -z "$CUST_S_INFO_TITLE" ] && { echo "config error: CUST_S_INFO_TITLE"; exit 1; }
[ -z "$CUST_S_INFO_USER_EMAIL" ] && { echo "config error: CUST_S_INFO_USER_EMAIL"; exit 1; }
[ -z "$CUST_S_INFO_AUTHORS" ] && { echo "config error: CUST_S_INFO_AUTHORS"; exit 1; }
[ -z "$CUST_S_INFO_FROM" ] && { echo "config error: CUST_S_INFO_FROM"; exit 1; }
[ -z "$CUST_S_INFO_OWNER" ] && { echo "config error: CUST_S_INFO_OWNER"; exit 1; }
[ -z "$CUST_S_INFO_CDC" ] && { echo "config error: CUST_S_INFO_CDC"; exit 1; }
[ -z "$CUST_S_INFO_TAGS" ] && { echo "config error: CUST_S_INFO_TAGS"; exit 1; }

[ -z "$CUST_T_PROJECT_NAME" ] && { echo "config error: CUST_T_PROJECT_NAME"; exit 1; }
[ -z "$CUST_T_R_PACKAGE_NAME" ] && { echo "config error: CUST_T_R_PACKAGE_NAME"; exit 1; }
[ -z "$CUST_T_PY_PACKAGE_NAME" ] && { echo "config error: CUST_T_PY_PACKAGE_NAME"; exit 1; }
[ -z "$CUST_T_REPO_PATH" ] && { echo "config error: CUST_T_REPO_PATH"; exit 1; }
[ -z "$CUST_T_CICD_PATH" ] && { echo "config error: CUST_T_CICD_PATH"; exit 1; }
[ -z "$CUST_T_REPO_HOST" ] && { echo "config error: CUST_T_REPO_HOST"; exit 1; }
[ -z "$CUST_T_REGS_PATH" ] && { echo "config error: CUST_T_REGS_PATH"; exit 1; }
[ -z "$CUST_T_REGS_HOST" ] && { echo "config error: CUST_T_REGS_HOST"; exit 1; }
[ -z "$CUST_T_IMAGE_ANCHOR" ] && { echo "config error: CUST_T_IMAGE_ANCHOR"; exit 1; }
[ -z "$CUST_T_VERS_BASE" ] && { echo "config error: CUST_T_VERS_BASE"; exit 1; }
[ -z "$CUST_T_VERS_ROXY" ] && { echo "config error: CUST_T_VERS_ROXY"; exit 1; }
[ -z "$CUST_T_DATA_LINK" ] && { echo "config error: CUST_T_DATA_LINK"; exit 1; }
[ -z "$CUST_T_RENV_OPTS" ] && { echo "config error: CUST_T_RENV_OPTS"; exit 1; }
[ -z "$CUST_T_INFO_AUTH_NAME" ] && { echo "config error: CUST_T_INFO_AUTH_NAME"; exit 1; }
[ -z "$CUST_T_INFO_AUTH_SURNAME" ] && { echo "config error: CUST_T_INFO_AUTH_SURNAME"; exit 1; }
[ -z "$CUST_T_INFO_AUTH_EMAIL" ] && { echo "config error: CUST_T_INFO_AUTH_EMAIL"; exit 1; }
[ -z "$CUST_T_INFO_DESC" ] && { echo "config error: CUST_T_INFO_DESC"; exit 1; }
[ -z "$CUST_T_INFO_TITLE" ] && { echo "config error: CUST_T_INFO_TITLE"; exit 1; }
[ -z "$CUST_T_INFO_USER_EMAIL" ] && { echo "config error: CUST_T_INFO_USER_EMAIL"; exit 1; }
[ -z "$CUST_T_INFO_AUTHORS" ] && { echo "config error: CUST_T_INFO_AUTHORS"; exit 1; }
[ -z "$CUST_T_INFO_FROM" ] && { echo "config error: CUST_T_INFO_FROM"; exit 1; }
[ -z "$CUST_T_INFO_OWNER" ] && { echo "config error: CUST_T_INFO_OWNER"; exit 1; }
[ -z "$CUST_T_INFO_CDC" ] && { echo "config error: CUST_T_INFO_CDC"; exit 1; }
[ -z "$CUST_T_INFO_TAGS" ] && { echo "config error: CUST_T_INFO_TAGS"; exit 1; }
# conf-check ends here



# #+NAME: naming-config-tail

# [[file:../../notes/custom/README.org::naming-config-tail][naming-config-tail]]
echo "--------------------------------"
echo ""
echo "#:< (naming-config)"
# naming-config-tail ends here

# File Rename

# #+NAME: cust-rename-pre

# [[file:../../notes/custom/README.org::cust-rename-pre][cust-rename-pre]]
echo "#:> (cust-rename)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
find . \
     \( -path ./home -o -path ./notes \) -prune -o \
     -name "$CUST_S_R_PACKAGE_NAME*" -o -name "$CUST_S_R_PROJECT_NAME*"
echo "--------------------------------"
find . \
     \( -path ./home -o -path ./notes \) -prune -o \
     -name "$CUST_S_PY_PACKAGE_NAME*" -o -name "$CUST_S_PY_PROJECT_NAME*"
echo "--------------------------------"
echo ""
# cust-rename-pre ends here



# #+NAME: cust-rename

# [[file:../../notes/custom/README.org::cust-rename][cust-rename]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

mv -v ./${CUST_S_R_PACKAGE_NAME}.Rproj ./${CUST_T_R_PACKAGE_NAME}.Rproj
mv -v ./man/${CUST_S_R_PACKAGE_NAME}-package.Rd ./man/${CUST_T_R_PACKAGE_NAME}-package.Rd
mv -v ./R/${CUST_S_R_PACKAGE_NAME}-package.r ./R/${CUST_T_R_PACKAGE_NAME}-package.r

[ -f ./inst/include/${CUST_S_R_PACKAGE_NAME}.h ] && \
mv -v ./inst/include/${CUST_S_R_PACKAGE_NAME}.h ./inst/include/${CUST_T_R_PACKAGE_NAME}.h
# cust-rename ends here



# #+NAME: cust-rename-post

# [[file:../../notes/custom/README.org::cust-rename-post][cust-rename-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
find . \
     \( -path ./home -o -path ./notes \) -prune -o \
     -name "$CUST_T_R_PACKAGE_NAME*" -o -name "$CUST_T_PROJECT_NAME*"
echo "--------------------------------"
echo ""
echo "#:< (cust-rename)"
# cust-rename-post ends here

# Package Name

# #+NAME: cust-package-pre

# [[file:../../notes/custom/README.org::cust-package-pre][cust-package-pre]]
echo "#:> (cust-packge)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_R_PACKAGE_NAME" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_PY_PACKAGE_NAME" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
# cust-package-pre ends here



# #+NAME: cust-package

# [[file:../../notes/custom/README.org::cust-package][cust-package]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

echo "--------------------------------"
grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_R_PACKAGE_NAME" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_R_PACKAGE_NAME}{$CUST_T_R_PACKAGE_NAME}g"
echo "--------------------------------"
grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_PY_PACKAGE_NAME" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_PY_PACKAGE_NAME}{$CUST_T_PY_PACKAGE_NAME}g"
echo "--------------------------------"
echo ""
# cust-package ends here




# #+NAME: cust-package-post

# [[file:../../notes/custom/README.org::cust-package-post][cust-package-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_T_R_PACKAGE_NAME" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_T_PY_PACKAGE_NAME" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
echo "#:< (cust-packge)"
# cust-package-post ends here

# Repo Address

# #+NAME: cust-repo-pre

# [[file:../../notes/custom/README.org::cust-repo-pre][cust-repo-pre]]
echo "#:> (cust-repo)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_REPO_PATH" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
# cust-repo-pre ends here



# #+NAME: cust-repo

# [[file:../../notes/custom/README.org::cust-repo][cust-repo]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "CUST_S_REPO_HOST$CUST_S_REPO_PATH" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_REPO_HOST$CUST_S_REPO_PATH}{$CUST_T_REPO_HOST$CUST_T_REPO_PATH}g"

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_REPO_PATH" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_REPO_PATH}{$CUST_T_REPO_PATH}g"

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "CUST_S_REPO_HOST$CUST_S_CICD_PATH" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_REPO_HOST$CUST_S_CICD_PATH}{$CUST_T_REPO_HOST$CUST_T_CICD_PATH}g"

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_CICD_PATH" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_CICD_PATH}{$CUST_T_CICD_PATH}g"
# cust-repo ends here




# #+NAME: cust-repo-post

# [[file:../../notes/custom/README.org::cust-repo-post][cust-repo-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_T_REPO_PATH" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
echo "#:< (cust-repo)"
# cust-repo-post ends here

# Registry Address

# #+NAME: cust-regs-pre

# [[file:../../notes/custom/README.org::cust-regs-pre][cust-regs-pre]]
echo "#:> (cust-regs)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_REGS_PATH" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
# cust-regs-pre ends here



# #+NAME: cust-regs

# [[file:../../notes/custom/README.org::cust-regs][cust-regs]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "CUST_S_REGS_HOST/$CUST_S_REGS_PATH}" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_REGS_HOST/$CUST_S_REGS_PATH}{CUST_T_REGS_HOST/$CUST_T_REGS_PATH}g"

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_REGS_PATH" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_REGS_PATH}{$CUST_T_REGS_PATH}g"
# cust-regs ends here




# #+NAME: cust-regs-post

# [[file:../../notes/custom/README.org::cust-regs-post][cust-regs-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_T_REGS_PATH" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'

echo "--------------------------------"
echo ""
echo "#:< (cust-regs)"
# cust-regs-post ends here

# Project Name

# #+NAME: cust-project-pre

# [[file:../../notes/custom/README.org::cust-project-pre][cust-project-pre]]
echo "#:> (cust-project)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_PROJECT_NAME" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
# cust-project-pre ends here



# #+NAME: cust-project

# [[file:../../notes/custom/README.org::cust-project][cust-project]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_PROJECT_NAME" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_PROJECT_NAME}{$CUST_T_PROJECT_NAME}g"
# cust-project ends here




# #+NAME: cust-project-post

# [[file:../../notes/custom/README.org::cust-project-post][cust-project-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_T_PROJECT_NAME" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
echo "--------------------------------"
echo ""
echo "#:< (cust-project)"
# cust-project-post ends here

# Data Store

# #+NAME: cust-data-store-pre

# [[file:../../notes/custom/README.org::cust-data-store-pre][cust-data-store-pre]]
echo "#:> (data-store)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf

echo "--------------------------------"
echo "#store - CUST_T_DATA_LINK=$CUST_T_DATA_LINK"
ls -lda ~/data
find  -L ~/data -maxdepth 5 -type d
#find -L ~/data -type f -exec ls -lh {} \;
echo "--------------------------------"
echo ""
# cust-data-store-pre ends here



# #+NAME: cust-data-store

# [[file:../../notes/custom/README.org::cust-data-store][cust-data-store]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

DD="$CUST_T_DATA_LINK"

[ -n "${DD}" ] || { echo "#UNDEF: CUST_T_DATA_LINK"; exit 1; } 

WD=$(pwd)

# dd base

mkdir -p ~/data

if [ ! -d ~/data/def/dd ]; then
    mkdir -p        ~/data/def/dd
    chgrp -R dsdata ~/data/def/dd 2> /dev/null
    chmod -R g+rws  ~/data/def/dd 2> /dev/null
fi

ls -l           ~/data/def

mkdir -p /user/$USER


cd ~/data
[ ! -e ~/data/local ] && [   -e /store/local ] && ln -s -Tv /store/local  ~/data/local
[ ! -e ~/data/local ] && [ ! -e /store/local ] && mkdir -p                ~/data/local
[ ! -e ~/data/share ] && [   -e /store/share ] && ln -s -Tv /store/share  ~/data/share
[ ! -e ~/data/share ] && [ ! -e /store/share ] && mkdir -p                ~/data/share

[ ! -e ~/data/user ] && [ -e /user/$USER ] && ln -s  -Tv /user/$USER      ~/data/user
[ ! -e ~/data/user ] && [ ! -e /user/$USER ] && mkdir -p                  ~/data/user

cd -

ls -l  ~/data

# dd path

mkdir -p ~/data/def/dd/$DD.def
mkdir -p ~/data/local/dd/$DD.loc
mkdir -p ~/data/user/dd/$DD.vol
mkdir -p ~/data/share/lib/dd/$DD.net


# sample data

if [ "${CUST_T_DATA_DEMO}" = '1' ]; then
    
    [ -d /vol/glob/dvd/data/vs ] || sudo mount /vol/glob/dvd
    
    if [ ! -d ~/data/share/lib/dd/$DD.net/examples ]; then
        
        cp -rv /vol/glob/dvd/data/vs/dve-ds.net/. ~/data/share/lib/dd/$DD.net
        chown -R $USER:dsdata ~/data/share/lib/dd/$DD.net 2> /dev/null
        chmod -R u+w,g+w ~/data/share/lib/dd/$DD.net 2> /dev/null
        cp -rv /vol/glob/dvd/data/vs/dve-ds.loc/. ~/data/local/dd/$DD.loc
        chown -R $USER:dsdata ~/data/local/dd/$DD.loc 2> /dev/null
        chmod -R u+w,g+w ~/data/local/dd/$DD.loc  2> /dev/null

    fi

    #cp -rv /vol/glob/dvd/data/vs/dve-ds.def/. ~/data/def/dd/$DD.def
    #chown -R $USER:dsdata ~/data/def/dd/$DD.def
    #chmod -R u+w,g+w ~/data/def/dd/$DD.def

fi

# ---

cd $WD
# cust-data-store ends here




# #+NAME: cust-data-store-post

# [[file:../../notes/custom/README.org::cust-data-store-post][cust-data-store-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf

echo "--------------------------------"
echo "#store - CUST_T_DATA_LINK=$CUST_T_DATA_LINK"

ls -lda ~/data
find  -L ~/data -maxdepth 5 -type d
#find -L ~/data -type f -exec ls -lh {} \;
echo "--------------------------------"
echo ""
echo "#:< (data-store)"
# cust-data-store-post ends here

# Data Import

# #+NAME: cust-data-import-pre

# [[file:../../notes/custom/README.org::cust-data-import-pre][cust-data-import-pre]]
echo "#:> (data-import)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf

echo "#import - CUST_T_DATA_LINK=$CUST_T_DATA_LINK"

find -L inst/extdata
find -L inst/extdata -type f -exec ls -lh {} \;
# cust-data-import-pre ends here



# #+NAME: cust-data-import

# [[file:../../notes/custom/README.org::cust-data-import][cust-data-import]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

WD=$(pwd)

mkdir -p ./inst/extdata/ext

ls -la ./inst/extdata/ext
cd     ./inst/extdata/ext
cat .gitignore

DD="$CUST_T_DATA_LINK"

[ -e $DD.def ] || ln -s -Tv ~/data/def/dd/$DD.def         $DD.def
[ -e $DD.loc ] || ln -s -Tv ~/data/local/dd/$DD.loc       $DD.loc
[ -e $DD.net ] || ln -s -Tv ~/data/share/lib/dd/$DD.net   $DD.net

ls -l
ls -l */.

# ---

cd $WD
# cust-data-import ends here




# #+NAME: cust-data-import-post

# [[file:../../notes/custom/README.org::cust-data-import-post][cust-data-import-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf

echo "#import - CUST_T_DATA_LINK=$CUST_T_DATA_LINK"

find -L inst/extdata
find -L inst/extdata -type f -exec ls -lh {} \;

echo "#:< (data-import)"
# cust-data-import-post ends here

# Data Link

# #+NAME: cust-data-link-pre

# [[file:../../notes/custom/README.org::cust-data-link-pre][cust-data-link-pre]]
echo "#:> (data-link)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_DATA_LINK" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'
# cust-data-link-pre ends here



# #+NAME: cust-data-link

# [[file:../../notes/custom/README.org::cust-data-link][cust-data-link]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

grep -l -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_S_DATA_LINK" | \
    xargs -t -l1 perl -pi -e  "s{$CUST_S_DATA_LINK}{$CUST_T_DATA_LINK}g"
# cust-data-link ends here




# #+NAME: cust-data-link-post

# [[file:../../notes/custom/README.org::cust-data-link-post][cust-data-link-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
grep -r \
     --exclude-dir=.git --exclude-dir=custom --exclude-dir=notes --exclude-dir=home --exclude-dir=logs \
     -I -e "$CUST_T_DATA_LINK" | \
    tr -s ' ' '^' | sed -e 's/:/\t/'

echo "#:< (data-link)"
# cust-data-link-post ends here

# Environment Versions

# #+NAME: cust-vers-pre

# [[file:../../notes/custom/README.org::cust-vers-pre][cust-vers-pre]]
echo "#:> (env-versions)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
grep -F -e "$CUST_S_VERS_BASE" -e "$CUST_S_VERS_ROXY" ./DESCRIPTION
grep -F -e "$CUST_S_IMAGE_ANCHOR" ./docker/r-images/dockerfiles/anchor.Dockerfile
# cust-vers-pre ends here



# #+NAME: cust-vers

# [[file:../../notes/custom/README.org::cust-vers][cust-vers]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

perl -pi -e  "s{(\s+R\s+)\Q$CUST_S_VERS_BASE\E}{\1$CUST_T_VERS_BASE}" ./DESCRIPTION
perl -pi -e  "s{(RoxygenNote:)\s*\Q$CUST_S_VERS_ROXY\E}{\1 $CUST_T_VERS_ROXY}" ./DESCRIPTION

perl -pi -e  "s{\Q$CUST_S_IMAGE_ANCHOR\E}{$CUST_T_IMAGE_ANCHOR}" ./docker/r-images/dockerfiles/anchor.Dockerfile
# cust-vers ends here



# #+NAME: cust-vers-post

# [[file:../../notes/custom/README.org::cust-vers-post][cust-vers-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
grep -F -e "$CUST_T_VERS_BASE" -e "$CUST_T_VERS_ROXY" ./DESCRIPTION
grep -F -e "$CUST_T_IMAGE_ANCHOR" ./docker/r-images/dockerfiles/anchor.Dockerfile

echo "#:< (env-versions)"
# cust-vers-post ends here

# Local Environment

# #+NAME: cust-dotenv-pre

# [[file:../../notes/custom/README.org::cust-dotenv-pre][cust-dotenv-pre]]
echo "#:> (.env-init)"
echo "--- .env* -------"
ls -l .env*
echo "-----------------"
# cust-dotenv-pre ends here



# #+NAME: cust-dotenv

# [[file:../../notes/custom/README.org::cust-dotenv][cust-dotenv]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

if [ -z "${X_ENV_FILE}" ]; then
    echo "ev - X_ENV_FILE undefined, skip"
elif [ -f "${X_ENV_FILE}" ]; then
    echo "ev - X_ENV_FILE=${X_ENV_FILE} found, skip"
else
    cat "${X_ENV_DEFAULT}" | grep '^[a-zA-Z0-9_]' > "${X_ENV_STRICT}"
    cp -v "${X_ENV_STRICT}" "${X_ENV_FILE}"
    ls -l "${X_ENV_FILE}" "${X_ENV_STRICT}" "${X_ENV_DEFAULT}"
    echo "ev - X_ENV_FILE=${X_ENV_FILE} created from ${X_ENV_DEFAULT}."
fi
# cust-dotenv ends here



# #+NAME: cust-dotenv-post

# [[file:../../notes/custom/README.org::cust-dotenv-post][cust-dotenv-post]]
echo "--- .env* -------"
ls -l .env*
echo "-----------------"
echo "#:< (env-versions)"
# cust-dotenv-post ends here

# Project Description/R

# #+NAME: cust-pinfo-r-vers-pre

# [[file:../../notes/custom/README.org::cust-pinfo-r-vers-pre][cust-pinfo-r-vers-pre]]
echo "#:> (project-desc/R)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- DESCRIPTION ----------------"
awk '/^Type:/,/^Imports:/' ./DESCRIPTION
echo "--------------------------------"
echo ""
# cust-pinfo-r-vers-pre ends here



# #+NAME: cust-pinfo-r

# [[file:../../notes/custom/README.org::cust-pinfo-r][cust-pinfo-r]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

perl -pi -e  "s{(given\s*=\s*)\"\Q$CUST_S_INFO_AUTH_NAME\E\"}{\1\"$CUST_T_INFO_AUTH_NAME\"}" ./DESCRIPTION
perl -pi -e  "s{(family\s*=\s*)\"\Q$CUST_S_INFO_AUTH_SURNAME\E\"}{\1\"$CUST_T_INFO_AUTH_SURNAME\"}" ./DESCRIPTION
perl -pi -e  's{(email\s*=\s*)\"\Q$ENV{CUST_S_INFO_AUTH_EMAIL}\E\"}{\1\"$ENV{CUST_T_INFO_AUTH_EMAIL}\"}' ./DESCRIPTION
perl -pi -e  "s{(Title\s*:\s*)\Q$CUST_S_INFO_TITLE\E}{\1$CUST_T_INFO_TITLE}" ./DESCRIPTION
perl -pi -e  "s{(Description\s*:\s*)\Q$CUST_S_INFO_DESC\E}{\1$CUST_T_INFO_DESC}" ./DESCRIPTION
# cust-pinfo-r ends here



# #+NAME: cust-pinfo-r-post

# [[file:../../notes/custom/README.org::cust-pinfo-r-post][cust-pinfo-r-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- DESCRIPTION ----------------"
awk '/^Type:/,/^Imports:/' ./DESCRIPTION
echo "--------------------------------"
echo ""

echo "#:< (project-desc/R)"
# cust-pinfo-r-post ends here

# Project Description/PY

# #+NAME: cust-pinfo-py-vers-pre

# [[file:../../notes/custom/README.org::cust-pinfo-py-vers-pre][cust-pinfo-py-vers-pre]]
echo "#:> (project-desc/PY)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- pyproject.toml ----------------"
awk '/\[project\]/,/^classifiers/' pyproject.toml
echo "--------------------------------"
echo ""
# cust-pinfo-py-vers-pre ends here



# #+NAME: cust-pinfo-py

# [[file:../../notes/custom/README.org::cust-pinfo-py][cust-pinfo-py]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

perl -pi -e  "s{^(\s+\{\s*name\s*=\s*)\"\Q$CUST_S_INFO_AUTH_NAME\E/}{\1\"$CUST_T_INFO_AUTH_NAME/}" pyproject.toml
perl -pi -e  "s{^(\s+\{\s*name\s*=\s*[^/]+/)\Q$CUST_S_INFO_AUTH_SURNAME\E\"}{\1$CUST_T_INFO_AUTH_SURNAME\"}" pyproject.toml
perl -pi -e  's{(email\s*=\s*)\"\Q$ENV{CUST_S_INFO_AUTH_EMAIL}\E\"}{\1\"$ENV{CUST_T_INFO_AUTH_EMAIL}\"}' pyproject.toml
perl -pi -e  "s{(description\s*=\s*)\"\Q$CUST_S_INFO_TITLE\E\"}{\1\"$CUST_T_INFO_TITLE\"}" pyproject.toml
# cust-pinfo-py ends here



# #+NAME: cust-pinfo-py-post

# [[file:../../notes/custom/README.org::cust-pinfo-py-post][cust-pinfo-py-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- pyproject.toml ----------------"
awk '/\[project\]/,/^classifiers/' pyproject.toml
echo "--------------------------------"
echo ""

echo "#:< (project-desc/PY)"
# cust-pinfo-py-post ends here

# Project Description/MD

# #+NAME: cust-pinfo-md-vers-pre

# [[file:../../notes/custom/README.org::cust-pinfo-md-vers-pre][cust-pinfo-md-vers-pre]]
echo "#:> (project-desc/MD)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- README.Rmd/README.md ----------------"
head -n 25 README.md
echo "--------------------------------"
echo ""
# cust-pinfo-md-vers-pre ends here



# #+NAME: cust-pinfo-md

# [[file:../../notes/custom/README.org::cust-pinfo-md][cust-pinfo-md]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

for f in README.*md; do
    perl -pi -e  "s{\Q$CUST_S_PROJECT_NAME\E}{$CUST_T_PROJECT_NAME}" $f
    perl -pi -e  "s{\Q$CUST_S_R_PACKAGE_NAME\E}{$CUST_T_R_PACKAGE_NAME}" $f
    perl -pi -e  "s{\Q$CUST_S_PY_PACKAGE_NAME\E}{$CUST_T_PY_PACKAGE_NAME}" $f
    perl -pi -e  "s{\Q$CUST_S_REPO_PATH\E}{$CUST_T_REPO_PAST}" $f
    perl -pi -e  "s{\Q$CUST_S_REPO_HOST\E}{$CUST_T_REPO_HOST}" $f
    perl -pi -e  "s{\Q$CUST_S_INFO_AUTH_NAME\E}{$CUST_T_INFO_AUTH_NAME}" $f
    perl -pi -e  "s{\Q$CUST_S_INFO_AUTH_SURNAME\E}{$CUST_T_INFO_AUTH_SURNAME}" $f
    perl -pi -e  "s{\Q$CUST_S_INFO_AUTH_EMAIL\E}{$CUST_T_INFO_AUTH_EMAIL}" $f
    perl -pi -e  "s{\Q$CUST_S_INFO_TITLE\E}{$CUST_T_INFO_TITLE}" $f
    perl -pi -e  "s{\Q$CUST_S_INFO_DESC\E}{$CUST_T_INFO_DESC}" $f
done
# cust-pinfo-md ends here



# #+NAME: cust-pinfo-md-post

# [[file:../../notes/custom/README.org::cust-pinfo-md-post][cust-pinfo-md-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- README.Rmd/README.md ----------------"
head -n 25 README.md
echo "--------------------------------"
echo ""

echo "#:< (project-desc/PY)"
# cust-pinfo-md-post ends here

# Image Description

# #+NAME: cust-binfo-pre

# [[file:../../notes/custom/README.org::cust-binfo-pre][cust-binfo-pre]]
echo "#:> (image-desc)"

[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- *.Dockerfiles ----------------"
find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     grep -I -e 'org.opencontainers.image' -e 'it.unimib.datalab' {} \; | sort -k2 | uniq | \
    tr -s ' ' ' ' | sed -e 's/:/:/'
echo "--------------------------------"
echo ""
# cust-binfo-pre ends here



# #+NAME: cust-binfo

# [[file:../../notes/custom/README.org::cust-binfo][cust-binfo]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     perl -pi -e  's!(org.opencontainers.image.authors=").*"!\1$ENV{CUST_T_INFO_AUTHORS}"!' {} \;

find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     perl -pi -e  's!(org.opencontainers.image.description=").*"!\1$ENV{CUST_T_INFO_DESC}"!' {} \;

find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     perl -pi -e  's!(it.unimib.datalab.from=").*"!\1$ENV{CUST_T_INFO_FROM}"!' {} \;

find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     perl -pi -e  's!(it.unimib.datalab.owner=").*"!\1$ENV{CUST_T_INFO_OWNER}"!' {} \;

find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     perl -pi -e  's!(it.unimib.datalab.cdc=").*"!\1$ENV{CUST_T_INFO_CDC}"!' {} \;

find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     perl -pi -e  's!(it.unimib.datalab.tags=").*"!\1$ENV{CUST_T_INFO_TAGS}"!' {} \;
# cust-binfo ends here




# #+NAME: cust-binfo-post

# [[file:../../notes/custom/README.org::cust-binfo-post][cust-binfo-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--- *.Dockerfiles ----------------"
find ./docker/r-images/dockerfiles -name '*.Dockerfile' -exec \
     grep -I -e 'org.opencontainers.image' -e 'it.unimib.datalab' {} \; | sort -k2 | uniq | \
    tr -s ' ' ' ' | sed -e 's/:/:/'
echo "--------------------------------"
echo ""
echo "#:< (image-desc)"
# cust-binfo-post ends here

# Confirm Customization

# #+NAME: cust-confirm-pre

# [[file:../../notes/custom/README.org::cust-confirm-pre][cust-confirm-pre]]
echo "#:> (cust-confirm)"

echo "--------------------------------"
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
env | grep ^CUST_ | tr '=' '\t' | sort
echo "--------------------------------"
echo ""
# cust-confirm-pre ends here



# #+NAME: cust-confirm

# [[file:../../notes/custom/README.org::cust-confirm][cust-confirm]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
[ "${CUST_X_CUSTOMIZED}" = '0' ] || exit 1

ls -l ./etc/custom/*.conf

T="$(date -Isec)"
mkdir -p ./etc/custom/done/$T

echo "=== reset renv dependecies, ..."
[ -f ./renv.lock ] && mv -v  ./renv.lock ./etc/custom/done/$T
echo "=== run renv::init() to re-initialize."

echo "=== reset uv dependecies, ..."
[ -f ./uv.lock ] && mv -v  ./uv.lock ./etc/custom/done/$T
echo "=== run uv lock to re-initialize."

cp -pv   ./etc/custom/*.conf ./etc/custom/done/$T

find ./etc/custom | sort

cp -pv ./etc/custom/custom-target.conf ./etc/custom/custom-source.conf
perl -pi -e  "s/CUST_T_/CUST_S_/"      ./etc/custom/custom-source.conf

perl -pi -e  "s/CUST_X_CUSTOMIZED\s*=\s*0/CUST_X_CUSTOMIZED=1/" ./etc/custom/custom.conf

ls -l ./etc/custom/*.conf
# cust-confirm ends here




# #+NAME: cust-confirm-post

# [[file:../../notes/custom/README.org::cust-confirm-post][cust-confirm-post]]
[ -f ./etc/custom/custom.conf ] && . ./etc/custom/custom.conf
echo "--------------------------------"
env | grep ^CUST_ | tr '=' '\t' | sort
echo "--------------------------------"
echo ""
echo "#:< (cust-confirm)"
# cust-confirm-post ends here

# Script Tail
# #+NAME: script-tail

# [[file:../../notes/custom/README.org::script-tail][script-tail]]
echo "<<< project customization, done."

echo '
     
   to check customized project, run:

   ./build.sh setup

   ./runtime.sh build all

   project developer s guide is available at:

      * https://gitlab.com/ub-dems/ds-labs/dve-sample-r/-/blob/main/notes/usage/README.md

'
echo "see:  $LOGFILE "
echo " "

less -SRX $LOGFILE
# script-tail ends here
