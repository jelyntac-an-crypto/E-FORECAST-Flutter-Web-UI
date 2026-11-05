/// A household registered by the user.
class Household {
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
    this.householdId,
    this.meterNumber,
    required this.name,
    required this.street,
    required this.city,
    required this.occupants,
    required this.provider,
    required this.ratePerKwh,
    required this.billingCycleDay,
    this.isSample = false,
  });

  /// One-line address for display.
  String get address => '$street, $city';
}
