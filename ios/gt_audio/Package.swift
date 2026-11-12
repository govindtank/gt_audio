// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "gt_audio",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "gt-audio", targets: ["gt_audio"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "gt_audio",
            dependencies: [],
            resources: []
        ),
    ]
)
