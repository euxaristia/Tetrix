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
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3")
            ]
        ),
        .target(
            name: "CPulseAudio",
            path: "Sources/CPulseAudio",
            sources: ["PulseAudioWrapper.c"],
            publicHeadersPath: "include",
            // C module with PulseAudio wrapper for audio (Linux only, Windows has stubs)
            cSettings: [
                // Linux: Add PulseAudio compiler flags
                .unsafeFlags(["-D_REENTRANT"], .when(platforms: [.linux]))
            ],
            linkerSettings: [
                // Linux: Link PulseAudio libraries
                .unsafeFlags(["-lpulse-simple", "-lpulse"], .when(platforms: [.linux]))
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
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3")
                // Note: SDL3_ttf has been removed - using Swift-native text rendering instead
                // Note: PulseAudio is linked by CPulseAudio target
            ]
        )
    ]
)
