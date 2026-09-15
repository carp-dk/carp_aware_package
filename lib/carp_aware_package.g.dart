// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carp_aware_package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppleWatchDevice _$AppleWatchDeviceFromJson(Map<String, dynamic> json) =>
    AppleWatchDevice(
        roleName:
            json['roleName'] as String? ?? AppleWatchDevice.DEFAULT_ROLE_NAME,
        isOptional: json['isOptional'] as bool? ?? true,
        label: json['label'] as String?,
        awareServerUrl: json['awareServerUrl'] as String?,
        motionSamplingRate: (json['motionSamplingRate'] as num?)?.toInt() ?? 10,
        accelerometerEnabled: json['accelerometerEnabled'] as bool? ?? true,
        deviceMotionEnabled: json['deviceMotionEnabled'] as bool? ?? true,
        motionEnabled: json['motionEnabled'] as bool? ?? true,
        batteryEnabled: json['batteryEnabled'] as bool? ?? true,
        deviceInfoEnabled: json['deviceInfoEnabled'] as bool? ?? true,
        heartRateEnabled: json['heartRateEnabled'] as bool? ?? true,
        locationEnabled: json['locationEnabled'] as bool? ?? false,
        headingEnabled: json['headingEnabled'] as bool? ?? false,
        bluetoothEnabled: json['bluetoothEnabled'] as bool? ?? false,
        audioEnabled: json['audioEnabled'] as bool? ?? false,
        ambientNoiseEnabled: json['ambientNoiseEnabled'] as bool? ?? true,
        audioClassificationEnabled:
            json['audioClassificationEnabled'] as bool? ?? true,
        audioDutyCycleEnabled: json['audioDutyCycleEnabled'] as bool? ?? true,
        audioActiveDuration: json['audioActiveDuration'] == null
            ? const Duration(minutes: 1)
            : Duration(
                microseconds: (json['audioActiveDuration'] as num).toInt(),
              ),
        audioRestDuration: json['audioRestDuration'] == null
            ? const Duration(minutes: 3)
            : Duration(
                microseconds: (json['audioRestDuration'] as num).toInt(),
              ),
        fileTransferInterval: json['fileTransferInterval'] == null
            ? const Duration(minutes: 15)
            : Duration(
                microseconds: (json['fileTransferInterval'] as num).toInt(),
              ),
        transferMode:
            $enumDecodeNullable(
              _$WatchTransferModeEnumMap,
              json['transferMode'],
            ) ??
            WatchTransferMode.incremental,
        deleteAfterTransfer: json['deleteAfterTransfer'] as bool? ?? true,
        backgroundSessionType:
            $enumDecodeNullable(
              _$WatchBackgroundSessionTypeEnumMap,
              json['backgroundSessionType'],
            ) ??
            WatchBackgroundSessionType.microphone,
        saveToLocalAwareDatabase:
            json['saveToLocalAwareDatabase'] as bool? ?? false,
        enableNativeLogging: json['enableNativeLogging'] as bool? ?? false,
      )
      ..$type = json['__type'] as String?
      ..defaultSamplingConfiguration =
          (json['defaultSamplingConfiguration'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              SamplingConfiguration.fromJson(e as Map<String, dynamic>),
            ),
          );

