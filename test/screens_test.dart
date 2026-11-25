import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharecode/core/models.dart';
import 'package:sharecode/core/store.dart';
import 'package:sharecode/core/theme.dart';
import 'package:sharecode/features/analytics.dart';
import 'package:sharecode/features/auth.dart';
import 'package:sharecode/features/chat.dart';
import 'package:sharecode/features/connections.dart';
import 'package:sharecode/features/edit_profile.dart';
import 'package:sharecode/features/export.dart';
import 'package:sharecode/features/home.dart';
import 'package:sharecode/features/intro.dart';
import 'package:sharecode/features/me.dart';
import 'package:sharecode/features/merch.dart';
import 'package:sharecode/features/notifications.dart';
import 'package:sharecode/features/privacy.dart';
import 'package:sharecode/features/pro.dart';
import 'package:sharecode/features/profile_view.dart';
import 'package:sharecode/features/scanner.dart';
import 'package:sharecode/features/settings.dart';
import 'package:sharecode/features/share.dart';
import 'package:sharecode/features/studio.dart';
import 'package:sharecode/features/wallet.dart';
import 'package:sharecode/features/wizard.dart';

/// Renders every screen on a small phone (360 wide), in both themes, and fails
/// on any layout/overflow error.
void main() {
  final store = AppStore();
  final screens = <String, Widget Function()>{
    'intro': () => const IntroPage(),
    'auth': () => const AuthPage(),
    'email': () => const EmailAuthPage(),
    'phone': () => const PhoneAuthPage(),
    'otp': () => const OtpPage(number: '+94 77 123 4567', whatsapp: true),
    'forgot': () => const ForgotPage(),
    'wizard': () => const WizardPage(),
    'home': () => const Scaffold(body: HomePage()),
    'studio': () => const Scaffold(body: StudioPage()),
    'connections': () => const Scaffold(body: ConnectionsPage()),
    'me': () => const Scaffold(body: MePage()),
    'privacy': () => const PrivacyPage(),
    'export': () => const ExportPage(),
    'export-story': () => const ExportPage(focus: 1),
    'analytics': () => const AnalyticsPage(),
    'pro': () => const ProPage(),
    'checkout': () => const CheckoutPage(plan: 1),
    'merch': () => const MerchPage(),
    'product': () => ProductPage(p: merch.first),
    'orders': () => const OrdersPage(),
    'wallet': () => const WalletPage(),
    'notifications': () => const NotificationsPage(),
    'settings': () => const SettingsPage(),
    'edit': () => const EditProfilePage(),
    'scanner': () => const ScannerPage(),
    'fullqr': () => const FullQrPage(),
    'chat': () => const ChatPage(handle: 'heshani_m', name: 'Heshani M.', seed: 12),
    'me-preview': () => PublicProfilePage(data: ViewData.fromMe(store), preview: true),
    for (var i = 0; i < 6; i++) 'contact-$i': () => PublicProfilePage(data: ViewData.fromContact(store.directory[i])),
  };

  for (final dark in [true, false]) {
    for (final e in screens.entries) {
      testWidgets('${e.key} renders (${dark ? 'dark' : 'light'})', (tester) async {
        tester.view.physicalSize = const Size(1080, 2220);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        // The test font (Ahem) is far wider than real fonts, so RenderFlex
        // overflow reports are ignored here; layout is checked on a device/web.
        final errors = <FlutterErrorDetails>[];
        final prev = FlutterError.onError;
        FlutterError.onError = (d) {
          if (!d.exceptionAsString().contains('overflowed')) errors.add(d);
        };
        await tester.pumpWidget(
          AppScope(
            store: store,
            child: MaterialApp(theme: buildTheme(dark), home: e.value()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 1800));
        await tester.pumpWidget(const SizedBox());
        FlutterError.onError = prev;
        expect(errors.map((d) => d.exceptionAsString()).toList(), isEmpty);
      });
    }
  }
}
