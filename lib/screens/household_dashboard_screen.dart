import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show LandingCard, LandingContainer, LandingGrid, SampleDataChip;
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';
import 'forecast_bill_screen.dart';
import 'record_consumption_screen.dart';
import 'usage_history_screen.dart';
import 'usage_monitoring_screen.dart';

/// SCR-05: Selected Household Dashboard.
/// Shows the details of the household it receives. Record Consumption, Usage
/// History and Usage Monitoring open their own screens. Forecast & Bill is
/// not built yet, so it shows a temporary message. This is a UI preview:
/// there are no forecasts for the household.
class HouseholdDashboardScreen extends StatelessWidget {
  final Household household;

  const HouseholdDashboardScreen({super.key, required this.household});

  void _comingSoon(BuildContext context, String feature) {
    showTemporaryMessage(
      context,
      '$feature is not built yet. Temporary message.',
    );
  }

  /// Opens the Record Consumption screen for this household.
  void _openRecordConsumption(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordConsumptionScreen(household: household),
      ),
    );
  }

  /// Opens the Usage History screen for this household.
  void _openUsageHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsageHistoryScreen(household: household),
      ),
    );
  }

  /// Opens the Forecast & Bill screen for this household.
  void _openForecastBill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForecastBillScreen(household: household),
      ),
    );
  }

  /// Opens the Usage Monitoring screen for this household.
  void _openUsageMonitoring(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsageMonitoringScreen(household: household),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

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
                    padding: EdgeInsets.symmetric(vertical: compact ? 20 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: 'My Households',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 12),
                        _HouseholdHeader(household: household),
                        const SizedBox(height: 20),
                        _DetailsCard(household: household),
                        const SizedBox(height: 20),
                        _PreviewNotice(isSample: household.isSample),
                        const SizedBox(height: 24),
                        Text(
                          'Household tools',
                          style: TextStyle(
                            color: LandingColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionGrid(
                          onAction: (feature) {
                            if (feature == 'Record Consumption') {
                              _openRecordConsumption(context);
                            } else if (feature == 'Usage History') {
                              _openUsageHistory(context);
                            } else if (feature == 'Usage Monitoring') {
                              _openUsageMonitoring(context);
                            } else if (feature == 'Forecast & Bill') {
                              _openForecastBill(context);
                            } else {
                              _comingSoon(context, feature);
                            }
                          },
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
    );
  }
}

/// Formats the rate for display, e.g. 12.5 -> "₱12.50 per kWh".
/// Keeps up to 4 decimals if the user entered them.
String _formatRate(double rate) {
  final text = rate.toStringAsFixed(4).replaceFirst(RegExp(r'0{1,2}$'), '');
  return '₱$text per kWh';
}

/// House icon, household name and address.
class _HouseholdHeader extends StatelessWidget {
  final Household household;

  const _HouseholdHeader({required this.household});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: LandingColors.periwinkleTint,
            borderRadius: BorderRadius.circular(LandingRadius.card),
          ),
          child: Icon(
            Icons.home_rounded,
            color: LandingColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                household.name,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: compact ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: LandingColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      household.address,
                      style: TextStyle(
                        color: LandingColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (household.isSample) ...[
                const SizedBox(height: 10),
                const SampleDataChip(label: 'Sample data'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Occupants, provider, rate per kWh and billing cycle day.
class _DetailsCard extends StatelessWidget {
  final Household household;

  const _DetailsCard({required this.household});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final occupants = household.occupants;

    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: EdgeInsets.all(compact ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Household details',
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            _DetailRow(
              icon: Icons.people_outline_rounded,
              label: 'Occupants',
              value: occupants == 1 ? '1 occupant' : '$occupants occupants',
            ),
            Divider(color: LandingColors.border, height: 1),
            _DetailRow(
              icon: Icons.bolt_rounded,
              label: 'Electricity provider',
              value: household.provider,
            ),
            Divider(color: LandingColors.border, height: 1),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Rate per kWh',
              value: _formatRate(household.ratePerKwh),
            ),
            Divider(color: LandingColors.border, height: 1),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Billing cycle day',
              value: 'Day ${household.billingCycleDay} of the month',
            ),
          ],
        ),
      ),
    );
  }
}

/// One label / value line with a small icon.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LandingColors.periwinkleTint,
              borderRadius: BorderRadius.circular(LandingRadius.control),
            ),
            child: Icon(icon, size: 18, color: LandingColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: LandingColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: LandingColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tells the user this screen is a preview and the tools are not built yet.
class _PreviewNotice extends StatelessWidget {
  final bool isSample;

  const _PreviewNotice({required this.isSample});

  @override
  Widget build(BuildContext context) {
    final extra = isSample
        ? ' This is a sample household, so its values are placeholders.'
        : '';

    return LandingCard(
      color: LandingColors.periwinkleTint,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SampleDataChip(label: 'Preview'),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This screen is a UI preview. The tools below are not built '
              'yet, so this household has no readings, usage history or '
              'forecast.$extra',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four household tools: 2 columns on wide screens, 1 on phones.
class _ActionGrid extends StatelessWidget {
  final void Function(String feature) onAction;

  const _ActionGrid({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;

        return LandingGrid(
          columns: columns,
          children: [
            _ActionCard(
              icon: Icons.edit_note_rounded,
              title: 'Record Consumption',
              description: 'Enter previous and current meter readings.',
              onTap: () => onAction('Record Consumption'),
            ),
            _ActionCard(
              icon: Icons.history_rounded,
              title: 'Usage History',
              description: 'Review recorded readings and past usage.',
              onTap: () => onAction('Usage History'),
            ),
            _ActionCard(
              icon: Icons.show_chart_rounded,
              title: 'Usage Monitoring',
              description: 'Track household electricity usage over time.',
              onTap: () => onAction('Usage Monitoring'),
            ),
            _ActionCard(
              icon: Icons.auto_graph_rounded,
              title: 'Forecast & Bill',
              description: 'View a forecast and an estimated bill.',
              onTap: () => onAction('Forecast & Bill'),
            ),
          ],
        );
      },
    );
  }
}

/// A tappable card for one tool. The whole card is the tap target.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The InkWell sits inside the card so its tap ripple stays visible.
    return LandingCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LandingRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: LandingColors.periwinkleTint,
                    borderRadius: BorderRadius.circular(LandingRadius.control),
                  ),
                  child: Icon(icon, color: LandingColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: LandingColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: LandingColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: LandingColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
