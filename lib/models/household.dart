
/// A household registered by the user.
class Household {
  final int? id;
  final int? householdId;
  final String? meterNumber;

  final String name;
  final String street;
  final String city;
  final int occupants;
  final String provider;
  final double ratePerKwh;
  final int billingCycleDay;

  /// True only for built-in demo households.
  final bool isSample;

  const Household({
    int? id,
    int? householdId,
    required this.name,
    required this.street,
    required this.city,
    required this.occupants,
    required this.provider,
    required this.ratePerKwh,
    required this.billingCycleDay,
    this.meterNumber,
    this.isSample = false,
  })  : id = id ?? householdId,
        householdId = householdId ?? id;

  /// One-line address for display.
  String get address => '$street, $city';

  /// Creates a Household from the backend response.
  factory Household.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] ?? '').toString();
    final parts = address.split(',');
    final parsedId = int.tryParse(
      '${json['household_id'] ?? ''}',
    );

    return Household(
      id: parsedId,
      householdId: parsedId,
      name: (json['household_name'] ?? '').toString(),
      street: parts.first.trim(),
      city: parts.length > 1
          ? parts.sublist(1).join(',').trim()
          : '',
      occupants: int.tryParse(
            '${json['occupants'] ?? ''}',
          ) ??
          0,
      provider: (json['electricity_provider'] ?? '').toString(),
      ratePerKwh: double.tryParse(
            '${json['rate_per_kwh'] ?? ''}',
          ) ??
          0.0,
      billingCycleDay: int.tryParse(
            '${json['billing_cycle_day'] ?? ''}',
          ) ??
          1,
      meterNumber: json['meter_number']?.toString(),
      isSample: false,
    );
  }
}
