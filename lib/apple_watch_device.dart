/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_aware_package.dart';

/// The runtime session the watch app uses to keep running when it is not in
/// the foreground.
///
/// watchOS suspends an app shortly after the wrist is lowered unless the app
/// holds a background runtime session. This is what makes continuous passive
/// sensing on the watch possible.
enum WatchBackgroundSessionType {
  /// Do not start a background session.
  ///
  /// Data is only collected while the watch app is in the foreground. Use this
  /// only for short, supervised data collection.
  none,

  /// Start an `HKWorkoutSession` with the activity type `other`.
  ///
  /// Gives the longest and most reliable background runtime, but the session
  /// shows up as a workout in the Apple fitness apps, and closes the activity
  /// rings differently. Do not use this if the study must not leave workout
  /// history on the participant's watch.
  workout,

  /// Start a silent microphone capture session.
  ///
  /// Gives background runtime without registering a workout. No audio is stored
  /// unless the audio sensor itself is enabled. Requires microphone permission
  /// and the `audio` background mode on the watch app.
  microphone,
}

/// Which records the watch includes when it transfers data to the phone.
enum WatchTransferMode {
  /// Transfer every record in the database on the watch on every transfer.
  ///
  /// Records that have been transferred before are sent again. This package
  /// discards duplicates based on the record id (see [AppleWatchData.recordId]),
  /// so this mode is safe - but it uses more radio time and battery as the
  /// database on the watch grows.
  all,

  /// Transfer only records collected since the last successful transfer.
  ///
  /// The watch keeps a bookmark of the last record transferred. This is the
  /// efficient choice for long-running studies.
  incremental,
}

