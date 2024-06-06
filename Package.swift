// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IdentitySdkCore",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Reach5", targets: ["Reach5"]),
        .library(name: "Reach5Google", targets: ["Reach5Google"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.8.2")),
        .package(url: "https://github.com/devicekit/DeviceKit.git", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/Thomvis/BrightFutures.git", .upToNextMajor(from: "8.2.0")),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", .upToNextMajor(from: "7.1.0")),
    ],
    targets: [
        .target(
            name: "Reach5",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "DeviceKit", package: "DeviceKit"),
                .product(name: "BrightFutures", package: "BrightFutures"),
            ],
            path: "IdentitySdkCore/IdentitySdkCore"),
        .target(
            name: "Reach5Google",
            dependencies: ["Reach5", "GoogleSignIn-iOS"],
            path: "IdentitySdkGoogle/IdentitySdkGoogle"),
    ]
)
