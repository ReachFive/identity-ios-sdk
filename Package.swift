// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IdentitySdkCore",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "IdentitySdkCore",
            targets: ["IdentitySdkCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.8.2")),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.1"),
        .package(url: "https://github.com/Thomvis/BrightFutures.git", from: "8.2"),
    
    
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "IdentitySdkCore",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ],
            path: "IdentitySdkCore/IdentitySdkCore"),
    ]
)
