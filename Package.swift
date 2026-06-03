// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AdaptivePanel",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "AdaptivePanel",
            targets: ["AdaptivePanel"]
        )
    ],
    targets: [
        .target(
            name: "AdaptivePanel"
        ),
        .testTarget(
            name: "AdaptivePanelTests",
            dependencies: ["AdaptivePanel"]
        ),
    ]
)
