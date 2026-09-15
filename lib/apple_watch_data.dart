/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_aware_package.dart';

/// The names of the tables in the AWARE database on the iPhone in which the
/// data transferred from the Apple Watch is stored.
///
/// Each record batch transferred from the watch is tagged with the table it
/// originates from. These names are used by the probes to pick the records
/// relevant to them from the shared stream of records.
class AppleWatchTable {
  static const String motion = 'ios_watch_motion';
  static const String heartRate = 'ios_watch_heart_rate';
  static const String battery = 'ios_watch_battery';
  static const String location = 'ios_watch_location';
  static const String heading = 'ios_watch_heading';
  static const String bluetooth = 'ios_watch_bluetooth';
  static const String ambientNoise = 'ios_watch_ambient_noise';
  static const String audioLabel = 'ios_watch_audio_label';
  static const String device = 'ios_watch_device';
}

/// The charging state of the Apple Watch battery.
///
/// A 1:1 mapping of [WKInterfaceDeviceBatteryState](https://developer.apple.com/documentation/watchkit/wkinterfacedevicebatterystate).
enum WatchBatteryState {
  /// The battery state of the watch cannot be determined.
  unknown,

  /// The watch runs on battery power and is discharging.
  unplugged,

  /// The watch is plugged in and charging, but not yet at 100%.
  charging,

  /// The watch is plugged in and the battery is at 100%.
  full,
}

/// Base class for all data collected from an Apple Watch using the
/// AWARE watchOS framework.
abstract class AppleWatchData extends Data {
  /// The AWARE device id of the Apple Watch which collected this data.
  String? deviceId;

  /// The timestamp of this data, as set by the Apple Watch.
  late DateTime timestamp;

  /// The AWARE data label of this data, if any.
  ///
  /// The label is set on the phone via the [AppleWatchDevice.label]
  /// configuration and is pulled by the watch app on startup.
  String? label;

  /// The id of the record in the local database on the Apple Watch.
  ///
  /// Together with [deviceId] and the data type, this uniquely identifies a
  /// record collected on the watch, and is used to avoid storing the same
  /// record twice. This is needed since a full transfer
  /// ([AppleWatchDevice.transferMode] set to [WatchTransferMode.all]) resends
  /// records which have been transferred before.
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? rowId;

  AppleWatchData({this.deviceId, DateTime? timestamp, this.label}) : super() {
    this.timestamp = timestamp ?? DateTime.now().toUtc();
  }

  /// Initialize the properties which all AWARE watch records have in common.
  AppleWatchData.fromRecord(Map<String, dynamic> record) : super() {
    deviceId = _string(record, 'deviceId');
    timestamp = _timestamp(record, 'timestamp');
    label = _string(record, 'label');
    rowId = _optionalInt(record, 'id');
  }

  @override
  String? get recordId => (rowId == null || rowId! < 0)
      ? null
      : '${deviceId ?? 'watch'}/$jsonType/$rowId';

  @override
  String toString() =>
      '${super.toString()}, deviceId: $deviceId, timestamp: $timestamp';
}

/// Motion data from the Apple Watch, sampled at the rate specified by
/// [AppleWatchDevice.motionSamplingRate].
///
/// A 1:1 mapping of an `AWMotionSensorData` record. Fields belonging to a
/// disabled sub-sensor (see [AppleWatchDevice.accelerometerEnabled] and
/// [AppleWatchDevice.deviceMotionEnabled]) are zero.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchMotion extends AppleWatchData {
  /// Raw acceleration on the x-axis in G (including gravity).
  double accX;

  /// Raw acceleration on the y-axis in G (including gravity).
  double accY;

  /// Raw acceleration on the z-axis in G (including gravity).
  double accZ;

  /// Attitude - roll in radians.
  double roll;

  /// Attitude - pitch in radians.
  double pitch;

  /// Attitude - yaw in radians.
  double yaw;

  /// Gravity vector on the x-axis in G.
  double gravityX;

  /// Gravity vector on the y-axis in G.
  double gravityY;

  /// Gravity vector on the z-axis in G.
  double gravityZ;

  /// Rotation rate around the x-axis in radians per second.
  double rotationX;

  /// Rotation rate around the y-axis in radians per second.
  double rotationY;

  /// Rotation rate around the z-axis in radians per second.
  double rotationZ;

  /// User acceleration on the x-axis in G (gravity removed).
  double userAccX;

  /// User acceleration on the y-axis in G (gravity removed).
  double userAccY;

  /// User acceleration on the z-axis in G (gravity removed).
  double userAccZ;

  AppleWatchMotion({
    super.deviceId,
    super.timestamp,
    super.label,
    this.accX = 0,
    this.accY = 0,
    this.accZ = 0,
    this.roll = 0,
    this.pitch = 0,
    this.yaw = 0,
    this.gravityX = 0,
    this.gravityY = 0,
    this.gravityZ = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    this.userAccX = 0,
    this.userAccY = 0,
    this.userAccZ = 0,
  });

  /// Create an [AppleWatchMotion] from an AWARE `ios_watch_motion` record.
  AppleWatchMotion.fromRecord(super.record)
    : accX = _double(record, 'accX'),
      accY = _double(record, 'accY'),
      accZ = _double(record, 'accZ'),
      roll = _double(record, 'roll'),
      pitch = _double(record, 'pitch'),
      yaw = _double(record, 'yaw'),
      gravityX = _double(record, 'gravityX'),
      gravityY = _double(record, 'gravityY'),
      gravityZ = _double(record, 'gravityZ'),
      rotationX = _double(record, 'rotationX'),
      rotationY = _double(record, 'rotationY'),
      rotationZ = _double(record, 'rotationZ'),
      userAccX = _double(record, 'userAccX'),
      userAccY = _double(record, 'userAccY'),
      userAccZ = _double(record, 'userAccZ'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchMotionFromJson;
  factory AppleWatchMotion.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchMotion>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchMotionToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.MOTION;

  @override
  String toString() =>
      '${super.toString()}, acc: [$accX,$accY,$accZ], '
      'attitude: [$roll,$pitch,$yaw]';
}