Map<String, dynamic> _$AppleWatchDeviceToJson(AppleWatchDevice instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'roleName': instance.roleName,
      'isOptional': ?instance.isOptional,
      'defaultSamplingConfiguration': ?instance.defaultSamplingConfiguration,
      'label': ?instance.label,
      'awareServerUrl': ?instance.awareServerUrl,
      'motionSamplingRate': instance.motionSamplingRate,
      'accelerometerEnabled': instance.accelerometerEnabled,
      'deviceMotionEnabled': instance.deviceMotionEnabled,
      'motionEnabled': instance.motionEnabled,
      'batteryEnabled': instance.batteryEnabled,
      'deviceInfoEnabled': instance.deviceInfoEnabled,
      'heartRateEnabled': instance.heartRateEnabled,
      'locationEnabled': instance.locationEnabled,
      'headingEnabled': instance.headingEnabled,
      'bluetoothEnabled': instance.bluetoothEnabled,
      'audioEnabled': instance.audioEnabled,
      'ambientNoiseEnabled': instance.ambientNoiseEnabled,
      'audioClassificationEnabled': instance.audioClassificationEnabled,
      'audioDutyCycleEnabled': instance.audioDutyCycleEnabled,
      'audioActiveDuration': instance.audioActiveDuration.inMicroseconds,
      'audioRestDuration': instance.audioRestDuration.inMicroseconds,
      'fileTransferInterval': instance.fileTransferInterval.inMicroseconds,
      'transferMode': _$WatchTransferModeEnumMap[instance.transferMode]!,
      'deleteAfterTransfer': instance.deleteAfterTransfer,
      'backgroundSessionType':
          _$WatchBackgroundSessionTypeEnumMap[instance.backgroundSessionType]!,
      'saveToLocalAwareDatabase': instance.saveToLocalAwareDatabase,
      'enableNativeLogging': instance.enableNativeLogging,
    };

const _$WatchTransferModeEnumMap = {
  WatchTransferMode.all: 'all',
  WatchTransferMode.incremental: 'incremental',
};

const _$WatchBackgroundSessionTypeEnumMap = {
  WatchBackgroundSessionType.none: 'none',
  WatchBackgroundSessionType.workout: 'workout',
  WatchBackgroundSessionType.microphone: 'microphone',
};

