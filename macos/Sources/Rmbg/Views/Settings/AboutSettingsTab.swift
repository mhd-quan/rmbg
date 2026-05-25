import SwiftUI

/// About tab. Lightweight credits + version readout.
struct AboutSettingsTab: View {
    private let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? "Rmbg"
    private let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        ?? "0.1.0"
    private let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        ?? "1"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(appName)
                .appFont(.titleL)
            Text("Version \(version) (\(build))")
                .appFont(.body)
                .foregroundStyle(Palette.textSecondary)

            Divider().padding(.vertical, Spacing.s)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Model")
                    .appFont(.caption)
                    .foregroundStyle(Palette.textTertiary)
                Text("BRIA RMBG-2.0 via Hugging Face Transformers")
                    .appFont(.body)
                Link("Model card on Hugging Face",
                     destination: URL(string: "https://huggingface.co/briaai/RMBG-2.0")!)
                    .appFont(.body)
            }

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("License")
                    .appFont(.caption)
                    .foregroundStyle(Palette.textTertiary)
                Text("RMBG-2.0 is licensed for non-commercial use unless you hold a commercial agreement with BRIA. This app is private.")
                    .appFont(.body)
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
