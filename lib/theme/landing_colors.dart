import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // Import to use the global themeNotifier
import '../services/api_service.dart';

/// Corner sizes used across the landing page and login screen.
class LandingRadius {
  LandingRadius._();
  static const double card = 12;
  static const double control = 8;
}

/// Holds light/dark mode and rebuilds the whole app when it changes.
/// The theme is saved in this browser only, separately for each logged-in
/// user (by user id). Light mode is the default.
class ThemeController {
  ThemeController._();

  // Point mode to the global themeNotifier in main.dart
  static ValueNotifier<ThemeMode> get mode => themeNotifier;
  static bool get isDark => mode.value == ThemeMode.dark;

  /// The browser-storage name for one user's theme.
  static String _key(int userId) => 'theme_mode_user_$userId';

  /// Shows a theme everywhere. Does not save anything.
  static void setMode(ThemeMode newMode) {
    mode.value = newMode;

    // Force rebuild every element so static LandingColors update everywhere
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }

  /// Used by the theme buttons and the Profile & Settings switch.
  /// Changes the theme and, if a user is logged in, saves it for that user.
  static void toggle() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
    _save(mode.value);
  }

  /// Saves the theme for the logged-in user. Nothing is saved if nobody is
  /// logged in (for example on the landing page).
  static Future<void> _save(ThemeMode value) async {
    final userId = ApiService.currentUserId;
    if (userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        value == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // The theme still changes on screen; it just will not be remembered.
    }
  }

  /// Call after login: shows this user's saved theme, or light mode if they
  /// have not saved one.
  static Future<void> loadForCurrentUser() async {
    final userId = ApiService.currentUserId;
    var theme = ThemeMode.light;

    if (userId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_key(userId)) == 'dark') {
          theme = ThemeMode.dark;
        }
      } catch (_) {
        // Keep light mode.
      }
    }

    setMode(theme);
  }

  /// Call at logout: shows light mode again. The saved preference is kept.
  static void resetToLight() => setMode(ThemeMode.light);
}

/// Palette for the landing page and login screen. Every color switches
/// between light and dark automatically.
class LandingColors {
  LandingColors._();

  static bool get _d => ThemeController.isDark;

  // Brand
  static Color get primary =>
      _d ? const Color(0xFF7479FF) : const Color(0xFF6367FF);
  static Color get secondary =>
      _d ? const Color(0xFF8E9CFF) : const Color(0xFF8494FF);

  // Backgrounds
  static Color get background =>
      _d ? const Color(0xFF0E0F1E) : const Color(0xFFFFFFFF);
  static Color get backgroundSoft =>
      _d ? const Color(0xFF15162B) : const Color(0xFFF8F7FF);

  // Pastel tints
  static Color get periwinkleTint =>
      _d ? const Color(0xFF1E2145) : const Color(0xFFEEF0FF);
  static Color get lavenderTint =>
      _d ? const Color(0xFF241F4A) : const Color(0xFFF1EDFF);
  static Color get pinkTint =>
      _d ? const Color(0xFF2E1B30) : const Color(0xFFFFEEF5);
  static Color get pinkBorder =>
      _d ? const Color(0xFF5C2E4C) : const Color(0xFFF8D3E4);
  static Color get pinkText =>
      _d ? const Color(0xFFF49AC6) : const Color(0xFFB4477A);

  // Text
  static Color get textPrimary =>
      _d ? const Color(0xFFF1F1FF) : const Color(0xFF202044);
  static Color get textSecondary =>
      _d ? const Color(0xFFA3A5C7) : const Color(0xFF686881);

  // Borders
  static Color get border =>
      _d ? const Color(0xFF2B2D52) : const Color(0xFFEAE7FF);

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get pageGradient => LinearGradient(
    colors: [background, backgroundSoft],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get ctaGradient => LinearGradient(
    colors: [periwinkleTint, pinkTint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: _d
          ? Colors.black.withValues(alpha: 0.35)
          : primary.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
