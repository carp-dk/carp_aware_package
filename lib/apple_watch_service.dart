/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_aware_package.dart';

/// A batch of records transferred from the Apple Watch to the phone.
///
/// The watch exports its local database in pages, compresses each page, and
/// transfers it to the phone as a file. One [AppleWatchRecords] is the content
/// of one such file, i.e. all records from one [table] in one chunk.
class AppleWatchRecords {
  /// The AWARE table these records come from. See [AppleWatchTable].
  final String table;

  /// The 1-based index of this chunk in the transfer session.
  final int chunkIndex;

  /// The total number of chunks in this transfer session for this [table].
  final int totalChunks;

  /// The records in this chunk, as raw AWARE rows.
  final List<Map<String, dynamic>> records;

  AppleWatchRecords({
    required this.table,
    required this.chunkIndex,
    required this.totalChunks,
    required this.records,
  });

  factory AppleWatchRecords.fromMap(Map<dynamic, dynamic> map) =>
      AppleWatchRecords(
        table: map['table'] as String? ?? 'unknown',
        chunkIndex: map['chunkIndex'] as int? ?? 1,
        totalChunks: map['totalChunks'] as int? ?? 1,
        records: (map['records'] as List<dynamic>? ?? [])
            .map((record) => Map<String, dynamic>.from(record as Map))
            .toList(),
      );

  @override
  String toString() =>
      '$runtimeType - table: $table, chunk: $chunkIndex/$totalChunks, '
      'records: ${records.length}';
}

/// The state of a chunk file transferred from the Apple Watch, as it is being
/// processed on the phone.
enum WatchFileTransferState {
  /// The file has arrived on the phone.
  received,

  /// The file is being decompressed and decoded.
  processing,

  /// The records in the file have been decoded and emitted.
  decoded,

  /// The records are being written to the local AWARE database on the phone.
  /// Only used when [AppleWatchDevice.saveToLocalAwareDatabase] is true.
  saving,

  /// The records have been written to the local AWARE database on the phone.
  saved,

  /// Processing of the file failed. See [AppleWatchFileTransfer.error].
  failed,

  /// Writing the records to the local AWARE database on the phone failed.
  saveFailed,

  /// The state reported by the native side is not known to this package.
  unknown,
}

/// Progress information on a chunk file transferred from the Apple Watch.
class AppleWatchFileTransfer {
  /// The AWARE table the records in this file come from. See [AppleWatchTable].
  final String table;

  /// The name of the transferred file.
  final String fileName;

  /// The 1-based index of this file in the transfer session.
  final int chunkIndex;

  /// The total number of files in this transfer session.
  final int totalChunks;

  /// How far this file has come in being processed.
  final WatchFileTransferState state;

  /// The error message, if [state] is [WatchFileTransferState.failed] or
  /// [WatchFileTransferState.saveFailed].
  final String? error;

  AppleWatchFileTransfer({
    required this.table,
    required this.fileName,
    required this.chunkIndex,
    required this.totalChunks,
    required this.state,
    this.error,
  });

  factory AppleWatchFileTransfer.fromMap(Map<dynamic, dynamic> map) =>
      AppleWatchFileTransfer(
        table: map['table'] as String? ?? 'unknown',
        fileName: map['fileName'] as String? ?? '',
        chunkIndex: map['chunkIndex'] as int? ?? 1,
        totalChunks: map['totalChunks'] as int? ?? 1,
        state: WatchFileTransferState.values.firstWhere(
          (state) => state.name == map['state'],
          orElse: () => WatchFileTransferState.unknown,
        ),
        error: map['error'] as String?,
      );

  @override
  String toString() =>
      '$runtimeType - $fileName ($table, $chunkIndex/$totalChunks): '
      '${state.name}${error != null ? ' - $error' : ''}';
}

