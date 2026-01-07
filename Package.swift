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
    targets: [
        .target(
            name: "Tenebris",
            path: "Sources/Tenebris"
        ),
        .target(
            name: "CSDL3",
            path: "Sources/CSDL3",
            // C module for SDL3 headers only (no source files)
            cSettings: [
                .headerSearchPath("include"),
                // Only use rewritten headers from Sources/CSDL3/include/SDL3/
                // No external SDL3 headers are included
            ],
            linkerSettings: [
                // Windows: Link against static libraries (built in CI, renamed to standard names)
                // Add current directory to library search path first (highest priority)
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3"),
                // Windows: Required system libraries for SDL3
                .linkedLibrary("ole32", .when(platforms: [.windows])),
                .linkedLibrary("oleaut32", .when(platforms: [.windows])),
                .linkedLibrary("imm32", .when(platforms: [.windows])),
                .linkedLibrary("version", .when(platforms: [.windows])),
                .linkedLibrary("winmm", .when(platforms: [.windows]))
            ]
        ),
        .executableTarget(
            name: "Tetrix",
            dependencies: ["CSDL3", "Tenebris"],
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
                // Windows: Link against static libraries (built in CI, renamed to standard names)
                // Add current directory to library search path first (highest priority)
                // This ensures the static SDL3.lib in the project root is found before any DLL import libraries
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3"),
                // Windows: Required system libraries for SDL3
                .linkedLibrary("ole32", .when(platforms: [.windows])),
                .linkedLibrary("oleaut32", .when(platforms: [.windows])),
                .linkedLibrary("imm32", .when(platforms: [.windows])),
                .linkedLibrary("version", .when(platforms: [.windows])),
                .linkedLibrary("winmm", .when(platforms: [.windows])),
                // Linux: Link PulseAudio libraries directly (no C wrapper needed)
                .unsafeFlags(["-lpulse-simple", "-lpulse"], .when(platforms: [.linux])),
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
