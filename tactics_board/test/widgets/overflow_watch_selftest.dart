import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'overflow_test.dart' show OverflowWatch;

/// Proves the sweep can fail.
///
/// The first version of the overflow sweep used tester.takeException() and
/// passed while printing pages of overflow warnings, because a RenderFlex
/// overflow is reported during paint and never surfaces there. A check that
/// cannot go red is worse than no check, so this pins the mechanism to a Row
/// that is deliberately too wide.
void main() {
  testWidgets('OverflowWatch catches a Row that is too wide', (tester) async {
    final watch = OverflowWatch()..start();
    addTearDown(watch.stop);
    await tester.binding.setSurfaceSize(const Size(100, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(children: [SizedBox(width: 400, height: 10)]),
      ),
    ));
    await tester.pump();

    expect(watch.drain('selftest'), isNotEmpty,
        reason: 'the sweep would not notice a real overflow');
  });

  testWidgets('and stays quiet when nothing overflows', (tester) async {
    final watch = OverflowWatch()..start();
    addTearDown(watch.stop);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Row(children: [SizedBox(width: 10, height: 10)])),
    ));
    await tester.pump();

    expect(watch.drain('selftest'), isEmpty);
  });
}
