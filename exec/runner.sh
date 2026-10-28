#!/bin/bash
##{{{
# runner.sh: R script launcher
# ====================================
#
#  R script runner via Rscript
#
#  "./exec/runner.sh help" for usage info
#

E_ROOT_DIR="$(realpath $(dirname $0)/..)"
E_EXEC_DIR="${E_ROOT_DIR}/exec"

export PATH=$E_EXEC_DIR:$PATH

. $(dirname $0)/../functions.sh

#}}} \\\    
#{{{ [ DOCS ] /////////////////////////////////////////////////////////////////

# ---(usage)------------------------------------------------

exit_usage() {

cat <<EOF | $PAGER   

usage $0 [-e r-script] [args, ...]

runs r-script in project via Rscript


where "r-script" is an R script name, defaults to

  ./exec/runner.R : default R script fron project root


NOTE
====

the scripts will be executerd from project root working directory 
and should be placed in the ./exec directory (added to PATH)



ENVIRONMENNT
============

inherited env:
 
- E_SCRIPT_NAME: script name (defaults to 'runner.sh')
- E_SCRIPT_FILE: script path (defaults to $E_EXEC_DIR/$E_EXEC_NAME)
- E_SCRIPT_ARGS: script arguments

exported env:

- E_ROOT_DIR: project base directory (working directory)
- E_EXEC_DIR: executable scripts directory ( $E_ROOT_DIR'/exec' )

- PATH: $E_EXEC_DIR:$PATH


EOF

exit 1

}


#}}} \\\
#{{{ [ MAIN ] /////////////////////////////////////////////////////////////////

# ---(call)------------------------------------------------

run_call() {
   Rscript ${E_SCRIPT_FILE} $@
   rc=$?
   return $rc
}

do_call() {
    info "> exec::($E_SCRIPT_NAME, $E_SCRIPT_ARGS) -- ${E_SCRIPT_FILE}"
    run_call
    info "< exec::($E_SCRIPT_NAME, $E_SCRIPT_ARGS) (rc: $rc)"

}

# ---(main)------------------------------------------------

main() {

case "$1" in
    -e)
        shift
        E_SCRIPT_NAME="$1"
        shift
        ;;
        -?|/h|-h|--help|help)
            exit_usage
            ;;
    *)
        ;;
esac

: ${E_SCRIPT_NAME:="runner.R"}
: ${E_SCRIPT_FILE:="$E_EXEC_DIR/$E_SCRIPT_NAME"}
: ${E_SCRIPT_ARGS:=($@)}

export E_SCRIPT_NAME
export E_SCRIPT_FILE
export E_SCRIPT_ARGS

#cd $E_ROOT_DIR

do_call $@
exit $rc

}

main $@

#}}} \\\

