/// The result of a forecast, as returned by the backend (POST /api/forecasts).
class ForecastResult {
  /// The id of the forecast saved on the server.
  final int forecastId;

  /// Predicted electricity use in kWh for the day after the latest reading.
  final double predictedKwh;

  /// Estimated bill in PHP for that predicted use.
  final double estimatedBill;

  const ForecastResult({
    required this.forecastId,
    required this.predictedKwh,
    required this.estimatedBill,
  });

  /// Creates a ForecastResult from the backend response.
  /// Numbers can arrive as whole numbers (10) or decimals (10.15), so they
  /// are converted safely. A missing or unreadable value becomes 0 instead
  /// of crashing.
  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    return ForecastResult(
      forecastId: _toInt(json['forecast_id']) ?? 0,
      predictedKwh: _toDouble(json['predicted_consumption_kwh']) ?? 0.0,
      estimatedBill: _toDouble(json['estimated_bill']) ?? 0.0,
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
  /// Returns null if the value is missing or not a number.
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
