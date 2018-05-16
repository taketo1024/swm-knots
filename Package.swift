// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyMath",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftyMath",
            targets: ["SwiftyMath"]),
        .library(
            name: "SwiftyHomology",
            targets: ["SwiftyHomology"]),
        .library(
            name: "SwiftyTopology",
            targets: ["SwiftyTopology"]),
        .library(
            name: "SwiftyLieGroups",
            targets: ["SwiftyLieGroups"]),
        .library(
            name: "SwiftyKnots",
            targets: ["SwiftyKnots"]),
        .library(
            name: "dSwiftyMath",
			type: .dynamic,
            targets: ["SwiftyMath", "SwiftyHomology", "SwiftyTopology", "SwiftyKnots"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftyMath",
            dependencies: [],
			path: "Sources/SwiftyMath"),

        .testTarget(
            name: "SwiftyMathTests",
            dependencies: ["SwiftyMath"]),

        .target(
            name: "SwiftyHomology",
            dependencies: ["SwiftyMath"],
			path: "Sources/SwiftyHomology"),

        .testTarget(
            name: "SwiftyHomologyTests",
            dependencies: ["SwiftyHomology"]),

        .target(
            name: "SwiftyTopology",
            dependencies: ["SwiftyMath", "SwiftyHomology"],
			path: "Sources/SwiftyTopology"),

        .testTarget(
            name: "SwiftyTopologyTests",
            dependencies: ["SwiftyTopology"]),

        .target(
            name: "SwiftyLieGroups",
            dependencies: ["SwiftyMath"],
			path: "Sources/SwiftyLieGroups"),

        .testTarget(
            name: "SwiftyLieGroupsTests",
            dependencies: ["SwiftyLieGroups"]),

        .target(
            name: "SwiftyKnots",
            dependencies: ["SwiftyMath", "SwiftyHomology"],
			path: "Sources/SwiftyKnots"),

        .testTarget(
            name: "SwiftyKnotsTests",
            dependencies: ["SwiftyKnots"]),

        .target(
            name: "Sample",
            dependencies: ["SwiftyMath", "SwiftyHomology", "SwiftyTopology", "SwiftyKnots"],
			path: "Sources/Sample"),

    ]
)
