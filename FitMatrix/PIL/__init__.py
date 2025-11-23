from importlib import import_module
from types import ModuleType

__all__ = ["Image", "ImageOps"]


def __getattr__(name: str) -> ModuleType:
    if name in __all__:
        module = import_module(f"PIL.{name}")
        globals()[name] = module
        return module
    raise AttributeError(name)
