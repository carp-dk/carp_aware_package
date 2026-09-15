# Adding the watchOS app to your Flutter iOS app

`carp_aware_package` receives data from an Apple Watch, it cannot collect it. The collecting is done
by a **companion watchOS app** which runs the [AWARE watchOS](https://github.com/awareframework/com.awareframework.ios.sensor.applewatch)
framework. That watch app is a watchOS target inside your Flutter app's Xcode project, and this guide
walks through adding it.

---

## Table of contents

1. [What you are building](#1-what-you-are-building)
2. [Prerequisites](#2-prerequisites)
3. [Step 1 — Enable Swift Package Manager](#step-1--enable-swift-package-manager)
4. [Step 2 — Raise the iOS deployment target to 16.0](#step-2--raise-the-ios-deployment-target-to-160)
5. [Step 3 — Add the package and open Xcode](#step-3--add-the-package-and-open-xcode)
6. [Step 4 — Add the watchOS app target](#step-4--add-the-watchos-app-target)
7. [Step 5 — Bundle identifiers and signing](#step-5--bundle-identifiers-and-signing)
8. [Step 6 — Add the AWARE framework to the watch target](#step-6--add-the-aware-framework-to-the-watch-target)
9. [Step 7 — Capabilities](#step-7--capabilities)
10. [Step 8 — Background modes and privacy strings](#step-8--background-modes-and-privacy-strings)
11. [Step 9 — The watch app source code](#step-9--the-watch-app-source-code)
12. [Step 10 — Build and run](#step-10--build-and-run)
13. [Step 11 — Verify the data flow](#step-11--verify-the-data-flow)
14. [Troubleshooting](#troubleshooting)
15. [Appendix A — Settings the phone sends to the watch](#appendix-a--settings-the-phone-sends-to-the-watch)
16. [Appendix B — What runs when](#appendix-b--what-runs-when)

---

## 1. What you are building

```
Runner.xcodeproj
├── Runner                (iOS app)      ← your Flutter app
│   └── carp_aware_package plugin        ← added by `flutter pub get`, via SwiftPM
│       └── carp-aware-package           ← AWARE iOS binaries, bundled with the plugin
│
└── CarpWatch Watch App   (watchOS app)  ← you add this in Step 4
    └── carp-aware-watch                 ← AWARE watchOS binaries, same plugin
```

At runtime:

```
   Apple Watch                                     iPhone
┌──────────────────────────┐              ┌────────────────────────────────┐
│ CarpWatch Watch App      │              │ Runner (your Flutter app)      │
│                          │              │                                │
│ 1. asks the phone for    │──get_settings──▶ carp_aware_package answers   │
│    its configuration     │◀──settings────│   from AppleWatchDevice        │
│                          │              │                                │
│ 2. AWARE sensors collect │              │                                │
│    into SQLite on watch  │              │                                │
│                          │              │                                │
│ 3. every N minutes:      │──file chunks──▶ AppleWatchSensor decodes them  │
│    zlib JSON chunks over │              │        ↓                       │
│    WatchConnectivity     │              │   CAMS Measurements → CARP      │
└──────────────────────────┘              └────────────────────────────────┘
```

The important design point: **the watch app has no default study configuration.** It asks the
phone what to sample, and the phone answers from the `AppleWatchDevice` in the deployed study
protocol.

## 2. Prerequisites

Requires minimum iOS 16 and watchOS 8.0

You also need **physical devices**: an iPhone with a paired Apple Watch. The simulator cannot pair a
watch to a phone in a way that makes `WatchConnectivity` file transfers work end-to-end, and heart
rate requires real hardware.

---

## Step 1 — Enable Swift Package Manager

The AWARE watchOS framework is only distributed via Swift Package Manager, so `carp_aware_package`
is a SwiftPM-only plugin. Enable SwiftPM once per machine:

```bash
flutter config --enable-swift-package-manager
```

Check that it took:

```bash
flutter config --list | grep swift-package-manager
# enable-swift-package-manager: true
```

> If your app was created before SwiftPM support existed, the first `flutter run` after enabling it
> migrates the Xcode project (it adds a local `FlutterGeneratedPluginSwiftPackage`). Commit that
> change. Plugins that still use CocoaPods keep working — the two coexist.

## Step 2 — Raise the iOS deployment target to 16.0

The AWARE framework requires iOS 16. Flutter keeps the deployment target in three places and they all
have to agree, otherwise Swift Package Manager will refuse to resolve with a message like
*"the package product 'carp-aware-package' requires minimum platform version 16.0"*.

**a) The Xcode project.** Open `ios/Runner.xcworkspace`, select the **Runner** project → **Runner**
target → **General** → **Minimum Deployments** → **iOS 16.0**. Do this for the *project* as well as
the target if they differ.

**b) The Podfile.** In `ios/Podfile`, uncomment and set the platform line:

```ruby
platform :ios, '16.0'
```

**c) The Flutter framework plist.** In `ios/Flutter/AppFrameworkInfo.plist`:

```xml
<key>MinimumOSVersion</key>
<string>16.0</string>
```

Then:

```bash
cd ios && pod install && cd ..
```

## Step 3 — Add the package and open Xcode

Add the dependency to your app's `pubspec.yaml`:

```yaml
dependencies:
  carp_core: ^latest
  carp_mobile_sensing: ^latest
  carp_aware_package: ^latest
```

```bash
flutter pub get
flutter build ios --config-only     # makes Flutter generate the SwiftPM package
```

Open the workspace — **not** the project — if your app uses any CocoaPods plugins:

```bash
open ios/Runner.xcworkspace
```

Confirm the plugin arrived: in the Project navigator you should see **Package Dependencies** →
`FlutterGeneratedPluginSwiftPackage`, and under it `carp_aware_package`.

The AWARE framework itself is **not** listed as a package. It ships with the plugin as pre-compiled
XCFrameworks, so the only AWARE-related packages you see are the open-source ones those binaries link
against: `com.awareframework.ios.core`, `GRDB`, and `DataCompression`.

## Step 4 — Add the watchOS app target

1. In Xcode: **File → New → Target…**
2. Pick the **watchOS** tab → **App** → **Next**.
3. Fill in:
   * **Product Name**: `CarpWatch` (any name works — this guide uses `CarpWatch`)
   * **Interface**: `SwiftUI`
   * **Language**: `Swift`
   * **Project**: `Runner`
   * **Embed in Companion Application**: `Runner` ← this is the important one
   * Leave **Include Notification Scene** and **Include Tests** unchecked unless you want them.
4. **Finish**. When Xcode asks whether to activate the new scheme, choose **Activate**.

Xcode creates:

* a group `CarpWatch Watch App` with `CarpWatchApp.swift`, `ContentView.swift`, and assets,
* a target `CarpWatch Watch App`,
* a scheme `CarpWatch Watch App`,
* an **Embed Watch Content** build phase on the `Runner` target.

> **Where do the files live?** Xcode puts them in `ios/CarpWatch Watch App/`. Commit that directory —
> it is part of your app's source, not generated output. Do not put it inside `ios/Runner/`.

## Step 5 — Bundle identifiers and signing

The watch app's bundle identifier **must** be the iOS app's bundle identifier plus one component:

| Target | Bundle identifier |
|---|---|
| `Runner` | `dk.carp.myapp` |
| `CarpWatch Watch App` | `dk.carp.myapp.watchkitapp` |

Xcode normally gets this right when you use *Embed in Companion Application*. Verify it under the
watch target → **Signing & Capabilities** → **Bundle Identifier**, and check that the build setting
`INFOPLIST_KEY_WKCompanionAppBundleIdentifier` on the watch target points at the iOS bundle
identifier.

Set the same **Team** on both targets, and let Xcode manage signing. If you use manual signing, you
need a second provisioning profile for the watch app bundle id.

## Step 6 — Add the AWARE framework to the watch target

The AWARE framework ships inside `carp_aware_package` as **pre-compiled XCFrameworks**. There is no
package URL to add and no AWARE source to check out — Xcode resolved it along with the plugin in
Step 3, so all that is left is to link it into the watch target.

1. Select the **`CarpWatch Watch App`** target → **General**.
2. Under **Frameworks, Libraries, and Embedded Content**, press **+**.
3. Pick **`carp-aware-watch`** from the list of package products → **Add**.

That one product brings in both AWARE watch modules —
`com_awareframework_ios_sensor_applewatch_shared` and
`com_awareframework_ios_sensor_applewatch_watchOS` — together with the open-source packages they were
compiled against. The binaries are static libraries, so there is nothing to embed and nothing to
sign; leave it on **Do Not Embed** if Xcode offers the choice.

> ⚠️ **Do not add `carp-aware-watch` to the `Runner` target.** The iOS side of the plugin links its
> own AWARE binaries through `carp-aware-package`. Adding the watch product to the app as well gives
> you two copies of the same modules.

Also make sure the watch target's **Minimum Deployments** is **watchOS 8.0 or later** (General tab).

## Step 7 — Capabilities

Select the **`CarpWatch Watch App`** target → **Signing & Capabilities** → **+ Capability**, and add:

* **Background Modes** — then tick the modes you need:
  * ☑︎ **Audio** — required for the `microphone` background session and for any sound sensing.
  * ☑︎ **Workout processing** — required for the `workout` background session.
  * ☑︎ **Location updates** — only if you sample location.
* **HealthKit** — required for heart rate. After adding it, tick **Background Delivery**.

This writes `CarpWatch Watch App.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
	<key>com.apple.developer.healthkit.background-delivery</key>
	<true/>
</dict>
</plist>
```

> You do **not** need HealthKit, microphone, or location capabilities on the `Runner` (iOS) target.
> The phone only receives already-collected files. Adding capabilities you do not use only makes App
> Review harder.

## Step 8 — Background modes and privacy strings

Xcode 15 and later generate the watch app's `Info.plist` from build settings, so the easiest way to
add these is the target's **Info** tab (which writes the `INFOPLIST_KEY_*` build settings for you).

**Background modes** — added by Step 7, but verify that the watch target ends up with:

```xml
<key>WKBackgroundModes</key>
<array>
	<string>workout-processing</string>
</array>
<key>UIBackgroundModes</key>
<array>
	<string>audio</string>
	<string>location</string>
</array>
```

Drop `location` if you do not sample location, and `audio` if you use neither sound sensing nor the
`microphone` background session.

**Privacy strings** — watchOS refuses to ask the participant for a permission whose purpose string is
missing, and the sensor then silently produces nothing. Add one for every sensor you might enable:

| Key | Needed for | Example value |
|---|---|---|
| `NSHealthShareUsageDescription` | Heart rate | "This study reads your heart rate from the Health app to measure physiological arousal." |
| `NSHealthUpdateUsageDescription` | HealthKit (required alongside the above) | "This study does not write any data to the Health app." |
| `NSMicrophoneUsageDescription` | Sound sensing and the `microphone` background session | "The microphone is used to measure the noise level around you. No audio is recorded or saved." |
| `NSLocationWhenInUseUsageDescription` | Location | "Your location is collected to describe where you spend your time." |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Location in the background | Same as above |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth scanning | "Nearby Bluetooth devices are scanned to estimate social context. No connection is made." |

Be honest and specific in these strings — participants read them, and App Review does too. In
particular, say plainly that no audio is stored, since that is the question the microphone prompt
raises.

> **Also add these to the iOS `Runner` target** if your Flutter app itself uses the corresponding
> sensors through other CARP sampling packages. They are separate plists.

## Step 9 — The watch app source code

Replace the three files Xcode generated. All of them go in `ios/CarpWatch Watch App/`.

### `CarpWatchApp.swift`

```swift
import SwiftUI

@main
struct CarpWatchApp: App {
    @StateObject private var controller = CarpWatchSensorController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
                .onAppear { controller.activate() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Hand whatever has been collected to the phone before the app is
            // suspended, so nothing is left behind if the app is terminated.
            if phase == .background { controller.transferNow() }
        }
    }
}
```

> On watchOS 9 and earlier, `onChange(of:)` takes a single-parameter closure:
> `.onChange(of: scenePhase) { phase in ... }`.

### `CarpWatchSensorController.swift`

This is the whole watch-side logic: build the sensors, ask the phone how to configure them, start
them, and hand the data over on a schedule.

```swift
import Foundation
import SwiftUI
import WatchConnectivity

import com_awareframework_ios_core
import com_awareframework_ios_sensor_applewatch_shared
import com_awareframework_ios_sensor_applewatch_watchOS

/// Runs the AWARE sensors on the watch, configured by the paired iPhone.
///
/// The phone answers a `get_settings` request with the `AppleWatchDevice`
/// configuration from the deployed CARP study protocol, so this controller
/// holds no study-specific configuration of its own - only defaults used until
/// the phone has been heard from.
@MainActor
final class CarpWatchSensorController: NSObject, ObservableObject {

    // MARK: - Published state (for the UI)

    @Published private(set) var isRunning = false
    @Published private(set) var statusMessage = "Not started"
    @Published private(set) var activeSensorCount = 0
    @Published private(set) var lastTransferAt: Date?
    @Published private(set) var isPhoneReachable = false

    /// The AWARE device id of this watch. Handy to show in a debug screen.
    let deviceId = AwareUtils.getCommonDeviceId()

    // MARK: - Settings received from the phone

    private var backgroundSessionType: AWBackgroundSessionType = .microphone
    private var transferInterval: TimeInterval = 15 * 60
    private var transferIncrementally = true
    private var deleteAfterTransfer = true

    private var enabled: [String: Bool] = [
        "motion": true,
        "battery": true,
        "device": true,
        "heartRate": true,
        "location": false,
        "heading": false,
        "bluetooth": false,
        "audio": false,
    ]

    private var transferTimer: Timer?
    private var hasAppliedPhoneSettings = false

    // MARK: - Sensors

    private lazy var motion = AWMotionSensor(AWMotionSensor.Config().apply { config in
        config.motionSensorHz = 10
        config.saveIntervalSeconds = 10
        config.activateAccelerometerSensor = true
        config.activateDeviceMotionSensor = true
        // Gyroscope and magnetometer are covered by device motion - leaving
        // them on doubles the data volume for very little extra information.
        config.activateGyroscopeSensor = false
        config.activateMagnetometerSensor = false
    })

    private lazy var battery = AWBatterySensor(AWBatterySensor.Config().apply { config in
        config.intervalSeconds = 60
    })

    private lazy var device = AWDeviceSensor(AWDeviceSensor.Config())

    private lazy var heartRate = AWHeartRateSensor(AWHeartRateSensor.Config())

    private lazy var location = AWLocationSensor(AWLocationSensor.Config())

    private lazy var heading = AWHeadingSensor(AWHeadingSensor.Config())

    private lazy var bluetooth = AWBluetoothSensor(AWBluetoothSensor.Config().apply { config in
        config.sensingDurationSeconds = 10
        config.sleepDurationSeconds = 50
    })

    private lazy var audio = AWAudioSensor(AWAudioSensor.Config().apply { config in
        config.activateAmbientNoiseSensor = true
        config.activateAudioClassificationSensor = true
        // Never store raw audio - the phone side of this package does not
        // accept it, and a study that records audio needs a very different
        // consent process.
        config.activateRawAudioSensor = false
        config.dutyCycleEnabled = true
        config.activeDuration = 60
        config.restDuration = 180
        config.storeOnlyTopK = 5
    })

    // MARK: - Lifecycle

    /// Called when the watch app appears. Resumes sampling if it was running
    /// when the app was last closed, and asks the phone for the study settings.
    func activate() {
        _ = AWWCSessionManager.shared          // activates the WCSession
        isRunning = UserDefaults.standard.bool(forKey: Self.isRunningKey)
        updateReachability()

        // Chunk size and format only matter for how the data is packed; leave
        // the columnar format on, it is 3-5x smaller than row-oriented JSON.
        AWDataTransferManager.shared.useColumnarFormat = true
        AWDataTransferManager.shared.recordsPerChunk = 500

        applyPhoneSettings()
        if isRunning { start() }
    }

    /// Ask the phone for the study configuration and apply it.
    ///
    /// Safe to call at any time - if the phone cannot be reached the call
    /// simply has no effect, and the sensors keep running with whatever
    /// configuration they already have.
    func applyPhoneSettings() {
        guard WCSession.default.isReachable else {
            statusMessage = hasAppliedPhoneSettings
                ? statusMessage
                : "Waiting for the phone…"
            return
        }

        AWWCSessionManager.shared.applyiPhoneSettings { [weak self] settings in
            Task { @MainActor in self?.apply(settings: settings) }
        }
    }

    /// Map the settings sent by `AppleWatchDevice` onto the AWARE sensors.
    private func apply(settings: [String: Any]) {
        // `applyiPhoneSettings` already applied `label`, `db_host`, and `debug`
        // to every sensor registered in AWSensorManager. Everything below has
        // to be applied by hand, because only we know which sensors exist.

        if let hz = settings["motion_sensor_hz"] as? Int {
            motion.CONFIG.motionSensorHz = hz
        }
        if let value = settings["watch_motion_accelerometer_enabled"] as? Bool {
            motion.CONFIG.activateAccelerometerSensor = value
        }
        if let value = settings["watch_motion_device_motion_enabled"] as? Bool {
            motion.CONFIG.activateDeviceMotionSensor = value
        }

        if let value = settings["watch_audio_ambient_noise_enabled"] as? Bool {
            audio.CONFIG.activateAmbientNoiseSensor = value
        }
        if let value = settings["watch_audio_classification_enabled"] as? Bool {
            audio.CONFIG.activateAudioClassificationSensor = value
        }
        if let value = settings["watch_audio_duty_cycle_enabled"] as? Bool {
            audio.CONFIG.dutyCycleEnabled = value
        }
        if let value = settings["watch_audio_active_duration"] as? Double {
            audio.CONFIG.activeDuration = value
        }
        if let value = settings["watch_audio_rest_duration"] as? Double {
            audio.CONFIG.restDuration = value
        }

        enabled["motion"] = settings["watch_motion_enabled"] as? Bool ?? enabled["motion"]!
        enabled["battery"] = settings["watch_battery_enabled"] as? Bool ?? enabled["battery"]!
        enabled["device"] = settings["watch_device_enabled"] as? Bool ?? enabled["device"]!
        enabled["heartRate"] = settings["watch_healthkit_enabled"] as? Bool ?? enabled["heartRate"]!
        enabled["location"] = settings["watch_location_enabled"] as? Bool ?? enabled["location"]!
        enabled["heading"] = settings["watch_heading_enabled"] as? Bool ?? enabled["heading"]!
        enabled["bluetooth"] = settings["watch_bluetooth_enabled"] as? Bool ?? enabled["bluetooth"]!
        enabled["audio"] = settings["watch_audio_enabled"] as? Bool ?? enabled["audio"]!

        backgroundSessionType = AWBackgroundSessionType(
            rawValueOrDefault: settings["watch_background_session_type"] as? String
        )

        if let seconds = settings["file_transfer_interval_seconds"] as? Double, seconds > 0 {
            transferInterval = seconds
        }
        transferIncrementally =
            (settings["watch_transfer_mode"] as? String ?? "incremental") == "incremental"
        deleteAfterTransfer = settings["watch_delete_after_transfer"] as? Bool ?? true

        hasAppliedPhoneSettings = true
        statusMessage = "Configured by the phone"

        // Restart so the new configuration takes effect right away.
        if isRunning { start() }
    }

    // MARK: - Start / stop

    func start() {
        let sensors = selectedSensors()
        guard !sensors.isEmpty else {
            stop()
            statusMessage = "No sensors enabled"
            return
        }

        AWSensorManager.shared.set(sensors: sensors) { [weak self] in
            guard let self else { return }

            // Asks for HealthKit authorization if a heart rate sensor is in the
            // set. On watchOS the prompt is shown on the watch.
            AWSensorManager.shared.requestPermissionHealthKit { _, _ in }

            AWSensorManager.shared.start(backgroundSessionType: self.backgroundSessionType) {
                Task { @MainActor in
                    self.isRunning = true
                    self.activeSensorCount = sensors.count
                    self.statusMessage = "Collecting from \(sensors.count) sensors"
                    self.persistRunningState()
                    self.scheduleTransfers()
                    self.updateReachability()
                }
            }
        }
    }

    func stop() {
        transferTimer?.invalidate()
        transferTimer = nil

        AWSensorManager.shared.stop { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.isRunning = false
                self.activeSensorCount = 0
                self.statusMessage = "Stopped"
                self.persistRunningState()
            }
        }
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func selectedSensors() -> [AwareSensor] {
        var sensors: [AwareSensor] = []
        if enabled["motion"] == true { sensors.append(motion) }
        if enabled["battery"] == true { sensors.append(battery) }
        if enabled["device"] == true { sensors.append(device) }
        if enabled["heartRate"] == true { sensors.append(heartRate) }
        if enabled["location"] == true { sensors.append(location) }
        if enabled["heading"] == true { sensors.append(heading) }
        if enabled["bluetooth"] == true { sensors.append(bluetooth) }
        if enabled["audio"] == true { sensors.append(audio) }
        return sensors
    }

    // MARK: - Transferring data to the phone

    private func scheduleTransfers() {
        transferTimer?.invalidate()
        transferTimer = Timer.scheduledTimer(
            withTimeInterval: transferInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in self?.transferNow() }
        }
    }

    /// Hand everything collected so far to the phone.
    ///
    /// `WCSession.transferFile` queues the files, so this works even when the
    /// phone is out of range - the OS delivers them when it comes back.
    func transferNow() {
        let sensors = selectedSensors()
        guard !sensors.isEmpty else { return }

        statusMessage = "Transferring…"

        let completion: (Error?) -> Void = { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.statusMessage = "Transfer failed: \(error.localizedDescription)"
                } else {
                    self.lastTransferAt = Date()
                    self.statusMessage = self.isRunning
                        ? "Collecting from \(self.activeSensorCount) sensors"
                        : "Transfer complete"
                }
                self.updateReachability()
            }
        }

        if transferIncrementally {
            AWSensorManager.shared.transferIncrementalData(
                deleteAfterTransfer: deleteAfterTransfer,
                completion: completion
            )
        } else {
            AWSensorManager.shared.transferAllData(
                deleteAfterTransfer: deleteAfterTransfer,
                completion: completion
            )
        }
    }

    // MARK: - Helpers

    private static let isRunningKey = "carp_watch_is_running"

    private func persistRunningState() {
        UserDefaults.standard.set(isRunning, forKey: Self.isRunningKey)
    }

    private func updateReachability() {
        isPhoneReachable = WCSession.isSupported() && WCSession.default.isReachable
    }
}
```

### `ContentView.swift`

A minimal screen. Participants mostly never open it — but you will, constantly, while testing.

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: CarpWatchSensorController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    controller.isRunning ? "Collecting" : "Stopped",
                    systemImage: controller.isRunning ? "waveform.path.ecg" : "pause.circle"
                )
                .font(.headline)

                Text(controller.statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Label(
                    controller.isPhoneReachable ? "Phone reachable" : "Phone out of range",
                    systemImage: controller.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)

                if let lastTransferAt = controller.lastTransferAt {
                    Text("Last transfer: \(lastTransferAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button(controller.isRunning ? "Stop" : "Start") {
                    controller.toggle()
                }
                .tint(controller.isRunning ? .red : .green)

                Button("Send data to phone") {
                    controller.transferNow()
                }

                Button("Reload settings") {
                    controller.applyPhoneSettings()
                }
                .font(.footnote)
            }
            .padding(.horizontal, 4)
        }
    }
}
```

### Should the participant have to press Start?

For most studies, no. Two ways to avoid it:

* **Auto-start.** The controller above persists `isRunning`, so once sampling has been started it
  resumes by itself every time the app launches. Call `start()` unconditionally in `activate()` if
  you want it to begin on first launch too.
* **Explain the watch app in onboarding.** Whichever you choose, tell participants that the watch app
  must be *opened once* after installation — watchOS will not run it in the background before its
  first launch.

## Step 10 — Build and run

1. Select the **Runner** scheme and your iPhone → **Run**. This installs the Flutter app *and*
   the watch app (it is embedded in the iOS app).
2. On the phone, open the **Watch** app → **Available Apps** → install `CarpWatch` if it did not
   install automatically.
3. On the watch, open `CarpWatch` once and press **Start**.
4. Grant the permissions the watch asks for.

To iterate on the watch app alone, select the **CarpWatch Watch App** scheme and your watch as the
destination. Xcode will run just the watch app, which is much faster.

From the command line, `flutter run` builds the `Runner` scheme and therefore also the watch app:

```bash
flutter run --release       # release, because background sensing in debug is throttled
```

## Step 11 — Verify the data flow

Work through this in order — each step rules out a whole class of problem.

**a) The phone sees the watch.**

```dart
final watchManager =
    DeviceController().getDeviceManager(AppleWatchDevice.DEVICE_TYPE)
        as AppleWatchDeviceManager;

print(watchManager.watchStatus);
// AppleWatchStatus - supported: true, paired: true, appInstalled: true,
//                    reachable: true, collecting: true, activation: activated
```

`appInstalled: false` means the companion app is not on the watch — go back to Step 10.

**b) The watch is collecting.** `collecting: true` above means the watch app has sent its "I am
running" status message. On the watch itself, the screen says *Collecting from N sensors*.

**c) A transfer arrives.** Press **Send data to phone** on the watch, and watch the phone:

```dart
watchManager.fileTransferEvents.listen((transfer) => print(transfer));
// AppleWatchFileTransfer - aw_ios_watch_motion_1755432000_1of3.json.zlib
//                          (ios_watch_motion, 1/3): received
//                          ... : processing
//                          ... : decoded
```

**d) Measurements are produced.**

```dart
client.measurements
    .where((m) => m.dataType.namespace ==
        AppleWatchSamplingPackage.APPLE_WATCH_NAMESPACE)
    .listen(print);
```

If (c) works but (d) does not, the measure is missing from the study protocol — check that you added
the `Measure` to the **watch** device and not to the phone.

---

## Troubleshooting

**`error: the package product 'carp-aware-package' requires minimum platform version 16.0`**
The Runner target's deployment target is below 16.0. Redo [Step 2](#step-2--raise-the-ios-deployment-target-to-160)
— all three places — then `flutter clean && flutter pub get`.

**`No such module 'com_awareframework_ios_sensor_applewatch_watchOS'`**
The AWARE binaries are not linked into the watch target. Watch target → **General** →
**Frameworks, Libraries, and Embedded Content** → **+** → pick `carp-aware-watch`. Note the module
name uses `_` where the AWARE target name uses `.`, and the platform suffix is capitalised exactly as
`watchOS`.

**Duplicate symbols when linking the iOS app**
`carp-aware-watch` was added to the `Runner` target as well as to the watch target. Remove it from
`Runner` — the plugin already links the iOS AWARE binaries through `carp-aware-package`. See
[Step 6](#step-6--add-the-aware-framework-to-the-watch-target).

**`failed to build module 'com_awareframework_ios_sensor_applewatch_shared'`**
Swift can read a pre-compiled module with the compiler that produced it or a newer one, never an
older one. Check which Xcode built the binaries in
`ios/carp_aware_package/Frameworks/BUILD-INFO.txt` and update Xcode to at least that release — or
rebuild them yourself with `tool/build_xcframeworks.sh` from a checkout of this package.

**The watch app builds but never sends anything**
* Did you press **Start** on the watch at least once?
* Is a sensor actually enabled? An `AppleWatchDevice` with everything off collects nothing.
* Check the AWARE logs: set `enableNativeLogging: true` on the `AppleWatchDevice` and
  `config.debug = true` on the watch sensors, then read the Xcode console with the watch attached.

**`appInstalled` stays false**
watchOS only offers to install the companion app if the bundle identifier relationship in
[Step 5](#step-5--bundle-identifiers-and-signing) is right. Delete the app from both devices,
verify the identifiers, and reinstall.

**Data stops arriving when the wrist is lowered**
The watch app has no background runtime session. Set `backgroundSessionType` to `microphone` or
`workout` on the `AppleWatchDevice`, and make sure the matching background mode is ticked in
[Step 7](#step-7--capabilities). `none` only collects in the foreground — that is what it is for.

**Heart rate is always empty**
HealthKit authorization was denied, or `NSHealthShareUsageDescription` is missing so the prompt was
never shown. Check **Watch → Settings → Privacy & Security → Health** on the watch.

**Everything works in debug but not overnight**
Build in release (`flutter run --release`). Debug builds are attached to Xcode, which changes how
aggressively watchOS suspends the app, and the difference cuts both ways.

**Measurements arrive with a 15 minute delay**
That is by design — see `fileTransferInterval`. Lower it if the study needs fresher data, but note
that each transfer wakes the radio on both devices. The timestamps on the data are the watch's own,
so the delay does not distort the data itself.

---

## Appendix A — Settings the phone sends to the watch

The watch receives these when it calls `AWWCSessionManager.shared.applyiPhoneSettings`. All of them
come from the `AppleWatchDevice` in the deployed study protocol.

| Key | Type | Applied automatically by AWARE | From `AppleWatchDevice` |
|---|---|---|---|
| `label` | String | ✓ `sensor.set(label:)` | `label` |
| `db_host` | String | ✓ `dbEngine.config.host` | `awareServerUrl` |
| `debug` | Bool | ✓ `syncConfig.debug` | `enableNativeLogging` |
| `motion_sensor_hz` | Int | — | `motionSamplingRate` |
| `watch_motion_enabled` | Bool | — | `motionEnabled` |
| `watch_motion_accelerometer_enabled` | Bool | — | `accelerometerEnabled` |
| `watch_motion_device_motion_enabled` | Bool | — | `deviceMotionEnabled` |
| `watch_battery_enabled` | Bool | — | `batteryEnabled` |
| `watch_device_enabled` | Bool | — | `deviceInfoEnabled` |
| `watch_healthkit_enabled` | Bool | — | `heartRateEnabled` |
| `watch_location_enabled` | Bool | — | `locationEnabled` |
| `watch_heading_enabled` | Bool | — | `headingEnabled` |
| `watch_bluetooth_enabled` | Bool | — | `bluetoothEnabled` |
| `watch_audio_enabled` | Bool | — | `audioEnabled` |
| `watch_audio_ambient_noise_enabled` | Bool | — | `ambientNoiseEnabled` |
| `watch_audio_classification_enabled` | Bool | — | `audioClassificationEnabled` |
| `watch_audio_duty_cycle_enabled` | Bool | — | `audioDutyCycleEnabled` |
| `watch_audio_active_duration` | Double (s) | — | `audioActiveDuration` |
| `watch_audio_rest_duration` | Double (s) | — | `audioRestDuration` |
| `file_transfer_interval_seconds` | Double (s) | — | `fileTransferInterval` |
| `watch_background_session_type` | String | — | `backgroundSessionType` |
| `watch_transfer_mode` | String | — | `transferMode` |
| `watch_delete_after_transfer` | Bool | — | `deleteAfterTransfer` |

The last two are added by `carp_aware_package` — the plain AWARE framework does not know about them.

Adding a setting of your own is a two-line change: put it in `AppleWatchDevice.toWatchSettings()` on
the Dart side, and read it in `apply(settings:)` on the watch. Settings the native
`AppleWatchSensor.Config` does not know about are forwarded verbatim.

## Appendix B — What runs when

| Situation | Watch app | iOS app | Data |
|---|---|---|---|
| Watch app in foreground | Collecting | Anything | Buffered on the watch |
| Wrist lowered, background session active | Collecting | Anything | Buffered on the watch |
| Wrist lowered, `backgroundSessionType: .none` | Suspended | Anything | Nothing collected |
| Watch out of range of the phone | Collecting | Anything | Buffered; transfers queue up |
| Transfer fires, iOS app killed | Collecting | Launched in the background by iOS | Decoded and stored by CAMS |
| Watch app force-quit by the participant | Stopped | Anything | Nothing collected until reopened |

The row that matters most: **iOS launches your app in the background to deliver WatchConnectivity
files**. That is why the study should be deployed and running in CAMS — the plugin activates the
`WCSession` as part of connecting the `AppleWatchDevice`, and a session that was never activated gets
no deliveries.
