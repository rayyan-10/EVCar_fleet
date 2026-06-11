import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictResponse {
  final double predictedRangeKm;

  // echoed back by the backend — confirms what was actually processed
  final double socEndPct;
  final double batteryHealthPct;
  final double batteryCapacityKwh;
  final double maxRangeKm;
  final double energyConsumedKwh;
  final double odometerKm;
  final double runningMode;

  PredictResponse({
    required this.predictedRangeKm,
    required this.socEndPct,
    required this.batteryHealthPct,
    required this.batteryCapacityKwh,
    required this.maxRangeKm,
    required this.energyConsumedKwh,
    required this.odometerKm,
    required this.runningMode,
  });
}

class EvRangeApiService {
  static final EvRangeApiService _instance = EvRangeApiService._internal();
  factory EvRangeApiService() => _instance;
  EvRangeApiService._internal();

  static const String _baseUrl = 'https://deputize-tweed-supremacy.ngrok-free.dev';

  /// Calls POST /predict and returns the full response including
  /// predicted_range_km and the echoed input from the backend.
  Future<PredictResponse> predictRange({
    required double socEndPct,
    required double batteryHealthPct,
    required double batteryCapacityKwh,
    required double maxRangeKm,
    required double energyConsumedKwh,
    required double odometerKm,
    required double runningMode,
  }) async {
    final uri = Uri.parse('$_baseUrl/predict');

    final body = jsonEncode({
      'soc_end_pct': socEndPct,
      'battery_health_pct': batteryHealthPct,
      'battery_capacity_kwh': batteryCapacityKwh,
      'max_range_km': maxRangeKm,
      'energy_consumed_kwh': energyConsumedKwh,
      'odometer_km': odometerKm,
      'running_mode': runningMode,
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // bypass ngrok interstitial page
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final predictedRange = (json['predicted_range_km'] as num).toDouble();

      // Backend echoes back the input under "input" key
      final inp = json['input'] as Map<String, dynamic>? ?? {};

      return PredictResponse(
        predictedRangeKm:    predictedRange,
        socEndPct:           (inp['soc_end_pct']          as num? ?? socEndPct).toDouble(),
        batteryHealthPct:    (inp['battery_health_pct']   as num? ?? batteryHealthPct).toDouble(),
        batteryCapacityKwh:  (inp['battery_capacity_kwh'] as num? ?? batteryCapacityKwh).toDouble(),
        maxRangeKm:          (inp['max_range_km']         as num? ?? maxRangeKm).toDouble(),
        energyConsumedKwh:   (inp['energy_consumed_kwh']  as num? ?? energyConsumedKwh).toDouble(),
        odometerKm:          (inp['odometer_km']          as num? ?? odometerKm).toDouble(),
        runningMode:         (inp['running_mode']         as num? ?? runningMode).toDouble(),
      );
    } else {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
