import '../models/vehicle_model.dart';
import '../models/prediction_model.dart';
import '../models/analytics_model.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Filters prediction list based on dynamic GUI parameters
  List<PredictionModel> filterPredictions({
    required List<PredictionModel> predictions,
    required List<VehicleModel> vehicles,
    DateTime? startDate,
    DateTime? endDate,
    String? driverIdQuery,
    String? carNameQuery,
    double? minBattery,
    double? maxBattery,
    double? minWeight,
    double? maxWeight,
    int? runningType, // 0 = City, 1 = Highway, null = All
    int? vehicleCondition, // 0 = Garage, 1 = Working, null = All
    double? minSpeed,
    double? maxSpeed,
    double? minIncome,
    double? maxIncome,
    double? minHealth,
    double? maxHealth,
  }) {
    // Map vehicles by driver ID for quick lookup
    final Map<String, VehicleModel> vehicleMap = {
      for (var v in vehicles) v.driverId: v
    };

    return predictions.where((pred) {
      // 1. Date Range Filter
      if (startDate != null && pred.predictionDate.isBefore(startDate)) return false;
      if (endDate != null && pred.predictionDate.isAfter(endDate)) return false;

      // Lookup matching vehicle specs
      final vehicle = vehicleMap[pred.driverId];
      if (vehicle == null) return false;

      // 2. Driver ID Query (Case-insensitive prefix)
      if (driverIdQuery != null && driverIdQuery.trim().isNotEmpty) {
        if (!pred.driverIdStr.toLowerCase().contains(driverIdQuery.trim().toLowerCase())) {
          return false;
        }
      }

      // 3. Car Name Query
      if (carNameQuery != null && carNameQuery.trim().isNotEmpty) {
        if (!pred.carName.toLowerCase().contains(carNameQuery.trim().toLowerCase())) {
          return false;
        }
      }

      // 4. Battery Capacity Range (based on vehicle spec)
      if (minBattery != null && vehicle.batteryCapacity < minBattery) return false;
      if (maxBattery != null && vehicle.batteryCapacity > maxBattery) return false;

      // 5. Vehicle Weight Range
      if (minWeight != null && vehicle.vehicleWeight < minWeight) return false;
      if (maxWeight != null && vehicle.vehicleWeight > maxWeight) return false;

      // 6. Running Type (City vs Highway)
      if (runningType != null && vehicle.runningType != runningType) return false;

      // 7. Vehicle Condition (Working vs Garage)
      if (vehicleCondition != null && vehicle.vehicleCondition != vehicleCondition) return false;

      // 8. Speed Range
      if (minSpeed != null && vehicle.currentSpeed < minSpeed) return false;
      if (maxSpeed != null && vehicle.currentSpeed > maxSpeed) return false;

      // 9. Income Range
      if (minIncome != null && vehicle.monthlyIncome < minIncome) return false;
      if (maxIncome != null && vehicle.monthlyIncome > maxIncome) return false;

      // 10. Vehicle Health Range (calculated in prediction)
      if (minHealth != null && pred.overallVehicleHealth < minHealth) return false;
      if (maxHealth != null && pred.overallVehicleHealth > maxHealth) return false;

      return true;
    }).toList();
  }

  /// Calculates core Admin KPIs based on a filtered prediction and vehicle list
  AdminStatsModel calculateStats({
    required List<PredictionModel> filteredPredictions,
    required List<VehicleModel> allVehicles,
  }) {
    if (filteredPredictions.isEmpty) return AdminStatsModel.empty();

    // Map unique drivers represented in the filtered predictions
    final Set<String> uniqueDriverIds = filteredPredictions.map((p) => p.driverId).toSet();
    final int totalDrivers = uniqueDriverIds.length;

    // Filter vehicle lists matching those drivers
    final List<VehicleModel> activeVehiclesList = allVehicles
        .where((v) => uniqueDriverIds.contains(v.driverId))
        .toList();

    final int totalVehicles = activeVehiclesList.length;
    final int activeVehiclesCount = activeVehiclesList.where((v) => v.vehicleCondition == 1).length;
    final int garageVehiclesCount = activeVehiclesList.where((v) => v.vehicleCondition == 0).length;

    // Averages
    double rangeSum = 0.0;
    double efficiencySum = 0.0;
    double incomeSum = 0.0;

    for (var pred in filteredPredictions) {
      rangeSum += pred.estimatedRange;
      efficiencySum += pred.efficiencyScore;
    }

    for (var vehicle in activeVehiclesList) {
      incomeSum += vehicle.monthlyIncome;
    }

    final double averageRange = rangeSum / filteredPredictions.length;
    final double averageEfficiency = efficiencySum / filteredPredictions.length;
    final double averageMonthlyIncome = totalVehicles > 0 ? (incomeSum / totalVehicles) : 0.0;
    final int totalPredictions = filteredPredictions.length;

    return AdminStatsModel(
      totalDrivers: totalDrivers,
      totalVehicles: totalVehicles,
      activeVehicles: activeVehiclesCount,
      garageVehicles: garageVehiclesCount,
      averageRange: averageRange,
      averageEfficiency: averageEfficiency,
      averageMonthlyIncome: averageMonthlyIncome,
      totalPredictions: totalPredictions,
    );
  }
}