/// A [DeviceConfiguration] for an Apple Watch running the AWARE watchOS
/// companion app, used in a [StudyProtocol].
///
/// This configuration is the single source of truth for what the watch samples.
/// The settings are handed to the watch app over `WatchConnectivity` when the
/// watch app asks for them (`get_settings`), which it does on startup and
/// whenever it calls `AWWCSessionManager.shared.applyiPhoneSettings()`.
/// This means that a study protocol deployed from CARP Web Services fully
/// determines the behaviour of the watch app - no watch-side code change needed.
///
/// Note that a sensor being enabled here is a *request* to the watch app. The
/// watch app decides which sensors to actually start, and the participant may
/// deny the underlying permission (HealthKit, microphone, location) on the watch.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class AppleWatchDevice extends CamsDevice<AppleWatchDeviceRegistration> {
  /// The type of an Apple Watch device.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.AppleWatchDevice';

  /// The default role name for an Apple Watch device.
  static const String DEFAULT_ROLE_NAME = 'Apple Watch';

  /// An AWARE data label added to every record collected on the watch.
  ///
  /// Typically used to tag data with a study or participant identifier.
  String? label;

  /// An optional AWARE server URL (e.g. `https://my-server.org/index.php`) which
  /// the watch app can upload to directly, bypassing the phone.
  ///
  /// Leave this null in a normal CARP study - data collected on the watch is
  /// then transferred to the phone and uploaded by CARP Mobile Sensing along
  /// with all other data in the study.
  String? awareServerUrl;

  /// The sampling rate of the motion sensor in Hz. Default is 10 Hz.
  ///
  /// Note that a high rate drains the watch battery fast and generates a lot of
  /// data - 10 Hz is about 36.000 measurements pr. hour.
  int motionSamplingRate;

  /// Should the watch collect raw accelerometer data as part of the motion
  /// sensor? Default is true.
  bool accelerometerEnabled;

  /// Should the watch collect device motion (attitude, gravity, rotation rate,
  /// user acceleration) as part of the motion sensor? Default is true.
  bool deviceMotionEnabled;

  /// Should the watch collect motion data at all? Default is true.
  bool motionEnabled;

  /// Should the watch collect battery level and charging state? Default is true.
  bool batteryEnabled;

  /// Should the watch collect information about itself and the phone it is
  /// paired with? Default is true.
  ///
  /// This is what links the AWARE device id of the watch to the id of the phone,
  /// and is cheap to collect - keep it enabled unless you have a reason not to.
  bool deviceInfoEnabled;

  /// Should the watch collect heart rate via HealthKit? Default is true.
  ///
  /// Requires the HealthKit capability and permission on the watch app.
  bool heartRateEnabled;

  /// Should the watch collect location? Default is false.
  ///
  /// Requires location permission on the watch app. Note that location is one
  /// of the most battery-expensive sensors on the watch.
  bool locationEnabled;

  /// Should the watch collect compass heading? Default is false.
  bool headingEnabled;

  /// Should the watch scan for nearby Bluetooth devices? Default is false.
  bool bluetoothEnabled;

  /// Should the watch use the microphone at all? Default is false.
  ///
  /// This is the master switch for [ambientNoiseEnabled] and
  /// [audioClassificationEnabled]. Requires microphone permission on the watch
  /// app. No raw audio is ever transferred to the phone by this package.
  bool audioEnabled;

  /// Should the watch measure the ambient noise level in decibel? Default is true.
  /// Only used when [audioEnabled] is true.
  bool ambientNoiseEnabled;

  /// Should the watch classify sounds using Apple's
  /// [SoundAnalysis](https://developer.apple.com/documentation/soundanalysis)?
  /// Default is true. Only used when [audioEnabled] is true.
  bool audioClassificationEnabled;

  /// Should audio processing be duty-cycled? Default is true.
  ///
  /// When enabled, the watch alternates between an [audioActiveDuration] phase
  /// where audio is analyzed and an [audioRestDuration] phase where it is not.
  /// This cuts the CPU cost of audio sensing significantly.
  bool audioDutyCycleEnabled;

  /// The length of the active phase of the audio duty cycle. Default is 1 minute.
  Duration audioActiveDuration;

  /// The length of the resting phase of the audio duty cycle. Default is 3 minutes.
  Duration audioRestDuration;

  /// How often the watch should transfer its collected data to the phone.
  /// Default is 15 minutes.
  ///
  /// A short interval gives fresher data but wakes the radio more often. Note
  /// that this is a request to the watch app - the OS decides when a queued
  /// transfer is actually delivered.
  Duration fileTransferInterval;

  /// Which records the watch includes in a transfer.
  /// Default is [WatchTransferMode.incremental].
  WatchTransferMode transferMode;

  /// Should records be deleted from the database on the watch once they have
  /// been transferred to the phone? Default is true.
  ///
  /// Keeps storage use on the watch bounded. Set to false if you want the watch
  /// to keep a local copy as a backup - but then watch out for disk usage.
  bool deleteAfterTransfer;

  /// How the watch app keeps running in the background.
  /// Default is [WatchBackgroundSessionType.microphone].
  WatchBackgroundSessionType backgroundSessionType;

  /// Should the records received from the watch also be stored in the local
  /// AWARE database on the phone? Default is false.
  ///
  /// Only enable this if you also sync the phone-side AWARE database to an
  /// AWARE server. In a normal CARP study the records are handled by CARP
  /// Mobile Sensing and storing them twice just uses disk space.
  bool saveToLocalAwareDatabase;

  /// Should the native AWARE framework print verbose logs to the console?
  /// Default is false.
  bool enableNativeLogging;

  /// Create a new [AppleWatchDevice] configuration.
  ///
  /// If [roleName] is not specified, then [DEFAULT_ROLE_NAME] is used.
  AppleWatchDevice({
    super.roleName = AppleWatchDevice.DEFAULT_ROLE_NAME,
    super.isOptional = true,
    this.label,
    this.awareServerUrl,
    this.motionSamplingRate = 10,
    this.accelerometerEnabled = true,
    this.deviceMotionEnabled = true,
    this.motionEnabled = true,
    this.batteryEnabled = true,
    this.deviceInfoEnabled = true,
    this.heartRateEnabled = true,
    this.locationEnabled = false,
    this.headingEnabled = false,
    this.bluetoothEnabled = false,
    this.audioEnabled = false,
    this.ambientNoiseEnabled = true,
    this.audioClassificationEnabled = true,
    this.audioDutyCycleEnabled = true,
    this.audioActiveDuration = const Duration(minutes: 1),
    this.audioRestDuration = const Duration(minutes: 3),
    this.fileTransferInterval = const Duration(minutes: 15),
    this.transferMode = WatchTransferMode.incremental,
    this.deleteAfterTransfer = true,
    this.backgroundSessionType = WatchBackgroundSessionType.microphone,
    this.saveToLocalAwareDatabase = false,
    this.enableNativeLogging = false,
  });

  @override
  DataTypeSamplingSchemeMap? get dataTypeSamplingSchemes =>
      AppleWatchSamplingPackage.watchSamplingSchemes;

  /// This configuration as the settings dictionary handed to the watch app.
  ///
  /// The keys follow the naming used by the AWARE watchOS framework, so that a
  /// watch app written against the plain AWARE API can read them directly in
  /// `AWWCSessionManager.shared.applyiPhoneSettings { settings in ... }`.
  Map<String, dynamic> toWatchSettings() => {
    if (label != null) 'label': label,
    if (awareServerUrl != null) 'db_host': awareServerUrl,
    'debug': enableNativeLogging,
    'motion_sensor_hz': motionSamplingRate,
    'file_transfer_interval_seconds': fileTransferInterval.inSeconds.toDouble(),
    'watch_motion_enabled': motionEnabled,
    'watch_motion_accelerometer_enabled': accelerometerEnabled,
    'watch_motion_device_motion_enabled': deviceMotionEnabled,
    'watch_battery_enabled': batteryEnabled,
    'watch_device_enabled': deviceInfoEnabled,
    'watch_healthkit_enabled': heartRateEnabled,
    'watch_location_enabled': locationEnabled,
    'watch_heading_enabled': headingEnabled,
    'watch_bluetooth_enabled': bluetoothEnabled,
    'watch_audio_enabled': audioEnabled,
    'watch_audio_ambient_noise_enabled': ambientNoiseEnabled,
    'watch_audio_classification_enabled': audioClassificationEnabled,
    'watch_audio_duty_cycle_enabled': audioDutyCycleEnabled,
    'watch_audio_active_duration': audioActiveDuration.inSeconds.toDouble(),
    'watch_audio_rest_duration': audioRestDuration.inSeconds.toDouble(),
    'watch_background_session_type': backgroundSessionType.name,
    'watch_transfer_mode': transferMode.name,
    'watch_delete_after_transfer': deleteAfterTransfer,
    // Phone-side settings - not forwarded to the watch.
    'save_to_local_aware_database': saveToLocalAwareDatabase,
  };

  @override
  Function get fromJsonFunction => _$AppleWatchDeviceFromJson;
  factory AppleWatchDevice.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchDevice>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchDeviceToJson(this);
}