/// Heart rate data from the Apple Watch, sampled via HealthKit.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchHeartRate extends AppleWatchData {
  /// Heart rate in beats per minute (BPM).
  double hr;

  AppleWatchHeartRate({
    super.deviceId,
    super.timestamp,
    super.label,
    this.hr = 0,
  });

  /// Create an [AppleWatchHeartRate] from an AWARE `ios_watch_heart_rate` record.
  AppleWatchHeartRate.fromRecord(super.record)
    : hr = _double(record, 'hr'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchHeartRateFromJson;
  factory AppleWatchHeartRate.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchHeartRate>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchHeartRateToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.HEART_RATE;

  @override
  String toString() => '${super.toString()}, hr: $hr';
}

/// Battery data from the Apple Watch.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchBattery extends AppleWatchData {
  /// The battery level of the watch in percent (0-100).
  ///
  /// Note that watchOS reports the battery level in steps of 5%.
  /// Is -1 if the level is unknown, e.g., when battery monitoring is disabled.
  int batteryLevel;

  /// The charging state of the watch battery.
  WatchBatteryState batteryState;

  AppleWatchBattery({
    super.deviceId,
    super.timestamp,
    super.label,
    this.batteryLevel = -1,
    this.batteryState = WatchBatteryState.unknown,
  });

  /// Create an [AppleWatchBattery] from an AWARE `ios_watch_battery` record.
  ///
  /// Note that AWARE stores the battery level as a fraction (0.0-1.0), which is
  /// converted to percent (0-100) here.
  AppleWatchBattery.fromRecord(super.record)
    : batteryLevel = _batteryLevel(_double(record, 'batteryLevel', -1)),
      batteryState = _batteryState(_optionalInt(record, 'batteryState')),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchBatteryFromJson;
  factory AppleWatchBattery.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchBattery>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchBatteryToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.BATTERY;

  @override
  String toString() =>
      '${super.toString()}, batteryLevel: $batteryLevel, '
      'batteryState: ${batteryState.name}';
}

/// Location data from the Apple Watch.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchLocation extends AppleWatchData {
  /// Latitude in decimal degrees.
  double latitude;

  /// Longitude in decimal degrees.
  double longitude;

  /// Altitude in meters above mean sea level.
  double altitude;

  /// Altitude in meters above the WGS 84 reference ellipsoid.
  double ellipsoidalAltitude;

  /// Horizontal accuracy (radius of uncertainty) in meters.
  double horizontalAccuracy;

  /// Vertical accuracy in meters.
  double verticalAccuracy;

  /// Instantaneous speed in meters per second.
  double speed;

  /// Accuracy of [speed] in meters per second.
  double speedAccuracy;

  /// Direction of travel in degrees relative to true north.
  double course;

  /// Accuracy of [course] in degrees.
  double courseAccuracy;

  AppleWatchLocation({
    super.deviceId,
    super.timestamp,
    super.label,
    this.latitude = 0,
    this.longitude = 0,
    this.altitude = 0,
    this.ellipsoidalAltitude = 0,
    this.horizontalAccuracy = 0,
    this.verticalAccuracy = 0,
    this.speed = 0,
    this.speedAccuracy = 0,
    this.course = 0,
    this.courseAccuracy = 0,
  });

  /// Create an [AppleWatchLocation] from an AWARE `ios_watch_location` record.
  AppleWatchLocation.fromRecord(super.record)
    : latitude = _double(record, 'latitude'),
      longitude = _double(record, 'longitude'),
      altitude = _double(record, 'altitude'),
      ellipsoidalAltitude = _double(record, 'ellipsoidalAltitude'),
      horizontalAccuracy = _double(record, 'horizontalAccuracy'),
      verticalAccuracy = _double(record, 'verticalAccuracy'),
      speed = _double(record, 'speed'),
      speedAccuracy = _double(record, 'speedAccuracy'),
      course = _double(record, 'course'),
      courseAccuracy = _double(record, 'courseAccuracy'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchLocationFromJson;
  factory AppleWatchLocation.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchLocation>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchLocationToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.LOCATION;

  @override
  String toString() =>
      '${super.toString()}, latitude: $latitude, longitude: $longitude';
}

