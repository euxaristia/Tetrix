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
        .systemLibrary(
            name: "CSDL2",
            pkgConfig: "sdl2",
            providers: [
                .apt(["libsdl2-dev", "libsdl2-ttf-dev"]),
                .brew(["sdl2", "sdl2_ttf"])
            ]
        ),
        .executableTarget(
            name: "Tetrix",
            dependencies: ["CSDL2"],
            path: ".",
            sources: [
                "main.swift",
                "SDL2Game.swift",
                "TetrisEngine.swift",
                "GameBoard.swift",
                "Tetromino.swift",
                "Position.swift",
                "TetrisMusic.swift"
            ],
            exclude: [
                "README.md",
                "DEBUG.md"
            ],
            linkerSettings: [
                .linkedLibrary("SDL2"),
                .linkedLibrary("SDL2_ttf")
            ]
        )
    ]
)
