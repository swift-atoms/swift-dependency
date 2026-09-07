// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-dependency",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Dependency", targets: ["Dependency"]),
        .library(name: "Dependency Standard Library Integration", targets: ["Dependency Standard Library Integration"]),
        .library(name: "Dependency Foundation Library Integration", targets: ["Dependency Foundation Library Integration"]),
        .library(name: "Dependency Test Support", targets: ["Dependency Test Support"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-witness.git",
            branch: "main"
        )

    ],
    targets: [
        .target(
            name: "Dependency",
            dependencies: [
                .product(name: "Witness", package: "swift-witness"),
            ],
            path: "Sources/Dependency"
        ),
        .target(
            name: "Dependency Standard Library Integration",
            dependencies: [
                .target(name: "Dependency"),
            ],
            path: "Sources/Dependency Standard Library Integration"
        ),
        .target(
            name: "Dependency Foundation Library Integration",
            dependencies: [
                .target(name: "Dependency"),
                .target(name: "Dependency Standard Library Integration"),
            ],
            path: "Sources/Dependency Foundation Library Integration"
        ),
        .target(
            name: "Dependency Test Support",
            dependencies: [
                .target(name: "Dependency"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Dependency Tests",
            dependencies: [
                .target(name: "Dependency"),
                .target(name: "Dependency Test Support"),
                .target(name: "Dependency Standard Library Integration"),
                .target(name: "Dependency Foundation Library Integration"),
            ],
            path: "Tests/Dependency Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
