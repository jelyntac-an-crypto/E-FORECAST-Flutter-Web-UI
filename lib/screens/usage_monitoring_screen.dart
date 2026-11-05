import 'dart:math' as math;

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
import '../models/usage_summary.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';

/// The time periods the user can look at.
enum _UsagePeriod {
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  thisMonth('This Month');

  final String label;

  const _UsagePeriod(this.label);
}

/// Usage Monitoring.
/// Shows the electricity consumption of one household over a chosen period:
/// summary cards (from the backend usage summary), the highest and lowest
/// readings, and a bar chart with one bar per saved reading. The data is
/// loaded when the screen opens, when the period changes and when the user
/// taps Refresh.
class UsageMonitoringScreen extends StatefulWidget {
  final Household household;

  const UsageMonitoringScreen({super.key, required this.household});

  @override
  State<UsageMonitoringScreen> createState() => _UsageMonitoringScreenState();
}

class _UsageMonitoringScreenState extends State<UsageMonitoringScreen> {
  // The period that is selected right now.
  _UsagePeriod _period = _UsagePeriod.last7Days;

  // The first and last day of the selected period (both days included).
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  // The totals from the backend. Null until the first load succeeds.
  UsageSummary? _summary;

  // The readings inside the period (newest first).
  List<ConsumptionRecord> _records = [];

  // True while data is being loaded. It only starts as true when the
  // household has a server ID, because only then is there anything to load.
  bool _isLoading = false;

  // A friendly message if the last load failed. Null when there is no error.
  String? _errorMessage;

  // Counts the loads. If the user changes the period while an older load is
  // still running, the older result is ignored when it arrives.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _updateRange();

    // A household without a server ID has no saved readings to load.
    if (widget.household.id != null) {
      _isLoading = true;
      _fetch();
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Works out the first and last day for the selected period.
  /// The last day is always today.
  void _updateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _rangeEnd = today;
    _rangeStart = switch (_period) {
      _UsagePeriod.last7Days => DateTime(
        today.year,
        today.month,
        today.day - 6,
      ),
      _UsagePeriod.last30Days => DateTime(
        today.year,
        today.month,
        today.day - 29,
      ),
      _UsagePeriod.thisMonth => DateTime(today.year, today.month, 1),
    };
  }

  /// Asks the backend for the totals and the readings of the selected period
  /// and stores the result. Safe to call from initState because it only
  /// updates the screen after the requests finish.
  Future<void> _fetch() async {
    final householdId = widget.household.id;
    if (householdId == null) return;

    final requestId = ++_requestId;
    final start = _rangeStart;
    final end = _rangeEnd;

    try {
      // Both requests run at the same time.
      final results = await Future.wait<Object>([
        ApiService.getUsageSummary(
          householdId: householdId,
          startDate: start,
          endDate: end,
        ),
        ApiService.getConsumptionHistory(
          householdId,
          startDate: start,
          endDate: end,
        ),
      ]);

      // Ignore the result if the screen is gone or a newer load has started.
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _summary = results[0] as UsageSummary;
        _records = results[1] as List<ConsumptionRecord>;
        _errorMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Loads the data again for the selected period. Used by Try Again.
  Future<void> _reload() async {
    // Ignore extra taps while a load is already running.
    if (_isLoading) return;

    setState(() {
      _updateRange();
      _isLoading = true;
      _errorMessage = null;
    });

    await _fetch();
  }

  /// Refresh button: loads the data again and tells the user when done.
  Future<void> _refresh() async {
    await _reload();

    if (!mounted) return;

    // Only confirm if the refresh worked. Errors are shown on the screen.
    if (_errorMessage == null && !_isLoading) {
      showTemporaryMessage(context, 'Usage data updated.');
    }
  }

  /// Switches to another period and loads its data.
  void _selectPeriod(_UsagePeriod period) {
    if (period == _period) return;

    setState(() {
      _period = period;
      _updateRange();
      _isLoading = true;
      _errorMessage = null;
    });

    _fetch();
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
              // The whole page scrolls together.
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
                        if (widget.household.id != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          _buildPeriodSelector(),
                        ],
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
                'Usage Monitoring',
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: AppText.pageTitle,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review electricity consumption over time for '
                '${widget.household.name}.',
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

  /// The three period buttons and the dates they cover.
  Widget _buildPeriodSelector() {
    return Row(
      children: [
        for (final period in _UsagePeriod.values) ...[
          _PeriodChip(
            label: period.label,
            selected: period == _period,
            onTap: () => _selectPeriod(period),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_fullDate(_rangeStart)} to ${_fullDate(_rangeEnd)}',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: AppText.caption,
              ),
            ),
          ),
        ),
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
            'usage to monitor.',
      );
    }

    if (_isLoading) {
      return _buildStateCard(
        title: 'Loading your usage…',
        message: 'This will only take a moment.',
        loading: true,
      );
    }

    if (_errorMessage != null) {
      return _buildStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Could not load usage',
        message: _errorMessage!,
        action: LandingPrimaryButton(
          label: 'Try Again',
          large: false,
          onPressed: _reload,
        ),
      );
    }

