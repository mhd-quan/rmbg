# rmbg

Local-first background removal app, starting with a Python backend worker for
BRIA RMBG-2.0. The GUI will be built later as a macOS-focused interface.

## Backend scope

- Load `briaai/RMBG-2.0` lazily through Hugging Face Transformers.
- Process one image into a transparent PNG.
- Process folders/files in batch and continue when one item fails.
- Preserve the original image size and EXIF orientation.
- Support alpha-mask export for preview/debug workflows.
- Select `auto`, `cpu`, `mps`, or `cuda` as the inference device.
- Emit JSON or JSON Lines so a native GUI can track jobs without scraping text.

On an Intel Mac with Radeon graphics, expect CPU to be the reliable baseline.
If the installed PyTorch build exposes MPS, `--device auto` will use it. A later
backend can add ONNX/CoreML as a separate engine for better Apple GPU coverage.

## Setup

Use Python 3.12 for the ML stack:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
```

Log in to Hugging Face after your account has been granted access to the model:

```bash
HF_HOME=.hf_home hf auth login
rmbg-backend auth status
```

The app automatically uses `.hf_home` in this workspace when it exists, and that
directory is ignored by git. You can override it with `RMBG_HF_HOME` or
`--hf-home`. The first inference run downloads the model weights into the
Hugging Face cache. You can pass `--cache-dir models/huggingface` if you want
the model cache inside this workspace too.

## CLI usage

Check device selection:

```bash
rmbg-backend devices
```

Run environment diagnostics:

```bash
rmbg-backend doctor --json
```

Warm the model:

```bash
rmbg-backend warmup --device auto
```

Process a single image:

```bash
rmbg-backend single ~/Desktop/input.jpg --output-dir outputs --save-alpha-mask
```

Process a single image and return a machine-readable payload:

```bash
rmbg-backend single ~/Desktop/input.jpg --output-dir outputs --save-preview --json
```

Process a folder:

```bash
rmbg-backend batch ~/Desktop/photos --output-dir outputs --recursive
```

Process a folder with progress events for a GUI:

```bash
rmbg-backend batch ~/Desktop/photos --output-dir outputs --recursive --json-lines
```

All processed images are emitted as PNG files with alpha transparency.

To export a flattened JPEG, provide a background color:

```bash
rmbg-backend single ~/Desktop/input.jpg --output-dir outputs --format jpeg --background-color '#ffffff'
```

Supported output formats are `png`, `jpeg`, `webp`, and `tiff`. Formats that
cannot store alpha, such as JPEG, require `--background-color`.

## GUI worker contract

The future SwiftUI app can run the backend as a child process. For a single
image, `--json` emits one JSON object:

```json
{
  "result": {
    "alpha_mask_path": null,
    "duration_seconds": 1.23,
    "height": 3024,
    "input_path": "/path/input.jpg",
    "output_path": "/path/input_rmbg.png",
    "preview_path": "/path/input_rmbg_preview.jpg",
    "width": 4032
  },
  "type": "single"
}
```

For batch jobs, `--json-lines` emits progress events followed by a final summary.
Each line is independent JSON. This example trims the nested result object:

```json
{"done":1,"item":{"error":null,"input_path":"/path/a.jpg","result":{"output_path":"/path/a_rmbg.png"}},"total":12,"type":"progress"}
{"duration_seconds":19.4,"failed":0,"processed":12,"results":[],"total":12,"type":"summary"}
```

## Backend API

The GUI can call the backend classes directly when embedded in a Python process,
or shell out to the CLI from a native SwiftUI app:

```python
from pathlib import Path

from rmbg_backend import ImageProcessor, ProcessingOptions, RmbgEngine

engine = RmbgEngine(device="auto")
processor = ImageProcessor(engine)
result = processor.process_file(
    Path("input.jpg"),
    ProcessingOptions(output_dir=Path("outputs")),
)
print(result.output_path)
```

## Notes

RMBG-2.0 is available for non-commercial use under its model license. Keep the
app private unless a separate commercial agreement is in place.
