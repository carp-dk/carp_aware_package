/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

// Umbrella module for the companion watchOS app.
//
// The AWARE watchOS framework ships with this plugin as pre-compiled
// XCFrameworks. Linking the `carp-aware-watch` product pulls in both AWARE
// watch modules and the open-source packages they were compiled against, so the
// watch app does not have to know about any of them.
//
// Re-exported, which means `import CarpAwareWatch` is enough for the watch app.
// Importing the AWARE modules directly keeps working as well.
@_exported import com_awareframework_ios_sensor_applewatch_shared
@_exported import com_awareframework_ios_sensor_applewatch_watchOS

/// The AWARE Apple Watch binaries this plugin was built against.
///
/// Carries no behaviour - it is here so the module is never an empty object
/// file, and so a watch app can log which AWARE build it is running.
public enum CarpAwareWatch {
    /// The AWARE framework version the bundled XCFrameworks were built from.
    ///
    /// See `Frameworks/BUILD-INFO.txt` for the exact revision.
    public static let awareVersion = "1.6.0"
}
