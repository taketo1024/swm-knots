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
			url: "https://github.com/taketo1024/SwiftyMath.git",
			from:"3.0.0"
		),
        .package(
			name:"SwiftyHomology",
			url: "https://github.com/taketo1024/SwiftyMath-homology.git",
			from: "3.0.0"
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
