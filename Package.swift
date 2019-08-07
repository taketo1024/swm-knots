// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyKnots",
    products: [
        .library(
            name: "SwiftyKnots",
            targets: ["SwiftyKnots"]),
    ],
    dependencies: [
        .package(url: "https://github.com/taketo1024/SwiftyMath.git", .branch("grid-homology")),
        .package(url: "https://github.com/taketo1024/SwiftyMath-homology.git", .branch("grid-homology")),
    ],
    targets: [
        .target(
            name: "SwiftyKnots",
            dependencies: ["SwiftyMath", "SwiftyHomology"],
			path: "Sources/SwiftyKnots"),
        .testTarget(
            name: "SwiftyKnotsTests",
            dependencies: ["SwiftyKnots"]),
        .target(
            name: "SwiftyKnots-Sample",
            dependencies: ["SwiftyMath", "SwiftyHomology", "SwiftyKnots"],
			path: "Sources/Sample"),
    ]
)
