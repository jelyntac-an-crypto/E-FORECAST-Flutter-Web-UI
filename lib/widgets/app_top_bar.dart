import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart' show LandingLogo;
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';

/// The top bar used on logged-in pages that have no sidebar.
/// Shows the logo on the left.
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(bottom: BorderSide(color: LandingColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.pagePadding,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: LandingLogo(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
