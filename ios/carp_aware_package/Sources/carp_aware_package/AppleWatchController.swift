/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

import Flutter
import Foundation
import WatchConnectivity

import com_awareframework_ios_core
import com_awareframework_ios_sensor_applewatch_iOS
import com_awareframework_ios_sensor_applewatch_shared

/// Owns the AWARE `AppleWatchSensor` on the phone and forwards everything it
/// receives from the Apple Watch to Dart.
///
/// This class - and not `AppleWatchSensor` - is the `WCSessionDelegate`. The
/// sensor installs itself as the delegate in its initializer, and this class
/// takes the delegate over right after, for two reasons:
///
///  1. The reply to the watch's `get_settings` request can be extended with the
///     CARP-specific settings which `AppleWatchSensor.Config` does not know about.
///  2. Watch state changes (pairing, reachability, the watch app starting and
///     stopping) can be pushed to Dart as they happen.
///
/// Everything the sensor does know how to handle is forwarded to it.
final class AppleWatchController: NSObject {

    /// The stream of sensor records transferred from the watch.
    ///
    /// The buffer is deliberately small: one buffered event is a whole chunk of
    /// up to 500 records, and Dart subscribes within moments of the app
    /// launching. It only has to bridge that gap.
    let recordStream = BufferedStreamHandler(capacity: 32)

    /// The stream of connection status and file transfer progress events.
    let eventStream = BufferedStreamHandler(capacity: 64)

    private var sensor: AppleWatchSensor?

    /// Settings which are handed to the watch app but are not part of
    /// `AppleWatchSensor.Config`.
    private var extraSettings: [String: Any] = [:]

    /// The AWARE device id of the paired watch, once it has been exchanged.
    private var watchDeviceId: String?

    private var lastError: String?
    private var lastMessageAt: Date?
    private var lastFileTransferAt: Date?

    // MARK: - Configuration

    /// Create the AWARE sensor if needed and apply [settings] to it.
    ///
    /// The settings are what the watch app receives when it asks the phone for
    /// its configuration, so calling this again updates the watch on its next
    /// `get_settings` request.
    func configure(settings: [String: Any]) {
        let config = sensor?.CONFIG ?? AppleWatchSensor.Config()
        apply(settings: settings, to: config)
        attachHandlers(to: config)

        if sensor == nil {
            // Creating the sensor makes it the WCSession delegate and activates
            // the session - take the delegate over again right after.
            sensor = AppleWatchSensor(config)
            activateSession()
        }

        extraSettings = Self.carpOnlySettingKeys.reduce(into: [:]) { result, key in
            if let value = settings[key] { result[key] = value }
        }

        emitStatus()
    }

    private func attachHandlers(to config: AppleWatchSensor.Config) {
        config.receivedDataHandler = { [weak self] table, chunkIndex, totalChunks, records in
            self?.emit(
                table: table,
                chunkIndex: chunkIndex,
                totalChunks: totalChunks,
                records: records
            )
        }
        config.fileTransferStatusHandler = {
            [weak self] table, chunkIndex, totalChunks, fileName, state, errorMessage in
            self?.emitFileTransfer(
                table: table,
                chunkIndex: chunkIndex,
                totalChunks: totalChunks,
                fileName: fileName,
                state: state,
                errorMessage: errorMessage
            )
        }
    }

    /// The keys which are forwarded to the watch as-is, since
    /// `AppleWatchSensor.Config` has no property for them.
    private static let carpOnlySettingKeys = [
        "watch_transfer_mode",
        "watch_delete_after_transfer",
    ]

