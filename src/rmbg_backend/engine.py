from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

from PIL import Image

from rmbg_backend.config import BackendConfig, ensure_hf_home
from rmbg_backend.device import DevicePreference, resolve_device

if TYPE_CHECKING:
    import torch


class RmbgEngine:
    """Lazy RMBG-2.0 inference wrapper.

    The model is loaded only on the first call to keep app startup fast. The
    GUI can instantiate this backend early, then warm it when the user starts a
    job or explicitly asks to preload the model.
    """

    def __init__(
        self,
        config: BackendConfig | None = None,
        device: DevicePreference | str = DevicePreference.AUTO,
    ) -> None:
        self.config = config or BackendConfig()
        self.device = resolve_device(device)
        self._model = None
        self._transform = None
        self._torch: torch | None = None

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def warmup(self) -> None:
        self._load()

    def predict_alpha(self, image: Image.Image) -> Image.Image:
        self._load()
        assert self._model is not None
        assert self._transform is not None
        assert self._torch is not None

        input_tensor = self._transform(image.convert("RGB")).unsqueeze(0).to(self.device)

        with self._torch.inference_mode():
            prediction = self._model(input_tensor)[-1].sigmoid().cpu()

        alpha = prediction[0].squeeze()
        alpha_image = self._to_pil_image(alpha)
        return alpha_image.resize(image.size, Image.Resampling.LANCZOS)

    def _load(self) -> None:
        if self._model is not None:
            return

        ensure_hf_home(self.config.hf_home)

        import torch
        from torchvision import transforms
        from transformers import AutoModelForImageSegmentation

        kwargs = {"trust_remote_code": True}
        if self.config.cache_dir is not None:
            kwargs["cache_dir"] = str(Path(self.config.cache_dir).expanduser())

        model = AutoModelForImageSegmentation.from_pretrained(self.config.model_id, **kwargs)
        model.eval().to(self.device)

        image_size = (self.config.image_size, self.config.image_size)
        transform = transforms.Compose(
            [
                transforms.Resize(image_size),
                transforms.ToTensor(),
                transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
            ]
        )

        self._torch = torch
        self._model = model
        self._transform = transform

    @staticmethod
    def _to_pil_image(tensor: object) -> Image.Image:
        from torchvision import transforms

        return transforms.ToPILImage()(tensor)
