from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from rmbg_backend.config import ensure_hf_home


@dataclass(frozen=True)
class AuthStatus:
    authenticated: bool
    username: str | None
    message: str


def get_auth_status(hf_home: Path | None = None) -> AuthStatus:
    ensure_hf_home(hf_home)
    try:
        from huggingface_hub import HfFolder, whoami
    except ImportError:
        return AuthStatus(
            authenticated=False,
            username=None,
            message="huggingface-hub is not installed.",
        )

    token = HfFolder.get_token()
    if not token:
        return AuthStatus(
            authenticated=False,
            username=None,
            message="No Hugging Face token found. Run: huggingface-cli login",
        )

    try:
        info = whoami(token=token)
    except Exception as exc:  # noqa: BLE001 - auth failures vary by hub version.
        return AuthStatus(authenticated=False, username=None, message=str(exc))

    username = info.get("name") or info.get("fullname")
    return AuthStatus(authenticated=True, username=username, message="Authenticated")
