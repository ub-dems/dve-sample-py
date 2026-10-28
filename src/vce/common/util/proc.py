import logging

from subprocess import run
from textwrap import dedent

import vce.common.util.time as tm
from vce.common.util.lint import unused

log = logging.getLogger(__name__)


def to_oneline(command_line):
    return dedent(command_line).replace("\n", " ").replace("; ", ";")


def to_manylines(command_lines):
    return dedent(command_lines)


class ProcGlobals:
    proc_num = 0


init_timer = tm.timer()


def new_proc_id():
    ProcGlobals.proc_num = ProcGlobals.proc_num + 1
    return ProcGlobals.proc_num


def run_context(command, script=None, name=None, parms=None, xargs=None, argv=None, *args, **kwargs):
    unused(kwargs)
    conf = None
    proc_id = new_proc_id()
    timer = tm.timer()
    prefix = f"//run({proc_id},{init_timer}):"
    ctx = {
        "command": command,
        "script": script,
        "proc_id": proc_id,
        "timer": timer,
        "prefix": prefix,
        "mp_conf": conf,
        "parms": parms,
        "name": name,
        "xargs": xargs,
        "args": args,
        "argv": argv,
    }
    return ctx


def run_command(command, script=None, name=None, parms=None, xargs=None, argv=None, *args, **kwargs):
    ctx = run_context(command, script, name, parms, xargs, argv, *args, **kwargs)
    msg = f"> {ctx['prefix']} {command}"
    log.info(msg)

    # TODO: multi-process config <c:NUMA>

    # if ctx["mp_conf"].enable:
    #     rc = run_para(ctx, command)
    # else:
    #     rc = run_proc(ctx, command)

    rc = run_proc(ctx, command)

    msg = f"< {ctx['prefix']}  (rc:{rc},elapsed{ctx['timer']})"
    log.info(msg)
    return rc


def run_proc(ctx, command):
    command_line = command
    msg = f"* {ctx['prefix']} {command_line}"
    log.info(msg)
    rp = run(command_line, shell=True, check=True)
    rc = rp.returncode
    return rc


def cmd_args(script=None, name=None, parms=None, xargs=None, argv=None, *args, **kwargs):
    unused(script, name, parms, xargs, args, kwargs)
    # result = [
    #     "--jobname",
    #     parms["job"],
    #     "--group",
    #     parms["group"],
    #     "--filename",
    #     parms["filename"],
    # ]
    # s = join(result)

    s_argv = " ".join(argv) if argv else ""
    s = f"{s_argv}"
    return s


def cmd_script(script=None, name=None, parms=None, xargs=None, argv=None, *args, **kwargs):
    result = f"python {script} {cmd_args(script, name, parms, xargs, argv, *args, **kwargs)}"
    return result


def call_command(command, name, xargs, argv=None, **kwargs):
    unused(kwargs)
    parms = {}
    run_command(command, parms, name, xargs, argv)


def call_script(script=None, name=None, xargs=None, argv=None, *args, **kwargs):
    # TODO: spawn process parms <c:NUMA c:PARMS>
    # parm = DD_PARMS[name]
    parms = {}
    command = cmd_script(script, name, parms, xargs, argv, *args, **kwargs)
    rc = run_command(command, script, name, parms, xargs, argv, *args, **kwargs)
    return rc
