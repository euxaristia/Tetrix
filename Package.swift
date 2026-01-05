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
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                // Try to link directly to DLL if .lib not available
                .unsafeFlags(["-L", "."], .when(configuration: .debug)),
                .unsafeFlags(["-L", "."], .when(configuration: .release)),
                // Obfuscation linker flags: strip symbols and reduce size
                .unsafeFlags(["-Xlinker", "/OPT:REF"], .when(configuration: .release)),
                .unsafeFlags(["-Xlinker", "/OPT:ICF"], .when(configuration: .release)),
                .unsafeFlags(["-Xlinker", "/DEBUG:NONE"], .when(configuration: .release)),
                .linkedLibrary("SDL3"),
                // Note: SDL3_ttf.lib will be needed for text rendering
                // Generate it from SDL3_ttf.dll using: .\create_sdl3_ttf_lib.ps1
                .linkedLibrary("SDL3_ttf")
            ]
        ),
        .executableTarget(
            name: "Tetrix",
            dependencies: ["CSDL3", "Tenebris"],
            path: ".",
            exclude: [
                "README.md",
                "DEBUG.md"
            ],
            sources: [
                "main.swift",
                "SDL3Game.swift",
                "TetrisEngine.swift",
                "GameBoard.swift",
                "Tetromino.swift",
                "Position.swift",
                "TetrisMusic.swift"
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
                // Try to link directly to DLL if .lib not available
                .unsafeFlags(["-L", "."], .when(configuration: .debug)),
                .unsafeFlags(["-L", "."], .when(configuration: .release)),
                // Aggressive obfuscation linker flags: strip symbols and reduce size
                .unsafeFlags(["-Xlinker", "/OPT:REF"], .when(configuration: .release)), // Remove unreferenced code
                .unsafeFlags(["-Xlinker", "/OPT:ICF"], .when(configuration: .release)), // Identical COMDAT folding
                .unsafeFlags(["-Xlinker", "/DEBUG:NONE"], .when(configuration: .release)), // No debug info
                .unsafeFlags(["-Xlinker", "/INCREMENTAL:NO"], .when(configuration: .release)), // Disable incremental linking
                .unsafeFlags(["-Xlinker", "/LTCG"], .when(configuration: .release)), // Link-time code generation
                .linkedLibrary("SDL3"),
                // Note: SDL3_ttf.lib will be needed for text rendering
                // Generate it from SDL3_ttf.dll using: .\create_sdl3_ttf_lib.ps1
                .linkedLibrary("SDL3_ttf")
            ]
        )
    ]
)
