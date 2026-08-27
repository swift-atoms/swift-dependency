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
        .library(
            name: "Dependency",
            targets: ["Dependency"]
        ),
        .library(
            name: "Dependency Standard Library Integration",
            targets: ["Dependency Standard Library Integration"]
        ),
        .library(
            name: "Dependency Apple Foundation Integration",
            targets: ["Dependency Apple Foundation Integration"]
        ),
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
                .product(name: "Witness", package: "swift-witness")
            ]
        ),
        .target(
            name: "Dependency Standard Library Integration",
            dependencies: ["Dependency"]
        ),
        .target(
            name: "Dependency Apple Foundation Integration",
            dependencies: [
                "Dependency",
                "Dependency Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Dependency Tests",
            dependencies: [
                "Dependency"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
