import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingLogo;
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import 'rate_carousel.dart';

/// Left sidebar of the desktop dashboard.
///
/// Top: the E-FORECAST logo.
/// Middle: the "Electricity Rates" section with the animated [RateCarousel].
class DashboardSidebar extends StatelessWidget {
  /// Width of the sidebar on desktop (shared value from app_tokens.dart).
  static const double width = AppLayout.sidebarWidth;

  /// Height of the logo area. The top navigation in the main content area
  /// uses the same height so the lines meet across the screen.
  /// (shared value from app_tokens.dart)
  static const double headerHeight = AppLayout.topBarHeight;

  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(right: BorderSide(color: LandingColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo area ────────────────────────────────────────────────────
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: LandingColors.border)),
            ),
            child: const LandingLogo(),
          ),

          // ── Electricity Rates ────────────────────────────────────────────
          // Scrolls only if the browser window is very short.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RatesHeading(),
                  SizedBox(height: 16),
                  RateCarousel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Electricity Rates" title with a short description.
class _RatesHeading extends StatelessWidget {
  const _RatesHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_rounded, size: 18, color: LandingColors.primary),
            const SizedBox(width: 6),
            Text(
              'Electricity Rates',
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Residential rates per kWh from nearby electricity companies.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
