"""Backend primitives for local RMBG-2.0 background removal."""

__all__ = [
    "BatchItemResult",
    "BatchOptions",
    "BatchProcessor",
    "DevicePreference",
    "ImageProcessor",
    "OutputFormat",
    "ProcessingOptions",
    "ProcessingResult",
    "RmbgEngine",
]


def __getattr__(name: str) -> object:
    if name in {"BatchItemResult", "BatchOptions", "BatchProcessor"}:
        from rmbg_backend import batch

        return getattr(batch, name)
    if name == "DevicePreference":
        from rmbg_backend.device import DevicePreference

        return DevicePreference
    if name == "RmbgEngine":
        from rmbg_backend.engine import RmbgEngine

        return RmbgEngine
    if name == "ImageProcessor":
        from rmbg_backend.processor import ImageProcessor

        return ImageProcessor
    if name in {"OutputFormat", "ProcessingOptions", "ProcessingResult"}:
        from rmbg_backend.schemas import OutputFormat, ProcessingOptions, ProcessingResult

        return {
            "OutputFormat": OutputFormat,
            "ProcessingOptions": ProcessingOptions,
            "ProcessingResult": ProcessingResult,
        }[name]
    raise AttributeError(name)
