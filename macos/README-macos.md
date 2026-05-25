# Rmbg — macOS Frontend

Native macOS app for the BRIA RMBG-2.0 background remover. Communicates with the
Python backend (`rmbg-backend` CLI) via subprocess and JSON.

## Requirements

- macOS 14 Sonoma or newer
- Xcode 15+ (for `swift build`) — or just the Command Line Tools
- The Python backend installed in `../.venv/` (see top-level README)

## Build

```bash
cd macos
./Scripts/build-app.sh           # → build/Debug/Rmbg.app
./Scripts/build-app.sh release   # → build/Release/Rmbg.app
```

## Run

```bash
./Scripts/run.sh                 # build debug, then open
# or, after building:
open build/Debug/Rmbg.app
```

## Open in Xcode (optional)

```bash
xed Package.swift
```

Xcode treats the Swift package as a regular project. SwiftUI previews work
in any file that defines a `#Preview { ... }` block.

## Where the app expects to find the backend

`BackendLocator` tries these paths in order:

1. The path saved in **Settings → Backend → Backend Executable**
2. `RmbgDevRepoRoot/.venv/bin/rmbg-backend` (Info.plist key, default
   `/Users/mhdquan/Documents/rmbg`)
3. `~/Documents/rmbg/.venv/bin/rmbg-backend`
4. The first hit of `which rmbg-backend` on `$PATH`

If none resolve, the sidebar footer shows a red warning. Open **Settings →
Backend** and pick the executable manually.

## Folder layout

| Path | Purpose |
|---|---|
| `Sources/Rmbg/App` | `@main`, root scenes, command menus |
| `Sources/Rmbg/Backend` | Subprocess bridge, JSON decoders, line streaming |
| `Sources/Rmbg/Models` | `ImageJob`, `BackendResult`, `AppSettings`, … |
| `Sources/Rmbg/Stores` | `@Observable` stores injected via `.environment` |
| `Sources/Rmbg/Views` | SwiftUI views grouped by area |
| `Sources/Rmbg/Views/Icons` | 20 custom `Shape` glyphs (Nucleo Micro Bold style) |
| `Sources/Rmbg/Styling` | Typography, spacing, palette, materials, haptics |
| `Sources/Rmbg/Utilities` | Image/URL helpers, hex color, logger |
| `Sources/Rmbg/Resources` | `Info.plist`, `Rmbg.entitlements`, `Assets.xcassets` |

## Notes

- The app is **not sandboxed** in the dev build because it shells out to a
  Python interpreter that lives outside the app bundle and writes to
  user-selected directories. Add the sandbox + relevant entitlements before
  distribution.
- All icons are drawn as SwiftUI `Path` shapes — no SVG, no SF Symbols. See
  `Sources/Rmbg/Views/Icons/`.
