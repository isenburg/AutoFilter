// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoFilter",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .executable(name: "AutoFilter", targets: ["AutoFilter"]),
        .executable(name: "AutoFilterInstaller", targets: ["AutoFilterInstaller"])
    ],
    targets: [
        .executableTarget(
            name: "AutoFilter",
            path: "Sources/AutoFilter"
        ),
        .executableTarget(
            name: "AutoFilterInstaller",
            path: "Sources/AutoFilterInstaller"
        )
    ]
)
