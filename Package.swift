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
			.branch("master")
		),
        .package(
			name:"SwiftyHomology",
			url: "../SwiftyHomology",
			.branch("master")
		),
    ],
    targets: [
        .target(
            name: "SwiftyKnots",
            dependencies: ["SwiftyMath", "SwiftyHomology"],
			resources: [.process("Resources")]
		),
        .testTarget(
            name: "SwiftyKnotsTests",
            dependencies: ["SwiftyKnots"]
		),
    ]
)
