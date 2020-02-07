// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib.widgets/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:fidl_fuchsia_ui_input/fidl_async.dart';

class MockSchedulerBinding extends Mock implements SchedulerBinding {}

const _samplingOffset = Duration(microseconds: -5500);

void main() {
  final result = <ui.PointerData>[];

  MockSchedulerBinding scheduler;
  PointerEventsListener pointerEventsListener;

  setUp(() {
    result.clear();
    scheduler = MockSchedulerBinding();
    pointerEventsListener = PointerEventsListener(
        scheduler: scheduler,
        callback: (ui.PointerDataPacket packet) {
          result.addAll(packet.data);
        },
        samplingOffset: _samplingOffset);
  });

  PointerEvent _createSimulatedPointerEvent(
      PointerEventPhase phase, int eventTimeUs, double x, double y) {
    return PointerEvent(
        buttons: 0,
        deviceId: 0,
        pointerId: 1,
        eventTime: eventTimeUs * 1000,
        phase: phase,
        type: PointerEventType.touch,
        x: x,
        y: y);
  }

  test('resampling', () {
    final event0 =
        _createSimulatedPointerEvent(PointerEventPhase.down, 1000, 0.0, 0.0);
    final event1 =
        _createSimulatedPointerEvent(PointerEventPhase.move, 2000, 10.0, 0.0);
    final event2 =
        _createSimulatedPointerEvent(PointerEventPhase.move, 3000, 20.0, 0.0);
    final event3 =
        _createSimulatedPointerEvent(PointerEventPhase.up, 4000, 30.0, 0.0);

    var frameTime = Duration(milliseconds: 6);
    when(scheduler.currentSystemFrameTimeStamp).thenReturn(frameTime);

    pointerEventsListener
      ..onPointerEvent(event0)
      ..onPointerEvent(event1)
      ..onPointerEvent(event2)
      ..onPointerEvent(event3);

    // No pointer events should have been dispatched yet.
    expect(result.isEmpty, true);

    // Frame callback should have been requested.
    FrameCallback callback =
        verify(scheduler.scheduleFrameCallback(captureThat(isNotNull)))
            .captured
            .single;
    verify(scheduler.scheduleFrame());
    clearInteractions(scheduler);

    frameTime = Duration(milliseconds: 7);
    when(scheduler.currentSystemFrameTimeStamp).thenReturn(frameTime);
    callback(Duration());

    // Two pointer events should have been dispatched.
    expect(result.length, 2);
    expect(result[0].timeStamp, Duration(milliseconds: 1));
    expect(result[0].change, ui.PointerChange.down);
    expect(result[0].physicalX, 0.0);
    expect(result[0].physicalY, 0.0);
    expect(result[0].physicalDeltaX, 0.0);
    expect(result[0].physicalDeltaY, 0.0);

    expect(result[1].timeStamp, frameTime + _samplingOffset);
    expect(result[1].change, ui.PointerChange.move);
    expect(result[1].physicalX, 5.0 * ui.window.devicePixelRatio);
    expect(result[1].physicalY, 0.0);
    expect(result[1].physicalDeltaX, 5.0 * ui.window.devicePixelRatio);
    expect(result[1].physicalDeltaY, 0.0);

    // Another frame callback should have been requested.
    callback = verify(scheduler.scheduleFrameCallback(captureThat(isNotNull)))
        .captured
        .single;
    verify(scheduler.scheduleFrame());
    clearInteractions(scheduler);

    frameTime = Duration(milliseconds: 9);
    when(scheduler.currentSystemFrameTimeStamp).thenReturn(frameTime);
    callback(Duration());

    // Another pointer event should have been dispatched.
    expect(result.length, 3);
    expect(result[2].timeStamp, frameTime + _samplingOffset);
    expect(result[2].change, ui.PointerChange.move);
    expect(result[2].physicalX, 25.0 * ui.window.devicePixelRatio);
    expect(result[2].physicalY, 0.0);
    expect(result[2].physicalDeltaX, 20.0 * ui.window.devicePixelRatio);
    expect(result[2].physicalDeltaY, 0.0);

    // Another frame callback should have been requested.
    callback = verify(scheduler.scheduleFrameCallback(captureThat(isNotNull)))
        .captured
        .single;
    verify(scheduler.scheduleFrame());
    clearInteractions(scheduler);

    frameTime = Duration(milliseconds: 11);
    when(scheduler.currentSystemFrameTimeStamp).thenReturn(frameTime);
    callback(Duration());

    // Last pointer event should have been dispatched.
    expect(result.length, 4);
    expect(result[3].timeStamp, Duration(milliseconds: 4));
    expect(result[3].change, ui.PointerChange.up);
    expect(result[3].physicalX, 30.0 * ui.window.devicePixelRatio);
    expect(result[3].physicalY, 0.0);
    expect(result[3].physicalDeltaX, 5.0 * ui.window.devicePixelRatio);
    expect(result[3].physicalDeltaY, 0.0);
  });

  test('bad event time', () {
    const _badEventTimeUs = 9999999;
    final event0 = _createSimulatedPointerEvent(
        PointerEventPhase.down, _badEventTimeUs, 0.0, 0.0);
    final event1 = _createSimulatedPointerEvent(
        PointerEventPhase.up, _badEventTimeUs, 0.0, 0.0);

    var frameTime = Duration(milliseconds: 6);
    when(scheduler.currentSystemFrameTimeStamp).thenReturn(frameTime);

    pointerEventsListener..onPointerEvent(event0)..onPointerEvent(event1);

    // No pointer events should have been dispatched yet.
    expect(result.isEmpty, true);

    // Frame callback should have been requested.
    FrameCallback callback =
        verify(scheduler.scheduleFrameCallback(captureThat(isNotNull)))
            .captured
            .single;
    verify(scheduler.scheduleFrame());
    clearInteractions(scheduler);

    frameTime = Duration(milliseconds: 20);
    when(scheduler.currentSystemFrameTimeStamp).thenReturn(frameTime);
    callback(Duration());

    // Event time stamps should have been ignored and two pointer events
    // should have been dispatched.
    expect(result.length, 2);
    expect(result[0].change, ui.PointerChange.down);
    expect(result[1].change, ui.PointerChange.up);
  });
}
