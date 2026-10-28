import sys
import logging

# from subprocess import Popen, PIPE, STDOUT, call, run
from subprocess import run
from shlex import join
from textwrap import dedent
from collections import namedtuple

from vce.cli.ctl import std_main
from vce.cli.xargs import get_numa_argparser

import vce.common.util.time as tm
import vce.common.util.file as fu
from vce.common.util.lint import unused

from vce.config.data import cfd

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger(__name__)

# ruff: noqa: PYI024

# //////////////////////////////////////////////////////////////////////////////////////////////////


def parm(job: str, group: str, filename: str):
    return dict(job=job, group=group, filename=filename)


def to_parms(parms):
    result = {}
    for parm in parms:
        result[parm["job"]] = parm
    if parms:
        result["auto"] = parms[0]
    return result


# //////////////////////////////////////////////////////////////////////////////////////////////////

X_SCRIPT = "demo_script.py"

DD_PARMS = to_parms(
    [
        parm("xxxx", "tesla", "Tesla 17 Caratteri Strani 2019 01 30   2018 12 31 .csv"),
    ]
)

# //////////////////////////////////////////////////////////////////////////////////////////////////

X_ARCH = "H16"  # @TODO: arch getenv

MpConf = namedtuple("MpConf", ["enable", "cores", "gpus", "slots"])

X_MP_CONF = dict(
    H8=MpConf(
        enable=False,
        cores=8,
        gpus=0,
        slots=1,
    ),
    H16=MpConf(
        enable=True,
        cores=16,
        gpus=0,
        slots=2,
    ),
    NC6=MpConf(
        enable=False,
        cores=6,
        gpus=1,
        slots=1,
    ),
)


def mp_conf(argv, xargs, name, sub, parm, **kwargs):
    unused(argv, xargs, name, sub, parm, kwargs)
    return X_MP_CONF[X_ARCH]


# //////////////////////////////////////////////////////////////////////////////////////////////////


class Globals:
    proc_num = 0


init_timer = tm.timer()


def new_proc_id():
    Globals.proc_num = Globals.proc_num + 1
    return Globals.proc_num


def to_oneline(command_line):
    return dedent(command_line).replace("\n", " ").replace("; ", ";")


def to_manylines(command_lines):
    return dedent(command_lines)


def run_context(argv, xargs, name, sub, parm, **kwargs):
    conf = mp_conf(argv, xargs, name, sub, parm, **kwargs)
    proc_id = new_proc_id()
    timer = tm.timer()
    prefix = f"//run({proc_id},{init_timer}):"
    ctx = dict(
        sub=sub,
        proc_id=proc_id,
        timer=timer,
        prefix=prefix,
        mp_conf=conf,
        parm=parm,
        name=name,
        xargs=xargs,
        argv=argv,
        extra=kwargs,
    )
    return ctx


def run_proc(ctx, command):
    command_line = command
    msg = f"* {ctx['prefix']} {command_line}"
    log.info(msg)
    rp = run(command_line, shell=True, check=True)
    rc = rp.returncode
    return rc


def run_para_imm(ctx, command):
    # mp_conf = ctx["mp_conf"]
    command_line = f"""\
    (
    :
    ; export X_NUMA_SLOTS="${{X_NUMA_SLOTS:=$(numactl -s | grep ^cpubind | cut -d: -f2)}}"
    ; export X_NUMA_CORES="${{X_NUMA_CORES:=$(lscpu | grep 'Core\\(s\\) per socket:' | cut -d: -f2 | tr -d ' ')}}"
    ; export X_CORE_JOBID="${{X_CORE_JOBID:=$(date -Isec)-$$}}"

    ; echo "### $(date -Isec) - $(date +%s) -- #job:[$X_CORE_JOBID] >>"

    ; env  X_CORE_MODE=1 "{command}"

    ; parallel
       env
        OMP_NUM_THREADS=${{OMP_NUM_THREADS:=$X_NUMA_CORES}}
        GOMP_CPU_AFFINITY={{}}
        X_CORE_SLOT={{}} X_CORE_SLOTS="$(echo $X_NUMA_SLOTS | wc -w)"
        X_CORE_MODE=0

       numactl
          --cpunodebind={{}}
          --membind={{}}

       "{command}"

    ::: $X_NUMA_SLOTS

    ; env  X_CORE_MODE=2 "{command}"

    ; echo "### $(date -Isec) - $(date +%s) -- #job:[$X_CORE_JOBID] <<"
    )
    """
    command_line = to_oneline(command_line)
    msg = f"* {ctx['prefix']} {command_line}"
    log.info(msg)
    rp = run(command_line, shell=True, check=True)
    rc = rp.returncode
    return rc


