import 'dart:math';
import '../models/vehicle_model.dart';
import '../models/prediction_model.dart';

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  /// Calculates all 20 AI prediction metrics from a VehicleModel
  PredictionModel predict(VehicleModel vehicle, double batteryPercentage) {
    // 1. Predicted Energy Consumption (Wh/km)
    // Base energy consumption scales with vehicle weight
    // A 1800kg car uses ~144 Wh/km base.
    final double baseEnergyConsumption = vehicle.vehicleWeight * 0.08;

    // Aerodynamic drag increases quadratically with speed
    // Baseline speed is 60 km/h. If car is parked (0 km/h), we assume a cruise speed of 85 km/h for range estimation.
    final double cruiseSpeed = vehicle.currentSpeed > 0 ? vehicle.currentSpeed : 85.0;
    final double speedFactor = 1.0 + (pow(cruiseSpeed - 60.0, 2) / 8000.0);

    // Running type factor: Highway (1) uses more energy due to drag; City (0) uses less due to regen braking
    final double runningFactor = vehicle.runningType == 1 ? 1.25 : 0.82;

    // Efficiency of the motor directly reduces energy consumption
    final double efficiencyFactor = 95.0 / vehicle.motorEfficiency;

    final double predictedEnergyConsumption = (baseEnergyConsumption * speedFactor * runningFactor * efficiencyFactor).clamp(100.0, 450.0);

    // 2. Estimated Remaining Range (KM)
    // Battery size in kWh
    final double batteryCapacityKwh = vehicle.batteryCapacity;
    final double remainingEnergyWh = batteryCapacityKwh * 1000.0 * (batteryPercentage / 100.0);
    final double estimatedRange = (remainingEnergyWh / predictedEnergyConsumption).clamp(5.0, 1000.0);

    // 3. Predicted Battery Drain Rate (% per 10km)
    // Drain rate = energy used in 10km / total capacity
    final double predictedBatteryDrainRate = ((predictedEnergyConsumption * 10.0) / (batteryCapacityKwh * 1000.0) * 100.0).clamp(0.5, 30.0);

    // 4. Battery Health Score (%)
    // Derived from vehicle age (simulated), weight stresses, and motor power strain
    final double weightStress = (vehicle.vehicleWeight - 1000.0) / 2000.0 * 2.0; // max 2% reduction
    final double powerStress = (vehicle.motorPower / 100.0) * 1.5; // max 9% reduction for 600kW
    double batteryHealthScore = (100.0 - weightStress - powerStress).clamp(65.0, 100.0);
    if (vehicle.vehicleCondition == 0) {
      batteryHealthScore -= 3.0; // Subtract for garage vehicles
    }

    // 5. Expected Charging Requirement (hours)
    // Time to charge back to 100% on standard 11kW AC charger
    final double chargeNeededKwh = batteryCapacityKwh * (1.0 - (batteryPercentage / 100.0));
    final double expectedChargingRequirement = (chargeNeededKwh / 11.0).clamp(0.0, 12.0);

    // 6. Efficiency Score (%)
    // Ideal consumption is ~130 Wh/km, worst is ~300 Wh/km
    final double efficiencyScore = (100.0 - ((predictedEnergyConsumption - 110.0) / 2.5)).clamp(15.0, 100.0);

    // 7. Vehicle Performance Score (%)
    // Power-to-weight ratio (kW/tonne) + torque factor
    final double powerToWeight = vehicle.motorPower / (vehicle.vehicleWeight / 1000.0);
    final double vehiclePerformanceScore = (40.0 + (powerToWeight * 0.15) + (vehicle.torque * 0.03)).clamp(30.0, 100.0);

    // 8. Cost Per Kilometer ($)
    // Electricity price estimate: $0.16 per kWh
    final double costPerKm = (predictedEnergyConsumption / 1000.0) * 0.16;

    // 9. Monthly Cost Estimation ($)
    // Average 1,500 km monthly travel
    final double monthlyCostEstimation = costPerKm * 1500.0;

    // 10. Maintenance Alert Score (%)
    // High weight, low battery health, and garage status increase this
    double maintenanceAlertScore = (100.0 - batteryHealthScore) * 2.5 + (vehicle.vehicleWeight > 2200 ? 12.0 : 0.0);
    if (vehicle.vehicleCondition == 0) {
      maintenanceAlertScore += 45.0; // Garage vehicles need service
    }
    maintenanceAlertScore = maintenanceAlertScore.clamp(5.0, 100.0);

    // 11. Risk Level (Low | Medium | High)
    String riskLevel = 'Low';
    final double riskScore = (cruiseSpeed * 0.45) + (maintenanceAlertScore * 0.55);
    if (riskScore > 75.0) {
      riskLevel = 'High';
    } else if (riskScore > 45.0) {
      riskLevel = 'Medium';
    }

    // 12. Recommended Speed (km/h)
    double recommendedSpeed = vehicle.runningType == 1 ? 95.0 : 50.0;
    if (batteryPercentage < 20.0) {
      recommendedSpeed -= 15.0; // Slow down to save battery if critically low
    }

    // 13. Recommended Driving Mode
    String recommendedDrivingMode = 'Normal';
    if (batteryPercentage < 20.0) {
      recommendedDrivingMode = 'Eco-Plus (Max Range)';
    } else if (batteryPercentage < 50.0) {
      recommendedDrivingMode = 'Eco Mode (Regen High)';
    } else if (vehicle.runningType == 0) {
      recommendedDrivingMode = 'Eco (City Cruise)';
    } else if (vehiclePerformanceScore > 85.0 && cruiseSpeed > 100.0) {
      recommendedDrivingMode = 'Sport / Performance';
    } else {
      recommendedDrivingMode = 'Comfort / Standard';
    }

    // 14. Carbon Savings Estimate (kg CO2)
    // Standard gasoline car emits ~0.140 kg CO2 / km
    // Electric vehicle grid charging emissions ~0.035 kg CO2 / km
    // Saving = 0.105 kg CO2 / km
    final double carbonSavingsEstimate = (estimatedRange * 0.105).clamp(0.0, 5000.0);

    // 15. Predicted Range If Highway (KM)
    final double hwConsumption = (baseEnergyConsumption * (1.0 + (pow(max(cruiseSpeed, 100.0) - 60.0, 2) / 8000.0)) * 1.25 * efficiencyFactor).clamp(100.0, 450.0);
    final double predictedRangeHighway = (remainingEnergyWh / hwConsumption).clamp(5.0, 1000.0);

    // 16. Predicted Range If City (KM)
    final double cityConsumption = (baseEnergyConsumption * (1.0 + (pow(50.0 - 60.0, 2) / 8000.0)) * 0.82 * efficiencyFactor).clamp(100.0, 450.0);
    final double predictedRangeCity = (remainingEnergyWh / cityConsumption).clamp(5.0, 1000.0);

    // 17. Next Service Recommendation
    String nextServiceRecommendation = 'Routine in 6 months';
    if (maintenanceAlertScore > 75.0) {
      nextServiceRecommendation = 'Immediate Inspection Required';
    } else if (maintenanceAlertScore > 45.0) {
      nextServiceRecommendation = 'Schedule service within 30 days';
    } else if (batteryHealthScore < 85.0) {
      nextServiceRecommendation = 'Battery service in 3 months';
    }

    // 18. Vehicle Utilization Score (%)
    double vehicleUtilizationScore = 65.0;
    if (vehicle.vehicleCondition == 0) {
      vehicleUtilizationScore = 15.0; // In garage, low utilization
    } else {
      // Scale utilization based on driving conditions and speed
      vehicleUtilizationScore += (vehicle.currentSpeed > 0 ? 15.0 : 0.0);
      vehicleUtilizationScore += (vehicle.monthlyIncome / 15000.0) * 15.0;
      vehicleUtilizationScore = vehicleUtilizationScore.clamp(30.0, 98.0);
    }

    // 19. Driver Efficiency Score (%)
    // Heavily affected by high speed cruise (above 110) or aggressive torque loads
    double speedPenalty = 0.0;
    if (cruiseSpeed > 110.0) {
      speedPenalty = (cruiseSpeed - 110.0) * 1.2;
    }
    final double torquePenalty = (vehicle.torque > 400.0) ? (vehicle.torque - 400.0) * 0.03 : 0.0;
    final double driverEfficiencyScore = (98.0 - speedPenalty - torquePenalty).clamp(25.0, 100.0);

    // 20. Overall Vehicle Health (%)
    final double overallVehicleHealth = (batteryHealthScore * 0.5) + 
                                       (vehicle.vehicleCondition == 1 ? 30.0 : 5.0) + 
                                       ((100.0 - maintenanceAlertScore) * 0.2);

    return PredictionModel(
      driverId: vehicle.driverId,
      driverIdStr: vehicle.driverIdStr,
      carName: vehicle.carName,
      predictionDate: DateTime.now(),
      batteryPercentage: batteryPercentage,
      estimatedRange: estimatedRange,
      predictedBatteryDrainRate: predictedBatteryDrainRate,
      batteryHealthScore: batteryHealthScore,
      expectedChargingRequirement: expectedChargingRequirement,
      efficiencyScore: efficiencyScore,
      vehiclePerformanceScore: vehiclePerformanceScore,
      predictedEnergyConsumption: predictedEnergyConsumption,
      costPerKm: costPerKm,
      monthlyCostEstimation: monthlyCostEstimation,
      riskLevel: riskLevel,
      recommendedSpeed: recommendedSpeed,
      recommendedDrivingMode: recommendedDrivingMode,
      maintenanceAlertScore: maintenanceAlertScore,
      carbonSavingsEstimate: carbonSavingsEstimate,
      predictedRangeHighway: predictedRangeHighway,
      predictedRangeCity: predictedRangeCity,
      nextServiceRecommendation: nextServiceRecommendation,
      vehicleUtilizationScore: vehicleUtilizationScore,
      driverEfficiencyScore: driverEfficiencyScore,
      overallVehicleHealth: overallVehicleHealth,
    );
  }
}
