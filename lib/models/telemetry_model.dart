class TelemetryRecord {
  final DateTime timestamp;
  final String driverId;
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

  factory TelemetryRecord.fromCsvRow(List<String> row) {
    DateTime ts;
    try {
      ts = _parseDate(row[0].trim());
    } catch (_) {
      ts = DateTime.now();
    }

    return TelemetryRecord(
      timestamp: ts,
      driverId: row[1].trim(),
      vehicleId: row[2].trim(),
      brand: row[3].trim(),
      carName: row[4].trim(),
      batteryCapacityKwh: double.tryParse(row[5]) ?? 0,
      maxRangeKm: double.tryParse(row[6]) ?? 0,
      vehicleWeightKg: double.tryParse(row[7]) ?? 0,
      motorPowerKw: double.tryParse(row[8]) ?? 0,
      runningMode: int.tryParse(row[9]) ?? 0,
      tripDistanceKm: double.tryParse(row[10]) ?? 0,
      tripDurationHr: double.tryParse(row[11]) ?? 0,
      incomeGenerated: double.tryParse(row[12]) ?? 0,
      avgSpeedKmph: double.tryParse(row[13]) ?? 0,
      maxSpeedKmph: double.tryParse(row[14]) ?? 0,
      overspeedEvents: int.tryParse(row[15]) ?? 0,
      hardBrakingEvents: int.tryParse(row[16]) ?? 0,
      rapidAccelerationEvents: int.tryParse(row[17]) ?? 0,
      idleTimeMinutes: double.tryParse(row[18]) ?? 0,
      weatherCondition: row[19].trim(),
      trafficDensity: row[20].trim(),
      ambientTemperature: double.tryParse(row[21]) ?? 0,
      socStartPct: double.tryParse(row[22]) ?? 0,
      socEndPct: double.tryParse(row[23]) ?? 0,
      batteryTemperature: double.tryParse(row[24]) ?? 0,
      batteryCycles: int.tryParse(row[25]) ?? 0,
      batteryHealthPct: double.tryParse(row[26]) ?? 0,
      energyConsumedKwh: double.tryParse(row[27]) ?? 0,
      odometerKm: double.tryParse(row[28]) ?? 0,
      brakeWearPct: double.tryParse(row[29]) ?? 0,
      suspensionHealthPct: double.tryParse(row[30]) ?? 0,
      daysSinceLastService: int.tryParse(row[31]) ?? 0,
      vehicleCondition: int.tryParse(row[32]) ?? 0,
      vehicleActive: int.tryParse(row[33]) ?? 0,
    );
  }

  static DateTime _parseDate(String s) {
    // Handles M/D/YYYY H:MM format
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
  }

  double get efficiencyWhPerKm =>
      tripDistanceKm > 0 ? (energyConsumedKwh * 1000) / tripDistanceKm : 0;

  double get socDrop => socStartPct - socEndPct;
}