def run_para(ctx, command):
    # mp_conf = ctx["mp_conf"]
    script_body = f"""\
    #!/bin/sh

    ##
    # run (parallel): {command}
    #

    set -x

    export X_NUMA_SLOTS="${{X_NUMA_SLOTS:=$(numactl -s | grep ^cpubind | cut -d: -f2)}}"
    export X_NUMA_CORES="${{X_NUMA_CORES:=$(lscpu | grep 'Core\\(s\\) per socket:' | cut -d: -f2 | tr -d ' ')}}"
    export X_CORE_JOBID="${{X_CORE_JOBID:=$(date -Isec)-$$}}"

    echo "### $(date -Isec) - $(date +%s) -- #job:[$X_CORE_JOBID] >>"

    env  X_CORE_MODE=1 {command}

    parallel  \
       env \
        OMP_NUM_THREADS=${{OMP_NUM_THREADS:=$X_NUMA_CORES}} \
        GOMP_CPU_AFFINITY={{}} \
        X_CORE_SLOT={{}} X_CORE_SLOTS="$(echo $X_NUMA_SLOTS | wc -w)" \
        X_CORE_MODE=0 \
          \
       numactl \
          --cpunodebind={{}} \
          --membind={{}} \
       \
       '{command}' \
       \
    ::: $X_NUMA_SLOTS

    env  X_CORE_MODE=2 {command}

    echo "### $(date -Isec) - $(date +%s) -- #job:[$X_CORE_JOBID] <<"

    """
    script_body = to_manylines(script_body)
    script_file = fu.write_script(script_body)
    script_out = fu.replace_ext(script_file, ".out")
    script_command = f"/bin/bash -c {script_file} 2>&1 | tee -a {script_out} "
    msg = f"* {ctx['prefix']} {script_command} # {command}"
    log.info(msg)
    rp = run(script_command, shell=True, check=True)
    rc = rp.returncode
    return rc


def run_command(argv, xargs, name, sub, parm, **kwargs):
    ctx = run_context(argv, xargs, name, sub, parm, **kwargs)
    msg = f"> {ctx['prefix']} {sub}"
    log.info(msg)
    if ctx["mp_conf"]:  # .enable
        rc = run_para(ctx, sub)
    else:
        rc = run_proc(ctx, sub)
    msg = f"< {ctx['prefix']}  (rc:{rc},elapsed{ctx['timer']})"
    log.info(msg)
    return rc


# //////////////////////////////////////////////////////////////////////////////////////////////////


def cmd_args(argv, xargs, name, parm, **kwargs):
    unused(argv, xargs, name, kwargs)
    result = [
        "--jobname",
        parm["job"],
        "--group",
        parm["group"],
        "--filename",
        parm["filename"],
    ]
    s = join(result)
    return s


def cmd_script(argv, xargs, name, parm, **kwargs):
    script_line = cmd_args(argv, xargs, name, parm, **kwargs)
    result = f"python {X_SCRIPT} {script_line}"
    return result


def call_command(argv, xargs, name, sub, **kwargs):
    parm = dict()
    run_command(argv, xargs, name, sub, parm, **kwargs)


def call_script(argv, xargs, name, **kwargs):
    parm = DD_PARMS[name]
    sub = cmd_script(argv, xargs, name, parm, **kwargs)
    run_command(argv, xargs, name, sub, parm, **kwargs)


# //////////////////////////////////////////////////////////////////////////////////////////////////


def exec_auto(argv, xargs, name, **kwargs):
    call_script(argv, xargs, name, **kwargs)


def exec_demo_script(argv, xargs, name, **kwargs):
    call_script(argv, xargs, name, **kwargs)


# //////////////////////////////////////////////////////////////////////////////////////////////////


def exec_test_find(argv, xargs, name, **kwargs):
    sub = to_oneline(
        f"""\
        find {cfd().DATA_WORK} -name '*.py' | xargs -l1 -I{{}} basename {{}}
    """
    )
    call_command(argv, xargs, name, sub, **kwargs)


def exec_test_numa(argv, xargs, name, **kwargs):
    test_script = to_oneline(
        """\
        import os;
        import time;
        print({},
           os.getpid(),
           os.getenv(\\"X_CORE_SLOT\\"),
           os.getenv(\\"OMP_NUM_THREADS\\"));
        time.sleep(1);
    """
    )
    sub = f"python -c '{test_script}'"
    call_command(argv, xargs, name, sub, **kwargs)


def exec_test(argv, xargs, name, **kwargs):
    msg = (
        f"#<numa.test>: cmd={'test_numa'}, xargs:<{xargs!s}>, argv:<{argv!s}>, kwargs:<{kwargs!s}>"
    )
    log.info(msg)
    print(msg)
    exec_test_numa(argv, xargs, name, **kwargs)


# //////////////////////////////////////////////////////////////////////////////////////////////////


def parse_args(argv=None, **kwargs):
    parser = get_numa_argparser()
    result = parser.parse_args(argv, **kwargs)
    return result


def exec(argv, xargs, **kwargs):
    """Dispatch execution to target entry point."""

    name = xargs.name
    if name == "_":
        name = "auto"

    if name == "auto":
        RC = exec_auto(argv, xargs, name, **kwargs)
    elif name == "demo_script":
        RC = exec_demo_script(argv, xargs, name, **kwargs)
    elif name == "test":
        RC = exec_test(argv, xargs, name, **kwargs)
    else:
        raise ValueError(f"invalid spec: {name}!")
    return RC


@std_main(log=log, debug=True)
def main(argv=None, **kwargs):
    """Process command line arguments."""
    print(__name__ + "main:" + str(argv))
    log.info(">> ### %s.main(argv=%s)", __name__, str(argv))
    xargs = parse_args(argv, **kwargs)
    RC = exec(argv, xargs, **kwargs)
    log.info("<< ### %s.main => (rc=%d)", __name__, RC)
    return RC


if __name__ == "__main__":
    main(sys.argv[1:])
