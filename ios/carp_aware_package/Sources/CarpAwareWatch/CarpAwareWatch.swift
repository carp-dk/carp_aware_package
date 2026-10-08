/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

// Umbrella module for the companion watchOS app.
//
// The AWARE watchOS framework is a Swift package dependency of this plugin.
// Linking the `carp-aware-watch` product pulls in both AWARE watch modules and
// the packages they depend on - in the same version the iOS side of the plugin
// uses - so the watch app does not have to add any of them itself.
//
// Re-exported, which means `import CarpAwareWatch` is enough for the watch app.
// Importing the AWARE modules directly keeps working as well.
@_exported import com_awareframework_ios_core
@_exported import com_awareframework_ios_sensor_applewatch_shared
@_exported import com_awareframework_ios_sensor_applewatch_watchOS

/// The AWARE Apple Watch framework this plugin is built against.
///
/// Carries no behaviour - it is here so the module is never an empty object
/// file, and so a watch app can log which AWARE release the plugin expects.
public enum CarpAwareWatch {
    /// The AWARE framework release this plugin is built and tested against.
    ///
    /// `Package.swift` pins exactly this release, so it is also the release
    /// built into the app. Keep the two in sync.
    public static let awareVersion = "1.6.0"
}
