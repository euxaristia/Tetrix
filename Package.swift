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
                // Windows: Try to link directly to DLL if .lib not available
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3"),
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
                "TetrisMusic.swift",
                "SettingsManager.swift"
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
                // Windows: Try to link directly to DLL if .lib not available
                .unsafeFlags(["-L", "."], .when(platforms: [.windows])),
                // Linux: Add /usr/local/lib for SDL3 built from source
                .unsafeFlags(["-L", "/usr/local/lib"], .when(platforms: [.linux])),
                .linkedLibrary("SDL3"),
                .linkedLibrary("SDL3_ttf")
            ]
        )
    ]
)
