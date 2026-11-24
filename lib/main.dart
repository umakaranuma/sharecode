import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (cloudEnabled) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  AppLinks();
  runApp(const VibeDropApp());
}

class VibeDropApp extends StatefulWidget {
  const VibeDropApp({super.key});
  @override
  State<VibeDropApp> createState() => _VibeDropAppState();
}

class _VibeDropAppState extends State<VibeDropApp> {
  late final Future<VibeState> loading = VibeState.load();
  final navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? linkSubscription;

  @override
  void initState() {
    super.initState();
    linkSubscription = AppLinks().uriLinkStream.listen((uri) {
      final host = Uri.tryParse(profileHost)?.host;
      if (uri.host != host ||
          uri.pathSegments.length != 2 ||
          uri.pathSegments.first != 'u') {
        return;
      }
      final handle = uri.pathSegments.last;
      if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(handle)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ScannedProfilePage(handle: handle)),
        );
      });
    });
  }

  @override
  void dispose() {
    linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigatorKey,
    title: 'VibeDrop',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAF8FF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6E22EA),
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF8FF),
        foregroundColor: Color(0xFF101034),
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6DEF8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6DEF8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6E22EA), width: 1.5),
        ),
      ),
    ),
    home: FutureBuilder<VibeState>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Could not load VibeDrop: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final state = snapshot.data!;
        if (cloudEnabled) {
          return StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, auth) {
              if (Supabase.instance.client.auth.currentSession == null) {
                return AuthPage(
                  onSignedIn: () async {
                    await state.pullCloud();
                    setState(() {});
                  },
                );
              }
              return VibeShell(state: state);
            },
          );
        }
        return VibeShell(state: state);
      },
    ),
  );
}
