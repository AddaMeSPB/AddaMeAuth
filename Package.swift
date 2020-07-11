// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "AddaMeAuth",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.5.1"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "6.5.0"),
        .package(url: "https://github.com/twof/VaporTwilioService.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc.1.4"),
        .package(url: "https://github.com/vapor/apns.git", from: "1.0.0-rc.1.1")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "MongoKitten", package: "MongoKitten"),
                .product(name: "Twilio", package: "VaporTwilioService"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "APNS", package: "apns")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)