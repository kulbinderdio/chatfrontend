// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacOSChatApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacOSChatApp", targets: ["MacOSChatApp"])
    ],
    dependencies: [
        // SQLite database interface
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        
        // Simplified Keychain API
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        
        // HTTP networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // JSON parsing
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1"),
        
        // Markdown rendering
        .package(url: "https://github.com/iwasrobbed/Down.git", from: "0.11.0"),
        
        // Testing frameworks
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.1.0")
    ],
    targets: [
        .executableTarget(
            name: "MacOSChatApp",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "Down", package: "Down")
            ],
            path: "MacOSChatApp"
        ),
        .testTarget(
            name: "MacOSChatAppTests",
            dependencies: [
                "MacOSChatApp",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
                .product(name: "OHHTTPStubs", package: "OHHTTPStubs"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "Down", package: "Down")
            ],
            path: "MacOSChatAppTests"
        )
    ]
)
