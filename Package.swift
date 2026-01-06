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
                // Windows: Add header path for statically built SDL3
                .headerSearchPath("sdl3-headers", .when(platforms: [.windows]))
            ],
            linkerSettings: [
                // Windows: Link against static libraries (built in CI, renamed to standard names)
                // Add current directory to library search path first (highest priority)
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3")
            ]
        ),
        .target(
            name: "CPulseAudio",
            path: "Sources/CPulseAudio",
            sources: [
                "PulseAudioWrapper.c"
            ],
            publicHeadersPath: "include",
            // C module with PulseAudio wrapper for Linux and WASAPI wrapper for Windows
            cSettings: [
                // Linux: Add PulseAudio compiler flags
                .unsafeFlags(["-D_REENTRANT"], .when(platforms: [.linux]))
            ],
            linkerSettings: [
                // Linux: Link PulseAudio libraries
                .unsafeFlags(["-lpulse-simple", "-lpulse"], .when(platforms: [.linux])),
                // Windows: Link WASAPI libraries
                .unsafeFlags(["-Xlinker", "avrt.lib"], .when(platforms: [.windows])),
                .unsafeFlags(["-Xlinker", "ole32.lib"], .when(platforms: [.windows])),
                .unsafeFlags(["-Xlinker", "uuid.lib"], .when(platforms: [.windows]))
            ]
        ),
        .executableTarget(
            name: "Tetrix",
            dependencies: ["CSDL3", "Tenebris", "CPulseAudio"],
            // X11Interop is part of CSDL3 module
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
                // Static linking and optimization flags for Windows release builds
                // Note: Static C runtime linking may require specific MSVC setup
                // These flags optimize the binary and remove debug info for obfuscation
                .unsafeFlags(["-Xlinker", "/DEBUG:NONE"], .when(platforms: [.windows], configuration: .release)),
                .unsafeFlags(["-Xlinker", "/OPT:REF"], .when(platforms: [.windows], configuration: .release)),
                .unsafeFlags(["-Xlinker", "/OPT:ICF"], .when(platforms: [.windows], configuration: .release)),
                // Strip unnecessary symbols
                .unsafeFlags(["-Xlinker", "/INCREMENTAL:NO"], .when(platforms: [.windows], configuration: .release)),
                // Build as Windows GUI application (no console window) but keep main() entry point
                .unsafeFlags(["-Xlinker", "/SUBSYSTEM:WINDOWS"], .when(platforms: [.windows])),
                .unsafeFlags(["-Xlinker", "/ENTRY:mainCRTStartup"], .when(platforms: [.windows])),
                // Note: SDL3_ttf has been removed - using Swift-native text rendering instead
                // Note: PulseAudio is linked by CPulseAudio target
                // Note: Swift runtime will still be dynamically linked (standard for Swift on Windows)
            ]
        )
    ]
)
