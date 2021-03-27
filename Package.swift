// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "speechly-ios-client",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Speechly",
            targets: ["Speechly"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
        .package(name: "speechly-api", url: "https://github.com/speechly/api.git", from: "0.1.3"),
    ],
    targets: [
        .target(
            name: "Speechly",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "SnapKit", package: "SnapKit"),
                .product(name: "SpeechlyAPI", package: "speechly-api"),
            ]),
        .testTarget(
            name: "SpeechlyTests",
            dependencies: ["Speechly"]),
    ]
)
