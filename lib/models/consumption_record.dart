/// One saved meter reading for a household, as returned by the backend
/// (GET /api/consumption/history).
class ConsumptionRecord {
  /// The day the reading was recorded.
  final DateTime date;

  /// kWh used, as calculated by the backend (current - previous).
  final double kwh;

  /// Meter readings. The database allows these to be empty, so they can be
  /// null for older records.
  final double? meterPrevious;
  final double? meterCurrent;

  const ConsumptionRecord({
    required this.date,
    required this.kwh,
    this.meterPrevious,
    this.meterCurrent,
  });

  /// Builds a record from one item of the backend's "records" list.
  /// Returns null if the item is unusable (no valid date, or no kWh that can
  /// be worked out), so one bad row never breaks the whole list.
  static ConsumptionRecord? tryParse(Map<dynamic, dynamic> json) {
    final date = DateTime.tryParse('${json['date'] ?? ''}');
    if (date == null) return null;

    final previous = _toDouble(json['meter_previous']);
    final current = _toDouble(json['meter_current']);

    // Use the kWh from the backend. If it is missing, work it out from the
    // two meter readings when both are available.
    double? kwh = _toDouble(json['kwh']);
    if (kwh == null && previous != null && current != null) {
      kwh = current - previous;
    }
    if (kwh == null) return null;

    return ConsumptionRecord(
      date: DateTime(date.year, date.month, date.day),
      kwh: kwh,
      meterPrevious: previous,
      meterCurrent: current,
    );
  }

  /// Turns a JSON number (or a numeric string) into a double.
  /// Returns null if the value is missing or not a number.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
