/// The usage totals for one household over a date range, as returned by the
/// backend (GET /api/usage/summary).
class UsageSummary {
  /// The household these totals belong to.
  final int householdId;

  /// The household's name, as saved on the server.
  final String householdName;

  /// Total kWh used across all readings in the date range.
  final double totalKwh;

  /// Average kWh per saved reading (not per calendar day: a reading can
  /// cover more than one day).
  final double averageKwh;

  /// How many saved readings (records) fall inside the date range.
  final int daysRecorded;

  const UsageSummary({
    required this.householdId,
    required this.householdName,
    required this.totalKwh,
    required this.averageKwh,
    required this.daysRecorded,
  });

  /// Creates a UsageSummary from the backend response.
  /// Numbers can arrive as whole numbers (358) or decimals (358.5), so they
  /// are converted safely. A missing or unreadable value becomes 0 (or an
  /// empty name) instead of crashing.
  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    return UsageSummary(
      householdId: _toInt(json['household_id']) ?? 0,
      householdName: (json['household_name'] ?? '').toString(),
      totalKwh: _toDouble(json['total_kwh']) ?? 0.0,
      averageKwh: _toDouble(json['average_kwh']) ?? 0.0,
      daysRecorded: _toInt(json['days_recorded']) ?? 0,
    );
  }

  /// Turns a JSON number (or a numeric string) into a double.
  /// Returns null if the value is missing or not a number.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  /// Turns a JSON number (or a numeric string) into an int.
  /// A value like 30.0 becomes 30. Returns null if it is missing or not a
  /// number.
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
