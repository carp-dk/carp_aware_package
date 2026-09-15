/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A CARP Mobile Sensing (CAMS) sampling package for collecting passive sensor
/// data from an Apple Watch using the
/// [AWARE watchOS](https://github.com/awareframework/com.awareframework.ios.sensor.applewatch)
/// sensing framework.
///
/// The watch collects data while the phone app is not running, stores it in a
/// local database on the watch, and transfers it to the paired iPhone in
/// compressed chunks over `WatchConnectivity`. This package unpacks those chunks
/// and emits them as CAMS [Measurement]s.
///
/// This package only works on iOS / watchOS.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'apple_watch_package.dart';
part 'apple_watch_device.dart';
part 'apple_watch_data.dart';
part 'apple_watch_probes.dart';
part 'apple_watch_service.dart';

part 'carp_aware_package.g.dart';