    private func apply(settings: [String: Any], to config: AppleWatchSensor.Config) {
        if let value = settings["label"] as? String { config.label = value }
        if let value = settings["db_host"] as? String { config.dbHost = value }
        if let value = settings["debug"] as? Bool { config.debug = value }

        if let value = settings["motion_sensor_hz"] as? Int { config.motionSensorHz = value }
        if let value = settings["file_transfer_interval_seconds"] as? Double {
            config.fileTransferIntervalSeconds = value
        }

        if let value = settings["watch_motion_enabled"] as? Bool { config.watchMotionEnabled = value }
        if let value = settings["watch_motion_accelerometer_enabled"] as? Bool {
            config.watchMotionAccelerometerEnabled = value
        }
        if let value = settings["watch_motion_device_motion_enabled"] as? Bool {
            config.watchMotionDeviceMotionEnabled = value
        }
        if let value = settings["watch_battery_enabled"] as? Bool { config.watchBatteryEnabled = value }
        if let value = settings["watch_device_enabled"] as? Bool { config.watchDeviceEnabled = value }
        if let value = settings["watch_healthkit_enabled"] as? Bool { config.watchHealthKitEnabled = value }
        if let value = settings["watch_location_enabled"] as? Bool { config.watchLocationEnabled = value }
        if let value = settings["watch_heading_enabled"] as? Bool { config.watchHeadingEnabled = value }
        if let value = settings["watch_bluetooth_enabled"] as? Bool { config.watchBluetoothEnabled = value }
        if let value = settings["watch_audio_enabled"] as? Bool { config.watchAudioEnabled = value }

        if let value = settings["watch_audio_ambient_noise_enabled"] as? Bool {
            config.watchAudioAmbientNoiseEnabled = value
        }
        if let value = settings["watch_audio_classification_enabled"] as? Bool {
            config.watchAudioClassificationEnabled = value
        }
        if let value = settings["watch_audio_duty_cycle_enabled"] as? Bool {
            config.watchAudioDutyCycleEnabled = value
        }
        if let value = settings["watch_audio_active_duration"] as? Double {
            config.watchAudioActiveDuration = value
        }
        if let value = settings["watch_audio_rest_duration"] as? Double {
            config.watchAudioRestDuration = value
        }

        config.watchBackgroundSessionType = AWBackgroundSessionType(
            rawValueOrDefault: settings["watch_background_session_type"] as? String
        )

        // CARP Mobile Sensing stores the data itself, so the records received
        // from the watch are by default not written to the AWARE database on
        // the phone as well.
        config.autoSaveReceivedData =
            settings["save_to_local_aware_database"] as? Bool ?? false
        config.keepOriginalFileFromWatch = false
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        // Activating an already activated session is a no-op, but it makes sure
        // this delegate - and not the sensor - gets the activation callback.
        WCSession.default.activate()
    }

    /// Stop passing data from the watch on to Dart.
    ///
    /// The sensor itself is kept - it owns the `WCSession` delegate chain, and
    /// tearing it down and building it up again on every connect/disconnect
    /// cycle would open a new database each time. The watch app keeps
    /// collecting either way; its data is picked up again on the next
    /// `configure`.
    func close() {
        sensor?.CONFIG.receivedDataHandler = nil
        sensor?.CONFIG.fileTransferStatusHandler = nil
        extraSettings = [:]
        emitStatus()
    }

    // MARK: - Status

    func statusMap() -> [String: Any] {
        guard WCSession.isSupported() else {
            return [
                "event": "status",
                "isSupported": false,
                "isPaired": false,
                "isWatchAppInstalled": false,
                "isReachable": false,
                "isCollectingData": false,
                "activationState": "unsupported",
                "outstandingFileTransferCount": 0,
                "phoneDeviceId": AwareUtils.getCommonDeviceId(),
            ]
        }

        let session = WCSession.default
        var status: [String: Any] = [
            "event": "status",
            "isSupported": true,
            "isPaired": session.isPaired,
            "isWatchAppInstalled": session.isWatchAppInstalled,
            "isReachable": session.isReachable,
            "isCollectingData": sensor?.isWatchCollectingData ?? false,
            "activationState": session.activationState.name,
            "outstandingFileTransferCount": session.outstandingFileTransfers.count,
            "phoneDeviceId": AwareUtils.getCommonDeviceId(),
        ]
        if let watchDeviceId { status["watchDeviceId"] = watchDeviceId }
        if let lastError { status["lastError"] = lastError }
        if let lastMessageAt {
            status["lastMessageAt"] = Int(lastMessageAt.timeIntervalSince1970 * 1000)
        }
        if let lastFileTransferAt {
            status["lastFileTransferAt"] = Int(lastFileTransferAt.timeIntervalSince1970 * 1000)
        }
        return status
    }

    /// Ask the watch app for its AWARE device id, and tell it the id of this phone.
    /// Only works while the watch app is reachable.
    func exchangeDeviceId(completion: @escaping (String?) -> Void) {
        guard let sensor, WCSession.isSupported(), WCSession.default.isReachable else {
            completion(nil)
            return
        }

        sensor.requestManualDeviceIdExchange { [weak self] result in
            switch result {
            case .success(let deviceId):
                self?.lastMessageAt = Date()
                self?.watchDeviceId = deviceId.isEmpty ? nil : deviceId
                self?.emitStatus()
                completion(deviceId.isEmpty ? nil : deviceId)
            case .failure(let error):
                self?.lastError = error.localizedDescription
                self?.emitStatus()
                completion(nil)
            }
        }
    }

    // MARK: - Emitting to Dart

    private func emit(
        table: String,
        chunkIndex: Int,
        totalChunks: Int,
        records: [[String: Any]]
    ) {
        recordStream.send([
            "table": table,
            "chunkIndex": chunkIndex,
            "totalChunks": totalChunks,
            "records": records.map(Self.encodable),
        ])
    }

