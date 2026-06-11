import 'package:flutter/services.dart';
import '../models/merged_telemetry_model.dart';

class MergedTelemetryService {
  static final MergedTelemetryService _i = MergedTelemetryService._();
  factory MergedTelemetryService() => _i;
  MergedTelemetryService._();

  List<MergedRecord>? _cache;
  List<DriverSummary>? _summaryCache;

  Future<List<MergedRecord>> loadRecords() async {
    if (_cache != null) return _cache!;
    final raw   = await rootBundle.loadString('assets/telemetry_merged1.csv');
    final lines = raw.split('\n');
    if (lines.isEmpty) return [];
    final headers = lines[0].split(',').map((e) => e.trim()).toList();
    final records = <MergedRecord>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',');
      final r = MergedRecord.fromCsvRow(headers, cols);
      if (r != null) records.add(r);
    }
    _cache = records;
    return records;
  }

  Future<List<DriverSummary>> loadSummaries() async {
    if (_summaryCache != null) return _summaryCache!;
    final records = await loadRecords();
    final grouped = <String, List<MergedRecord>>{};
    for (final r in records) {
      grouped.putIfAbsent(r.driverId, () => []).add(r);
    }

    _summaryCache = grouped.entries.map((e) {
      final recs = e.value;
      double avg(double Function(MergedRecord) f) =>
          recs.map(f).reduce((a, b) => a + b) / recs.length;
      double sum(double Function(MergedRecord) f) =>
          recs.map(f).reduce((a, b) => a + b);
      int sumI(int Function(MergedRecord) f) =>
          recs.map(f).reduce((a, b) => a + b);
      int maxI(int Function(MergedRecord) f) =>
          recs.map(f).reduce((a, b) => a > b ? a : b);
      double maxD(double Function(MergedRecord) f) =>
          recs.map(f).reduce((a, b) => a > b ? a : b);

      return DriverSummary(
        driverId:             e.key,
        driverName:           recs.first.driverName,
        carName:              recs.first.carName,
        brand:                recs.first.brand,
        driverType:           recs.first.driverType,
        trips:                recs.length,
        totalIncome:          sum((r) => r.incomeGenerated),
        totalDistKm:          sum((r) => r.tripDistanceKm),
        totalEnergyKwh:       sum((r) => r.energyConsumedKwh),
        totalOverspeed:       sumI((r) => r.overspeedEvents),
        totalHardBraking:     sumI((r) => r.hardBrakingEvents),
        totalRapidAccel:      sumI((r) => r.rapidAccelerationEvents),
        avgBatteryHealth:     avg((r) => r.batteryHealthPct),
        avgBreakdownProb:     avg((r) => r.actualBreakdownProbability),
        avgRUL:               avg((r) => r.remainingUsefulLifeDays.toDouble()),
        avgDegRate:           avg((r) => r.batteryDegradationRate),
        avgBrakeWear:         avg((r) => r.brakeWearPct),
        avgSuspension:        avg((r) => r.suspensionHealthPct),
        baseDriverScore:      recs.first.baseDriverScore,
        maxDaysSinceService:  maxI((r) => r.daysSinceLastService),
        maxSpeedKmph:         maxD((r) => r.maxSpeedKmph),
        avgSpeedKmph:         avg((r) => r.avgSpeedKmph),
      );
    }).toList()
      ..sort((a, b) => a.driverId.compareTo(b.driverId));

    return _summaryCache!;
  }

  void clearCache() {
    _cache = null;
    _summaryCache = null;
  }
}