AppleWatchDeviceRegistration _$AppleWatchDeviceRegistrationFromJson(
  Map<String, dynamic> json,
) => AppleWatchDeviceRegistration(
  deviceId: json['deviceId'] as String?,
  deviceDisplayName: json['deviceDisplayName'] as String?,
  registrationCreatedOn: json['registrationCreatedOn'] == null
      ? null
      : DateTime.parse(json['registrationCreatedOn'] as String),
  isConnected: json['isConnected'] as bool? ?? false,
  batteryChargingState:
      $enumDecodeNullable(
        _$BatteryChargingStateEnumMap,
        json['batteryChargingState'],
      ) ??
      BatteryChargingState.unknown,
  hardwareName: json['hardwareName'] as String?,
  watchDeviceId: json['watchDeviceId'] as String?,
  model: json['model'] as String?,
  systemVersion: json['systemVersion'] as String?,
  isWatchAppInstalled: json['isWatchAppInstalled'] as bool? ?? false,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchDeviceRegistrationToJson(
  AppleWatchDeviceRegistration instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': instance.deviceId,
  'deviceDisplayName': ?instance.deviceDisplayName,
  'registrationCreatedOn': instance.registrationCreatedOn.toIso8601String(),
  'isConnected': instance.isConnected,
  'batteryChargingState':
      _$BatteryChargingStateEnumMap[instance.batteryChargingState]!,
  'hardwareName': ?instance.hardwareName,
  'watchDeviceId': ?instance.watchDeviceId,
  'model': ?instance.model,
  'systemVersion': ?instance.systemVersion,
  'isWatchAppInstalled': instance.isWatchAppInstalled,
};

const _$BatteryChargingStateEnumMap = {
  BatteryChargingState.unknown: 'unknown',
  BatteryChargingState.full: 'full',
  BatteryChargingState.normal: 'normal',
  BatteryChargingState.low: 'low',
  BatteryChargingState.critical: 'critical',
};

AppleWatchMotion _$AppleWatchMotionFromJson(Map<String, dynamic> json) =>
    AppleWatchMotion(
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
      accX: (json['accX'] as num?)?.toDouble() ?? 0,
      accY: (json['accY'] as num?)?.toDouble() ?? 0,
      accZ: (json['accZ'] as num?)?.toDouble() ?? 0,
      roll: (json['roll'] as num?)?.toDouble() ?? 0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0,
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0,
      gravityX: (json['gravityX'] as num?)?.toDouble() ?? 0,
      gravityY: (json['gravityY'] as num?)?.toDouble() ?? 0,
      gravityZ: (json['gravityZ'] as num?)?.toDouble() ?? 0,
      rotationX: (json['rotationX'] as num?)?.toDouble() ?? 0,
      rotationY: (json['rotationY'] as num?)?.toDouble() ?? 0,
      rotationZ: (json['rotationZ'] as num?)?.toDouble() ?? 0,
      userAccX: (json['userAccX'] as num?)?.toDouble() ?? 0,
      userAccY: (json['userAccY'] as num?)?.toDouble() ?? 0,
      userAccZ: (json['userAccZ'] as num?)?.toDouble() ?? 0,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchMotionToJson(AppleWatchMotion instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'deviceId': ?instance.deviceId,
      'timestamp': instance.timestamp.toIso8601String(),
      'label': ?instance.label,
      'accX': instance.accX,
      'accY': instance.accY,
      'accZ': instance.accZ,
      'roll': instance.roll,
      'pitch': instance.pitch,
      'yaw': instance.yaw,
      'gravityX': instance.gravityX,
      'gravityY': instance.gravityY,
      'gravityZ': instance.gravityZ,
      'rotationX': instance.rotationX,
      'rotationY': instance.rotationY,
      'rotationZ': instance.rotationZ,
      'userAccX': instance.userAccX,
      'userAccY': instance.userAccY,
      'userAccZ': instance.userAccZ,
    };

AppleWatchHeartRate _$AppleWatchHeartRateFromJson(Map<String, dynamic> json) =>
    AppleWatchHeartRate(
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
      hr: (json['hr'] as num?)?.toDouble() ?? 0,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchHeartRateToJson(
  AppleWatchHeartRate instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': ?instance.deviceId,
  'timestamp': instance.timestamp.toIso8601String(),
  'label': ?instance.label,
  'hr': instance.hr,
};

AppleWatchBattery _$AppleWatchBatteryFromJson(Map<String, dynamic> json) =>
    AppleWatchBattery(
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
      batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? -1,
      batteryState:
          $enumDecodeNullable(
            _$WatchBatteryStateEnumMap,
            json['batteryState'],
          ) ??
          WatchBatteryState.unknown,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchBatteryToJson(AppleWatchBattery instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'deviceId': ?instance.deviceId,
      'timestamp': instance.timestamp.toIso8601String(),
      'label': ?instance.label,
      'batteryLevel': instance.batteryLevel,
      'batteryState': _$WatchBatteryStateEnumMap[instance.batteryState]!,
    };

const _$WatchBatteryStateEnumMap = {
  WatchBatteryState.unknown: 'unknown',
  WatchBatteryState.unplugged: 'unplugged',
  WatchBatteryState.charging: 'charging',
  WatchBatteryState.full: 'full',
};

AppleWatchLocation _$AppleWatchLocationFromJson(Map<String, dynamic> json) =>
    AppleWatchLocation(
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
      ellipsoidalAltitude:
          (json['ellipsoidalAltitude'] as num?)?.toDouble() ?? 0,
      horizontalAccuracy: (json['horizontalAccuracy'] as num?)?.toDouble() ?? 0,
      verticalAccuracy: (json['verticalAccuracy'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      speedAccuracy: (json['speedAccuracy'] as num?)?.toDouble() ?? 0,
      course: (json['course'] as num?)?.toDouble() ?? 0,
      courseAccuracy: (json['courseAccuracy'] as num?)?.toDouble() ?? 0,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchLocationToJson(AppleWatchLocation instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'deviceId': ?instance.deviceId,
      'timestamp': instance.timestamp.toIso8601String(),
      'label': ?instance.label,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'ellipsoidalAltitude': instance.ellipsoidalAltitude,
      'horizontalAccuracy': instance.horizontalAccuracy,
      'verticalAccuracy': instance.verticalAccuracy,
      'speed': instance.speed,
      'speedAccuracy': instance.speedAccuracy,
      'course': instance.course,
      'courseAccuracy': instance.courseAccuracy,
    };

AppleWatchHeading _$AppleWatchHeadingFromJson(Map<String, dynamic> json) =>
    AppleWatchHeading(
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
      trueHeading: (json['trueHeading'] as num?)?.toDouble() ?? 0,
      magneticHeading: (json['magneticHeading'] as num?)?.toDouble() ?? 0,
      headingAccuracy: (json['headingAccuracy'] as num?)?.toDouble() ?? 0,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      z: (json['z'] as num?)?.toDouble() ?? 0,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchHeadingToJson(AppleWatchHeading instance) =>
    <String, dynamic>{
      '__type': ?instance.$type,
      'deviceId': ?instance.deviceId,
      'timestamp': instance.timestamp.toIso8601String(),
      'label': ?instance.label,
      'trueHeading': instance.trueHeading,
      'magneticHeading': instance.magneticHeading,
      'headingAccuracy': instance.headingAccuracy,
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
    };

AppleWatchBluetooth _$AppleWatchBluetoothFromJson(Map<String, dynamic> json) =>
    AppleWatchBluetooth(
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
      identifier: json['identifier'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rssi: (json['rssi'] as num?)?.toDouble() ?? 0,
    )..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchBluetoothToJson(
  AppleWatchBluetooth instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': ?instance.deviceId,
  'timestamp': instance.timestamp.toIso8601String(),
  'label': ?instance.label,
  'identifier': instance.identifier,
  'name': instance.name,
  'rssi': instance.rssi,
};

AppleWatchAmbientNoise _$AppleWatchAmbientNoiseFromJson(
  Map<String, dynamic> json,
) => AppleWatchAmbientNoise(
  deviceId: json['deviceId'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  label: json['label'] as String?,
  decibel: (json['decibel'] as num?)?.toDouble() ?? 0,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchAmbientNoiseToJson(
  AppleWatchAmbientNoise instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': ?instance.deviceId,
  'timestamp': instance.timestamp.toIso8601String(),
  'label': ?instance.label,
  'decibel': instance.decibel,
};

AppleWatchAudioLabel _$AppleWatchAudioLabelFromJson(
  Map<String, dynamic> json,
) => AppleWatchAudioLabel(
  deviceId: json['deviceId'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  label: json['label'] as String?,
  audioLabel: json['audioLabel'] as String? ?? '',
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchAudioLabelToJson(
  AppleWatchAudioLabel instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': ?instance.deviceId,
  'timestamp': instance.timestamp.toIso8601String(),
  'label': ?instance.label,
  'audioLabel': instance.audioLabel,
  'confidence': instance.confidence,
};

AppleWatchDeviceInfo _$AppleWatchDeviceInfoFromJson(
  Map<String, dynamic> json,
) => AppleWatchDeviceInfo(
  deviceId: json['deviceId'] as String?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  label: json['label'] as String?,
  pairedIosDeviceId: json['pairedIosDeviceId'] as String? ?? '',
  name: json['name'] as String?,
  model: json['model'] as String?,
  systemName: json['systemName'] as String?,
  systemVersion: json['systemVersion'] as String?,
  preferredContentSizeCategory: json['preferredContentSizeCategory'] as String?,
)..$type = json['__type'] as String?;

Map<String, dynamic> _$AppleWatchDeviceInfoToJson(
  AppleWatchDeviceInfo instance,
) => <String, dynamic>{
  '__type': ?instance.$type,
  'deviceId': ?instance.deviceId,
  'timestamp': instance.timestamp.toIso8601String(),
  'label': ?instance.label,
  'pairedIosDeviceId': instance.pairedIosDeviceId,
  'name': ?instance.name,
  'model': ?instance.model,
  'systemName': ?instance.systemName,
  'systemVersion': ?instance.systemVersion,
  'preferredContentSizeCategory': ?instance.preferredContentSizeCategory,
};