    private func emitFileTransfer(
        table: String,
        chunkIndex: Int,
        totalChunks: Int,
        fileName: String,
        state: String,
        errorMessage: String?
    ) {
        var event: [String: Any] = [
            "event": "fileTransfer",
            "table": table,
            "chunkIndex": chunkIndex,
            "totalChunks": totalChunks,
            "fileName": fileName,
            "state": Self.transferStateNames[state] ?? state,
        ]
        if let errorMessage { event["error"] = errorMessage }
        eventStream.send(event)
    }

    /// Maps the state names used by `AppleWatchSensor` to the names of the
    /// `WatchFileTransferState` enum on the Dart side.
    private static let transferStateNames = ["save_failed": "saveFailed"]

    private func emitStatus() {
        eventStream.send(statusMap())
    }

    /// Keep only the value types the Flutter standard codec can carry.
    ///
    /// Records come from SQLite through `JSONSerialization`, so the values are
    /// `NSNumber`, `NSString`, or `NSNull` - but be defensive, since one bad
    /// value would make the whole chunk fail to encode.
    private static func encodable(_ record: [String: Any]) -> [String: Any] {
        record.compactMapValues { (value: Any) -> Any? in
            if value is NSNull { return nil }
            if let number = value as? NSNumber { return number }
            if let string = value as? String { return string }
            if let data = value as? Data { return FlutterStandardTypedData(bytes: data) }
            return String(describing: value)
        }
    }
}

// MARK: - WCSessionDelegate

extension AppleWatchController: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        lastMessageAt = Date()
        lastError = error?.localizedDescription
        emitStatus()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        emitStatus()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another watch - reactivate to pair with it.
        WCSession.default.activate()
        emitStatus()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        emitStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        emitStatus()
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        lastFileTransferAt = Date()
        let fileName = file.fileURL.lastPathComponent

        // WatchConnectivity deletes the file as soon as this method returns, so
        // the sensor has to read it before we leave this call. Delegate calls
        // are already made on a background queue, so this does not block the UI.
        sensor?.didReceive(file: file)

        emitStatus()

        // Let the watch know the file arrived, so it can clean up its own copy.
        guard session.isReachable else { return }
        session.sendMessage(
            ["event_name": "file_transfer_completion", "file_path": fileName],
            replyHandler: { [weak self] _ in self?.lastMessageAt = Date() },
            errorHandler: { [weak self] error in
                self?.lastError = error.localizedDescription
            }
        )
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        lastMessageAt = Date()

        // The watch app reports whether it is collecting data as `status`.
        if let status = message["status"] as? Int {
            sensor?.isWatchCollectingData = (status == 1)
        }
        sensor?.messageHandler?(message)
        emitStatus()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        lastMessageAt = Date()

        guard let sensor else {
            replyHandler(["status": "unavailable"])
            return
        }

        // Remember the watch device id when the watch introduces itself.
        if let deviceId = message["device_id"] as? String, !deviceId.isEmpty {
            watchDeviceId = deviceId
        }

        sensor.didReceive(message: message) { [weak self] reply in
            var merged = reply
            if (message["method"] as? String) == "get_settings",
                let extra = self?.extraSettings
            {
                merged.merge(extra) { _, new in new }
            }
            replyHandler(merged)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        lastMessageAt = Date()
        sensor?.messageHandler?(applicationContext)
    }
}

// MARK: - Helpers

/// A `FlutterStreamHandler` which buffers events until Dart starts listening.
///
/// Files sent by the watch can arrive before the Dart side has subscribed -
/// e.g. right after the app is launched - and dropping them would mean losing
/// data the watch has already thrown away.
final class BufferedStreamHandler: NSObject, FlutterStreamHandler {

    private let capacity: Int
    private var buffer: [Any] = []
    private var sink: FlutterEventSink?
    private let lock = NSLock()

    init(capacity: Int) {
        self.capacity = capacity
    }

    func send(_ event: Any) {
        lock.lock()
        let sink = self.sink
        if sink == nil {
            buffer.append(event)
            if buffer.count > capacity { buffer.removeFirst(buffer.count - capacity) }
        }
        lock.unlock()

        guard let sink else { return }
        DispatchQueue.main.async { sink(event) }
    }

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        lock.lock()
        sink = events
        let pending = buffer
        buffer.removeAll()
        lock.unlock()

        DispatchQueue.main.async { pending.forEach { events($0) } }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        lock.lock()
        sink = nil
        lock.unlock()
        return nil
    }
}

extension WCSessionActivationState {
    var name: String {
        switch self {
        case .notActivated: return "notActivated"
        case .inactive: return "inactive"
        case .activated: return "activated"
        @unknown default: return "unknown"
        }
    }
}
