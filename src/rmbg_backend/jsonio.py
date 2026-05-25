from __future__ import annotations

import json
from enum import Enum
from pathlib import Path
from typing import Any


def dumps_json(payload: Any) -> str:
    return json.dumps(payload, ensure_ascii=False, sort_keys=True, default=_json_default)


def _json_default(value: object) -> str:
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, Enum):
        return value.value
    raise TypeError(f"Object of type {type(value).__name__} is not JSON serializable")