/// The runtime status of the connection between the phone and the Apple Watch.
class AppleWatchStatus {
  /// Is `WatchConnectivity` supported on this phone?
  /// Always false on Android and on iPads.
  final bool isSupported;

  /// Is an Apple Watch paired with this phone?
  final bool isPaired;

  /// Is the companion watch app installed on the paired Apple Watch?
  final bool isWatchAppInstalled;

  /// Is the watch app reachable right now?
  ///
  /// Note that reachability is only needed for live messaging. Data files are
  /// queued by the OS and delivered when the watch comes into range again, so
  /// data collection works fine while this is false.
  final bool isReachable;

  /// Is the watch app currently collecting data?
  ///
  /// This is based on the last status message sent by the watch app, and is
  /// therefore only known after the watch app has been started at least once.
  final bool isCollectingData;

  /// The activation state of the `WCSession` -
  /// `notActivated`, `inactive`, or `activated`.
  final String activationState;

  /// The number of file transfers from the watch which have not yet completed.
  final int outstandingFileTransferCount;

  /// The AWARE device id of this phone.
  final String? phoneDeviceId;

  /// The AWARE device id of the paired watch, if it has been exchanged.
  final String? watchDeviceId;

  /// When the phone last exchanged a message with the watch.
  final DateTime? lastMessageAt;

  /// When the phone last received a file from the watch.
  final DateTime? lastFileTransferAt;

  /// The last communication error, if any.
  final String? lastError;

  AppleWatchStatus({
    this.isSupported = false,
    this.isPaired = false,
    this.isWatchAppInstalled = false,
    this.isReachable = false,
    this.isCollectingData = false,
    this.activationState = 'notActivated',
    this.outstandingFileTransferCount = 0,
    this.phoneDeviceId,
    this.watchDeviceId,
    this.lastMessageAt,
    this.lastFileTransferAt,
    this.lastError,
  });

  factory AppleWatchStatus.fromMap(Map<dynamic, dynamic> map) =>
      AppleWatchStatus(
        isSupported: map['isSupported'] as bool? ?? false,
        isPaired: map['isPaired'] as bool? ?? false,
        isWatchAppInstalled: map['isWatchAppInstalled'] as bool? ?? false,
        isReachable: map['isReachable'] as bool? ?? false,
        isCollectingData: map['isCollectingData'] as bool? ?? false,
        activationState: map['activationState'] as String? ?? 'notActivated',
        outstandingFileTransferCount:
            map['outstandingFileTransferCount'] as int? ?? 0,
        phoneDeviceId: map['phoneDeviceId'] as String?,
        watchDeviceId: map['watchDeviceId'] as String?,
        lastMessageAt: _dateTime(map['lastMessageAt']),
        lastFileTransferAt: _dateTime(map['lastFileTransferAt']),
        lastError: map['lastError'] as String?,
      );

  /// Is the watch ready to collect data, i.e. paired with this phone and with
  /// the companion watch app installed?
  bool get isAvailable => isSupported && isPaired && isWatchAppInstalled;

  static DateTime? _dateTime(Object? milliseconds) => (milliseconds is num)
      ? DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt(), isUtc: true)
      : null;

  @override
  String toString() =>
      '$runtimeType - supported: $isSupported, paired: $isPaired, '
      'appInstalled: $isWatchAppInstalled, reachable: $isReachable, '
      'collecting: $isCollectingData, activation: $activationState';
}

/// The interface to the native AWARE `AppleWatchSensor` running on the iPhone.
///
/// This service is a singleton and is used by the [AppleWatchDeviceManager].
/// Only use it directly if you need low-level access to the watch connection,
/// e.g. for building a debug UI.
class AppleWatchService {
  static const MethodChannel _methodChannel = MethodChannel(
    'carp_aware_package/methods',
  );
  static const EventChannel _recordChannel = EventChannel(
    'carp_aware_package/records',
  );
  static const EventChannel _eventChannel = EventChannel(
    'carp_aware_package/events',
  );

