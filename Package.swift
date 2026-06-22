// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "doedit",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", branch: "main")
    ],
    targets: [
        .target(
            name: "doeditCore",
            path: "Sources/Model"
        ),
        .executableTarget(
            name: "doedit",
            dependencies: [
                "doeditCore",
                .product(name: "TUIkit", package: "TUIkit")
            ],
            path: "Sources",
            exclude: ["Model"]
        ),
        .testTarget(
            name: "doeditTests",
            dependencies: ["doeditCore"],
            path: "Tests"
        )
    ]
)
