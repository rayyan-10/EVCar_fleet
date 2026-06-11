import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../models/prediction_model.dart';
import '../services/supabase_service.dart';
import '../services/prediction_service.dart';
import '../services/ev_range_api_service.dart';
class PredictionController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final PredictionService _predictionService = PredictionService();
  final EvRangeApiService _evRangeApi = EvRangeApiService();

  PredictionModel? _activePrediction;
  List<PredictionModel> _history = [];
  List<PredictionModel> _filteredHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters state
  String _historyFilterType = 'All'; // 'All' | 'Today' | 'Week' | 'Month' | 'Custom'
  DateTime? _customStart;
  DateTime? _customEnd;
  String _searchQuery = ''; // Filter by Driver ID or Car Name

  PredictionModel? get activePrediction => _activePrediction;
  List<PredictionModel> get history => _history;
  List<PredictionModel> get filteredHistory => _filteredHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get historyFilterType => _historyFilterType;
  String get searchQuery => _searchQuery;
  DateTime? get customStart => _customStart;
  DateTime? get customEnd => _customEnd;

  Future<void> fetchPredictionHistory(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _history = await _supabaseService.getPredictions(driverId);
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> runPrediction(VehicleModel vehicle, double batteryPercentage,
      {double odometerKm = 0.0, double runningMode = 0.0,
       double? energyConsumedKwh, double? maxRangeKm,
       double batteryHealthPct = 91.5,
       double speedKmph = 0.0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Call FastAPI /predict — returns predicted_range_km + echoed input
      double? mlRangeKm;
      double resolvedEnergy  = energyConsumedKwh ?? vehicle.batteryCapacity * 0.20;
      double resolvedMaxRange = maxRangeKm ?? vehicle.batteryCapacity * 8.0;
      double backendRunMode  = runningMode == 0 ? 1.0 : 0.0; // flip: app 0=City→backend 1

      try {
        final input = {
          'soc_end_pct':          batteryPercentage,
          'battery_health_pct':   batteryHealthPct,
          'battery_capacity_kwh': vehicle.batteryCapacity,
          'max_range_km':         resolvedMaxRange,
          'energy_consumed_kwh':  resolvedEnergy,
          'odometer_km':          odometerKm,
          'running_mode':         backendRunMode,
        };
        if (kDebugMode) debugPrint('[PREDICT] Input sent to FastAPI: $input');

        final resp = await _evRangeApi.predictRange(
          socEndPct:          batteryPercentage,
          batteryHealthPct:   batteryHealthPct,
          batteryCapacityKwh: vehicle.batteryCapacity,
          maxRangeKm:         resolvedMaxRange,
          energyConsumedKwh:  resolvedEnergy,
          odometerKm:         odometerKm,
          runningMode:        backendRunMode,
        );

        mlRangeKm        = resp.predictedRangeKm;
        resolvedEnergy   = resp.energyConsumedKwh;
        resolvedMaxRange = resp.maxRangeKm;
        batteryHealthPct = resp.batteryHealthPct;

        if (kDebugMode) debugPrint('[PREDICT] FastAPI response → predicted_range_km: $mlRangeKm km');
      } catch (e) {
        if (kDebugMode) debugPrint('[PREDICT] FastAPI unavailable, using physics fallback. Error: $e');
      }

      // 2. Build all 20 metrics using backend-confirmed values
      final prediction = _predictionService.predict(
        vehicle,
        batteryPercentage,
        mlRangeKm:          mlRangeKm,
        batteryHealthPct:   batteryHealthPct,
        batteryCapacityKwh: vehicle.batteryCapacity,
        maxRangeKm:         resolvedMaxRange,
        energyConsumedKwh:  resolvedEnergy,
        odometerKm:         odometerKm,
        runningMode:        backendRunMode,
        speedKmph:          speedKmph,
      );

      // 3. Save to Supabase
      await _supabaseService.savePrediction(prediction);
      _activePrediction = prediction;

      // 4. Check speed violation (>100 km/h)
      if (speedKmph > 100) {
        await _supabaseService.checkAndSaveViolation(
          driverId:     vehicle.driverId,
          driverIdStr:  vehicle.driverIdStr,
          carName:      vehicle.carName,
          speedKmph:    speedKmph,
          predictionId: prediction.id,
        );
        if (kDebugMode) debugPrint('[VIOLATION] Speed $speedKmph km/h > 100 — violation recorded.');
      }

      // 5. Refresh history
      _history = await _supabaseService.getPredictions(vehicle.driverId);
      _applyFilters();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void setFilterType(String type, {DateTime? start, DateTime? end}) {
    _historyFilterType = type;
    _customStart = start;
    _customEnd = end;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final now = DateTime.now();
    _filteredHistory = _history.where((pred) {
      // 1. Date filters
      if (_historyFilterType == 'Today') {
        final todayStart = DateTime(now.year, now.month, now.day);
        if (pred.predictionDate.isBefore(todayStart)) return false;
      } else if (_historyFilterType == 'Week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        if (pred.predictionDate.isBefore(weekAgo)) return false;
      } else if (_historyFilterType == 'Month') {
        final monthAgo = now.subtract(const Duration(days: 30));
        if (pred.predictionDate.isBefore(monthAgo)) return false;
      } else if (_historyFilterType == 'Custom') {
        if (_customStart != null && pred.predictionDate.isBefore(_customStart!)) return false;
        if (_customEnd != null && pred.predictionDate.isAfter(_customEnd!)) return false;
      }

      // 2. Search query filter (Driver ID or Car Name)
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchDriverId = pred.driverIdStr.toLowerCase().contains(q);
        final matchCarName = pred.carName.toLowerCase().contains(q);
        if (!matchDriverId && !matchCarName) return false;
      }

      return true;
    }).toList();
  }

  void resetPredictionState() {
    _activePrediction = null;
    _history = [];
    _filteredHistory = [];
    _errorMessage = null;
    _historyFilterType = 'All';
    _searchQuery = '';
    _customStart = null;
    _customEnd = null;
    notifyListeners();
  }
}