/// A [DeviceRegistration] for an [AppleWatchDevice], holding the runtime
/// information about the Apple Watch which is paired with the phone.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AppleWatchDeviceRegistration extends HardwareDeviceRegistration {
  /// The AWARE device id of the watch, if it has been exchanged with the phone.
  ///
  /// Note that the watch and the phone have different AWARE device ids. The
  /// link between them is also recorded in [AppleWatchDeviceInfo].
  String? watchDeviceId;

  /// The model of the watch, e.g. `Apple Watch`, if known.
  String? model;

  /// The version of watchOS running on the watch, if known.
  String? systemVersion;

  /// Is the companion watch app installed on the paired watch?
  bool isWatchAppInstalled;

  AppleWatchDeviceRegistration({
    super.deviceId,
    super.deviceDisplayName,
    super.registrationCreatedOn,
    super.isConnected,
    super.batteryChargingState,
    super.hardwareName,
    this.watchDeviceId,
    this.model,
    this.systemVersion,
    this.isWatchAppInstalled = false,
  });

  @override
  Function get fromJsonFunction => _$AppleWatchDeviceRegistrationFromJson;
  factory AppleWatchDeviceRegistration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AppleWatchDeviceRegistration>(json);
  @override
  Map<String, dynamic> toJson() => _$AppleWatchDeviceRegistrationToJson(this);
}

