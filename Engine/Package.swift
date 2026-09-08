// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AllergenEngine",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "AllergenEngine", targets: ["AllergenEngine"])
    ],
    targets: [
        .target(name: "AllergenEngine"),
        .executableTarget(name: "Validate", dependencies: ["AllergenEngine"]),
        .executableTarget(name: "Check", dependencies: ["AllergenEngine"])
    ]
)
