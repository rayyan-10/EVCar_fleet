/// A row from telemetry_merged1.csv — enriched with driver metadata.
class MergedRecord {
  final String driverId;
  final String vehicleId;
  final String brand;
  final String carName;
  final String driverName;
  final String driverType; // Safe | Normal | Aggressive
  final int experienceYears;
  final double baseDriverScore;

  final double tripDistanceKm;
  final double incomeGenerated;
  final double avgSpeedKmph;
  final double maxSpeedKmph;
  final int overspeedEvents;
  final int hardBrakingEvents;
  final int rapidAccelerationEvents;
  final double idleTimeMinutes;
  final String weatherCondition;
  final double energyConsumedKwh;
  final double batteryHealthPct;
  final double batteryDegradationRate;
  final double actualBreakdownProbability;
  final String breakdownRiskLevel;
  final int remainingUsefulLifeDays;
  final double actualRangeKm;
  final double socStartPct;
  final double socEndPct;
  final int daysSinceLastService;
  final double brakeWearPct;
  final double suspensionHealthPct;
  final int runningMode;

  const MergedRecord({
    required this.driverId,
    required this.vehicleId,
    required this.brand,
    required this.carName,
    required this.driverName,
    required this.driverType,
    required this.experienceYears,
    required this.baseDriverScore,
    required this.tripDistanceKm,
    required this.incomeGenerated,
    required this.avgSpeedKmph,
    required this.maxSpeedKmph,
    required this.overspeedEvents,
    required this.hardBrakingEvents,
    required this.rapidAccelerationEvents,
    required this.idleTimeMinutes,
    required this.weatherCondition,
    required this.energyConsumedKwh,
    required this.batteryHealthPct,
    required this.batteryDegradationRate,
    required this.actualBreakdownProbability,
    required this.breakdownRiskLevel,
    required this.remainingUsefulLifeDays,
    required this.actualRangeKm,
    required this.socStartPct,
    required this.socEndPct,
    required this.daysSinceLastService,
    required this.brakeWearPct,
    required this.suspensionHealthPct,
    required this.runningMode,
  });

  static MergedRecord? fromCsvRow(List<String> h, List<String> v) {
    try {
      int col(String name) => h.indexOf(name);
      double d(String name) => double.tryParse(v[col(name)].trim()) ?? 0;
      int i(String name)    => int.tryParse(v[col(name)].trim()) ?? 0;
      String s(String name) {
        final c = col(name);
        return c >= 0 && c < v.length ? v[c].trim() : '';
      }

      return MergedRecord(
        driverId:                   s('driver_id'),
        vehicleId:                  s('vehicle_id'),
        brand:                      s('brand_x'),
        carName:                    s('car_name_x'),
        driverName:                 s('driver_name'),
        driverType:                 s('driver_type'),
        experienceYears:            i('experience_years'),
        baseDriverScore:            d('base_driver_score'),
        tripDistanceKm:             d('trip_distance_km'),
        incomeGenerated:            d('income_generated'),
        avgSpeedKmph:               d('avg_speed_kmph'),
        maxSpeedKmph:               d('max_speed_kmph'),
        overspeedEvents:            i('overspeed_events'),
        hardBrakingEvents:          i('hard_braking_events'),
        rapidAccelerationEvents:    i('rapid_acceleration_events'),
        idleTimeMinutes:            d('idle_time_minutes'),
        weatherCondition:           s('weather_condition'),
        energyConsumedKwh:          d('energy_consumed_kwh'),
        batteryHealthPct:           d('battery_health_pct_x'),
        batteryDegradationRate:     d('battery_degradation_rate'),
        actualBreakdownProbability: d('actual_breakdown_probability'),
        breakdownRiskLevel:         s('breakdown_risk_level'),
        remainingUsefulLifeDays:    i('remaining_useful_life_days'),
        actualRangeKm:              d('actual_range_km'),
        socStartPct:                d('soc_start_pct'),
        socEndPct:                  d('soc_end_pct'),
        daysSinceLastService:       i('days_since_last_service_x'),
        brakeWearPct:               d('brake_wear_pct_x'),
        suspensionHealthPct:        d('suspension_health_pct_x'),
        runningMode:                i('running_mode'),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Per-driver aggregated summary computed from all records.
class DriverSummary {
  final String driverId;
  final String driverName;
  final String carName;
  final String brand;
  final String driverType;
  final int trips;
  final double totalIncome;
  final double totalDistKm;
  final double totalEnergyKwh;
  final int totalOverspeed;
  final int totalHardBraking;
  final int totalRapidAccel;
  final double avgBatteryHealth;
  final double avgBreakdownProb;
  final double avgRUL;
  final double avgDegRate;
  final double avgBrakeWear;
  final double avgSuspension;
  final double baseDriverScore;
  final int maxDaysSinceService;
  final double maxSpeedKmph;
  final double avgSpeedKmph;

  const DriverSummary({
    required this.driverId,
    required this.driverName,
    required this.carName,
    required this.brand,
    required this.driverType,
    required this.trips,
    required this.totalIncome,
    required this.totalDistKm,
    required this.totalEnergyKwh,
    required this.totalOverspeed,
    required this.totalHardBraking,
    required this.totalRapidAccel,
    required this.avgBatteryHealth,
    required this.avgBreakdownProb,
    required this.avgRUL,
    required this.avgDegRate,
    required this.avgBrakeWear,
    required this.avgSuspension,
    required this.baseDriverScore,
    required this.maxDaysSinceService,
    required this.maxSpeedKmph,
    required this.avgSpeedKmph,
  });

  double get incomePerKm => totalDistKm > 0 ? totalIncome / totalDistKm : 0;
  double get efficiencyWhPerKm => totalDistKm > 0 ? (totalEnergyKwh * 1000) / totalDistKm : 0;
}
