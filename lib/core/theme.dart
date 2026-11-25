import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens for VibeDrop. Resolved from the active brightness.
class VC extends ThemeExtension<VC> {
  const VC({
    required this.bg,
    required this.card,
    required this.card2,
    required this.border,
    required this.text,
    required this.sub,
    required this.dark,
  });
  final Color bg, card, card2, border, text, sub;
  final bool dark;

  static const violet = Color(0xFF7C3AED);
  static const fuchsia = Color(0xFFC026D3);
  static const pink = Color(0xFFEC4899);
  static const orange = Color(0xFFFF7A18);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const gold = Color(0xFFFBBF24);

  static const brand = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF9333EA), Color(0xFFC026D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const sunset = LinearGradient(
    colors: [Color(0xFFFF7A18), Color(0xFFEC4899), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const proGrad = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFFF7A18)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkC = VC(
    bg: Color(0xFF0A0914),
    card: Color(0xFF15132A),
    card2: Color(0xFF1D1A38),
    border: Color(0x1FFFFFFF),
    text: Color(0xFFF5F3FF),
    sub: Color(0xFF9E9ABD),
    dark: true,
  );
  static const lightC = VC(
    bg: Color(0xFFF6F3FF),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF1ECFF),
    border: Color(0xFFE6DEF8),
    text: Color(0xFF14112E),
    sub: Color(0xFF6B6788),
    dark: false,
  );

  Color get accent => dark ? const Color(0xFFA78BFA) : violet;

  @override
  VC copyWith() => this;
  @override
  VC lerp(ThemeExtension<VC>? other, double t) => t < .5 ? this : (other as VC);
}

extension Ctx on BuildContext {
  VC get c => Theme.of(this).extension<VC>()!;
  TextTheme get tt => Theme.of(this).textTheme;
  Size get screen => MediaQuery.sizeOf(this);
}

ThemeData buildTheme(bool dark) {
  final c = dark ? VC.darkC : VC.lightC;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: VC.violet,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: c.card,
    ),
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    extensions: [c],
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: c.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? VC.violet
            : (dark ? const Color(0xFF3A3658) : const Color(0xFFCFC8E6)),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      hintStyle: TextStyle(color: c.sub.withValues(alpha: .7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: VC.violet, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: VC.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: VC.red, width: 1.6),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
