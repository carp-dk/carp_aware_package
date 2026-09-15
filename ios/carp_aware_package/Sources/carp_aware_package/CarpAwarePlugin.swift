/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

import Flutter
import Foundation

/// The Flutter plugin exposing the AWARE `AppleWatchSensor` to CARP Mobile Sensing.
///
/// Three channels are used:
///  * `carp_aware_package/methods` - configuring the watch and reading its status.
///  * `carp_aware_package/records` - the sensor records transferred from the watch.
///  * `carp_aware_package/events`  - connection status and file transfer progress.
public class CarpAwarePlugin: NSObject, FlutterPlugin {

    private static let methodChannelName = "carp_aware_package/methods"
    private static let recordChannelName = "carp_aware_package/records"
    private static let eventChannelName = "carp_aware_package/events"

    private let controller = AppleWatchController()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = CarpAwarePlugin()

        let methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        FlutterEventChannel(
            name: recordChannelName,
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(instance.controller.recordStream)

        FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: registrar.messenger()
        ).setStreamHandler(instance.controller.eventStream)

        // Keep the plugin alive for the lifetime of the app so that data files
        // sent by the watch are still received while no Dart code is listening.
        registrar.publish(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            guard let settings = call.arguments as? [String: Any] else {
                result(
                    FlutterError(
                        code: "invalid_arguments",
                        message: "'configure' expects a map of watch settings.",
                        details: nil
                    )
                )
                return
            }
            controller.configure(settings: settings)
            result(true)

        case "status":
            result(controller.statusMap())

        case "exchangeDeviceId":
            controller.exchangeDeviceId { deviceId in result(deviceId) }

        case "close":
            controller.close()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
