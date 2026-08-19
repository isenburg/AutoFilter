// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoQSO",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .executable(name: "AutoQSO", targets: ["AutoQSO"]),
        .executable(name: "AutoQSOInstaller", targets: ["AutoQSOInstaller"])
    ],
    targets: [
        .executableTarget(
            name: "AutoQSO",
            path: "Sources/AutoQSO"
        ),
        .executableTarget(
            name: "AutoQSOInstaller",
            path: "Sources/AutoQSOInstaller"
        )
    ]
)