/// A [DeviceManager] for an [AppleWatchDevice].
///
/// This device manager does not connect to the watch in the Bluetooth sense -
/// the watch is paired with the phone by the operating system and the AWARE
/// watchOS framework talks to the phone over `WatchConnectivity`. "Connecting"
/// therefore means:
///
///  1. configuring the native AWARE `AppleWatchSensor` on the phone from the
///     [AppleWatchDevice] configuration,
///  2. listening for the data files the watch sends, and
///  3. checking that a watch is paired and that the companion watch app is
///     installed on it.
///
/// Note that the watch app collects and buffers data even when the phone app is
/// not running. Data therefore arrives in bursts when a transfer completes,
/// and not as a continuous stream.
class AppleWatchDeviceManager
    extends
        HardwareDeviceManager<AppleWatchDevice, AppleWatchDeviceRegistration> {
  final StreamController<AppleWatchRecords> _recordController =
      StreamController.broadcast();
  final StreamController<int> _batteryEventController =
      StreamController.broadcast();

  StreamSubscription<AppleWatchRecords>? _recordSubscription;
  StreamSubscription<AppleWatchStatus>? _statusSubscription;

  int? _batteryLevel;
  AppleWatchStatus _watchStatus = AppleWatchStatus();
  AppleWatchDeviceInfo? _watchInfo;

  AppleWatchDeviceManager([AppleWatchDevice? configuration])
    : super(AppleWatchDevice.DEVICE_TYPE, configuration: configuration);

  /// The service handling the communication with the native AWARE framework.
  AppleWatchService get service => AppleWatchService();

  /// The stream of record batches received from the Apple Watch.
  ///
  /// All probes in this package listen to this stream and pick the records
  /// belonging to their own data type.
  Stream<AppleWatchRecords> get records => _recordController.stream;

  /// The last known status of the connection to the Apple Watch.
  AppleWatchStatus get watchStatus => _watchStatus;

  /// The stream of status changes of the connection to the Apple Watch.
  Stream<AppleWatchStatus> get watchStatusEvents => service.statusEvents;

  /// The stream of progress events for the data files transferred from the watch.
  Stream<AppleWatchFileTransfer> get fileTransferEvents =>
      service.fileTransferEvents;

  /// Information on the watch itself, if it has been reported by the watch app.
  AppleWatchDeviceInfo? get watchInfo => _watchInfo;

  @override
  String? get displayName =>
      _watchInfo?.name ?? _watchInfo?.model ?? 'Apple Watch';

  /// The battery level of the Apple Watch in percent (0-100).
  ///
  /// Note that this is the level in the most recent battery record transferred
  /// from the watch, and can therefore be up to
  /// [AppleWatchDevice.fileTransferInterval] old. Returns null if no battery
  /// record has been received, e.g. if [AppleWatchDevice.batteryEnabled] is false.
  @override
  int? get batteryLevel => _batteryLevel;

  @override
  Stream<int> get batteryEvents => _batteryEventController.stream;

  @override
  bool get canConnect => Platform.isIOS;

  @override
  void onConfigure() {
    // Nothing to do here - the native sensor is configured on connect, since
    // configuring it activates the WatchConnectivity session.
  }

  // No phone-side permissions are needed to talk to a paired Apple Watch.
  // The watch app asks for HealthKit, microphone, and location permissions
  // itself, on the watch.
  @override
  Future<bool> onHasPermissions() async => true;

  @override
  Future<void> onRequestPermissions() async {}

  @override
  AppleWatchDeviceRegistration createRegistration() =>
      AppleWatchDeviceRegistration(
        deviceId: _watchStatus.watchDeviceId,
        deviceDisplayName: displayName,
        isConnected: isConnected,
        hardwareName: _watchInfo?.model,
        batteryChargingState: (batteryLevel != null)
            ? HardwareDeviceRegistration.parseBatteryLevel(batteryLevel!)
            : BatteryChargingState.unknown,
        watchDeviceId: _watchStatus.watchDeviceId,
        model: _watchInfo?.model,
        systemVersion: _watchInfo?.systemVersion,
        isWatchAppInstalled: _watchStatus.isWatchAppInstalled,
      );

  @override
  Future<DeviceStatus> onConnect() async {
    if (!Platform.isIOS) {
      warning(
        '$runtimeType - The Apple Watch sampling package is only supported on iOS.',
      );
      return DeviceStatus.unknown;
    }

    if (configuration == null) {
      warning('$runtimeType - No configuration available - cannot connect.');
      return DeviceStatus.disconnected;
    }

    // Start listening before configuring - the phone may already be holding
    // data files which the watch sent while the app was not running, and those
    // are delivered as soon as the native sensor is created.
    _recordSubscription ??= service.records.listen(
      _onRecords,
      onError: (Object error) =>
          warning('$runtimeType - Error in the record stream - $error'),
    );
    _statusSubscription ??= service.statusEvents.listen(_onStatus);

    if (!await service.configure(configuration!)) {
      warning(
        '$runtimeType - Could not configure the native AWARE Apple Watch sensor.',
      );
      return DeviceStatus.disconnected;
    }

    // Try to learn the AWARE device id of the watch. This only succeeds while
    // the watch app is reachable, and is not needed for data collection.
    unawaited(service.exchangeDeviceId());

    _watchStatus = await service.getStatus();

    if (!_watchStatus.isSupported) {
      warning(
        '$runtimeType - WatchConnectivity is not supported on this device.',
      );
      return DeviceStatus.unknown;
    }
    if (!_watchStatus.isPaired) {
      warning('$runtimeType - No Apple Watch is paired with this phone.');
      return DeviceStatus.disconnected;
    }
    if (!_watchStatus.isWatchAppInstalled) {
      warning(
        '$runtimeType - The companion watch app is not installed on the paired '
        'Apple Watch. Ask the participant to install it from the Watch app on '
        'the phone.',
      );
      return DeviceStatus.disconnected;
    }

    return DeviceStatus.connected;
  }

  @override
  Future<bool> onDisconnect() async {
    await _recordSubscription?.cancel();
    await _statusSubscription?.cancel();
    _recordSubscription = null;
    _statusSubscription = null;
    await service.close();
    return true;
  }

  void _onStatus(AppleWatchStatus newStatus) {
    _watchStatus = newStatus;

    // A watch which has been unpaired, or has had the companion app removed,
    // cannot deliver data - so stop sampling. Losing the app is recoverable
    // (the participant may install it again), losing the pairing is not.
    if (isConnected && !newStatus.isAvailable) {
      warning(
        '$runtimeType - The Apple Watch is no longer available - $newStatus',
      );
      status = newStatus.isPaired
          ? DeviceStatus.disconnecting
          : DeviceStatus.disconnected;
    }
  }

  void _onRecords(AppleWatchRecords batch) {
    debug('$runtimeType - Received $batch');

    // Keep the battery level and the watch info up to date, no matter whether
    // the corresponding measures are part of the study.
    if (batch.table == AppleWatchTable.battery) _updateBatteryLevel(batch);
    if (batch.table == AppleWatchTable.device) _updateWatchInfo(batch);

    _recordController.add(batch);
  }

  void _updateBatteryLevel(AppleWatchRecords batch) {
    if (batch.records.isEmpty) return;

    final level = AppleWatchBattery.fromRecord(batch.records.last).batteryLevel;
    if (level >= 0 && level != _batteryLevel) {
      _batteryLevel = level;
      _batteryEventController.add(level);
    }
  }

  void _updateWatchInfo(AppleWatchRecords batch) {
    if (batch.records.isEmpty) return;
    _watchInfo = AppleWatchDeviceInfo.fromRecord(batch.records.last);
  }
}
