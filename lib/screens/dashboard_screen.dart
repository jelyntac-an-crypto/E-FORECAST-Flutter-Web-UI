
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        ThemeToggleButton;
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/welcome_greeting.dart';
import '../widgets/household_card.dart';
import 'add_household_screen.dart';
import 'home_screen.dart';
import 'household_dashboard_screen.dart';
import 'report_form_screen.dart';
import 'reports_screen.dart';

/// SCR-03: Main Dashboard.
/// Loads the households registered to the signed-in user.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Household> _households = [];

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  /// Retrieves the signed-in user's households from FastAPI.
  Future<void> _loadHouseholds() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await ApiService.getHouseholds();

      final loadedHouseholds = response.map((item) {
        final address = item['address']?.toString() ?? '';

        // Separate the address into street and city.
        final parts = address.split(',');

        final street = parts.length > 1
            ? parts.sublist(0, parts.length - 1).join(',').trim()
            : address;

        final city = parts.length > 1
            ? parts.last.trim()
            : '';

        return Household(
          householdId: (item['household_id'] as num?)?.toInt(),
          meterNumber: item['meter_number']?.toString(),
          name: item['household_name']?.toString() ?? 'Household',
          street: street,
          city: city,
          occupants: (item['occupants'] as num?)?.toInt() ?? 1,
          provider: item['electricity_provider']?.toString() ?? 'Not set',
          ratePerKwh: (item['rate_per_kwh'] as num?)?.toDouble() ?? 0.0,
          billingCycleDay: (item['billing_cycle_day'] as num?)?.toInt() ?? 1,
          );
      }).toList();

      if (!mounted) return;

      setState(() {
        _households
          ..clear()
          ..addAll(loadedHouseholds);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Opens SCR-04 and reloads the households after saving.
  Future<void> _addHousehold() async {
    final created = await Navigator.of(context).push<Household>(
      MaterialPageRoute(
        builder: (_) => const AddHouseholdScreen(),
      ),
    );

    if (!mounted || created == null) return;

    await _loadHouseholds();

    if (!mounted) return;

    showTemporaryMessage(
      context,
      'Household "${created.name}" registered successfully.',
    );
  }

  /// Opens SCR-05 for the selected household.
  void _viewHousehold(Household household) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HouseholdDashboardScreen(household: household),
      ),
    );
  }

  /// Opens the report form.
  void _openReportForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportFormScreen(),
      ),
    );
  }

  /// Opens the Reports screen.
  void _openReports() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportsScreen(),
      ),
    );
  }

  void _openProfile() {
    showTemporaryMessage(
      context,
      'Profile / Settings (SCR-11) is not built yet. Temporary message.',
    );
  }

  /// Returns to the landing page.
  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: LandingColors.backgroundSoft,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left sidebar.
            DashboardSidebar(
              onSubmitReport: _openReportForm,
              onViewReports: _openReports,
            ),

            // Right dashboard content.
            Expanded(
              child: Column(
                children: [
                  _DashboardTopBar(
                    onProfile: _openProfile,
                    onLogout: _logout,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: LandingContainer(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 24 : 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const WelcomeGreeting(),
                              const SizedBox(height: 28),

                              _DashboardHeader(
                                onAddHousehold: _addHousehold,
                              ),

                              const SizedBox(height: 24),

                              // Loading state.
                              if (_isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(),
                                  ),
                                )

                              // Error state.
                              else if (_loadError != null)
                                LandingCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Unable to load households',
                                        style: TextStyle(
                                          color: LandingColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _loadError!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: LandingColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      LandingPrimaryButton(
                                        label: 'Try Again',
                                        large: false,
                                        onPressed: _loadHouseholds,
                                      ),
                                    ],
                                  ),
                                )

                              // Household list.
                              else
                                _HouseholdSection(
                                  households: _households,
                                  onAddHousehold: _addHousehold,
                                  onViewHousehold: _viewHousehold,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a floating SnackBar in the E-FORECAST style.
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

enum _AccountAction { profile, logout }

/// Dashboard top navigation bar.
class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _DashboardTopBar({
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Container(
      height: DashboardSidebar.headerHeight,
      decoration: BoxDecoration(
        color: LandingColors.background,
        border: Border(
          bottom: BorderSide(color: LandingColors.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  const ThemeToggleButton(),

                  if (compact)
                    _buildMenu()
                  else ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onProfile,
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Profile / Settings'),
                      style: _linkStyle(),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                      ),
                      label: const Text('Logout'),
                      style: _linkStyle(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _linkStyle() {
    return TextButton.styleFrom(
      foregroundColor: LandingColors.textSecondary,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account menu',
      icon: Icon(
        Icons.account_circle_outlined,
        color: LandingColors.textPrimary,
        size: 24,
      ),
      onSelected: (action) {
        switch (action) {
          case _AccountAction.profile:
            onProfile();
            break;

          case _AccountAction.logout:
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccountAction.profile,
          child: _menuRow(
            Icons.person_outline_rounded,
            'Profile / Settings',
          ),
        ),
        PopupMenuItem(
          value: _AccountAction.logout,
          child: _menuRow(
            Icons.logout_rounded,
            'Logout',
          ),
        ),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: LandingColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Dashboard page title and Add Household button.
class _DashboardHeader extends StatelessWidget {
  final VoidCallback onAddHousehold;

  const _DashboardHeader({
    required this.onAddHousehold,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Households',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage the households registered to your account.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );

    final addButton = LandingPrimaryButton(
      label: 'Add Household',
      large: false,
      onPressed: onAddHousehold,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: addButton,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }
}

/// Displays the empty state or household cards.
class _HouseholdSection extends StatelessWidget {
  final List<Household> households;
  final VoidCallback onAddHousehold;
  final void Function(Household household) onViewHousehold;

  const _HouseholdSection({
    required this.households,
    required this.onAddHousehold,
    required this.onViewHousehold,
  });

  @override
  Widget build(BuildContext context) {
    if (households.isEmpty) {
      return _EmptyHouseholds(
        onAddHousehold: onAddHousehold,
      );
    }

    return _HouseholdGrid(
      households: households,
      onViewHousehold: onViewHousehold,
    );
  }
}

/// Empty state shown when no households are registered.
class _EmptyHouseholds extends StatelessWidget {
  final VoidCallback onAddHousehold;

  const _EmptyHouseholds({
    required this.onAddHousehold,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: LandingColors.periwinkleTint,
                borderRadius: BorderRadius.circular(
                  LandingRadius.card,
                ),
              ),
              child: Icon(
                Icons.home_work_outlined,
                color: LandingColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No households yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Households you add will appear here, so you can '
                'manage each one from this page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            LandingPrimaryButton(
              label: 'Add Household',
              large: false,
              onPressed: onAddHousehold,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays household cards out in 1, 2 or 3 columns.
class _HouseholdGrid extends StatelessWidget {
  final List<Household> households;
  final void Function(Household household) onViewHousehold;

  const _HouseholdGrid({
    required this.households,
    required this.onViewHousehold,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;

        final width = constraints.maxWidth;

        final columns = width >= 900
            ? 3
            : (width >= 600 ? 2 : 1);

        final cardWidth =
            ((width - spacing * (columns - 1)) / columns)
                .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final household in households)
              SizedBox(
                width: cardWidth,
                child: HouseholdCard(
                  name: household.name,
                  address: household.address,
                  occupants: household.occupants,
                  provider: household.provider,
                  onView: () => onViewHousehold(household),
                ),
              ),
          ],
        );
      },
    );
  }
}
