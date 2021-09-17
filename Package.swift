// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swm-knots",
    products: [
        .library(
            name: "SwmKnots",
            targets: ["SwmKnots"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/taketo1024/swm-core.git",
            from:"1.2.1"
        ),
        .package(
            url: "https://github.com/davecom/SwiftGraph.git",
            from: "3.1.0"
        ),
    ],
    targets: [
        .target(
            name: "SwmKnots",
            dependencies: [
                .product(name: "SwmCore", package: "swm-core"),
                "SwiftGraph",
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SwmKnotsTests",
            dependencies: ["SwmKnots"]
        ),
    ]
)
