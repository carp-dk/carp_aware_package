/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_aware_package.dart';

/// A sampling package for collecting passive sensor data from an Apple Watch
/// using the [AWARE watchOS](https://github.com/awareframework/com.awareframework.ios.sensor.applewatch)
/// framework. Supports the following measures:
///
///  * dk.carp.watch.aware.motion
///  * dk.carp.watch.aware.heartrate
///  * dk.carp.watch.aware.battery
///  * dk.carp.watch.aware.location
///  * dk.carp.watch.aware.heading
///  * dk.carp.watch.aware.bluetooth
///  * dk.carp.watch.aware.ambientnoise
///  * dk.carp.watch.aware.audiolabel
///  * dk.carp.watch.aware.device
///
/// All measures are:
///
///  * Event-based measures.
///  * Using the [AppleWatchDevice] connected device for data collection.
///  * Configured on the [AppleWatchDevice] rather than per measure - the watch
///    is one sensing unit and the settings are handed to it as a whole.
///
/// Data is collected on the watch while the phone app is not running, buffered
/// in a database on the watch, and transferred to the phone in compressed
/// chunks. Measurements therefore arrive in bursts - typically every
/// [AppleWatchDevice.fileTransferInterval] - and not continuously.
///
/// An example of a study protocol configuration might be:
///
/// ```dart
///   // The Apple Watch, configured to sample motion at 10 Hz and heart rate,
///   // and to hand its data to the phone every 15 minutes.
///   final watch = AppleWatchDevice(
///     motionSamplingRate: 10,
///     heartRateEnabled: true,
///     fileTransferInterval: const Duration(minutes: 15),
///   );
///   protocol.addConnectedDevice(watch, phone);
///
///   // Collect motion, heart rate, and battery data from the watch.
///   protocol.addTaskControl(
///       ImmediateTrigger(),
///       BackgroundTask(measures: [
///         Measure(type: AppleWatchSamplingPackage.MOTION),
///         Measure(type: AppleWatchSamplingPackage.HEART_RATE),
///         Measure(type: AppleWatchSamplingPackage.BATTERY),
///       ]),
///       watch);
/// ```
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```dart
///   SamplingPackageRegistry().register(AppleWatchSamplingPackage());
/// ```
///
/// Note that this package requires a companion watchOS app built with the AWARE
/// watchOS framework to be part of the iOS app. See the
/// [watchOS app setup guide](https://github.com/carp-dk/carp_aware_package/blob/main/doc/watchos_app_setup.md).
class AppleWatchSamplingPackage implements SamplingPackage {
  /// The namespace of the data types in this package.
  ///
  /// Note that this uses the `dk.carp` naming, and not the legacy
  /// `dk.cachet.carp` naming still held by [NameSpace.CARP].
  static const String APPLE_WATCH_NAMESPACE = "dk.carp.watch.aware";

  /// Measure type for motion data from the watch - raw acceleration, attitude,
  /// gravity, rotation rate, and user acceleration.
  static const String MOTION = "$APPLE_WATCH_NAMESPACE.motion";

  /// Measure type for heart rate (BPM) from the watch, sampled via HealthKit.
  static const String HEART_RATE = "$APPLE_WATCH_NAMESPACE.heartrate";

  /// Measure type for battery level and charging state of the watch.
  static const String BATTERY = "$APPLE_WATCH_NAMESPACE.battery";

  /// Measure type for location data from the watch.
  static const String LOCATION = "$APPLE_WATCH_NAMESPACE.location";

  /// Measure type for compass heading data from the watch.
  static const String HEADING = "$APPLE_WATCH_NAMESPACE.heading";

  /// Measure type for nearby Bluetooth devices scanned by the watch.
  static const String BLUETOOTH = "$APPLE_WATCH_NAMESPACE.bluetooth";

  /// Measure type for the ambient noise level (dB) measured by the watch.
  static const String AMBIENT_NOISE = "$APPLE_WATCH_NAMESPACE.ambientnoise";

  /// Measure type for sound classifications made by the watch.
  static const String AUDIO_LABEL = "$APPLE_WATCH_NAMESPACE.audiolabel";

  /// Measure type for information on the watch itself and the phone it is
  /// paired with.
  static const String DEVICE = "$APPLE_WATCH_NAMESPACE.device";

  static final AppleWatchDeviceManager _deviceManager =
      AppleWatchDeviceManager();

  static DataTypeSamplingSchemeMap? _samplingSchemes;

  /// The sampling schemes for all data types collected from an Apple Watch.
  ///
  /// Exposed as a static member since the [AppleWatchDevice] configuration
  /// also needs to report which data types the watch supports.
  static DataTypeSamplingSchemeMap get watchSamplingSchemes =>
      _samplingSchemes ??= DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: MOTION,
            displayName: "Apple Watch Motion",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: HEART_RATE,
            displayName: "Apple Watch Heart Rate",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: BATTERY,
            displayName: "Apple Watch Battery",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: LOCATION,
            displayName: "Apple Watch Location",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: HEADING,
            displayName: "Apple Watch Heading",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: BLUETOOTH,
            displayName: "Apple Watch Bluetooth Scan",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: AMBIENT_NOISE,
            displayName: "Apple Watch Ambient Noise",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: AUDIO_LABEL,
            displayName: "Apple Watch Sound Classification",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          DataTypeMetaData(
            type: DEVICE,
            displayName: "Apple Watch Device Information",
            timeType: DataTimeType.POINT,
          ),
        ),
      ]);

  @override
  DataTypeSamplingSchemeMap get samplingSchemes => watchSamplingSchemes;

  @override
  List<DataTypeMetaData> get dataTypes => samplingSchemes.dataTypes;

  @override
  Probe? create(String type) => switch (type) {
    MOTION => AppleWatchMotionProbe(),
    HEART_RATE => AppleWatchHeartRateProbe(),
    BATTERY => AppleWatchBatteryProbe(),
    LOCATION => AppleWatchLocationProbe(),
    HEADING => AppleWatchHeadingProbe(),
    BLUETOOTH => AppleWatchBluetoothProbe(),
    AMBIENT_NOISE => AppleWatchAmbientNoiseProbe(),
    AUDIO_LABEL => AppleWatchAudioLabelProbe(),
    DEVICE => AppleWatchDeviceInfoProbe(),
    _ => null,
  };

  @override
  void onRegister() {
    // register the device configuration and registration
    FromJsonFactory().registerAll([
      AppleWatchDevice(),
      AppleWatchDeviceRegistration(),
    ]);

    // register all data types
    FromJsonFactory().registerAll([
      AppleWatchMotion(),
      AppleWatchHeartRate(),
      AppleWatchBattery(),
      AppleWatchLocation(),
      AppleWatchHeading(),
      AppleWatchBluetooth(),
      AppleWatchAmbientNoise(),
      AppleWatchAudioLabel(),
      AppleWatchDeviceInfo(),
    ]);
  }

  @override
  String get deviceType => AppleWatchDevice.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;
}
