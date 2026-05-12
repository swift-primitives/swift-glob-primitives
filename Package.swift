// swift-tools-version: 6.3.1

import PackageDescription

// Glob Primitives — L1 vocabulary for cross-platform glob pattern matching.
//
// Defines the canonical pattern grammar consumed by both POSIX and Windows
// L3-policy match implementations:
//
//   *  matches any sequence of characters (except path separator)
//   ** matches zero or more path segments (recursive)
//   ?  matches any single Unicode scalar
//   [abc]  matches any scalar in the set
//   [!abc] / [^abc]  matches any scalar not in the set
//
// Brace expansion `{a,b,c}` is shell policy, not glob core — pre-expand
// patterns at a higher layer if needed.
//
// Per Item 3.5 (relocation cycle 2026-05-02) — relocated from L2 swift-iso-9945's
// `ISO 9945 Glob` target with namespace shape change `ISO_9945.Kernel.Glob.*` →
// top-level `Glob.*`. The grammar mixes POSIX basics (*/?/[]), Bash extensions
// (**), and workspace policy (canonical `/` separator on all platforms) — no
// single spec authority — so per `feedback_authority_not_platform`, L1 is the
// correct authority-less vocabulary home. The POSIX libc wrappers
// (`ISO_9945.Glob.{Fnmatch, Expand}`) remain at L2 swift-iso-9945, correctly
// POSIX-spec-bound.

let package = Package(
    name: "swift-glob-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Glob Primitives",
            targets: ["Glob Primitives"]
        ),
        .library(
            name: "Glob Primitives Standard Library Integration",
            targets: ["Glob Primitives Standard Library Integration"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-ascii-primitives"),
    ],
    targets: [
        .target(
            name: "Glob Primitives",
            dependencies: [
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ]
        ),
        .target(
            name: "Glob Primitives Standard Library Integration",
            dependencies: [
                "Glob Primitives",
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
