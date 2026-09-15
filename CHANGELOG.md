## 1.0.0

Initial release of the CARP AWARE Apple Watch sampling package.

* wraps the [AWARE watchOS](https://github.com/awareframework/com.awareframework.ios.sensor.applewatch)
  framework (v. 1.6.0) as a CARP Mobile Sensing sampling package
* ships that framework as pre-compiled XCFrameworks for iOS and watchOS, so an app builds
  against this package without access to the AWARE source - the watch app links the
  `carp-aware-watch` product instead of adding the AWARE package itself
* adds the `AppleWatchDevice` connected device, which configures the watch from the study protocol
* supports nine measure types in the `dk.carp.watch.aware` namespace - motion, heart rate,
  battery, location, heading, bluetooth, ambient noise, audio label, and device information
* iOS-only Swift Package Manager plugin bridging the native AWARE `AppleWatchSensor` to Dart
* de-duplicates records using the record id from the database on the watch
* exposes the runtime state of the watch connection and the transfer progress via the
  `AppleWatchDeviceManager`
* includes a [guide](doc/watchos_app_setup.md) for adding the companion watchOS app to a Flutter app
