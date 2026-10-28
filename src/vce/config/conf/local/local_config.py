import os
from pathlib import Path
from typing import Any, Self, cast
import toml

from vce.config.conf.base import BaseConfig, BaseConfigConsts
from vce.config.conf.base.base_config import BaseConfigImpl, BaseConfigStore
from vce.config.conf.local import LocalConfigConsts, ProjectConfig, get_local_config
from vce.common.util.file import find_file_upwards
from vce.common.util.format import dump_object


class ProjectConfigImpl(BaseConfigImpl, ProjectConfig):
    @classmethod
    def create(cls, section: str = LocalConfigConsts.CONFIG_L_SECTION_NAME) -> Self:
        try:
            result = cls(section=section)
            result.setup()
            return result
        except Exception as ex:
            print(type(ex))
            print(ex.args)
            print(ex)
            raise ex

    def __init__(self, section: str = LocalConfigConsts.CONFIG_L_SECTION_NAME):
        self._section = section
        self._base_path = None
        self._project_path = None
        self._config_path = None
        self._local = {}

    def setup(self) -> Self:
        self._project_path = find_file_upwards(LocalConfigConsts.CONFIG_L_PROJECT_FILE)
        if not self.has_project:
            return self

        assert self._project_path is not None
        self._base_path = self._project_path.parent
        self._local = self.load_local_config()
        if not self.is_config_defined:
            return self

        self._config_path = self.resolve_config_path()
        return self

    def load_local_config(self) -> dict[str, Any]:
        """Load configuration from pyproject.toml.

        Returns:
        Configuration dictionary with tool.local settings
        """
        try:
            pyproject_path = self.project_path

            data = toml.load(pyproject_path)
            tools = data.get(LocalConfigConsts.CONFIG_L_SECTION_PARENT, {})
            section = tools.get(LocalConfigConsts.CONFIG_L_SECTION_NAME, {})
            result = cast("dict[str, Any]", section)
            return result
        except Exception as ex:
            print(type(ex))
            print(ex.args)
            print(ex)
            raise ex

    def resolve_config_path(self) -> Path:
        """Find config.yaml from current dir and parents,
           in not found try path relative to pyproject.toml

        Returns:
        Path of resolved config
        """
        try:
            config_filename = self.get_value(
                LocalConfigConsts.CONFIG_L_KEY_CONFIG, LocalConfigConsts.CONFIG_L_DEF_CONFIG
            )
            config_path = find_file_upwards(config_filename)

            if config_path is None:
                config_path = find_file_upwards(config_filename, self.base_path)

            if config_path is None:
                msg = f"config file not found: {config_filename} in dir: {Path.cwd()}"
                raise ValueError(msg)

            if not config_path.exists():
                msg = f"config file not found: {config_filename} in dir: {Path.cwd()}"
                raise ValueError(msg)

            return config_path

        except Exception as ex:
            print(type(ex))
            print(ex.args)
            print(ex)
            raise ex

    @property
    def section(self) -> str:
        return self._section

    @property
    def base_path(self) -> Path:
        if self._base_path is None:
            raise ValueError("base_path is None")
        return self._base_path

    @property
    def project_path(self) -> Path:
        if self._project_path is None:
            raise ValueError("project_path is None")
        return self._project_path

    @property
    def config_path(self) -> Path:
        if self._config_path is None:
            raise ValueError("config_path is None")
        return self._config_path

    @property
    def has_project(self) -> bool:
        return self._project_path is not None and self._project_path.exists()

    @property
    def has_config(self) -> bool:
        return self._config_path is not None and self._config_path.exists()

    @property
    def is_config_defined(self) -> bool:
        return self.local.get(LocalConfigConsts.CONFIG_L_KEY_HAS_CONFIG, LocalConfigConsts.CONFIG_L_DEF_HAS_CONFIG)

    @property
    def local(self) -> dict[str, Any]:
        return self._local

    def get_value(self, key: str, default_value: Any = None) -> Any:
        env_key = LocalConfigConsts.CONFIG_L_ENV_PREFIX + key.upper()
        env_value = os.getenv(env_key)
        if env_value:
            return env_value
        result = self._local.get(key, default_value)
        return result

    def has_value(self, key: str) -> bool:
        try:
            self.get_value(key)
            return True
        except ValueError:
            return False

    def dump(self, full: bool = False) -> str:
        result = dump_object(self)
        return result


class ProjectConfigStore(object):
    def __init__(self):
        self._local = {}

    def get_local(self, section: str = LocalConfigConsts.CONFIG_L_SECTION_NAME) -> ProjectConfig:
        result = self._local.get(section)
        if result:
            return result
        result = ProjectConfigImpl.create(section)
        self._local[section] = result
        return result


class ProjectConfigStoreGlobals(object):
    store = ProjectConfigStore()


class LocalConfigStore[T: BaseConfig](BaseConfigStore[T]):
    def __init__(self, config_class: type[BaseConfig]):
        self._config_class = config_class
        self._config = {}

    def is_config_defined(self, what=BaseConfigConsts.CONFIG_S_DEFAULT) -> bool:
        loc: ProjectConfig = get_local_config()
        if what == BaseConfigConsts.CONFIG_S_MAIN:
            result = loc.is_config_defined
        else:
            result = False
        return result

    def config_name(self, what=BaseConfigConsts.CONFIG_S_DEFAULT) -> str:
        loc: ProjectConfig = get_local_config()

        result = None
        if what == BaseConfigConsts.CONFIG_S_MAIN:
            result = loc.config_path.name
        if result is None:
            raise ValueError(f'Config Name unknown: "{what}", cannot load')
        return result

    def config_path(self, what=BaseConfigConsts.CONFIG_S_DEFAULT) -> str:
        loc: ProjectConfig = get_local_config()

        result = None
        if what == BaseConfigConsts.CONFIG_S_MAIN:
            result = loc.config_path.as_posix()
        if result is None:
            raise ValueError(f'Config Path unknown: "{what}", cannot load')
        return result
