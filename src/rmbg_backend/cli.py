from __future__ import annotations

from pathlib import Path
from typing import Annotated

import typer

from rmbg_backend.auth import get_auth_status
from rmbg_backend.device import DevicePreference, resolve_device
from rmbg_backend.jsonio import dumps_json
from rmbg_backend.schemas import OutputFormat

app = typer.Typer(help="Local backend worker for RMBG-2.0 background removal.")
auth_app = typer.Typer(help="Hugging Face authentication helpers.")
app.add_typer(auth_app, name="auth")


DeviceArg = Annotated[
    DevicePreference,
    typer.Option(
        "--device",
        case_sensitive=False,
        help="Inference device. On Intel macOS, auto normally falls back to CPU unless MPS is available.",
    ),
]


@auth_app.command("status")
def auth_status(
    json_output: Annotated[bool, typer.Option("--json")] = False,
    hf_home: Annotated[Path | None, typer.Option("--hf-home")] = None,
) -> None:
    status = get_auth_status(hf_home=hf_home)
    if json_output:
        typer.echo(
            dumps_json(
                {
                    "authenticated": status.authenticated,
                    "username": status.username,
                    "message": status.message,
                }
            )
        )
    else:
        typer.echo(status.message)
        if status.username:
            typer.echo(f"User: {status.username}")
    raise typer.Exit(code=0 if status.authenticated else 1)


@app.command()
def devices(json_output: Annotated[bool, typer.Option("--json")] = False) -> None:
    selected = resolve_device(DevicePreference.AUTO)
    if json_output:
        typer.echo(dumps_json({"auto": selected}))
    else:
        typer.echo(f"auto: {selected}")


@app.command()
def doctor(
    json_output: Annotated[bool, typer.Option("--json")] = False,
    hf_home: Annotated[Path | None, typer.Option("--hf-home")] = None,
) -> None:
    from rmbg_backend.preflight import run_preflight

    report = run_preflight(hf_home=hf_home)
    if json_output:
        typer.echo(dumps_json(report.to_dict()))
    else:
        typer.echo(f"Python: {report.python}")
        typer.echo(f"Platform: {report.platform}")
        typer.echo(f"Auto device: {report.auto_device}")
        for check in report.checks:
            typer.echo(f"{check.status.upper()} {check.name}: {check.message}")
    raise typer.Exit(code=0 if report.ok else 1)


@app.command()
def warmup(
    device: DeviceArg = DevicePreference.AUTO,
    cache_dir: Annotated[Path | None, typer.Option("--cache-dir")] = None,
    hf_home: Annotated[Path | None, typer.Option("--hf-home")] = None,
    json_output: Annotated[bool, typer.Option("--json")] = False,
) -> None:
    from rmbg_backend.config import BackendConfig
    from rmbg_backend.engine import RmbgEngine

    engine = RmbgEngine(BackendConfig(cache_dir=cache_dir, hf_home=hf_home), device=device)
    if not json_output:
        typer.echo(f"Loading {engine.config.model_id} on {engine.device}...")
    engine.warmup()
    if json_output:
        typer.echo(
            dumps_json(
                {
                    "type": "warmup",
                    "model_id": engine.config.model_id,
                    "device": engine.device,
                    "loaded": engine.is_loaded,
                }
            )
        )
    else:
        typer.echo("Model loaded.")


@app.command()
def single(
    input_path: Annotated[Path, typer.Argument(exists=True, readable=True)],
    output_dir: Annotated[Path | None, typer.Option("--output-dir", "-o")] = None,
    suffix: Annotated[str, typer.Option("--suffix")] = "_rmbg",
    device: DeviceArg = DevicePreference.AUTO,
    cache_dir: Annotated[Path | None, typer.Option("--cache-dir")] = None,
    hf_home: Annotated[Path | None, typer.Option("--hf-home")] = None,
    output_format: Annotated[
        OutputFormat,
        typer.Option("--format", case_sensitive=False, help="Output image format."),
    ] = OutputFormat.PNG,
    background_color: Annotated[
        str | None,
        typer.Option("--background-color", help="Hex color used to flatten non-alpha outputs."),
    ] = None,
    overwrite: Annotated[bool, typer.Option("--overwrite")] = False,
    save_alpha_mask: Annotated[bool, typer.Option("--save-alpha-mask")] = False,
    save_preview: Annotated[bool, typer.Option("--save-preview")] = False,
    preview_background: Annotated[str, typer.Option("--preview-background")] = "#f2f2f7",
    json_output: Annotated[bool, typer.Option("--json")] = False,
) -> None:
    from rmbg_backend.config import BackendConfig
    from rmbg_backend.engine import RmbgEngine
    from rmbg_backend.processor import ImageProcessor
    from rmbg_backend.schemas import ProcessingOptions

    engine = RmbgEngine(BackendConfig(cache_dir=cache_dir, hf_home=hf_home), device=device)
    processor = ImageProcessor(engine)
    result = processor.process_file(
        input_path,
        ProcessingOptions(
            output_dir=output_dir,
            suffix=suffix,
            output_format=output_format,
            background_color=background_color,
            overwrite=overwrite,
            save_alpha_mask=save_alpha_mask,
            save_preview=save_preview,
            preview_background=preview_background,
        ),
    )
    if json_output:
        typer.echo(dumps_json({"type": "single", "result": result.to_dict()}))
    else:
        typer.echo(str(result.output_path))
        if result.alpha_mask_path:
            typer.echo(str(result.alpha_mask_path))
        if result.preview_path:
            typer.echo(str(result.preview_path))


