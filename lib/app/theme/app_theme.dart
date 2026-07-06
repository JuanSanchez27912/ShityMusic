import 'package:flutter/material.dart';

class AppTheme {
  static const Color _sand = Color(0xFFF5EFE4);
  static const Color _ink = Color(0xFF102A43);
  static const Color _ember = Color(0xFFDA5B21);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _pine = Color(0xFF071A1D);
  static const Color _mist = Color(0xFFB7E4DC);

  static final ThemeData lightTheme = _buildTheme(
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: _ember,
          brightness: Brightness.light,
        ).copyWith(
          primary: _teal,
          secondary: _ember,
          surface: const Color(0xFFFFFBF4),
          onSurface: _ink,
        ),
    scaffoldColor: _sand,
  );

  static final ThemeData darkTheme = _buildTheme(
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.dark,
        ).copyWith(
          primary: _mist,
          secondary: const Color(0xFFFF9966),
          surface: const Color(0xFF0B1619),
          onSurface: const Color(0xFFE6F5F1),
        ),
    scaffoldColor: _pine,
  );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldColor,
      textTheme:
          Typography.material2021(
            platform: TargetPlatform.iOS,
            colorScheme: colorScheme,
          ).black.copyWith(
            headlineLarge: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
            titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: const TextStyle(fontSize: 15, height: 1.45),
          ),
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.94),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.82),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.88),
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }

  static LinearGradient backdropGradient(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF031014), Color(0xFF0B2326), Color(0xFF1B2C31)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8F2E8), Color(0xFFF1E4D3), Color(0xFFEAEFE8)],
    );
  }
}
