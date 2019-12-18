// swift-tools-version:5.1
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
        .package(url: "https://github.com/taketo1024/SwiftyMath.git", from:"2.0.0"),
        .package(url: "https://github.com/taketo1024/SwiftyMath-homology.git", from: "2.0.0"),
        .package(url: "https://github.com/taketo1024/SwiftyMath-solver.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftyKnots",
            dependencies: ["SwiftyMath", "SwiftyHomology", "SwiftySolver"],
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