@app.command()
def batch(
    inputs: Annotated[list[Path], typer.Argument(exists=True, readable=True)],
    output_dir: Annotated[Path, typer.Option("--output-dir", "-o", file_okay=False)],
    suffix: Annotated[str, typer.Option("--suffix")] = "_rmbg",
    device: DeviceArg = DevicePreference.AUTO,
    cache_dir: Annotated[Path | None, typer.Option("--cache-dir")] = None,
    hf_home: Annotated[Path | None, typer.Option("--hf-home")] = None,
    output_format: Annotated[
        OutputFormat,
        typer.Option("--format", case_sensitive=False, help="Output image format."),
    ] = OutputFormat.PNG,
    background_color: Annotated[
        str | None,
        typer.Option("--background-color", help="Hex color used to flatten non-alpha outputs."),
    ] = None,
    recursive: Annotated[bool, typer.Option("--recursive", "-r")] = False,
    overwrite: Annotated[bool, typer.Option("--overwrite")] = False,
    save_alpha_mask: Annotated[bool, typer.Option("--save-alpha-mask")] = False,
    save_preview: Annotated[bool, typer.Option("--save-preview")] = False,
    preview_background: Annotated[str, typer.Option("--preview-background")] = "#f2f2f7",
    json_output: Annotated[
        bool,
        typer.Option("--json", help="Emit only the final summary as JSON."),
    ] = False,
    json_lines: Annotated[
        bool,
        typer.Option("--json-lines", help="Emit progress and final summary as JSON Lines."),
    ] = False,
) -> None:
    from rmbg_backend.batch import BatchOptions, BatchProcessor
    from rmbg_backend.config import BackendConfig
    from rmbg_backend.engine import RmbgEngine
    from rmbg_backend.processor import ImageProcessor

    engine = RmbgEngine(BackendConfig(cache_dir=cache_dir, hf_home=hf_home), device=device)
    processor = ImageProcessor(engine)
    batch_processor = BatchProcessor(processor)

    def progress(done: int, total: int, _item: object | None) -> None:
        if json_lines:
            item_payload = _item.to_dict() if _item is not None else None
            typer.echo(
                dumps_json(
                    {
                        "type": "progress",
                        "done": done,
                        "total": total,
                        "item": item_payload,
                    }
                )
            )
        elif not json_output:
            typer.echo(f"{done}/{total}", err=True)

    results, duration = batch_processor.process_paths_with_timing(
        inputs,
        BatchOptions(
            output_dir=output_dir,
            suffix=suffix,
            output_format=output_format,
            background_color=background_color,
            recursive=recursive,
            overwrite=overwrite,
            save_alpha_mask=save_alpha_mask,
            save_preview=save_preview,
            preview_background=preview_background,
        ),
        on_progress=progress,
    )

    failures = [item for item in results if item.error is not None]
    summary = {
        "type": "summary",
        "processed": len(results) - len(failures),
        "total": len(results),
        "failed": len(failures),
        "duration_seconds": duration,
        "results": [item.to_dict() for item in results],
    }
    if json_output or json_lines:
        typer.echo(dumps_json(summary))
    else:
        typer.echo(f"Processed {len(results) - len(failures)}/{len(results)} in {duration:.2f}s")
        for failure in failures:
            typer.echo(f"FAILED {failure.input_path}: {failure.error}", err=True)
    raise typer.Exit(code=1 if failures else 0)


if __name__ == "__main__":
    app()
