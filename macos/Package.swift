// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Rmbg",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Rmbg", targets: ["Rmbg"]),
    ],
    targets: [
        .executableTarget(
            name: "Rmbg",
            path: "Sources/Rmbg",
            exclude: [
                "Resources/Info.plist",
                "Resources/Rmbg.entitlements",
            ],
            resources: [
                .process("Resources/Assets.xcassets"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("DeprecateApplicationMain"),
                .enableExperimentalFeature("StrictConcurrency=minimal"),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Combine"),
                .linkedFramework("UniformTypeIdentifiers"),
            ]
        ),
    ]
)
