from __future__ import annotations

from enum import Enum


class DevicePreference(str, Enum):
    AUTO = "auto"
    CPU = "cpu"
    MPS = "mps"
    CUDA = "cuda"


def resolve_device(preference: DevicePreference | str = DevicePreference.AUTO) -> str:
    pref = DevicePreference(preference)
    if pref == DevicePreference.CPU:
        return "cpu"

    try:
        import torch
    except ImportError as exc:
        if pref == DevicePreference.AUTO:
            return "cpu"
        raise RuntimeError("PyTorch is required for non-CPU device probing.") from exc

    if pref == DevicePreference.CUDA:
        if torch.cuda.is_available():
            return "cuda"
        raise RuntimeError("CUDA was requested, but torch.cuda.is_available() is false.")

    if pref == DevicePreference.MPS:
        if _mps_available(torch):
            return "mps"
        raise RuntimeError("MPS was requested, but it is not available in this PyTorch install.")

    if torch.cuda.is_available():
        return "cuda"
    if _mps_available(torch):
        return "mps"
    return "cpu"


def _mps_available(torch_module: object) -> bool:
    backends = getattr(torch_module, "backends", None)
    mps = getattr(backends, "mps", None)
    if mps is None:
        return False
    is_built = getattr(mps, "is_built", lambda: False)
    is_available = getattr(mps, "is_available", lambda: False)
    return bool(is_built() and is_available())