  static final AppleWatchService _instance = AppleWatchService._();

  /// Get the singleton [AppleWatchService].
  factory AppleWatchService() => _instance;
  AppleWatchService._();

  Stream<AppleWatchRecords>? _records;
  Stream<dynamic>? _events;

  /// Is this platform able to talk to an Apple Watch at all?
  bool get isSupportedPlatform => Platform.isIOS;

  /// Configure the native AWARE `AppleWatchSensor` from [configuration].
  ///
  /// Creates the sensor if it does not exist yet and (re)applies the watch
  /// settings. The settings are pulled by the watch app when it starts, or
  /// whenever it calls `applyiPhoneSettings()`.
  ///
  /// Returns true if the native sensor was configured.
  Future<bool> configure(AppleWatchDevice configuration) async {
    if (!isSupportedPlatform) return false;

    try {
      return await _methodChannel.invokeMethod<bool>(
            'configure',
            configuration.toWatchSettings(),
          ) ??
          false;
    } catch (error) {
      warning('$runtimeType - Error configuring the Apple Watch - $error');
      return false;
    }
  }

  /// The current status of the connection to the Apple Watch.
  Future<AppleWatchStatus> getStatus() async {
    if (!isSupportedPlatform) return AppleWatchStatus();

    try {
      final status = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'status',
      );
      return (status == null)
          ? AppleWatchStatus()
          : AppleWatchStatus.fromMap(status);
    } catch (error) {
      warning('$runtimeType - Error getting the Apple Watch status - $error');
      return AppleWatchStatus();
    }
  }

  /// Ask the watch app for its AWARE device id and tell it the device id of
  /// this phone. This only works while the watch app is reachable.
  ///
  /// Returns the AWARE device id of the watch, or null if the exchange failed.
  Future<String?> exchangeDeviceId() async {
    if (!isSupportedPlatform) return null;

    try {
      return await _methodChannel.invokeMethod<String>('exchangeDeviceId');
    } catch (error) {
      warning(
        '$runtimeType - Error exchanging device id with the watch - $error',
      );
      return null;
    }
  }

  /// Tear down the native AWARE `AppleWatchSensor` and stop listening for data
  /// from the watch.
  ///
  /// Note that this does not stop data collection on the watch itself - the
  /// watch app keeps collecting and will deliver its data on the next transfer.
  Future<void> close() async {
    if (!isSupportedPlatform) return;

    try {
      await _methodChannel.invokeMethod<void>('close');
    } catch (error) {
      warning('$runtimeType - Error closing the Apple Watch sensor - $error');
    }
  }

  /// The stream of record batches transferred from the Apple Watch.
  Stream<AppleWatchRecords> get records => _records ??= (!isSupportedPlatform)
      ? const Stream.empty()
      : _recordChannel
            .receiveBroadcastStream()
            .map(
              (event) =>
                  AppleWatchRecords.fromMap(event as Map<dynamic, dynamic>),
            )
            .asBroadcastStream();

  Stream<dynamic> get _eventStream => _events ??= (!isSupportedPlatform)
      ? const Stream.empty()
      : _eventChannel.receiveBroadcastStream().asBroadcastStream();

  /// The stream of status changes of the connection to the Apple Watch.
  Stream<AppleWatchStatus> get statusEvents => _eventStream
      .where((event) => (event as Map)['event'] == 'status')
      .map((event) => AppleWatchStatus.fromMap(event as Map<dynamic, dynamic>));

  /// The stream of progress events for the chunk files transferred from the
  /// Apple Watch. Useful for showing transfer progress in the app UI.
  Stream<AppleWatchFileTransfer> get fileTransferEvents => _eventStream
      .where((event) => (event as Map)['event'] == 'fileTransfer')
      .map(
        (event) =>
            AppleWatchFileTransfer.fromMap(event as Map<dynamic, dynamic>),
      );
}
