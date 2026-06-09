import 'package:flutter/services.dart';
import '../models/telemetry_model.dart';

class TelemetryCsvService {
  static final TelemetryCsvService _instance = TelemetryCsvService._internal();
  factory TelemetryCsvService() => _instance;
  TelemetryCsvService._internal();

  List<TelemetryRecord>? _cachedRecords;

  Future<List<TelemetryRecord>> loadRecords() async {
    if (_cachedRecords != null) return _cachedRecords!;
    final raw = await rootBundle.loadString('assets/telemetry.csv');
    final lines = raw.split('\n');
    final records = <TelemetryRecord>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',');
      if (cols.length < 34) continue;
      try {
        records.add(TelemetryRecord.fromCsvRow(cols));
      } catch (_) {
        // skip malformed rows
      }
    }
    _cachedRecords = records;
    return records;
  }

  void clearCache() => _cachedRecords = null;
}
