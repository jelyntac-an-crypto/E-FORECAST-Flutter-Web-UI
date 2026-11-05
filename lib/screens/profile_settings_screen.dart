import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingCard, LandingContainer, LandingSecondaryButton;
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';
import 'home_screen.dart';

/// Profile & Settings.
/// - Profile: waiting for backend endpoints, so the fields are disabled and
///   nothing is faked.
/// - Appearance: a working light/dark switch, remembered in this browser.
/// - Account: Logout, which clears the login token.
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  /// Clears the login token and returns to the landing page.
  void _logout(BuildContext context) {
    ApiService.logout();
    ThemeController.resetToLight();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same pattern as the other screens: the theme-aware light theme.
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        body: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: LandingContainer(
                  maxWidth: 960,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: 'My Households',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Profile & Settings',
                          style: TextStyle(
                            color: LandingColors.textPrimary,
                            fontSize: AppText.pageTitle,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your account details and how E-FORECAST '
                          'looks.',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: AppText.body,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _buildProfileCard(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAppearanceCard(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAccountCard(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile: disabled fields until the backend has profile endpoints.
  Widget _buildProfileCard() {
    return _SettingsCard(
      icon: Icons.person_outline_rounded,
      title: 'Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile details are not available yet. They need a backend '
            'profile endpoint (GET and PUT /api/users/me). Editing is turned '
            'off until then.',
            style: TextStyle(
              color: LandingColors.textSecondary,
              fontSize: AppText.body,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'Not available yet',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Not available yet',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const OutlinedButton(
            onPressed: null,
            child: Text('Edit Profile (coming soon)'),
          ),
        ],
      ),
    );
  }

  /// Appearance: the light/dark switch. It saves in this browser only.
  Widget _buildAppearanceCard() {
    return _SettingsCard(
      icon: Icons.palette_outlined,
      title: 'Appearance',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark mode',
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved on this browser only.',
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: AppText.caption,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: ThemeController.isDark,
            onChanged: (_) => ThemeController.toggle(),
          ),
        ],
      ),
    );
  }

  /// Account: Logout.
  Widget _buildAccountCard(BuildContext context) {
    return _SettingsCard(
      icon: Icons.manage_accounts_outlined,
      title: 'Account',
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Log out of E-FORECAST on this browser.',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: AppText.body,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          LandingSecondaryButton(
            label: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

/// A card with an icon, a title and some content.
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: LandingColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: AppText.sectionTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}
