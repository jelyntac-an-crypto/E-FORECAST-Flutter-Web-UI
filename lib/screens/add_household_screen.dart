
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../landing/landing_widgets.dart'
    show
        LandingCard,
        LandingContainer,
        LandingPrimaryButton,
        LandingSecondaryButton;
import '../models/household.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/landing_colors.dart';
import '../widgets/app_back_link.dart';
import '../widgets/app_top_bar.dart';

/// SCR-04: Add Household.
/// Saves household details to the FastAPI backend.
class AddHouseholdScreen extends StatefulWidget {
  const AddHouseholdScreen({super.key});

  @override
  State<AddHouseholdScreen> createState() => _AddHouseholdScreenState();
}

class _AddHouseholdScreenState extends State<AddHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _meterNumberCtrl = TextEditingController();
  final _occupantsCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _billingDayCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _meterNumberCtrl.dispose();
    _occupantsCtrl.dispose();
    _providerCtrl.dispose();
    _rateCtrl.dispose();
    _billingDayCtrl.dispose();
    super.dispose();
  }

  // Validates the form and saves the household through FastAPI.
  Future<void> _save() async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final householdName = _nameCtrl.text.trim();
      final street = _streetCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      final occupants = int.parse(_occupantsCtrl.text.trim());
      final provider = _providerCtrl.text.trim();
      final rate = double.parse(_rateCtrl.text.trim());
      final billingDay = int.parse(_billingDayCtrl.text.trim());

      // Send all required household details to FastAPI.
      await ApiService.createHousehold(
        householdName: householdName,
        address: '$street, $city',
        meterNumber: _meterNumberCtrl.text.trim(),
        occupants: occupants,
        electricityProvider: provider,
        ratePerKwh: rate,
        billingCycleDay: billingDay,
      );

      if (!mounted) return;

      // Return to the dashboard after successful registration.
      Navigator.of(context).pop(
        Household(
          name: householdName,
          street: street,
          city: city,
          occupants: occupants,
          provider: provider,
          ratePerKwh: rate,
          billingCycleDay: billingDay,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Leaves the screen without saving.
  void _cancel() {
    if (_isSaving) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

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
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 20 : 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBackLink(
                          label: 'My Households',
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
                          'All household details are securely saved to your account.',
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
          'Add Household',
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontSize: AppText.pageTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the details of the household you want to track.',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= 480;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                controller: _nameCtrl,
                label: 'Household Name',
                hint: 'e.g. Family Home',
                icon: Icons.home_outlined,
                capitalization: TextCapitalization.words,
                validator: _validateName,
              ),
              const SizedBox(height: 16),

              _field(
                controller: _meterNumberCtrl,
                label: 'Meter Number',
                hint: 'Enter your electricity meter number',
                icon: Icons.electric_meter_outlined,
                validator: (v) => _validateRequired(v, 'Meter number'),
              ),
              const SizedBox(height: 16),

              _fieldRow(
                twoCol,
                _field(
                  controller: _streetCtrl,
                  label: 'Street / Barangay',
                  icon: Icons.signpost_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      _validateRequired(v, 'Street / Barangay'),
                ),
                _field(
                  controller: _cityCtrl,
                  label: 'City / Municipality',
                  icon: Icons.location_city_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      _validateRequired(v, 'City / Municipality'),
                ),
              ),
              const SizedBox(height: 16),

              _fieldRow(
                twoCol,
                _field(
                  controller: _occupantsCtrl,
                  label: 'Number of Occupants',
                  icon: Icons.people_outline_rounded,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) => _validateWholeNumber(
                    v,
                    label: 'Number of occupants',
                    min: 1,
                    max: 50,
                  ),
                ),
                _field(
                  controller: _providerCtrl,
                  label: 'Electricity Provider',
                  icon: Icons.bolt_rounded,
                  capitalization: TextCapitalization.words,
                  validator: (v) =>
                      _validateRequired(v, 'Electricity provider'),
                ),
              ),
              const SizedBox(height: 16),

              _fieldRow(
                twoCol,
                _field(
                  controller: _rateCtrl,
                  label: 'Rate per kWh (₱)',
                  hint: 'e.g. 12.50',
                  helper: 'Price per kWh on your bill',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  formatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,4}'),
                    ),
                  ],
                  validator: _validateRate,
                ),
                _field(
                  controller: _billingDayCtrl,
                  label: 'Billing Cycle Day',
                  hint: '1 to 31',
                  helper: 'Day of the month (1–31)',
                  icon: Icons.event_outlined,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  last: true,
                  validator: (v) => _validateWholeNumber(
                    v,
                    label: 'Billing cycle day',
                    min: 1,
                    max: 31,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (twoCol)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LandingSecondaryButton(
                      label: 'Cancel',
                      onPressed: _cancel,
                    ),
                    const SizedBox(width: 12),
                    LandingPrimaryButton(
                      label: _isSaving ? 'Saving...' : 'Save Household',
                      onPressed: _save,
                    ),
                  ],
                )
              else ...[
                LandingPrimaryButton(
                  label: _isSaving ? 'Saving...' : 'Save Household',
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
                LandingSecondaryButton(
                  label: 'Cancel',
                  onPressed: _cancel,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Displays fields side by side or stacked on narrow screens.
  Widget _fieldRow(bool twoCol, Widget a, Widget b) {
    if (!twoCol) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          a,
          const SizedBox(height: 16),
          b,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  // Creates a text field using the shared E-FORECAST input style.
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    String? helper,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
    bool last = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_isSaving,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textCapitalization: capitalization,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: last ? (_) => _save() : null,
      style: TextStyle(
        color: LandingColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: Icon(
          icon,
          size: 18,
          color: LandingColors.textSecondary,
        ),
      ),
    );
  }
}

// Validation helpers.

String? _validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required';
  }
  return null;
}

/// The server accepts 2 to 100 characters.
/// The form keeps the existing 60-character limit.
String? _validateName(String? value) {
  final required = _validateRequired(value, 'Household name');
  if (required != null) return required;

  if (value!.trim().length > 60) {
    return 'Use 60 characters or fewer';
  }
  return null;
}

/// Validates a whole number between [min] and [max].
String? _validateWholeNumber(
  String? value, {
  required String label,
  required int min,
  required int max,
}) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) return '$label is required';

  final number = int.tryParse(text);

  if (number == null) return 'Enter a whole number';

  if (number < min || number > max) {
    return 'Enter a number from $min to $max';
  }

  return null;
}

/// Validates a positive decimal number.
String? _validateRate(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) return 'Rate per kWh is required';

  final rate = double.tryParse(text);

  if (rate == null) {
    return 'Enter a valid number, e.g. 12.50';
  }

  if (rate <= 0) return 'Rate must be greater than 0';

  return null;
}
