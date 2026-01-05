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
            name: "CSDL3",
            path: "Sources/CSDL3",
            cSettings: [
                .headerSearchPath("include")
            ],
            linkerSettings: [
                // Try to link directly to DLL if .lib not available
                .unsafeFlags(["-L", "."], .when(configuration: .debug)),
                .unsafeFlags(["-L", "."], .when(configuration: .release)),
                .linkedLibrary("SDL3"),
                // Note: SDL3_ttf.lib will be needed for text rendering
                // Generate it from SDL3_ttf.dll using: .\create_sdl3_ttf_lib.ps1
                .linkedLibrary("SDL3_ttf")
            ]
        ),
        .executableTarget(
            name: "Tetrix",
            dependencies: ["CSDL3"],
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
            linkerSettings: [
                // Try to link directly to DLL if .lib not available
                .unsafeFlags(["-L", "."], .when(configuration: .debug)),
                .unsafeFlags(["-L", "."], .when(configuration: .release)),
                .linkedLibrary("SDL3"),
                // Note: SDL3_ttf.lib will be needed for text rendering
                // Generate it from SDL3_ttf.dll using: .\create_sdl3_ttf_lib.ps1
                .linkedLibrary("SDL3_ttf")
            ]
        )
    ]
)
