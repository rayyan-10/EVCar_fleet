class AdminStatsModel {
  final int totalDrivers;
  final int totalVehicles;
  final int activeVehicles;
  final int garageVehicles;
  final double averageRange;
  final double averageEfficiency;
  final double averageMonthlyIncome;
  final int totalPredictions;

  AdminStatsModel({
    required this.totalDrivers,
    required this.totalVehicles,
    required this.activeVehicles,
    required this.garageVehicles,
    required this.averageRange,
    required this.averageEfficiency,
    required this.averageMonthlyIncome,
    required this.totalPredictions,
  });

  factory AdminStatsModel.empty() {
    return AdminStatsModel(
      totalDrivers: 0,
      totalVehicles: 0,
      activeVehicles: 0,
      garageVehicles: 0,
      averageRange: 0.0,
      averageEfficiency: 0.0,
      averageMonthlyIncome: 0.0,
      totalPredictions: 0,
    );
  }
}
