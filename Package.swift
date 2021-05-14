// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyKnots",
    products: [
        .library(
            name: "SwiftyKnots",
            targets: ["SwiftyKnots"]
        ),
    ],
    dependencies: [
        .package(
			name:"SwiftyMath",
			url: "../SwiftyMath",
			.branch("matrix-improve")
		),
        .package(
			name:"SwiftyHomology",
			url: "../SwiftyHomology",
			.branch("matrix-improve")
		),
        .package(
			name:"SwiftySolver",
			url: "../SwiftySolver",
			.branch("matrix-improve")
		),
    ],
    targets: [
        .target(
            name: "SwiftyKnots",
            dependencies: ["SwiftyMath", "SwiftyHomology", "SwiftySolver"],
			path: "Sources/SwiftyKnots",
			resources: [.process("Resources")]
		),
        .testTarget(
            name: "SwiftyKnotsTests",
            dependencies: ["SwiftyKnots"]
		),
        .target(
            name: "SwiftyKnots-Sample",
            dependencies: ["SwiftyMath", "SwiftyHomology", "SwiftyKnots"],
			path: "Sources/Sample"
		),
    ]
)
