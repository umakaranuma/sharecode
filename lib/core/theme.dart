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

  static const violet = Color(0xFFF2711C);
  static const fuchsia = Color(0xFFFF9A4D);
  static const pink = Color(0xFFE5557A);
  static const orange = Color(0xFFF29B4B);
  static const green = Color(0xFF2FCB92);
  static const red = Color(0xFFF0545F);
  static const blue = Color(0xFF5AA0F5);
  static const gold = Color(0xFFF2C46B);

  static const brand = LinearGradient(
    colors: [Color(0xFFE8590C), Color(0xFFFF8A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const sunset = LinearGradient(
    colors: [Color(0xFFF29B4B), Color(0xFFE5557A), Color(0xFFFF8A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const proGrad = LinearGradient(
    colors: [Color(0xFFF6D98C), Color(0xFFD9A441)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkC = VC(
    bg: Color(0xFF0C0A09),
    card: Color(0xFF161311),
    card2: Color(0xFF1F1B18),
    border: Color(0x1AFFFFFF),
    text: Color(0xFFF8F3EE),
    sub: Color(0xFF9B9189),
    dark: true,
  );
  static const lightC = VC(
    bg: Color(0xFFFAF7F2),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF3EDE6),
    border: Color(0xFFEAE2D9),
    text: Color(0xFF1C1612),
    sub: Color(0xFF7C7168),
    dark: false,
  );

  Color get accent => dark ? const Color(0xFFFFA566) : violet;

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
    textTheme: base.textTheme
        .apply(bodyColor: c.text, displayColor: c.text)
        .copyWith(
          bodyLarge: TextStyle(fontSize: 14.5, color: c.text),
          titleMedium: TextStyle(fontSize: 14.5, color: c.text),
        ),
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
            : (dark ? const Color(0xFF3A332E) : const Color(0xFFD6CCC2)),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      hintStyle: TextStyle(color: c.sub.withValues(alpha: .7), fontSize: 14),
      labelStyle: TextStyle(color: c.sub, fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: VC.violet, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: VC.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
