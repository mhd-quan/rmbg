import Foundation

/// Builds CLI argument vectors for each backend subcommand. Centralized so
/// the argv shape stays in sync with `src/rmbg_backend/cli.py`.
enum BackendCommand {
    static func authStatus() -> [String] {
        ["auth", "status", "--json"]
    }

    static func devices() -> [String] {
        ["devices", "--json"]
    }

    static func doctor() -> [String] {
        ["doctor", "--json"]
    }

    static func warmup(device: DevicePreference) -> [String] {
        ["warmup", "--device", device.rawValue, "--json"]
    }

    static func single(input: URL, options: ExportRequest) -> [String] {
        var args = ["single", input.path,
                    "--output-dir", options.outputDirectory.path,
                    "--suffix", options.suffix,
                    "--device", options.device.rawValue,
                    "--format", options.outputFormat.rawValue,
                    "--preview-background", options.previewBackground,
                    "--json"]
        if let bg = options.backgroundColor {
            args.append(contentsOf: ["--background-color", bg])
        }
        if options.overwrite { args.append("--overwrite") }
        if options.saveAlphaMask { args.append("--save-alpha-mask") }
        if options.savePreview { args.append("--save-preview") }
        return args
    }

    static func batch(inputs: [URL], options: ExportRequest) -> [String] {
        var args = ["batch"]
        args.append(contentsOf: inputs.map(\.path))
        args.append(contentsOf: [
            "--output-dir", options.outputDirectory.path,
            "--suffix", options.suffix,
            "--device", options.device.rawValue,
            "--format", options.outputFormat.rawValue,
            "--preview-background", options.previewBackground,
            "--json-lines",
        ])
        if let bg = options.backgroundColor {
            args.append(contentsOf: ["--background-color", bg])
        }
        if options.recursive { args.append("--recursive") }
        if options.overwrite { args.append("--overwrite") }
        if options.saveAlphaMask { args.append("--save-alpha-mask") }
        if options.savePreview { args.append("--save-preview") }
        return args
    }
}