    final summary = _summary;

    if (summary == null || _records.isEmpty) {
      return _buildStateCard(
        icon: Icons.show_chart_rounded,
        title: 'No readings in this period',
        message:
            'No readings were saved from ${_fullDate(_rangeStart)} to '
            '${_fullDate(_rangeEnd)}. Try a longer period, or record a new '
            'reading with Record Consumption.',
      );
    }

    return _buildContent(summary);
  }

  /// The summary cards, the chart and a short note.
  Widget _buildContent(UsageSummary summary) {
    // The records are newest first. The highest and lowest are found here.
    final highest = _records.reduce((a, b) => b.kwh > a.kwh ? b : a);
    final lowest = _records.reduce((a, b) => b.kwh < a.kwh ? b : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryTiles(summary, highest, lowest),
        const SizedBox(height: AppSpacing.xl),
        _buildChartCard(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'The average is per saved reading. A reading can cover more than '
          'one day if you do not record every day.',
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

  /// Five tiles: total, average, readings, highest and lowest.
  /// The totals come from the backend. The highest and lowest are worked out
  /// from the readings in the period.
  Widget _buildSummaryTiles(
    UsageSummary summary,
    ConsumptionRecord highest,
    ConsumptionRecord lowest,
  ) {
    final count = summary.daysRecorded;

    final tiles = <Widget>[
      LandingStatTile(
        label: 'Total Consumption',
        value: '${summary.totalKwh.toStringAsFixed(2)} kWh',
        caption: _period.label,
        highlight: true,
      ),
      LandingStatTile(
        label: 'Average per Reading',
        value: '${summary.averageKwh.toStringAsFixed(2)} kWh',
        caption: 'Per saved reading',
      ),
      LandingStatTile(
        label: 'Readings',
        value: '$count',
        caption: count == 1 ? 'Saved reading' : 'Saved readings',
      ),
      LandingStatTile(
        label: 'Highest Reading',
        value: '${highest.kwh.toStringAsFixed(2)} kWh',
        caption: _fullDate(highest.date),
      ),
      LandingStatTile(
        label: 'Lowest Reading',
        value: '${lowest.kwh.toStringAsFixed(2)} kWh',
        caption: _fullDate(lowest.date),
      ),
    ];

    return Column(
      children: [
        _buildTileRow(tiles.sublist(0, 3)),
        const SizedBox(height: AppSpacing.lg),
        _buildTileRow(tiles.sublist(3)),
      ],
    );
  }

  /// A row with three equal slots. A row with fewer tiles leaves the rest
  /// empty so the tiles keep the same width in both rows.
  Widget _buildTileRow(List<Widget> tiles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: i < tiles.length ? tiles[i] : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  /// The card that holds the bar chart.
  Widget _buildChartCard() {
    // The records are newest first. The chart reads left to right in time.
    final chartRecords = _records.reversed.toList();

    return SizedBox(
      width: double.infinity,
      child: LandingCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consumption per reading',
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: AppText.cardTitle,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Each bar is one saved reading, in kWh. Hover over a bar to '
              'see its date and exact value.',
              style: TextStyle(
                color: LandingColors.textSecondary,
                fontSize: AppText.caption,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _UsageBarChart(records: chartRecords),
          ],
        ),
      ),
    );
  }
}

/// A small pill button for choosing the period.
class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LandingRadius.control),
      side: BorderSide(
        color: selected ? LandingColors.primary : LandingColors.border,
      ),
    );

    return Material(
      color: selected ? LandingColors.primary : LandingColors.background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : LandingColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A bar chart made of plain widgets (no chart package). One bar for each
/// saved reading, oldest on the left. It has a kWh scale on the left, date
/// labels underneath, and a tooltip with the exact value when hovering.
class _UsageBarChart extends StatelessWidget {
  /// The readings to draw, oldest first. Must not be empty.
  final List<ConsumptionRecord> records;

  const _UsageBarChart({required this.records});

  static const double _chartHeight = 300;
  static const double _yAxisWidth = 56;
  static const double _labelRowHeight = 28;

  // The scale has this many equal steps (so 5 lines including zero).
  static const int _steps = 4;

  // With this many readings or fewer, the kWh value is printed on each bar.
  static const int _maxBarsWithValues = 10;

  @override
  Widget build(BuildContext context) {
    final count = records.length;
    final highest = records.fold<double>(0, (m, r) => math.max(m, r.kwh));

    // A tidy step size, so the scale shows round numbers (for example
    // 0, 5, 10, 15, 20) and the tallest bar always fits.
    final step = _niceStep(highest / _steps);
    final axisMax = step * _steps;

    // The chart has a fixed height, so "stretch" is safe here even though
    // the page scrolls.
    return SizedBox(
      height: _chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _yAxisWidth,
            child: Column(
              children: [
                Expanded(child: _buildYAxis(step)),
                const SizedBox(height: _labelRowHeight),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / count;

                // Show a date label only every few bars when bars are narrow,
                // so the labels never overlap.
                final labelEvery = math.max(1, (64 / slotWidth).ceil());

                return Column(
                  children: [
                    Expanded(child: _buildPlot(axisMax, slotWidth)),
                    SizedBox(
                      height: _labelRowHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < count; i++)
                            Expanded(child: _buildDateLabel(i, labelEvery)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The kWh numbers on the left, one for each grid line.
  Widget _buildYAxis(double step) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [for (var i = 0; i <= _steps; i++) _buildYLabel(i, step)],
    );
  }

  Widget _buildYLabel(int index, double step) {
    // -1 is the top of the plot and 1 is the bottom.
    final y = 1 - 2 * index / _steps;

    return Align(
      alignment: Alignment(1, y),
      // Moves the label so its middle sits on the grid line.
      child: FractionalTranslation(
        translation: Offset(0, y / 2),
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            _formatAxisValue(step * index),
            style: TextStyle(color: LandingColors.textSecondary, fontSize: 11),
          ),
        ),
      ),
    );
  }

  /// The grid lines and the bars.
  Widget _buildPlot(double axisMax, double slotWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final plotHeight = constraints.maxHeight;
        final showValues = records.length <= _maxBarsWithValues;
        final barWidth = math.min(36.0, slotWidth * 0.62);

        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            for (var i = 0; i <= _steps; i++)
              Align(
                alignment: Alignment(0, 1 - 2 * i / _steps),
                child: Container(height: 1, color: LandingColors.border),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final record in records)
                  Expanded(
                    child: _buildBar(
                      record,
                      axisMax,
                      plotHeight,
                      barWidth,
                      showValues,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// One bar with its tooltip (and its value on top when there is room).
  Widget _buildBar(
    ConsumptionRecord record,
    double axisMax,
    double plotHeight,
    double barWidth,
    bool showValue,
  ) {
    final fraction = axisMax <= 0
        ? 0.0
        : (record.kwh / axisMax).clamp(0.0, 1.0).toDouble();

    var barHeight = fraction * plotHeight;

    // Keep a very small but real value visible.
    if (record.kwh > 0 && barHeight < 3) barHeight = 3;

    return Tooltip(
      message:
          '${_fullDate(record.date)}\n${record.kwh.toStringAsFixed(2)} kWh',
      preferBelow: false,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: LandingColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
          if (showValue)
            Positioned(
              left: 0,
              right: 0,
              bottom: barHeight + 4,
              child: Text(
                record.kwh.toStringAsFixed(2),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The date under a bar. Bars that are skipped get an empty space.
  Widget _buildDateLabel(int index, int labelEvery) {
    if (index % labelEvery != 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      // Lets the label be a little wider than a narrow bar slot.
      child: OverflowBox(
        minWidth: 0,
        maxWidth: 72,
        child: Text(
          _shortDate(records[index].date),
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(color: LandingColors.textSecondary, fontSize: 11),
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

const List<String> _monthNames = [
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

/// Short date for chart labels, e.g. "01 Nov".
String _shortDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  return '$day ${_monthNames[d.month - 1]}';
}

/// Full date for the screen, e.g. "01 Nov 2026".
String _fullDate(DateTime d) => '${_shortDate(d)} ${d.year}';

/// Rounds a step size up to 1, 2 or 5 (times a power of 10), so the chart
/// scale shows round numbers.
double _niceStep(double rawStep) {
  if (rawStep <= 0) return 1;

  final magnitude = math
      .pow(10, (math.log(rawStep) / math.ln10).floor())
      .toDouble();
  final fraction = rawStep / magnitude;

  final double nice;
  if (fraction <= 1) {
    nice = 1;
  } else if (fraction <= 2) {
    nice = 2;
  } else if (fraction <= 5) {
    nice = 5;
  } else {
    nice = 10;
  }

  return nice * magnitude;
}

/// A number for the chart scale: "10" for whole numbers, "2.5" or "0.15" for
/// the others.
String _formatAxisValue(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);

  final text = value.toStringAsFixed(2);
  return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
}
