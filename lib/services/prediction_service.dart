import 'dart:math';
import '../models/vehicle_model.dart';
import '../models/prediction_model.dart';

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  /// Builds all 20 prediction metrics.
  ///
  /// Secondary telemetry mirrors telemetry_advisor.py exactly using the
  /// confirmed backend-echoed values when provided.
  PredictionModel predict(
    VehicleModel vehicle,
    double batteryPercentage, {
    double? mlRangeKm,
    double? batteryHealthPct,
    double? batteryCapacityKwh,
    double? maxRangeKm,
    double? energyConsumedKwh,
    double? odometerKm,
    double? runningMode,
    double speedKmph = 0.0,
  }) {
    // ── resolve inputs ────────────────────────────────────────────────────
    final double soc        = batteryPercentage;
    final double health     = batteryHealthPct ?? 91.5;
    final double capKwh     = batteryCapacityKwh ?? vehicle.batteryCapacity;
    final double energyUsed = energyConsumedKwh ?? capKwh * 0.20;
    final double odo        = odometerKm ?? 0.0;
    // backend running_mode: 1=City, 0=Highway (inverse of app's runningType 0=City,1=Highway)
    final double backendMode = runningMode ?? (vehicle.runningType == 0 ? 1.0 : 0.0);
    final bool   isCity      = backendMode == 1.0;

    // ── 1. Estimated Range — ML result (required) ─────────────────────────
    final double estimatedRange = (mlRangeKm ?? 0.0).clamp(5.0, 1000.0);

    // ── 2. Energy draw & drain rate (mirrors telemetry_advisor.py) ────────
    final double energyDrawWhPerKm =
        double.parse(((energyUsed * 1000) / max(odo, 1)).toStringAsFixed(1));
    final double drainRatePer10km =
        double.parse(((energyUsed / max(capKwh, 1e-6)) * 100 / max(odo / 10, 1))
            .toStringAsFixed(1));
    final double predictedBatteryDrainRate = drainRatePer10km.clamp(0.5, 30.0);

    // ── 3. Efficiency score ───────────────────────────────────────────────
    final double efficiencyScore =
        (100 - (energyDrawWhPerKm - 100) / 2).clamp(0, 100);

    // ── 4. Battery health score — user-supplied value ─────────────────────
    final double batteryHealthScore = health.clamp(0.0, 100.0);

    // ── 5. Charging requirement (11 kW AC) ────────────────────────────────
    final double chargeNeededKwh = capKwh * (1 - soc / 100);
    final double expectedChargingRequirement =
        (chargeNeededKwh / 11.0).clamp(0.0, 12.0);

    // ── 6. Cost per km & monthly cost ─────────────────────────────────────
    final double costPerKm =
        double.parse(((energyDrawWhPerKm / 1000) * 0.16).toStringAsFixed(4));
    final double monthlyCostEstimation =
        double.parse((costPerKm * 1500).toStringAsFixed(2));

    // ── 7. Carbon savings (0.105 kg CO2/km vs ICE) ───────────────────────
    final double carbonSavingsEstimate =
        double.parse((estimatedRange * 0.105).toStringAsFixed(1));

    // ── 8. Range if highway / city ────────────────────────────────────────
    final double predictedRangeHighway;
    final double predictedRangeCity;
    if (isCity) {
      predictedRangeHighway = double.parse((estimatedRange * 0.80).toStringAsFixed(1));
      predictedRangeCity    = estimatedRange;
    } else {
      predictedRangeHighway = estimatedRange;
      predictedRangeCity    = double.parse((estimatedRange * 1.20).toStringAsFixed(1));
    }

    // ── 9. Recommended speed & driving mode ───────────────────────────────
    final double recommendedSpeed;
    final String recommendedDrivingMode;
    if (soc < 20) {
      recommendedSpeed       = 60;
      recommendedDrivingMode = 'Eco-Plus (Max Range)';
    } else if (isCity) {
      recommendedSpeed       = 50;
      recommendedDrivingMode = 'Eco (City Cruise)';
    } else {
      recommendedSpeed       = 90;
      recommendedDrivingMode = 'Comfort / Standard';
    }

    // ── 10. Maintenance alert score ───────────────────────────────────────
    final double maintenanceAlertScore =
        ((100 - health) * 1.5 + (odo / 500000) * 20).clamp(0.0, 100.0);

    // ── 11. Service recommendation ────────────────────────────────────────
    final String nextServiceRecommendation;
    if (maintenanceAlertScore > 75) {
      nextServiceRecommendation = 'Immediate Inspection Required';
    } else if (maintenanceAlertScore > 45) {
      nextServiceRecommendation = 'Schedule service within 30 days';
    } else if (health < 85) {
      nextServiceRecommendation = 'Battery service in 3 months';
    } else {
      nextServiceRecommendation = 'Routine in 6 months';
    }

    // ── 12. Vehicle utilization ───────────────────────────────────────────
    final double vehicleUtilizationScore =
        (65 + (soc / 100) * 20 + (isCity ? 0.5 : 1.0) * 10).clamp(30.0, 98.0);

    // ── 13. Driver efficiency ─────────────────────────────────────────────
    final double speedPenalty =
        recommendedSpeed > 110 ? (recommendedSpeed - 110) * 1.2 : 0.0;
    final double driverEfficiencyScore = (98 - speedPenalty).clamp(25.0, 100.0);

    // ── 14. Risk level ────────────────────────────────────────────────────
    final String riskLevel;
    if (soc < 15 || health < 75) {
      riskLevel = 'High';
    } else if (soc < 30 || health < 85 || energyDrawWhPerKm > 220) {
      riskLevel = 'Medium';
    } else {
      riskLevel = 'Low';
    }

    // ── 15. Vehicle performance score (physics — uses vehicle specs) ───────
    final double powerToWeight =
        vehicle.motorPower / (vehicle.vehicleWeight / 1000.0);
    final double vehiclePerformanceScore =
        (40.0 + powerToWeight * 0.15 + vehicle.torque * 0.03).clamp(30.0, 100.0);

    // ── 16. Overall vehicle health ────────────────────────────────────────
    final double overallVehicleHealth =
        (batteryHealthScore * 0.5) +
        (vehicle.vehicleCondition == 1 ? 30.0 : 5.0) +
        ((100.0 - maintenanceAlertScore) * 0.2);

    return PredictionModel(
      driverId:                    vehicle.driverId,
      driverIdStr:                 vehicle.driverIdStr,
      carName:                     vehicle.carName,
      predictionDate:              DateTime.now(),
      batteryPercentage:           soc,
      estimatedRange:              estimatedRange,
      predictedBatteryDrainRate:   predictedBatteryDrainRate,
      batteryHealthScore:          batteryHealthScore,
      expectedChargingRequirement: expectedChargingRequirement,
      efficiencyScore:             efficiencyScore,
      vehiclePerformanceScore:     vehiclePerformanceScore,
      predictedEnergyConsumption:  energyDrawWhPerKm,
      costPerKm:                   costPerKm,
      monthlyCostEstimation:       monthlyCostEstimation,
      riskLevel:                   riskLevel,
      recommendedSpeed:            recommendedSpeed,
      recommendedDrivingMode:      recommendedDrivingMode,
      maintenanceAlertScore:       maintenanceAlertScore,
      carbonSavingsEstimate:       carbonSavingsEstimate,
      predictedRangeHighway:       predictedRangeHighway,
      predictedRangeCity:          predictedRangeCity,
      nextServiceRecommendation:   nextServiceRecommendation,
      vehicleUtilizationScore:     vehicleUtilizationScore,
      driverEfficiencyScore:       driverEfficiencyScore,
      overallVehicleHealth:        overallVehicleHealth,
      speedKmph:                   speedKmph,
    );
  }
}
