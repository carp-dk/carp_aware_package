import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_aware_package/carp_aware_package.dart';

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  late SmartphoneStudyProtocol protocol;
  late Smartphone phone;
  late AppleWatchDevice watch;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUpAll(() {
    CarpMobileSensing.ensureInitialized();

    // register the Apple Watch sampling package
    SamplingPackageRegistry().register(AppleWatchSamplingPackage());

    // Initialization of serialization
    CarpMobileSensing();

    // Create a new study protocol.
    protocol =
        SmartphoneStudyProtocol(
            ownerId: 'alex@uni.dk',
            name: 'Apple Watch package test',
          )
          ..description =
              'Testing the Apple Watch sampling package with a simple study protocol.';

    // Define which devices are used for data collection.
    phone = Smartphone(roleName: 'iPhone 16');
    watch = AppleWatchDevice(
      roleName: 'Apple Watch',
      motionSamplingRate: 25,
      heartRateEnabled: true,
      audioEnabled: true,
      fileTransferInterval: const Duration(minutes: 10),
    );

    protocol
      ..addPrimaryDevice(phone)
      ..addConnectedDevice(watch, phone);

    // Add a background task that collects everything the watch can sample.
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..measures = AppleWatchSamplingPackage().dataTypes
            .map((type) => Measure(type: type.type))
            .toList(),
      watch,
    );
  });

  test('SmartphoneStudyProtocol -> JSON', () async {
    print(protocol);
    print(toJsonString(protocol));
    expect(protocol.ownerId, 'alex@uni.dk');
    await writeToFile(toJsonString(protocol), 'protocol.json');
  });

  test('StudyProtocol -> JSON -> StudyProtocol :: deep assert', () async {
    final studyJson = toJsonString(protocol);
    final protocolFromJson = SmartphoneStudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), studyJson);
  });

  test('JSON File -> StudyProtocol', () async {
    final plainJson = File('test/json/protocol.json').readAsStringSync();

    final protocol = StudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    expect(protocol.ownerId, 'alex@uni.dk');
    expect(protocol.primaryDevice.roleName, phone.roleName);
    expect(protocol.connectedDevices?.first.roleName, watch.roleName);

    final watchFromJson = protocol.connectedDevices?.first as AppleWatchDevice;
    expect(watchFromJson.motionSamplingRate, 25);
    expect(watchFromJson.fileTransferInterval, const Duration(minutes: 10));
    expect(
      watchFromJson.backgroundSessionType,
      WatchBackgroundSessionType.microphone,
    );
  });

  test('Config types', () async {
    final allConfigurations = [
      AppleWatchDevice(
        roleName: 'Apple Watch',
        label: 'study-1',
        locationEnabled: true,
        transferMode: WatchTransferMode.all,
        backgroundSessionType: WatchBackgroundSessionType.workout,
      ),
      AppleWatchDeviceRegistration(
        deviceId: '9C4A1E2B',
        watchDeviceId: '9C4A1E2B',
        model: 'Apple Watch',
        systemVersion: '11.2',
        isWatchAppInstalled: true,
      ),
    ];

    for (var configuration in allConfigurations) {
      final configurationJson = toJsonString(configuration);
      final configurationFromJson = Function.apply(
        configuration.fromJsonFunction,
        [json.decode(configurationJson) as Map<String, dynamic>],
      );
      print(toJsonString(configurationFromJson));
      expect(toJsonString(configurationFromJson), equals(configurationJson));
    }
  });

  test('Data types', () async {
    final timestamp = DateTime.parse('2026-08-17T12:00:00.000Z');
    final allData = <AppleWatchData>[
      AppleWatchMotion(
        deviceId: 'watch-1',
        timestamp: timestamp,
        accX: 0.1,
        accY: -0.2,
        accZ: 0.98,
      ),
      AppleWatchHeartRate(deviceId: 'watch-1', timestamp: timestamp, hr: 72),
      AppleWatchBattery(
        deviceId: 'watch-1',
        timestamp: timestamp,
        batteryLevel: 65,
        batteryState: WatchBatteryState.unplugged,
      ),
      AppleWatchLocation(
        deviceId: 'watch-1',
        timestamp: timestamp,
        latitude: 55.786,
        longitude: 12.523,
      ),
      AppleWatchHeading(
        deviceId: 'watch-1',
        timestamp: timestamp,
        trueHeading: 180,
      ),
      AppleWatchBluetooth(
        deviceId: 'watch-1',
        timestamp: timestamp,
        identifier: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0',
        name: 'Some BLE device',
        rssi: -67,
      ),
      AppleWatchAmbientNoise(
        deviceId: 'watch-1',
        timestamp: timestamp,
        decibel: -32.5,
      ),
      AppleWatchAudioLabel(
        deviceId: 'watch-1',
        timestamp: timestamp,
        audioLabel: 'speech',
        confidence: 0.87,
      ),
      AppleWatchDeviceInfo(
        deviceId: 'watch-1',
        timestamp: timestamp,
        pairedIosDeviceId: 'phone-1',
        model: 'Apple Watch',
        systemVersion: '11.2',
      ),
    ];

    for (var data in allData) {
      final dataJson = toJsonString(data);
      final dataFromJson = Function.apply(data.fromJsonFunction, [
        json.decode(dataJson) as Map<String, dynamic>,
      ]);
      print(toJsonString(dataFromJson));
      expect(toJsonString(dataFromJson), equals(dataJson));
    }
  });

  test('Measurement -> JSON', () async {
    final data = AppleWatchHeartRate(deviceId: 'watch-1', hr: 68);
    final measurement = Measurement.fromData(data);

    expect(
      measurement.data.dataType.namespace,
      AppleWatchSamplingPackage.APPLE_WATCH_NAMESPACE,
    );
    expect(
      measurement.dataType.toString(),
      AppleWatchSamplingPackage.HEART_RATE,
    );

    print(_encode(measurement.toJson()));
  });

  test('AWARE record -> Data', () async {
    // A record as it arrives from the AWARE watchOS framework - note that the
    // timestamp is in milliseconds and that numbers may be int or double.
    final record = <String, dynamic>{
      'id': 42,
      'deviceId': '9C4A1E2B-1234',
      'timestamp': 1755432000000,
      'label': 'study-1',
      'accX': 0.0125,
      'accY': -1,
      'accZ': 0.98,
      'roll': 0.1,
      'pitch': 0.2,
      'yaw': 0.3,
      'gravityX': 0,
      'gravityY': 0,
      'gravityZ': -1,
      'rotationX': 0.01,
      'rotationY': 0.02,
      'rotationZ': 0.03,
      'userAccX': 0.001,
      'userAccY': 0.002,
      'userAccZ': 0.003,
      'os': 'watchOS',
      'timezone': 120,
      'jsonVersion': 1,
    };

    final motion = AppleWatchMotion.fromRecord(record);

    expect(motion.deviceId, '9C4A1E2B-1234');
    expect(motion.label, 'study-1');
    expect(motion.timestamp.millisecondsSinceEpoch, 1755432000000);
    expect(motion.timestamp.isUtc, true);
    expect(motion.accX, 0.0125);
    // an int in the record must still parse into a double field
    expect(motion.accY, -1.0);
    expect(
      motion.recordId,
      '9C4A1E2B-1234/${AppleWatchSamplingPackage.MOTION}/42',
    );

    print(toJsonString(motion));
  });

  test('AWARE battery record -> Data', () async {
    // AWARE reports the battery level as a fraction and the state as an int.
    final battery = AppleWatchBattery.fromRecord(<String, dynamic>{
      'id': 7,
      'timestamp': 1755432000000,
      'batteryLevel': 0.65,
      'batteryState': 2,
    });

    expect(battery.batteryLevel, 65);
    expect(battery.batteryState, WatchBatteryState.charging);
  });

  test('Sparse and malformed records do not throw', () async {
    final noise = AppleWatchAmbientNoise.fromRecord(<String, dynamic>{});
    expect(noise.decibel, 0);
    expect(noise.deviceId, isNull);
    expect(noise.recordId, isNull);

    final label = AppleWatchAudioLabel.fromRecord(<String, dynamic>{
      'timestamp': 'not-a-number',
      'confidence': '0.5',
      'audioLabel': 'speech',
    });
    expect(label.confidence, 0.5);
    expect(label.audioLabel, 'speech');
  });

  test('Watch settings', () async {
    final settings = watch.toWatchSettings();

    expect(settings['motion_sensor_hz'], 25);
    expect(settings['file_transfer_interval_seconds'], 600.0);
    expect(settings['watch_healthkit_enabled'], true);
    expect(settings['watch_audio_enabled'], true);
    expect(settings['watch_location_enabled'], false);
    expect(settings['watch_background_session_type'], 'microphone');
    expect(settings['watch_transfer_mode'], 'incremental');
    expect(settings['watch_delete_after_transfer'], true);

    print(_encode(settings));
  });

  test('Sampling package', () async {
    final package = AppleWatchSamplingPackage();

    expect(package.deviceType, AppleWatchDevice.DEVICE_TYPE);
    expect(package.dataTypes.length, 9);
    for (var type in package.dataTypes) {
      expect(package.create(type.type), isNotNull);
    }
    expect(package.create('dk.carp.watch.aware.unknown'), isNull);
  });
}
