import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton,
        LandingStatTile;
import '../models/forecast_result.dart';
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';
import 'record_consumption_screen.dart';

/// Forecast & Bill.
/// The user taps Generate Forecast. The backend predicts the electricity use
/// for the day after the latest reading and the estimated bill. The screen
/// shows loading, success, "not enough data" and error states.
class ForecastBillScreen extends StatefulWidget {
  final Household household;

  const ForecastBillScreen({super.key, required this.household});

  @override
  State<ForecastBillScreen> createState() => _ForecastBillScreenState();
}

class _ForecastBillScreenState extends State<ForecastBillScreen> {
  // The forecast from the backend. Null until one is generated.
  ForecastResult? _result;

  // True while the backend is working.
  bool _isLoading = false;

  // True when the household has fewer than 7 readings.
  bool _notEnoughData = false;

  // A friendly message for any other error.
  String? _errorMessage;

  /// Asks the backend for a forecast.
  Future<void> _generate() async {
    final id = widget.household.id;

    // Ignore extra taps while a forecast is already being generated.
    if (id == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _notEnoughData = false;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.generateForecast(householdId: id);

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _result = null;
        _isLoading = false;
        if (e.code == 'INSUFFICIENT_HISTORICAL_DATA') {
          _notEnoughData = true;
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _result = null;
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  /// Opens Record Consumption so the user can add more readings.
  void _openRecordConsumption() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordConsumptionScreen(household: widget.household),
      ),
    );
  }

  /// Back link: returns to the household dashboard.
  void _goBack() => Navigator.of(context).pop();

  // ── Build ─────────────────────────────────────────────────────────────────

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
                          label: widget.household.name,
                          onPressed: _goBack,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildBody(),
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

  /// Title and short description.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forecast & Bill',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'See the predicted electricity use and estimated bill for '
          '${widget.household.name}.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.body,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Chooses what to show: no server ID, loading, not enough data, error,
  /// the result, or the first "Generate Forecast" prompt.
  Widget _buildBody() {
    if (widget.household.id == null) {
      return _buildStateCard(
        icon: Icons.cloud_off_outlined,
        title: 'Not saved on the server yet',
        message:
            'This household is not saved on the server yet, so a forecast '
            'cannot be generated.',
      );
    }

    if (_isLoading) {
      return _buildStateCard(
        title: 'Generating your forecast…',
        message: 'This will only take a moment.',
        loading: true,
      );
    }

    if (_notEnoughData) {
      return _buildStateCard(
        icon: Icons.insights_outlined,
        title: 'Not enough readings yet',
        message:
            'A forecast needs at least 7 saved readings. Record a few more '
            'readings, then come back and generate your forecast.',
        action: LandingPrimaryButton(
          label: 'Record Consumption',
          large: false,
          onPressed: _openRecordConsumption,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Could not generate forecast',
        message: _errorMessage!,
        action: LandingPrimaryButton(
          label: 'Try Again',
          large: false,
          onPressed: _generate,
        ),
      );
    }

    final result = _result;

    if (result == null) {
      return _buildStateCard(
        icon: Icons.auto_graph_rounded,
        title: 'Ready to forecast',
        message:
            'Tap the button to predict the next day\'s electricity use and '
            'the estimated bill, based on your saved readings.',
        action: LandingPrimaryButton(
          label: 'Generate Forecast',
          onPressed: _generate,
        ),
      );
    }

    return _buildResult(result);
  }

  /// The two result tiles, a short note and the Generate Again button.
  Widget _buildResult(ForecastResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LandingStatTile(
                label: 'Predicted Consumption',
                value: '${result.predictedKwh.toStringAsFixed(2)} kWh',
                caption: 'For the day after your latest reading',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: LandingStatTile(
                label: 'Estimated Bill',
                value: _money(result.estimatedBill),
                caption: 'Cost of the predicted consumption',
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'This is an estimate made by the forecasting model. Your real '
          'use and bill may be different.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.caption,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LandingSecondaryButton(label: 'Generate Again', onPressed: _generate),
      ],
    );
  }

  /// One card for the idle, loading, not-enough-data, error and
  /// no-server-ID states.
  Widget _buildStateCard({
    required String title,
    required String message,
    IconData? icon,
    bool loading = false,
    Widget? action,
  }) {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: LandingColors.primary,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 36, color: LandingColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: AppText.cardTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: AppText.body,
                  height: 1.5,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats an amount as pesos with commas, e.g. 1234.5 -> "₱1,234.50".
String _money(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '₱$whole.${parts[1]}';
}
