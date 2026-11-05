import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';

/// Shows a short message in the E-FORECAST style (a floating SnackBar).
/// Shared by the dashboard screens.
void showTemporaryMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: LandingColors.background,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LandingRadius.control),
        side: BorderSide(color: LandingColors.border),
      ),
      content: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: LandingColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
