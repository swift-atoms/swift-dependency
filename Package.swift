// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-dependency-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Dependency Primitives",
            targets: ["Dependency Primitives"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-witness-primitives.git", branch: "main"),
        // SDG(operates-on): DI operates on property wrapper patterns (@Dependency, @Environment)
        // .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        // SDG(operates-on): DI operates on lens/prism patterns for nested value access
        // .package(url: "https://github.com/swift-primitives/swift-optic-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Dependency Primitives",
            dependencies: [
                .product(name: "Witness Primitives", package: "swift-witness-primitives"),
                // .product(name: "Property Primitives", package: "swift-property-primitives"),
                // .product(name: "Optic Primitives", package: "swift-optic-primitives"),
            ]
        ),
        .testTarget(
            name: "Dependency Primitives Tests",
            dependencies: [
                "Dependency Primitives",
            ]
        )
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
