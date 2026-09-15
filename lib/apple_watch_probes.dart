/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_aware_package.dart';

/// Base class for all probes collecting data from an Apple Watch.
///
/// All Apple Watch probes share one stream of records from the
/// [AppleWatchDeviceManager] and pick the records from the AWARE [table] which
/// holds their own data type.
///
/// Note that the watch transfers its data in bursts, so measurements from these
/// probes arrive in batches - typically once every
/// [AppleWatchDevice.fileTransferInterval] - and not continuously.
abstract class AppleWatchProbe extends StreamProbe {
  @override
  AppleWatchDeviceManager get deviceManager =>
      super.deviceManager as AppleWatchDeviceManager;

  /// The AWARE table holding the records collected by this probe.
  String get table;

  /// Convert one AWARE record into the [AppleWatchData] of this probe.
  AppleWatchData toData(Map<String, dynamic> record);

  @override
  Stream<Measurement> get stream => deviceManager.records
      .where((batch) => batch.table == table)
      .expand((batch) => batch.records)
      .map((record) {
        final data = toData(record);
        return Measurement.fromData(
          data,
          data.timestamp.microsecondsSinceEpoch,
        );
      });
}

/// Collects motion data ([AppleWatchMotion]) from the Apple Watch.
class AppleWatchMotionProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.motion;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchMotion.fromRecord(record);
}

/// Collects heart rate data ([AppleWatchHeartRate]) from the Apple Watch.
class AppleWatchHeartRateProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.heartRate;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchHeartRate.fromRecord(record);
}

/// Collects battery data ([AppleWatchBattery]) from the Apple Watch.
class AppleWatchBatteryProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.battery;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchBattery.fromRecord(record);
}

/// Collects location data ([AppleWatchLocation]) from the Apple Watch.
class AppleWatchLocationProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.location;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchLocation.fromRecord(record);
}

/// Collects compass heading data ([AppleWatchHeading]) from the Apple Watch.
class AppleWatchHeadingProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.heading;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchHeading.fromRecord(record);
}

/// Collects nearby Bluetooth devices ([AppleWatchBluetooth]) scanned by the
/// Apple Watch.
class AppleWatchBluetoothProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.bluetooth;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchBluetooth.fromRecord(record);
}

/// Collects ambient noise levels ([AppleWatchAmbientNoise]) from the Apple Watch.
class AppleWatchAmbientNoiseProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.ambientNoise;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchAmbientNoise.fromRecord(record);
}

/// Collects sound classifications ([AppleWatchAudioLabel]) made by the Apple Watch.
class AppleWatchAudioLabelProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.audioLabel;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchAudioLabel.fromRecord(record);
}

/// Collects information ([AppleWatchDeviceInfo]) about the Apple Watch itself.
class AppleWatchDeviceInfoProbe extends AppleWatchProbe {
  @override
  String get table => AppleWatchTable.device;

  @override
  AppleWatchData toData(Map<String, dynamic> record) =>
      AppleWatchDeviceInfo.fromRecord(record);
}
