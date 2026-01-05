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
                // Try to link directly to DLL if .lib not available (Windows only, but safe to include)
                .unsafeFlags(["-L", "."], .when(configuration: .debug)),
                .unsafeFlags(["-L", "."], .when(configuration: .release)),
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
                // Try to link directly to DLL if .lib not available (Windows only, but safe to include)
                .unsafeFlags(["-L", "."], .when(configuration: .debug)),
                .unsafeFlags(["-L", "."], .when(configuration: .release)),
                .linkedLibrary("SDL3"),
                .linkedLibrary("SDL3_ttf")
            ]
        )
    ]
)
