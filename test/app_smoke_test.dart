import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharecode/app_state.dart';
import 'package:sharecode/ui.dart';

void main() {
  testWidgets('dashboard opens QR Studio and profile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: VibeShell(state: VibeState.demo())),
    );
    await tester.pumpAndSettle();
    expect(find.text('VibeDrop'), findsOneWidget);
    expect(find.text('Share QR'), findsOneWidget);

    await tester.tap(find.text('Studio'));
    await tester.pumpAndSettle();
    expect(find.text('QR Studio'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Kavishan Tharmaraj'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.tap(find.text('Connections'));
    await tester.pumpAndSettle();
    expect(find.text('No recent scans'), findsOneWidget);
    expect(find.text('No waves yet'), findsOneWidget);
  });
}
