// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tidy",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Tidy", targets: ["Tidy"])],
    targets: [.executableTarget(name: "Tidy")]
)
