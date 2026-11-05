// Design constants for the desktop website.
//
// These are just named numbers. Using a name like AppSpacing.lg instead of
// a plain 24 means we can change the look of the whole site from one place.
//
// The values match what the app already uses today, so adding this file
// changes nothing on screen. Colors are NOT here: they stay in
// landing_colors.dart so the light/dark switching keeps working.

// Gaps and padding. Each name is one step bigger than the last.
class AppSpacing {
  AppSpacing._(); // Not meant to be created. Only used as AppSpacing.lg etc.

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
}

/// Corner roundness. Same values as LandingRadius in landing_colors.dart.
class AppRadius {
  AppRadius._();

  static const double card = 12;
  static const double control = 8;
}

/// Big layout sizes for the logged-in desktop pages.
class AppLayout {
  AppLayout._();

  /// Width of the left sidebar.
  static const double sidebarWidth = 280;

  /// Height of the top bar (and of the logo area in the sidebar).
  static const double topBarHeight = 64;

  /// The widest the page content is allowed to be. On a bigger screen the
  /// content stays this wide and is centered.
  static const double contentMaxWidth = 1200;

  /// Space on the left and right of the page content.
  static const double pagePadding = 24;

  /// Smallest browser width we design for (a small laptop).
  static const double minDesktopWidth = 1024;
}

/// Text sizes. Only the size is stored here. Color comes from LandingColors,
/// because the color changes between light and dark mode.
class AppText {
  AppText._();

  static const double pageTitle = 28; // For example "My Households"
  static const double sectionTitle = 20; // A heading inside a page
  static const double cardTitle = 16; // The title of a card
  static const double body = 14; // Normal text
  static const double caption = 12; // Small helper text
}
