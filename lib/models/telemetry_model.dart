class TelemetryRecord {
  final DateTime timestamp;
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String brand;
  final String carName;
  final double batteryCapacityKwh;
  final double maxRangeKm;
  final double vehicleWeightKg;
  final double motorPowerKw;
  final int runningMode; // 0=city, 1=highway
  final double tripDistanceKm;
  final double tripDurationHr;
  final double incomeGenerated;
  final double avgSpeedKmph;
  final double maxSpeedKmph;
  final int overspeedEvents;
  final int hardBrakingEvents;
  final int rapidAccelerationEvents;
  final double idleTimeMinutes;
  final String weatherCondition;
  final String trafficDensity;
  final double ambientTemperature;
  final double socStartPct;
  final double socEndPct;
  final double batteryTemperature;
  final int batteryCycles;
  final double batteryHealthPct;
  final double energyConsumedKwh;
  final double odometerKm;
  final double brakeWearPct;
  final double suspensionHealthPct;
  final int daysSinceLastService;
  final int vehicleCondition;
  final int vehicleActive;

  const TelemetryRecord({
    required this.timestamp,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.brand,
    required this.carName,
    required this.batteryCapacityKwh,
    required this.maxRangeKm,
    required this.vehicleWeightKg,
    required this.motorPowerKw,
    required this.runningMode,
    required this.tripDistanceKm,
    required this.tripDurationHr,
    required this.incomeGenerated,
    required this.avgSpeedKmph,
    required this.maxSpeedKmph,
    required this.overspeedEvents,
    required this.hardBrakingEvents,
    required this.rapidAccelerationEvents,
    required this.idleTimeMinutes,
    required this.weatherCondition,
    required this.trafficDensity,
    required this.ambientTemperature,
    required this.socStartPct,
    required this.socEndPct,
    required this.batteryTemperature,
    required this.batteryCycles,
    required this.batteryHealthPct,
    required this.energyConsumedKwh,
    required this.odometerKm,
    required this.brakeWearPct,
    required this.suspensionHealthPct,
    required this.daysSinceLastService,
    required this.vehicleCondition,
    required this.vehicleActive,
  });

  factory TelemetryRecord.fromCsvRow(List<String> row, Map<String, int> colMap) {
    // Helper to get value by column name or fallback to index
    double getDouble(String key, int fallbackIndex) {
      final idx = colMap[key] ?? colMap['${key}_x'] ?? colMap['${key}_y'] ?? fallbackIndex;
      if (idx >= row.length) return 0;
      return double.tryParse(row[idx]) ?? 0;
    }

    int getInt(String key, int fallbackIndex) {
      final idx = colMap[key] ?? colMap['${key}_x'] ?? colMap['${key}_y'] ?? fallbackIndex;
      if (idx >= row.length) return 0;
      return int.tryParse(row[idx]) ?? 0;
    }

    String getString(String key, int fallbackIndex) {
      final idx = colMap[key] ?? colMap['${key}_x'] ?? colMap['${key}_y'] ?? fallbackIndex;
      if (idx >= row.length) return '';
      return row[idx].trim();
    }

    DateTime ts;
    try {
      final dateStr = getString('timestamp', 0);
      ts = _parseDate(dateStr);
    } catch (_) {
      ts = DateTime.now();
    }

    return TelemetryRecord(
      timestamp: ts,
      driverId: getString('driver_id', 1),
      driverName: getString('driver_name', 56),
      vehicleId: getString('vehicle_id', 2),
      brand: getString('brand', 3),
      carName: getString('car_name', 4),
      batteryCapacityKwh: getDouble('battery_capacity_kwh', 5),
      maxRangeKm: getDouble('max_range_km', 6),
      vehicleWeightKg: getDouble('vehicle_weight_kg', 7),
      motorPowerKw: getDouble('motor_power_kw', 8),
      runningMode: getInt('running_mode', 9),
      tripDistanceKm: getDouble('trip_distance_km', 10),
      tripDurationHr: getDouble('trip_duration_hr', 11),
      incomeGenerated: getDouble('income_generated', 12),
      avgSpeedKmph: getDouble('avg_speed_kmph', 13),
      maxSpeedKmph: getDouble('max_speed_kmph', 14),
      overspeedEvents: getInt('overspeed_events', 15),
      hardBrakingEvents: getInt('hard_braking_events', 16),
      rapidAccelerationEvents: getInt('rapid_acceleration_events', 17),
      idleTimeMinutes: getDouble('idle_time_minutes', 18),
      weatherCondition: getString('weather_condition', 19),
      trafficDensity: getString('traffic_density', 20),
      ambientTemperature: getDouble('ambient_temperature', 21),
      socStartPct: getDouble('soc_start_pct', 22),
      socEndPct: getDouble('soc_end_pct', 23),
      batteryTemperature: getDouble('battery_temperature', 24),
      batteryCycles: getInt('battery_cycles', 25),
      batteryHealthPct: getDouble('battery_health_pct', 26),
      energyConsumedKwh: getDouble('energy_consumed_kwh', 27),
      odometerKm: getDouble('odometer_km', 28),
      brakeWearPct: getDouble('brake_wear_pct', 29),
      suspensionHealthPct: getDouble('suspension_health_pct', 30),
      daysSinceLastService: getInt('days_since_last_service', 31),
      vehicleCondition: getInt('vehicle_condition', 32),
      vehicleActive: getInt('vehicle_active', 33),
    );
  }

  static DateTime _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {}

    try {
      final parts = s.split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0'];
      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  double get efficiencyWhPerKm =>
      tripDistanceKm > 0 ? (energyConsumedKwh * 1000) / tripDistanceKm : 0;

  double get socDrop => socStartPct - socEndPct;

  /// running | charging | garage
  String get vehicleState {
    if (vehicleActive == 1) return 'running';
    if (socEndPct > socStartPct) return 'charging';
    return 'garage';
  }

  /// Cost proxy: energy cost at ₹8/kWh (standard EV tariff)
  double get estimatedCostInr => energyConsumedKwh * 8.0;
}
