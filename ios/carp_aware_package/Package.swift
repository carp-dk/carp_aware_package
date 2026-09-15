// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// The AWARE Apple Watch framework is shipped with this plugin as pre-compiled
// XCFrameworks in `Frameworks/`, built by `tool/build_xcframeworks.sh`. Its
// source is not distributed.
//
// The XCFrameworks contain static libraries, so the open-source packages AWARE
// links against are *not* baked into them - they are declared as ordinary
// dependencies below. That keeps exactly one copy of each in the app, which
// matters because the AWARE API exposes `GRDB.DatabaseQueue` in public
// signatures.
//
// The module names are the ones SwiftPM derived from the AWARE target names, so
// `import com_awareframework_ios_sensor_applewatch_shared` and friends resolve
// against the binaries exactly as they did against the sources.
let awareShared = "com_awareframework_ios_sensor_applewatch_shared"
let awareIOS = "com_awareframework_ios_sensor_applewatch_iOS"
let awareWatchOS = "com_awareframework_ios_sensor_applewatch_watchOS"

let package = Package(
    name: "carp_aware_package",
    platforms: [
        // The AWARE watchOS framework requires iOS 16. Make sure the
        // IPHONEOS_DEPLOYMENT_TARGET of the Runner target is 16.0 or higher.
        .iOS("16.0"),
        // The companion watchOS app links the `carp-aware-watch` product from
        // this same package - see doc/watchos_app_setup.md.
        .watchOS("8.0"),
    ],
    products: [
        // Linked into the Flutter app by the generated plugin package.
        .library(name: "carp-aware-package", targets: ["carp_aware_package"]),
        // Linked by the companion watchOS app target, by hand.
        .library(name: "carp-aware-watch", targets: ["CarpAwareWatch"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/awareframework/com.awareframework.ios.core.git",
            from: "1.6.0"
        ),
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.8.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.3.0"),
    ],
    targets: [
        .binaryTarget(name: awareShared, path: "Frameworks/\(awareShared).xcframework"),
        .binaryTarget(name: awareIOS, path: "Frameworks/\(awareIOS).xcframework"),
        .binaryTarget(name: awareWatchOS, path: "Frameworks/\(awareWatchOS).xcframework"),

        // The iOS side of the plugin - the Flutter method channel and the
        // AWARE sensor running on the phone.
        .target(
            name: "carp_aware_package",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .target(name: awareShared),
                .target(name: awareIOS),
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
                .product(name: "DataCompression", package: "DataCompression"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),

        // The watchOS side. This target carries no logic - it exists so that
        // the watch app can link one product and get the AWARE watchOS modules
        // together with everything they need at link time.
        //
        // Each of the two targets above depends on the binaries of one platform
        // only, so building this package as a whole for a single platform will
        // fail on the other target. That is fine in practice: an app builds
        // `carp-aware-package` for iOS and `carp-aware-watch` for watchOS, and
        // never both for the same destination.
        .target(
            name: "CarpAwareWatch",
            dependencies: [
                .target(name: awareShared),
                .target(name: awareWatchOS),
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
                .product(name: "DataCompression", package: "DataCompression"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
    ]
)
