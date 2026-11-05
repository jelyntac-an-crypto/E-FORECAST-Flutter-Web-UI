import 'package:flutter/material.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton,
        LandingStatTile;
import '../models/consumption_record.dart';
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';

/// Usage History.
/// Shows every saved meter reading for one household, newest first, with a
/// summary (number of readings and total kWh) and a table. The records are
/// loaded from the backend when the screen opens, and the Refresh button
/// loads them again.
class UsageHistoryScreen extends StatefulWidget {
  final Household household;

  const UsageHistoryScreen({super.key, required this.household});

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  // The records shown in the table (newest first).
  List<ConsumptionRecord> _records = [];

  // True while the records are being loaded. It only starts as true when the
  // household has a server ID, because only then is there anything to load.
  bool _isLoading = false;

  // A friendly message if the last load failed. Null when there is no error.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // A household without a server ID has no saved readings to load.
    if (widget.household.id != null) {
      _isLoading = true;
      _fetch();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Asks the backend for the household's readings and stores the result.
  /// Does not need setState before it starts, so it is safe to call from
  /// initState. It updates the screen when the request finishes.
  Future<void> _fetch() async {
    final householdId = widget.household.id;
    if (householdId == null) return;

    try {
      final records = await ApiService.getConsumptionHistory(householdId);

      if (!mounted) return;

      setState(() {
        _records = records;
        _errorMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Loads the readings again. Used by Try Again.
  Future<void> _reload() async {
    // Ignore extra taps while a load is already running.
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _fetch();
  }

  /// Refresh button: loads the readings again and tells the user when done.
  Future<void> _refresh() async {
    await _reload();

    if (!mounted) return;

    // Only confirm if the refresh worked. Errors are shown on the screen.
    if (_errorMessage == null) {
      showTemporaryMessage(context, 'Usage history updated.');
    }
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
              // The whole page scrolls, so a long table scrolls with it.
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

  /// Title, short description and the Refresh button.
  Widget _buildHeader() {
    final hasServerId = widget.household.id != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usage History',
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: AppText.pageTitle,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Saved meter readings for ${widget.household.name}, '
                'newest first.',
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: AppText.body,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        // Nothing to refresh if the household is not saved on the server.
        if (hasServerId) ...[
          const SizedBox(width: AppSpacing.lg),
          LandingSecondaryButton(
            label: _isLoading ? 'Loading…' : 'Refresh',
            onPressed: _isLoading ? () {} : _refresh,
          ),
        ],
      ],
    );
  }

  /// Chooses what to show: no server ID, loading, error, empty or the data.
  Widget _buildBody() {
    if (widget.household.id == null) {
      return _buildStateCard(
        icon: Icons.cloud_off_outlined,
        title: 'Not saved on the server yet',
        message:
            'This household is not saved on the server yet, so there is no '
            'usage history to show.',
      );
    }

    if (_isLoading) {
      return _buildStateCard(
        title: 'Loading your readings…',
        message: 'This will only take a moment.',
        loading: true,
      );
    }

    if (_errorMessage != null) {
      return _buildStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Could not load usage history',
        message: _errorMessage!,
        action: LandingPrimaryButton(
          label: 'Try Again',
          large: false,
          onPressed: _reload,
        ),
      );
    }

    if (_records.isEmpty) {
      return _buildStateCard(
        icon: Icons.history_rounded,
        title: 'No readings yet',
        message:
            'Readings you record for this household will show up here. '
            'Use Record Consumption to add your first one.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummary(),
        const SizedBox(height: AppSpacing.xl),
        _buildTable(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Used (kWh) is the current reading minus the previous reading.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: AppText.caption,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// One card for the loading, error, empty and no-server-ID states.
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

  /// Two tiles: how many readings there are and the total kWh used.
  Widget _buildSummary() {
    final count = _records.length;
    final totalKwh = _records.fold<double>(0, (sum, r) => sum + r.kwh);

    // Note: this must NOT use CrossAxisAlignment.stretch. The page scrolls,
    // so its height is unlimited, and "stretch" cannot work with that.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LandingStatTile(
            label: 'Total Readings',
            value: '$count',
            caption: count == 1 ? 'Saved reading' : 'Saved readings',
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: LandingStatTile(
            label: 'Total Usage',
            value: '${totalKwh.toStringAsFixed(2)} kWh',
            caption: 'Across all saved readings',
            highlight: true,
          ),
        ),
      ],
    );
  }

  /// The table of readings. It sits inside the page scroll, so it scrolls
  /// together with the page.
  Widget _buildTable() {
    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: EdgeInsets.zero,
        // Clips the header background to the card's rounded corners.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LandingRadius.card - 1),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: LandingColors.border),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: LandingColors.backgroundSoft),
                children: [
                  _cell('Date', header: true),
                  _cell('Previous Reading', header: true, right: true),
                  _cell('Current Reading', header: true, right: true),
                  _cell('Used (kWh)', header: true, right: true),
                ],
              ),
              for (final record in _records)
                TableRow(
                  children: [
                    _cell(_displayDate(record.date)),
                    _cell(_formatReading(record.meterPrevious), right: true),
                    _cell(_formatReading(record.meterCurrent), right: true),
                    _cell(
                      record.kwh.toStringAsFixed(2),
                      right: true,
                      strong: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// One table cell. Numbers are right-aligned so the digits line up.
  Widget _cell(
    String text, {
    bool header = false,
    bool right = false,
    bool strong = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: header ? 14 : 16),
      child: Align(
        alignment: right ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: header
                ? LandingColors.textSecondary
                : LandingColors.textPrimary,
            fontSize: header ? AppText.caption : AppText.body,
            fontWeight: header || strong ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  /// A meter reading with 2 decimals. Older records may have no reading,
  /// so those show a dash.
  String _formatReading(double? value) =>
      value == null ? '—' : value.toStringAsFixed(2);

  /// Friendly format for the screen, e.g. "01 Nov 2026".
  String _displayDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = d.day.toString().padLeft(2, '0');
    return '$day ${months[d.month - 1]} ${d.year}';
  }
}
