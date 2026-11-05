import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton;
import '../models/household.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_message.dart';
import '../widgets/app_top_bar.dart';

/// Record Consumption.
/// Lets the user enter a date plus the previous and current meter readings
/// for one household, then sends them to the backend. The backend works out
/// the kWh used. When the screen opens, the previous reading is filled in
/// from the household's last saved reading (the user can still edit it).
/// On success the screen closes and returns `true`.
class RecordConsumptionScreen extends StatefulWidget {
  final Household household;

  const RecordConsumptionScreen({super.key, required this.household});

  @override
  State<RecordConsumptionScreen> createState() =>
      _RecordConsumptionScreenState();
}

class _RecordConsumptionScreenState extends State<RecordConsumptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateCtrl = TextEditingController();
  final _previousCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();

  // The date the user picked. Starts as today.
  late DateTime _selectedDate;

  // True while the reading is being sent (shows "Saving…").
  bool _isSaving = false;

  // True while the last saved reading is being loaded.
  bool _isLoadingPrevious = true;

  // True if the previous reading was filled in from a saved reading.
  bool _prefilled = false;

  // True if the household was checked and has no saved readings yet.
  bool _noSavedReadings = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _dateCtrl.text = _displayDate(_selectedDate);
    _loadPreviousReading();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _previousCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Looks up the household's last saved reading and fills in the previous
  /// reading field. The field always stays editable. If anything goes wrong
  /// the user can simply type the value.
  Future<void> _loadPreviousReading() async {
    final householdId = widget.household.id;

    // A household without a server ID has no saved readings to look up.
    if (householdId == null) {
      setState(() => _isLoadingPrevious = false);
      return;
    }

    try {
      final last = await ApiService.getLastMeterReading(householdId);

      if (!mounted) return;

      setState(() {
        _isLoadingPrevious = false;

        if (last == null) {
          _noSavedReadings = true;
          return;
        }

        // Do not overwrite anything the user already typed or started saving.
        if (_previousCtrl.text.trim().isEmpty && !_isSaving) {
          _previousCtrl.text = last.toStringAsFixed(2);
          _prefilled = true;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPrevious = false);

      showTemporaryMessage(
        context,
        e.isSessionExpired
            ? e.message
            : 'Could not load your last meter reading. '
                  'You can type it in yourself.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrevious = false);

      showTemporaryMessage(
        context,
        'Could not load your last meter reading. You can type it in yourself.',
      );
    }
  }

  /// Opens the calendar and saves the chosen date.
  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select reading date',
      // Keep the calendar in the E-FORECAST light theme.
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = _dateOnly(picked);
      _dateCtrl.text = _displayDate(_selectedDate);
    });
  }

  /// Checks the form, sends the reading to the backend and handles the result.
  Future<void> _submit() async {
    // Stops double taps and a second Enter key press while saving.
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Households added only inside the app have no server id yet.
    final householdId = widget.household.id;
    if (householdId == null) {
      showTemporaryMessage(
        context,
        'This household is not saved on the server yet, so readings '
        'cannot be recorded for it.',
      );
      return;
    }

    final previous = double.parse(_previousCtrl.text.trim());
    final current = double.parse(_currentCtrl.text.trim());

    setState(() => _isSaving = true);

    try {
      final result = await ApiService.recordConsumption(
        householdId: householdId,
        consumptionDate: _selectedDate,
        meterPrevious: previous,
        meterCurrent: current,
      );

      if (!mounted) return;

      // The backend returns the kWh it calculated.
      final kwhValue = result['kwh'];
      final kwh = kwhValue is num
          ? kwhValue.toDouble()
          : double.tryParse('$kwhValue');

      showTemporaryMessage(
        context,
        kwh == null
            ? 'Consumption recorded successfully.'
            : 'Consumption recorded: ${kwh.toStringAsFixed(2)} kWh used.',
      );

      // Go back to the household dashboard.
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      // Friendly backend message. The user stays on the form to fix it.
      // This includes an expired or missing login (401).
      if (!mounted) return;
      setState(() => _isSaving = false);
      showTemporaryMessage(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showTemporaryMessage(context, 'Something went wrong. Please try again.');
    }
  }

  /// Leaves the screen without saving.
  void _cancel() => Navigator.of(context).pop();

  // ── Build ─────────────────────────────────────────────────────────────────

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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: LandingContainer(
                  maxWidth: 720,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 20 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: widget.household.name,
                          onPressed: _cancel,
                        ),
                        const SizedBox(height: 12),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: LandingCard(
                            padding: EdgeInsets.all(compact ? 20 : 28),
                            child: _buildForm(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The kWh used is calculated for you from the two '
                          'meter readings.',
                          style: TextStyle(
                            color: LandingColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record Consumption',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the previous and current meter readings for '
          '${widget.household.name}.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Helper text under the previous reading field. It tells the user what
  /// happened with the automatic fill-in.
  String get _previousHelper {
    if (_isLoadingPrevious) return 'Loading your last saved reading…';
    if (_prefilled) {
      return 'Filled in from your last saved reading. You can edit it.';
    }
    if (_noSavedReadings) {
      return 'No saved readings yet. Enter your meter reading as the '
          'starting point.';
    }
    return 'The last reading you recorded';
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      // Errors appear after the user has interacted with a field.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Buttons sit side by side when there is room.
          final wide = constraints.maxWidth >= 480;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date field: tapping opens the calendar.
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _isSaving ? null : _pickDate,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Consumption date is required'
                    : null,
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Consumption Date',
                  helperText: 'Tap to choose the date of the reading',
                  helperMaxLines: 2,
                  prefixIcon: Icon(
                    Icons.event_outlined,
                    size: 18,
                    color: LandingColors.textSecondary,
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: LandingColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _meterField(
                controller: _previousCtrl,
                label: 'Previous Meter Reading',
                hint: 'e.g. 211.00',
                helper: _previousHelper,
                icon: Icons.speed_outlined,
                validator: _validatePrevious,
              ),
              const SizedBox(height: 16),
              _meterField(
                controller: _currentCtrl,
                label: 'Current Meter Reading',
                hint: 'e.g. 223.50',
                helper: 'The reading on your meter now',
                icon: Icons.bolt_rounded,
                validator: _validateCurrent,
                last: true,
              ),
              const SizedBox(height: 24),
              if (wide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LandingSecondaryButton(
                      label: 'Cancel',
                      onPressed: _isSaving ? () {} : _cancel,
                    ),
                    const SizedBox(width: 12),
                    LandingPrimaryButton(
                      label: _isSaving ? 'Saving…' : 'Record Consumption',
                      onPressed: _isSaving ? () {} : _submit,
                    ),
                  ],
                )
              else ...[
                LandingPrimaryButton(
                  label: _isSaving ? 'Saving…' : 'Record Consumption',
                  onPressed: _isSaving ? () {} : _submit,
                ),
                const SizedBox(height: 12),
                LandingSecondaryButton(
                  label: 'Cancel',
                  onPressed: _isSaving ? () {} : _cancel,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// A meter reading field: numbers only, up to 2 decimal places.
  Widget _meterField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String helper,
    required IconData icon,
    required String? Function(String?) validator,
    bool last = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_isSaving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _submit() : null,
      style: TextStyle(color: LandingColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        suffixText: 'kWh',
        prefixIcon: Icon(icon, size: 18, color: LandingColors.textSecondary),
      ),
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validatePrevious(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Previous meter reading is required';

    final number = double.tryParse(text);
    if (number == null) return 'Enter a valid number, e.g. 211.00';
    if (number < 0) return 'Reading cannot be negative';
    return null;
  }

  String? _validateCurrent(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Current meter reading is required';

    final current = double.tryParse(text);
    if (current == null) return 'Enter a valid number, e.g. 223.50';
    if (current < 0) return 'Reading cannot be negative';

    // The current reading must be higher than the previous one.
    final previous = double.tryParse(_previousCtrl.text.trim());
    if (previous != null && current <= previous) {
      return 'Must be greater than the previous reading';
    }
    return null;
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  /// Removes the time part so only the day is kept.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
