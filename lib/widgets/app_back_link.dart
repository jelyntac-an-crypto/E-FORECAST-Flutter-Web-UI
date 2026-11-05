import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';

/// A small "← label" link shown at the top of a page to go back.
/// Used by Add Household and Household Dashboard.
class AppBackLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AppBackLink({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: LandingColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