/// Compass heading data from the Apple Watch.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchHeading extends AppleWatchData {
  /// Heading in degrees relative to true north.
  double trueHeading;

  /// Heading in degrees relative to magnetic north.
  double magneticHeading;

  /// Maximum deviation of the reported heading in degrees.
  double headingAccuracy;

  /// Geomagnetic data for the x-axis in microteslas.
  double x;

  /// Geomagnetic data for the y-axis in microteslas.
  double y;

  /// Geomagnetic data for the z-axis in microteslas.
  double z;

  AppleWatchHeading({
    super.deviceId,
    super.timestamp,
    super.label,
    this.trueHeading = 0,
    this.magneticHeading = 0,
    this.headingAccuracy = 0,
    this.x = 0,
    this.y = 0,
    this.z = 0,
  });

  /// Create an [AppleWatchHeading] from an AWARE `ios_watch_heading` record.
  AppleWatchHeading.fromRecord(super.record)
    : trueHeading = _double(record, 'trueHeading'),
      magneticHeading = _double(record, 'magneticHeading'),
      headingAccuracy = _double(record, 'headingAccuracy'),
      x = _double(record, 'x'),
      y = _double(record, 'y'),
      z = _double(record, 'z'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchHeadingFromJson;
  factory AppleWatchHeading.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchHeading>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchHeadingToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.HEADING;

  @override
  String toString() => '${super.toString()}, trueHeading: $trueHeading';
}

/// A Bluetooth device scanned by the Apple Watch.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchBluetooth extends AppleWatchData {
  /// The identifier of the scanned Bluetooth device.
  ///
  /// On Apple platforms this is a UUID generated per app installation, and not
  /// the MAC address of the device.
  String identifier;

  /// The advertised name of the scanned Bluetooth device, if any.
  String name;

  /// The Received Signal Strength Indicator (RSSI) in dBm.
  double rssi;

  AppleWatchBluetooth({
    super.deviceId,
    super.timestamp,
    super.label,
    this.identifier = '',
    this.name = '',
    this.rssi = 0,
  });

  /// Create an [AppleWatchBluetooth] from an AWARE `ios_watch_bluetooth` record.
  AppleWatchBluetooth.fromRecord(super.record)
    : identifier = _string(record, 'identifier') ?? '',
      name = _string(record, 'name') ?? '',
      rssi = _double(record, 'rssi'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchBluetoothFromJson;
  factory AppleWatchBluetooth.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchBluetooth>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchBluetoothToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.BLUETOOTH;

  @override
  String toString() =>
      '${super.toString()}, identifier: $identifier, name: $name, rssi: $rssi';
}

/// Ambient noise level measured by the microphone of the Apple Watch.
///
/// Note that no audio is stored - only the sound pressure level.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchAmbientNoise extends AppleWatchData {
  /// The sound pressure level in decibel (dB).
  double decibel;

  AppleWatchAmbientNoise({
    super.deviceId,
    super.timestamp,
    super.label,
    this.decibel = 0,
  });

  /// Create an [AppleWatchAmbientNoise] from an AWARE `ios_watch_ambient_noise`
  /// record. Note that AWARE names the decibel column `db`.
  AppleWatchAmbientNoise.fromRecord(super.record)
    : decibel = _double(record, 'db'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchAmbientNoiseFromJson;
  factory AppleWatchAmbientNoise.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchAmbientNoise>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchAmbientNoiseToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.AMBIENT_NOISE;

  @override
  String toString() => '${super.toString()}, decibel: $decibel';
}

