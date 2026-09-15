// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_aware_package/carp_aware_package.dart';

/// This is a very simple example of how this sampling package is used as part
/// of defining a study protocol in CARP Mobile Sensing (CAMS).
///
/// NOTE, however, that the code below will not run on its own. A study protocol
/// needs to be deployed and executed in the CAMS framework, and the iOS app
/// needs a companion watchOS app - see `doc/watchos_app_setup.md`.
///
/// See the documentation on how to use CAMS:
/// https://docs.carp.dk/carp-mobile-sensing/
void main() async {
  // Register this sampling package before using its measures.
  SamplingPackageRegistry().register(AppleWatchSamplingPackage());

  // Create a study protocol.
  final protocol = SmartphoneStudyProtocol(
    ownerId: 'owner@dtu.dk',
    name: 'Apple Watch Sensing Example',
  );

  // Define which devices are used for data collection - the phone and an
  // Apple Watch paired with it.
  final phone = Smartphone();

  // The Apple Watch configuration is what tells the watch app what to sample.
  // It is handed to the watch over WatchConnectivity when the watch app asks
  // the phone for its settings.
  final watch = AppleWatchDevice(
    motionSamplingRate: 10,
    heartRateEnabled: true,
    batteryEnabled: true,
    // Sound sensing is off by default - enable the microphone and say what to
    // do with it. Note that no audio is ever transferred to the phone.
    audioEnabled: true,
    ambientNoiseEnabled: true,
    audioClassificationEnabled: true,
    // Hand the collected data to the phone every 15 minutes, and only send
    // records which have not been transferred before.
    fileTransferInterval: const Duration(minutes: 15),
    transferMode: WatchTransferMode.incremental,
    // Keep the watch app alive in the background without registering a workout.
    backgroundSessionType: WatchBackgroundSessionType.microphone,
  );

  protocol
    ..addPrimaryDevice(phone)
    ..addConnectedDevice(watch, phone);

  // Add a background task that collects motion, heart rate, battery, and sound
  // data from the watch.
  //
  // Note that the task is added to the watch - not to the phone - since the
  // watch is the device collecting the data.
  protocol.addTaskControl(
    ImmediateTrigger(),
    BackgroundTask(
      measures: [
        Measure(type: AppleWatchSamplingPackage.MOTION),
        Measure(type: AppleWatchSamplingPackage.HEART_RATE),
        Measure(type: AppleWatchSamplingPackage.BATTERY),
        Measure(type: AppleWatchSamplingPackage.AMBIENT_NOISE),
        Measure(type: AppleWatchSamplingPackage.AUDIO_LABEL),
        // Records which watch is paired with which phone - cheap to collect and
        // useful when cleaning the data afterwards.
        Measure(type: AppleWatchSamplingPackage.DEVICE),
      ],
    ),
    watch,
  );

  // Deploy the protocol on this phone and start sampling.
  final client = SmartPhoneClientManager();
  await client.configure();
  final study = await client.addStudyFromProtocol(protocol);
  await client.tryDeployment(study.studyDeploymentId, study.deviceRoleName);
  client.resume();

  // Print all measurements collected - including the ones from the watch.
  client.measurements.listen(print);

  // The device manager holds the runtime state of the watch, which is useful
  // for telling the participant what is going on.
  final watchManager =
      DeviceController().getDeviceManager(AppleWatchDevice.DEVICE_TYPE)
          as AppleWatchDeviceManager?;
  if (watchManager == null) return;

  // Is a watch paired, is the companion watch app installed on it, and is the
  // watch app collecting data right now?
  print(watchManager.watchStatus);
  watchManager.watchStatusEvents.listen((status) => print('Watch: $status'));

  // The battery level of the watch, as of the most recent transfer.
  print('Watch battery: ${watchManager.batteryLevel}%');

  // Follow the data files as they arrive from the watch.
  watchManager.fileTransferEvents.listen(
    (transfer) => print(
      'Transfer ${transfer.chunkIndex}/${transfer.totalChunks} '
      '(${transfer.table}): ${transfer.state.name}',
    ),
  );
}
