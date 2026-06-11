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
    if (lines.isEmpty) return [];

    // Build column map from header
    final headerRow = lines[0].trim().split(',');
    final colMap = <String, int>{};
    for (int i = 0; i < headerRow.length; i++) {
      colMap[headerRow[i].trim().toLowerCase()] = i;
    }

    final records = <TelemetryRecord>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',');
      if (cols.length < 30) continue;
      try {
        records.add(TelemetryRecord.fromCsvRow(cols, colMap));
      } catch (_) {
        // skip malformed rows
      }
    }
    _cachedRecords = records;
    return records;
  }

  void clearCache() => _cachedRecords = null;
}
