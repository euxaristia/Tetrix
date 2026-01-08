// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tetrix",
    products: [
        .executable(
            name: "Tetrix",
            targets: ["Tetrix"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/euxaristia/SwiftSDL.git", from: "1.0.25")
    ],
    targets: [
        .target(
            name: "Tenebris",
            path: "Sources/Tenebris"
        ),
        .executableTarget(
            name: "Tetrix",
            dependencies: [.product(name: "SwiftSDL", package: "SwiftSDL"), "Tenebris"],
            path: "Sources/Tetrix",
            exclude: [
                // No exclusions needed - all Swift files are in Sources/Tetrix
            ],
            swiftSettings: [
                // Aggressive obfuscation and optimization flags for release builds
                .unsafeFlags(["-O"], .when(configuration: .release)), // Maximum optimization
                .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)), // WMO for better inlining
                .unsafeFlags(["-Xfrontend", "-enable-lexical-lifetimes=false"], .when(configuration: .release)),
                .unsafeFlags(["-Xfrontend", "-disable-implicit-concurrency-module-import"], .when(configuration: .release)),
                .unsafeFlags(["-Xfrontend", "-disable-implicit-string-processing-module-import"], .when(configuration: .release)),
                // Additional optimization flags
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)), // Cross-module optimization
            ],
            linkerSettings: [
                // Note: SDL3 and system libraries are now linked by SwiftSDL
                // Note: PulseAudio libraries are now linked by SwiftSDL
                // Static linking and optimization flags for Windows release builds
                // Note: Static C runtime linking may require specific MSVC setup
                // These flags optimize the binary and remove debug info for obfuscation
                .unsafeFlags(["-Xlinker", "/DEBUG:NONE"], .when(platforms: [.windows], configuration: .release)),
                .unsafeFlags(["-Xlinker", "/OPT:REF"], .when(platforms: [.windows], configuration: .release)),
                .unsafeFlags(["-Xlinker", "/OPT:ICF"], .when(platforms: [.windows], configuration: .release)),
                // Strip unnecessary symbols - remove unreferenced code and symbols
                .unsafeFlags(["-Xlinker", "/INCREMENTAL:NO"], .when(platforms: [.windows], configuration: .release)),
                // Note: Full symbol stripping requires llvm-strip post-build step (handled in CI)
                // Build as Windows GUI application (no console window) but keep main() entry point
                .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(platforms: [.windows])),
                .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"], .when(platforms: [.windows])),
                // Note: SDL3_ttf has been removed - using Swift-native text rendering instead
                // Note: PulseAudio is now directly linked (pure Swift implementation, no C wrapper)
                // Note: Swift runtime will still be dynamically linked (standard for Swift on Windows)
            ]
        )
    ]
)
