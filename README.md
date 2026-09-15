# CARP AWARE Apple Watch Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_aware_package.svg)](https://pub.dev/packages/carp_aware_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)
[![arXiv](https://img.shields.io/badge/arXiv-2006.11904-green.svg)](https://arxiv.org/abs/2006.11904)
[![Discord](https://img.shields.io/badge/Discord-Join-5865F2?logo=discord&logoColor=white)](https://discord.gg/SaePJ7MnQr)

This library contains a sampling package for collecting **passive sensor data from an Apple Watch**,
to work with the [`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) (CAMS) framework.
It wraps the [AWARE watchOS](https://github.com/awareframework/com.awareframework.ios.sensor.applewatch)
sensing framework by Yuuki Nishiyama (The University of Tokyo).

This package supports sampling of the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types)
types (note that the package defines its own namespace of `dk.carp.watch.aware`):

| Measure type | Data class | Description |
|---|---|---|
| `dk.carp.watch.aware.motion` | `AppleWatchMotion` | Raw acceleration, attitude, gravity, rotation rate, and user acceleration |
| `dk.carp.watch.aware.heartrate` | `AppleWatchHeartRate` | Heart rate (BPM) sampled via HealthKit |
| `dk.carp.watch.aware.battery` | `AppleWatchBattery` | Battery level and charging state of the watch |
| `dk.carp.watch.aware.location` | `AppleWatchLocation` | Location, altitude, speed, and course |
| `dk.carp.watch.aware.heading` | `AppleWatchHeading` | Compass heading and geomagnetic data |
| `dk.carp.watch.aware.bluetooth` | `AppleWatchBluetooth` | Nearby Bluetooth devices scanned by the watch |
| `dk.carp.watch.aware.ambientnoise` | `AppleWatchAmbientNoise` | Ambient noise level in decibel |
| `dk.carp.watch.aware.audiolabel` | `AppleWatchAudioLabel` | Sound classification using Apple's SoundAnalysis |
| `dk.carp.watch.aware.device` | `AppleWatchDeviceInfo` | Watch model, watchOS version, and the paired phone |

> **This package is iOS / watchOS only**, and it requires a companion watchOS app to be part of your
> Flutter app. See the [watchOS app setup guide](doc/watchos_app_setup.md) - it is a required step,
> not an optional one.

See the [CAMS documentation site](https://docs.carp.dk/carp-mobile-sensing/) for further documentation.
See the [CARP Mobile Sensing App](https://github.com/carp-dk/carp.sensing-flutter/tree/main/apps/carp_mobile_sensing_app)
for an example of how to build a mobile sensing app in Flutter.

For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/carp-dk/carp.sensing-flutter).

If you're interested in writing your own sampling packages for CARP, see the description on
how to [extend](https://docs.carp.dk/carp-mobile-sensing/extending-carp-mobile-sensing) CARP Mobile Sensing.

## How it works

```
   Apple Watch                                iPhone
┌────────────────────────┐            ┌──────────────────────────────┐
│ Watch app (watchOS)    │            │ Flutter app (iOS)            │
│                        │            │                              │
│  AWARE sensors         │            │  carp_aware_package plugin   │
│        ↓               │            │        ↓                     │
│  SQLite on the watch   │            │  AppleWatchSensor (AWARE)    │
│        ↓               │            │        ↓                     │
│  zlib JSON chunks  ────┼────────────┼──▶  AppleWatchDeviceManager  │
│    (WatchConnectivity) │            │        ↓                     │
└────────────────────────┘            │  probes → CAMS Measurements  │
                                      │        ↓                     │
                                      │  CARP data manager / CAWS    │
                                      └──────────────────────────────┘
```

The watch app collects data **while your Flutter app is not running** - the watch does not need to be
near the phone, and the phone does not need to be awake. Data is buffered in a database on the watch
and handed to the phone in compressed chunks on a schedule you choose (15 minutes by default).

This has two effects you should design your study around:

* **Measurements arrive in bursts, not continuously.** A chunk covering the last 15 minutes lands at
  once. Timestamps on the data are the ones set by the watch, so the data itself is correctly ordered
  in time - only its arrival is delayed.
* **The watch is configured from the study protocol.** The `AppleWatchDevice` configuration is handed
  to the watch app over `WatchConnectivity`. A protocol deployed from CARP Web Services therefore
  fully determines what the watch samples, without changing any watch-side code.

## Installing

To use this package, add the following to your `pubspec.yaml` file. Note that this package only works
together with `carp_mobile_sensing`.

```yaml
dependencies:
  flutter:
    sdk: flutter
  carp_core: ^latest
  carp_mobile_sensing: ^latest
  carp_aware_package: ^latest
  ...
```

### Android Integration

Not supported. The AWARE watchOS framework is an Apple-only framework.

If your app also runs on Android, registering this package is harmless - the probes simply never
produce data, and the `AppleWatchDeviceManager` reports that it cannot connect.

### iOS Integration

Three things are needed, in this order:

**1. Swift Package Manager.** The AWARE watchOS framework reaches your app as pre-compiled
XCFrameworks carried by this plugin, which are wired up through SwiftPM. There is no CocoaPods
podspec. Enable SwiftPM once per machine:

```bash
flutter config --enable-swift-package-manager
```

**2. iOS 16 deployment target.** The AWARE framework requires iOS 16. In Xcode, set the Runner
target's **Minimum Deployments** to iOS 16.0, and align the two other places Flutter keeps this
number:

```ruby
# ios/Podfile
platform :ios, '16.0'
```

```xml
<!-- ios/Flutter/AppFrameworkInfo.plist -->
<key>MinimumOSVersion</key>
<string>16.0</string>
```

**3. A companion watchOS app.** This package receives data - it cannot collect it. The watch app
that does the collecting is a watchOS target inside your Flutter app's Xcode project, and you have to
add it yourself.

👉 **[Follow the watchOS app setup guide](doc/watchos_app_setup.md)** - it walks through adding the
target, wiring up the AWARE framework, setting capabilities and permissions, and includes the
complete watch app source code, ready to paste in.

### How the AWARE framework is shipped

The AWARE watchOS framework is **not** a source dependency of this package. It is compiled ahead of
time into XCFrameworks that live in `ios/carp_aware_package/Frameworks` and are published together
with the plugin, so building an app against `carp_aware_package` never needs access to the AWARE
source:

| XCFramework | Linked by |
|---|---|
| `com_awareframework_ios_sensor_applewatch_shared` | the iOS app *and* the watch app |
| `com_awareframework_ios_sensor_applewatch_iOS` | the iOS side of this plugin, via `carp-aware-package` |
| `com_awareframework_ios_sensor_applewatch_watchOS` | the companion watch app, via `carp-aware-watch` |

They hold static libraries, so the open-source packages AWARE builds on
(`com.awareframework.ios.core`, [GRDB](https://github.com/groue/GRDB.swift) and
[DataCompression](https://github.com/mw99/DataCompression)) are deliberately *not* baked into them.
SwiftPM resolves those the usual way, which keeps exactly one copy of each in your app - it has to,
because the AWARE API uses `GRDB.DatabaseQueue` in public signatures.

`ios/carp_aware_package/Frameworks/BUILD-INFO.txt` records the AWARE revision, the Xcode release and
the dependency versions each build came from. Swift reads a pre-compiled module with the compiler
that produced it or a newer one, never an older one, so your Xcode has to be at least the one named
there.

To rebuild the binaries - after bumping AWARE, or to produce them with a different Xcode - check this
package out with its submodule and run:

```bash
git submodule update --init
tool/build_xcframeworks.sh
```

## Using it

To use this package, import it into your app together with the
[`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing) package:

```dart
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_aware_package/carp_aware_package.dart';
```

Before creating a study and running it, register this package in the
[`SamplingPackageRegistry`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry-class.html):

```dart
SamplingPackageRegistry().register(AppleWatchSamplingPackage());
```

### Adding the watch to a study protocol

The Apple Watch is a *connected device* of the phone. Add it to the protocol, and add the measures to
the watch - not to the phone - since the watch is the device collecting them.

```dart
// Define which devices are used for data collection.
final phone = Smartphone();

final watch = AppleWatchDevice(
  motionSamplingRate: 10,
  heartRateEnabled: true,
  batteryEnabled: true,
  fileTransferInterval: const Duration(minutes: 15),
);

protocol
  ..addPrimaryDevice(phone)
  ..addConnectedDevice(watch, phone);

// Collect motion, heart rate, and battery data from the watch.
protocol.addTaskControl(
  ImmediateTrigger(),
  BackgroundTask(measures: [
    Measure(type: AppleWatchSamplingPackage.MOTION),
    Measure(type: AppleWatchSamplingPackage.HEART_RATE),
    Measure(type: AppleWatchSamplingPackage.BATTERY),
  ]),
  watch,
);
```

### Configuring the watch

Everything the watch does is configured on the `AppleWatchDevice`. A sensor being enabled here is a
*request*: the watch app decides which sensors to actually start, and the participant may deny the
underlying permission on the watch.

| Property | Default | Description |
|---|---|---|
| `label` | `null` | An AWARE data label added to every record, e.g. a study id |
| `motionSamplingRate` | `10` | Motion sampling rate in Hz |
| `accelerometerEnabled` | `true` | Collect raw accelerometer data |
| `deviceMotionEnabled` | `true` | Collect attitude, gravity, rotation rate, user acceleration |
| `motionEnabled` | `true` | Run the motion sensor at all |
| `batteryEnabled` | `true` | Collect battery level and charging state |
| `deviceInfoEnabled` | `true` | Collect watch model and the paired phone id |
| `heartRateEnabled` | `true` | Collect heart rate via HealthKit |
| `locationEnabled` | `false` | Collect location (expensive on watch battery) |
| `headingEnabled` | `false` | Collect compass heading |
| `bluetoothEnabled` | `false` | Scan for nearby Bluetooth devices |
| `audioEnabled` | `false` | Master switch for the microphone |
| `ambientNoiseEnabled` | `true` | Measure noise level in dB (needs `audioEnabled`) |
| `audioClassificationEnabled` | `true` | Classify sounds (needs `audioEnabled`) |
| `audioDutyCycleEnabled` | `true` | Alternate between analyzing and resting |
| `audioActiveDuration` | 1 min | Length of the active audio phase |
| `audioRestDuration` | 3 min | Length of the resting audio phase |
| `fileTransferInterval` | 15 min | How often the watch hands data to the phone |
| `transferMode` | `incremental` | Send only new records, or all of them |
| `deleteAfterTransfer` | `true` | Delete records from the watch once transferred |
| `backgroundSessionType` | `microphone` | How the watch app keeps running - `none`, `workout`, or `microphone` |
| `saveToLocalAwareDatabase` | `false` | Also write received records to the AWARE database on the phone |
| `enableNativeLogging` | `false` | Verbose logging from the native AWARE framework |
| `awareServerUrl` | `null` | Let the watch upload directly to an AWARE server, bypassing CARP |

Note that no raw audio is ever transferred to the phone by this package - only the noise level and
the sound classification labels.

#### Background sessions

watchOS suspends an app shortly after the wrist is lowered, unless the app holds a background runtime
session. `backgroundSessionType` picks which one:

* `microphone` (default) - a silent microphone capture session. Gives background runtime without
  registering a workout. Requires microphone permission and the `audio` background mode.
* `workout` - an `HKWorkoutSession`. The longest and most reliable background runtime, but it shows
  up as a workout in Apple's fitness apps and affects the activity rings. Do not use this if the
  study must not leave workout history on the participant's watch.
* `none` - no background session. Data is only collected while the watch app is in the foreground.

### Runtime state of the watch

The `AppleWatchDeviceManager` exposes the runtime state of the connection, which is useful for
telling the participant what is going on:

```dart
final watchManager =
    DeviceController().getDeviceManager(AppleWatchDevice.DEVICE_TYPE)
        as AppleWatchDeviceManager;

// Is a watch paired, is the companion watch app installed, is it collecting?
print(watchManager.watchStatus);
watchManager.watchStatusEvents.listen((status) => print(status));

// The battery level of the watch, as of the last transfer.
print('Watch battery: ${watchManager.batteryLevel}%');

// Follow the data files as they arrive from the watch.
watchManager.fileTransferEvents.listen((transfer) => print(transfer));
```

`AppleWatchStatus.isAvailable` is the one to check before telling a participant that everything is
fine: it is true when `WatchConnectivity` is supported, a watch is paired, **and** the companion watch
app is installed on it. `isReachable` is *not* needed for data collection - the OS queues transfers
and delivers them when the watch comes back into range.

## Data volume and battery

The watch is a small device with a small battery. A few numbers to plan a study with:

* Motion at 10 Hz is roughly 36.000 records pr. hour, per participant. At 50 Hz it is 180.000.
  Every record becomes one CAMS `Measurement`.
* The AWARE authors measured 16-29 hours of battery life with a single sensor enabled. More sensors
  and higher sampling rates cut this down quickly.
* Location is the most expensive sensor on the watch - enable it only if the study needs it.
* `transferMode: WatchTransferMode.incremental` together with `deleteAfterTransfer: true` keeps both
  the radio time and the storage use on the watch bounded. This is the default.

Records are de-duplicated: every record carries the id it had in the database on the watch, which
CAMS uses as the `recordId` of the measurement. Re-transferring the same record - which
`WatchTransferMode.all` does by design - therefore does not produce duplicate data in the local
CAMS database.

## Credits

The watchOS sensing framework wrapped by this package is
[`com.awareframework.ios.sensor.applewatch`](https://github.com/awareframework/com.awareframework.ios.sensor.applewatch)
by Yuuki Nishiyama (The University of Tokyo), available under the Apache License 2.0.

If this framework helps your research project, please cite:

> Y. Nishiyama and K. Sezaki, "[Smartwatch-Based Sensing Framework for Continuous Data Collection:
> Design and Implementation](https://dl.acm.org/doi/10.1145/3594739.3612874)", UbiComp/ISWC '23
> Adjunct, pages 620-625, ACM, 2023.
