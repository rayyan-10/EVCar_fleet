class PredictionModel {
  final String? id;
  final String driverId;
  final String driverIdStr;
  final String carName;
  final DateTime predictionDate;
  final double batteryPercentage; // Remaining capacity at prediction

  // The 20 AI prediction metrics
  final double estimatedRange; // 1. Estimated Remaining Range (KM)
  final double predictedBatteryDrainRate; // 2. Predicted Battery Drain Rate (Wh/km)
  final double batteryHealthScore; // 3. Battery Health Score (%)
  final double expectedChargingRequirement; // 4. Expected Charging Requirement (hours)
  final double efficiencyScore; // 5. Efficiency Score (%)
  final double vehiclePerformanceScore; // 6. Vehicle Performance Score (%)
  final double predictedEnergyConsumption; // 7. Predicted Energy Consumption (Wh/km)
  final double costPerKm; // 8. Cost Per Kilometer ($)
  final double monthlyCostEstimation; // 9. Monthly Cost Estimation ($)
  final String riskLevel; // 10. Risk Level ('Low' | 'Medium' | 'High')
  final double recommendedSpeed; // 11. Recommended Speed (km/h)
  final String recommendedDrivingMode; // 12. Recommended Driving Mode
  final double maintenanceAlertScore; // 13. Maintenance Alert Score (%)
  final double carbonSavingsEstimate; // 14. Carbon Savings Estimate (kg CO2)
  final double predictedRangeHighway; // 15. Predicted Range If Highway (KM)
  final double predictedRangeCity; // 16. Predicted Range If City (KM)
  final String nextServiceRecommendation; // 17. Next Service Recommendation (text/date)
  final double vehicleUtilizationScore; // 18. Vehicle Utilization Score (%)
  final double driverEfficiencyScore; // 19. Driver Efficiency Score (%)
  final double overallVehicleHealth; // 20. Overall Vehicle Health (%)

  PredictionModel({
    this.id,
    required this.driverId,
    required this.driverIdStr,
    required this.carName,
    required this.predictionDate,
    required this.batteryPercentage,
    required this.estimatedRange,
    required this.predictedBatteryDrainRate,
    required this.batteryHealthScore,
    required this.expectedChargingRequirement,
    required this.efficiencyScore,
    required this.vehiclePerformanceScore,
    required this.predictedEnergyConsumption,
    required this.costPerKm,
    required this.monthlyCostEstimation,
    required this.riskLevel,
    required this.recommendedSpeed,
    required this.recommendedDrivingMode,
    required this.maintenanceAlertScore,
    required this.carbonSavingsEstimate,
    required this.predictedRangeHighway,
    required this.predictedRangeCity,
    required this.nextServiceRecommendation,
    required this.vehicleUtilizationScore,
    required this.driverEfficiencyScore,
    required this.overallVehicleHealth,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'] as String?,
      driverId: json['driver_id'] as String,
      driverIdStr: json['driver_id_str'] as String,
      carName: json['car_name'] as String,
      predictionDate: DateTime.parse(json['prediction_date'] as String),
      batteryPercentage: (json['battery_percentage'] as num).toDouble(),
      estimatedRange: (json['estimated_range'] as num).toDouble(),
      predictedBatteryDrainRate: (json['predicted_battery_drain_rate'] as num).toDouble(),
      batteryHealthScore: (json['battery_health_score'] as num).toDouble(),
      expectedChargingRequirement: (json['expected_charging_requirement'] as num).toDouble(),
      efficiencyScore: (json['efficiency_score'] as num).toDouble(),
      vehiclePerformanceScore: (json['vehicle_performance_score'] as num).toDouble(),
      predictedEnergyConsumption: (json['predicted_energy_consumption'] as num).toDouble(),
      costPerKm: (json['cost_per_km'] as num).toDouble(),
      monthlyCostEstimation: (json['monthly_cost_estimation'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      recommendedSpeed: (json['recommended_speed'] as num).toDouble(),
      recommendedDrivingMode: json['recommended_driving_mode'] as String,
      maintenanceAlertScore: (json['maintenance_alert_score'] as num).toDouble(),
      carbonSavingsEstimate: (json['carbon_savings_estimate'] as num).toDouble(),
      predictedRangeHighway: (json['predicted_range_highway'] as num).toDouble(),
      predictedRangeCity: (json['predicted_range_city'] as num).toDouble(),
      nextServiceRecommendation: json['next_service_recommendation'] as String,
      vehicleUtilizationScore: (json['vehicle_utilization_score'] as num).toDouble(),
      driverEfficiencyScore: (json['driver_efficiency_score'] as num).toDouble(),
      overallVehicleHealth: (json['overall_vehicle_health'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'driver_id': driverId,
      'driver_id_str': driverIdStr,
      'car_name': carName,
      'prediction_date': predictionDate.toIso8601String(),
      'battery_percentage': batteryPercentage,
      'estimated_range': estimatedRange,
      'predicted_battery_drain_rate': predictedBatteryDrainRate,
      'battery_health_score': batteryHealthScore,
      'expected_charging_requirement': expectedChargingRequirement,
      'efficiency_score': efficiencyScore,
      'vehicle_performance_score': vehiclePerformanceScore,
      'predicted_energy_consumption': predictedEnergyConsumption,
      'cost_per_km': costPerKm,
      'monthly_cost_estimation': monthlyCostEstimation,
      'risk_level': riskLevel,
      'recommended_speed': recommendedSpeed,
      'recommended_driving_mode': recommendedDrivingMode,
      'maintenance_alert_score': maintenanceAlertScore,
      'carbon_savings_estimate': carbonSavingsEstimate,
      'predicted_range_highway': predictedRangeHighway,
      'predicted_range_city': predictedRangeCity,
      'next_service_recommendation': nextServiceRecommendation,
      'vehicle_utilization_score': vehicleUtilizationScore,
      'driver_efficiency_score': driverEfficiencyScore,
      'overall_vehicle_health': overallVehicleHealth,
    };
  }
}
