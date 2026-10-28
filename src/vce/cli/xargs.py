import sys
import argparse
from typing import Optional
from abc import ABC, abstractmethod

from vce.common.util.lint import unused


class AppArgsConsts(object):
    ARG_TYPE_GENERIC = "generic"

    ARG_TYPE_MAIN = "main"
    ARG_TYPE_RUNNER = "runner"
    ARG_TYPE_AUTO = "auto"

    ARG_TYPE_TEST = "test"
    ARG_TYPE_DEMO = "demo"

    ARG_TYPE_NUMA = "numa"
    ARG_TYPE_PART = "part"

    ARGS_ENV_AUTO = "X_E_AUTO"


class IAppArgs(ABC):
    # def __init__(self):
    #     pass

    @abstractmethod
    def get_parser(self) -> argparse.ArgumentParser:
        pass

    @abstractmethod
    def parse_args(self, argv=None, **kwargs) -> dict:
        pass

    @abstractmethod
    def get_args(self) -> dict:
        pass


class AppBaseArgs(IAppArgs):
    arg_type = AppArgsConsts.ARG_TYPE_GENERIC

    def __init__(self, parent: Optional[IAppArgs] = None, **kwargs):
        unused(kwargs)
        self.parent = parent
        self.xargs = {}

    def get_args(self) -> dict:
        return self.xargs

    def make_parser(self) -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser(add_help=False, conflict_handler="resolve")
        return parser

    def base_parser(self) -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser(add_help=False, conflict_handler="resolve")

        parser.add_argument(
            "--verbose",
            "-v",
            action="count",
            default=0,
            help="increase output verbosity",
        )
        return parser

    def handle_unknown(self, xargs, unknown, **kwargs) -> dict:
        """Runner Script Argument Parser."""
        unused(unknown, kwargs)
        return xargs

    def parse_args(self, argv=None, **kwargs) -> dict:
        """Process command line arguments."""
        unused(kwargs)
        if not argv:
            argv = sys.argv[1:]

        parser = self.get_parser()
        xargs, unknown = parser.parse_known_args(argv)
        result = self.handle_unknown(xargs=xargs, unknown=unknown)
        self.xargs = result
        return result


class AppMainArgs(AppBaseArgs):
    arg_type = AppArgsConsts.ARG_TYPE_MAIN

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def base_parser(self) -> argparse.ArgumentParser:
        return super().base_parser()

    def main_parser(self) -> argparse.ArgumentParser:
        parent = self.base_parser()
        parser = argparse.ArgumentParser(parents=[parent], conflict_handler="resolve")
        parser.add_argument("--exec", "-e", type=str, help="command to dispatch", default="_")
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.main_parser()


def get_main_argparser(*args, **kwargs) -> AppMainArgs:
    result = AppMainArgs(*args, **kwargs)
    return result


class AppRunnerArgs(AppBaseArgs):
    arg_type = AppArgsConsts.ARG_TYPE_RUNNER

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def base_parser(self) -> argparse.ArgumentParser:
        return super().base_parser()

    def runner_parser(self) -> argparse.ArgumentParser:
        """Runner Script Argument Parser."""
        parser = self.base_parser()
        parser.add_argument("--cmd", "-c", type=str, help="script to execute", default="_")
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.runner_parser()


def get_runner_argparser(*args, **kwargs) -> AppRunnerArgs:
    result = AppRunnerArgs(*args, **kwargs)
    return result


class AppAutoArgs(AppRunnerArgs):
    arg_type = AppArgsConsts.ARG_TYPE_AUTO

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def auto_parser(self) -> argparse.ArgumentParser:
        """Auto Script Argument Parser."""
        parser = self.runner_parser()
        parser.add_argument("--name", "-n", type=str, help="job params entry key", default="_")
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.auto_parser()


def get_auto_argparser(*args, **kwargs) -> AppAutoArgs:
    result = AppAutoArgs(*args, **kwargs)
    return result


class AppTestArgs(AppAutoArgs):
    arg_type = AppArgsConsts.ARG_TYPE_TEST

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def test_parser(self) -> argparse.ArgumentParser:
        parser = self.auto_parser()
        parser.add_argument("--demo-arg-1", "-1", type=str, help="demo script arg 1", default="A")
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.test_parser()


def get_test_argparser(*args, **kwargs) -> AppTestArgs:
    result = AppTestArgs(*args, **kwargs)
    return result


class AppDemoArgs(AppAutoArgs):
    arg_type = AppArgsConsts.ARG_TYPE_DEMO

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def demo_parser(self) -> argparse.ArgumentParser:
        parser = self.auto_parser()
        parser.add_argument("--demo-arg-1", "-1", type=str, help="demo script arg 1", default="A")
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.demo_parser()


def get_demo_argparser(*args, **kwargs) -> AppDemoArgs:
    result = AppDemoArgs(*args, **kwargs)
    return result


# ///[ NUMA ]///////////////////////////////////////////////////


class AppNumaArgs(AppAutoArgs):
    arg_type = AppArgsConsts.ARG_TYPE_NUMA

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def numa_parser(self) -> argparse.ArgumentParser:
        """Auto Script Argument Parser."""
        parser = self.auto_parser()
        parser.add_argument("--numa-enable", "-r", type=str, help="enable numa execution", default="0")
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.auto_parser()


def get_numa_argparser(*args, **kwargs) -> AppNumaArgs:
    result = AppNumaArgs(*args, **kwargs)
    return result


class AppPartArgs(AppNumaArgs):
    arg_type = AppArgsConsts.ARG_TYPE_PART

    def __init__(self, parent=None, **kwargs):
        super().__init__(parent=parent, **kwargs)

    def part_parser(self) -> argparse.ArgumentParser:
        parser = self.numa_parser()
        parser.add_argument(
            "--part-arg-1",
            "-1",
            type=str,
            help="demo part (numa) script arg 1",
            default="X",
        )
        return parser

    def get_parser(self) -> argparse.ArgumentParser:
        return self.part_parser()


def get_part_argparser(*args, **kwargs) -> AppPartArgs:
    result = AppPartArgs(*args, **kwargs)
    return result
