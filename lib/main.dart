import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'features/auth.dart';
import 'features/intro.dart';
import 'features/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VibeDropApp());
}

class VibeDropApp extends StatefulWidget {
  const VibeDropApp({super.key});
  @override
  State<VibeDropApp> createState() => _VibeDropAppState();
}

class _VibeDropAppState extends State<VibeDropApp> {
  final store = AppStore();

  @override
  Widget build(BuildContext context) => AppScope(
    store: store,
    child: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        SystemChrome.setSystemUIOverlayStyle(
          store.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
        return MaterialApp(
          title: 'VibeDrop',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(false),
          darkTheme: buildTheme(true),
          themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
          home: const Root(),
        );
      },
    ),
  );
}

class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final Widget page;
    if (!s.seenIntro) {
      page = const IntroPage(key: ValueKey('intro'));
    } else if (!s.signedIn) {
      page = const AuthPage(key: ValueKey('auth'));
    } else {
      page = const Shell(key: ValueKey('shell'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      child: page,
    );
  }
}