/// A sound classification made by the Apple Watch using
/// [SoundAnalysis](https://developer.apple.com/documentation/soundanalysis).
///
/// Note that no audio is stored - only the classification label.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchAudioLabel extends AppleWatchData {
  /// The identifier of the classified sound, e.g. `speech` or `laughter`.
  String audioLabel;

  /// The confidence of the classification in the range [0.0; 1.0].
  double confidence;

  AppleWatchAudioLabel({
    super.deviceId,
    super.timestamp,
    super.label,
    this.audioLabel = '',
    this.confidence = 0,
  });

  /// Create an [AppleWatchAudioLabel] from an AWARE `ios_watch_audio_label` record.
  AppleWatchAudioLabel.fromRecord(super.record)
    : audioLabel = _string(record, 'audioLabel') ?? '',
      confidence = _double(record, 'confidence'),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchAudioLabelFromJson;
  factory AppleWatchAudioLabel.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchAudioLabel>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchAudioLabelToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.AUDIO_LABEL;

  @override
  String toString() =>
      '${super.toString()}, audioLabel: $audioLabel, confidence: $confidence';
}

/// Information on the Apple Watch itself and the iPhone it is paired with.
///
/// This data is collected once every time data collection is started on the
/// watch, and is what links the AWARE device id of the watch to the AWARE
/// device id of the phone.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchDeviceInfo extends AppleWatchData {
  /// The AWARE device id of the iPhone this watch is paired with.
  String pairedIosDeviceId;

  /// The name of the watch, as set by the user.
  String? name;

  /// The model of the watch, e.g. `Apple Watch`.
  String? model;

  /// The name of the operating system of the watch, e.g. `Watch OS`.
  String? systemName;

  /// The version of the operating system of the watch, e.g. `11.2`.
  String? systemVersion;

  /// The preferred content size category (i.e., dynamic type setting) on the watch.
  String? preferredContentSizeCategory;

  AppleWatchDeviceInfo({
    super.deviceId,
    super.timestamp,
    super.label,
    this.pairedIosDeviceId = '',
    this.name,
    this.model,
    this.systemName,
    this.systemVersion,
    this.preferredContentSizeCategory,
  });

  /// Create an [AppleWatchDeviceInfo] from an AWARE `ios_watch_device` record.
  AppleWatchDeviceInfo.fromRecord(super.record)
    : pairedIosDeviceId = _string(record, 'pairedIosDeviceId') ?? '',
      name = _string(record, 'name'),
      model = _string(record, 'model'),
      systemName = _string(record, 'systemName'),
      systemVersion = _string(record, 'systemVersion'),
      preferredContentSizeCategory = _string(
        record,
        'preferredContentSizeCategory',
      ),
      super.fromRecord();

  @override
  Function get fromJsonFunction => _$AppleWatchDeviceInfoFromJson;
  factory AppleWatchDeviceInfo.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchDeviceInfo>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchDeviceInfoToJson(this);

  @override
  String get jsonType => AppleWatchSamplingPackage.DEVICE;

  @override
  String toString() =>
      '${super.toString()}, model: $model, systemVersion: $systemVersion, '
      'pairedIosDeviceId: $pairedIosDeviceId';
}

// ---------------------------------------------------------------------------
//    HELPER METHODS FOR PARSING AWARE RECORDS
//
// Records arrive from the native side as plist-bridged JSON, where a numeric
// value can be an int or a double depending on how it was serialized on the
// watch. Hence, all values are parsed defensively.
// ---------------------------------------------------------------------------

double _double(Map<String, dynamic> record, String key, [double orElse = 0]) {
  final value = record[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? orElse;
  return orElse;
}

int? _optionalInt(Map<String, dynamic> record, String key) {
  final value = record[key];
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _string(Map<String, dynamic> record, String key) {
  final value = record[key];
  if (value == null) return null;
  final string = value is String ? value : value.toString();
  return string.isEmpty ? null : string;
}

/// AWARE stores the timestamp as milliseconds since epoch (UTC).
DateTime _timestamp(Map<String, dynamic> record, String key) {
  final milliseconds = _optionalInt(record, key);
  return (milliseconds == null || milliseconds <= 0)
      ? DateTime.now().toUtc()
      : DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

/// WatchKit reports the battery level as a fraction in the range [0.0; 1.0],
/// or as -1 if unknown. CARP uses percent (0-100).
int _batteryLevel(double level) =>
    (level < 0) ? -1 : (level * 100).round().clamp(0, 100);

WatchBatteryState _batteryState(int? state) =>
    (state == null || state < 0 || state >= WatchBatteryState.values.length)
    ? WatchBatteryState.unknown
    : WatchBatteryState.values[state];
