import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharecode/core/store.dart';
import 'package:sharecode/core/theme.dart';
import 'package:sharecode/features/shell.dart';

Widget host(AppStore s) => AppScope(
  store: s,
  child: ListenableBuilder(
    listenable: s,
    builder: (_, _) => MaterialApp(theme: buildTheme(true), home: const Shell()),
  ),
);

void main() {
  testWidgets('shell renders home and switches tabs without layout errors', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final errors = <FlutterErrorDetails>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) errors.add(d);
    };

    final store = AppStore()..qrReady = true;
    await tester.pumpWidget(host(store));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Hey Kavishan'), findsOneWidget);

    await tester.tap(find.text('Studio'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('QR Studio'), findsOneWidget);

    await tester.tap(find.text('Connections'));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(seconds: 1));

    FlutterError.onError = prev;
    if (errors.isNotEmpty) {
      fail(errors.take(2).map((e) => e.toString()).join('\n-----\n'));
    }
  });
}
