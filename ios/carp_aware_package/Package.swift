// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// The AWARE Apple Watch framework is an ordinary Swift package dependency, which
// Swift Package Manager fetches from GitHub together with this plugin.
//
// AWARE exposes a single product containing all three of its modules -
// `com_awareframework_ios_sensor_applewatch_shared`, `..._iOS`, and
// `..._watchOS` - and that product builds for both iOS and watchOS. The iOS
// side of this plugin and the companion watch app therefore link the same
// package, and since SwiftPM resolves one version of a package for the whole
// app, the phone and the watch always run the same AWARE release.
//
// That product is all-or-nothing, so the iOS app links the `..._watchOS` module
// as well. Most of its sources are not wrapped in `#if os(watchOS)`, so its
// audio code - including `AVAudioSession.requestRecordPermission` - ends up,
// unused, in the iOS binary. That is why the Runner target needs an
// NSMicrophoneUsageDescription (doc/watchos_app_setup.md, Step 8).
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
        // Pinned exactly: AWARE has renamed public types (1.2.2) and database
        // tables (1.3.0) within 1.x, and the Dart side of this plugin matches
        // records by those table names (`AppleWatchTable`), so a rename would
        // silently drop data. Bump deliberately, together with
        // `CarpAwareWatch.awareVersion`, after re-testing.
        .package(
            url: "https://github.com/awareframework/com.awareframework.ios.sensor.applewatch.git",
            exact: "1.6.0"
        ),
        // AWARE depends on this as well. It is declared here too because this
        // plugin imports `com_awareframework_ios_core` itself, and
        // `CarpAwareWatch` re-exports it to the watch app.
        .package(
            url: "https://github.com/awareframework/com.awareframework.ios.core.git",
            from: "1.6.0"
        ),
    ],
    targets: [
        // The iOS side of the plugin - the Flutter method channel and the
        // AWARE sensor running on the phone.
        .target(
            name: "carp_aware_package",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(
                    name: "com.awareframework.ios.sensor.applewatch",
                    package: "com.awareframework.ios.sensor.applewatch"
                ),
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
            ]
        ),

        // The watchOS side. This target carries no logic - it exists so that
        // the watch app can link one product of this plugin and get the AWARE
        // watchOS modules in the very version the iOS side was resolved with.
        .target(
            name: "CarpAwareWatch",
            dependencies: [
                .product(
                    name: "com.awareframework.ios.sensor.applewatch",
                    package: "com.awareframework.ios.sensor.applewatch"
                ),
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
            ]
        ),
    ]
)
