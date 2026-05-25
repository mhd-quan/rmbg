from __future__ import annotations

import importlib.util
import platform
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from rmbg_backend.auth import get_auth_status
from rmbg_backend.config import DEFAULT_MODEL_ID
from rmbg_backend.device import DevicePreference, resolve_device


@dataclass(frozen=True)
class CheckResult:
    name: str
    status: str
    message: str
    details: dict[str, Any] | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "status": self.status,
            "message": self.message,
            "details": self.details or {},
        }


@dataclass(frozen=True)
class PreflightReport:
    ok: bool
    checks: list[CheckResult]
    python: str
    platform: str
    machine: str
    executable: str
    model_id: str
    auto_device: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "ok": self.ok,
            "checks": [check.to_dict() for check in self.checks],
            "python": self.python,
            "platform": self.platform,
            "machine": self.machine,
            "executable": self.executable,
            "model_id": self.model_id,
            "auto_device": self.auto_device,
        }


def run_preflight(model_id: str = DEFAULT_MODEL_ID, hf_home: Path | None = None) -> PreflightReport:
    checks = [
        _python_check(),
        _package_check("pillow", "PIL"),
        _package_check("pillow-heif", "pillow_heif", optional=True),
        _package_check("torch", "torch"),
        _package_check("torchvision", "torchvision"),
        _package_check("transformers", "transformers"),
        _package_check("huggingface-hub", "huggingface_hub"),
        _package_check("typer", "typer"),
        _auth_check(hf_home),
    ]
    auto_device = _resolve_auto_device()
    checks.append(
        CheckResult(
            name="device",
            status="ok",
            message=f"Auto device resolves to {auto_device}.",
            details={"auto": auto_device},
        )
    )

    ok = all(check.status != "error" for check in checks)
    return PreflightReport(
        ok=ok,
        checks=checks,
        python=platform.python_version(),
        platform=platform.platform(),
        machine=platform.machine(),
        executable=sys.executable,
        model_id=model_id,
        auto_device=auto_device,
    )


def _python_check() -> CheckResult:
    version = sys.version_info
    if version >= (3, 10):
        return CheckResult(
            name="python",
            status="ok",
            message=f"Python {platform.python_version()} is supported.",
        )
    return CheckResult(
        name="python",
        status="error",
        message="Python 3.10 or newer is required.",
    )


def _package_check(package_name: str, import_name: str, optional: bool = False) -> CheckResult:
    found = importlib.util.find_spec(import_name) is not None
    if found:
        return CheckResult(
            name=package_name,
            status="ok",
            message=f"{package_name} is installed.",
        )
    return CheckResult(
        name=package_name,
        status="warning" if optional else "error",
        message=(
            f"{package_name} is not installed."
            if not optional
            else f"{package_name} is not installed; HEIC/HEIF input may not open."
        ),
    )


def _auth_check(hf_home: Path | None) -> CheckResult:
    status = get_auth_status(hf_home=hf_home)
    return CheckResult(
        name="huggingface-auth",
        status="ok" if status.authenticated else "error",
        message=status.message,
        details={"username": status.username},
    )


def _resolve_auto_device() -> str:
    try:
        return resolve_device(DevicePreference.AUTO)
    except Exception as exc:  # noqa: BLE001 - diagnostics should report instead of crashing.
        return f"unavailable: {exc}"
