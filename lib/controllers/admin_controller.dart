import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../models/prediction_model.dart';
import '../models/analytics_model.dart';
import '../models/speed_violation_model.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';

// Helper for conditional imports on Web to trigger file downloads
import '../views/widgets/web_helper_non_web.dart'
    if (dart.library.html) '../views/widgets/web_helper_web.dart' as web_helper;

class AdminController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final AnalyticsService _analyticsService = AnalyticsService();

  // Raw DB records cache
  List<VehicleModel> _allVehicles = [];
  List<PredictionModel> _allPredictions = [];
  List<SpeedViolationModel> _violations = [];

  // Filtered lists
  List<PredictionModel> _filteredPredictions = [];
  AdminStatsModel _stats = AdminStatsModel.empty();

  bool _isLoading = false;
  String? _errorMessage;

  // Active filters state
  DateTime? _startDate;
  DateTime? _endDate;
  String _driverIdQuery = '';
  String _carNameQuery = '';
  double? _minBattery;
  double? _maxBattery;
  double? _minWeight;
  double? _maxWeight;
  int? _runningType; // 0=City, 1=Highway, null=All
  int? _vehicleCondition; // 1=Working, 0=Garage, null=All
  double? _minSpeed;
  double? _maxSpeed;
  double? _minIncome;
  double? _maxIncome;
  double? _minHealth;
  double? _maxHealth;

  // Table sorting & pagination
  String _sortColumn = 'driver_id_str';
  bool _sortAscending = true;
  int _currentPage = 1;
  int _rowsPerPage = 10;

  // Getters
  List<PredictionModel> get filteredPredictions => _filteredPredictions;
  List<VehicleModel> get allVehicles => _allVehicles;
  List<SpeedViolationModel> get violations => _violations;
  AdminStatsModel get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filter state getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get driverIdQuery => _driverIdQuery;
  String get carNameQuery => _carNameQuery;
  double? get minBattery => _minBattery;
  double? get maxBattery => _maxBattery;
  double? get minWeight => _minWeight;
  double? get maxWeight => _maxWeight;
  int? get runningType => _runningType;
  int? get vehicleCondition => _vehicleCondition;
  double? get minSpeed => _minSpeed;
  double? get maxSpeed => _maxSpeed;
  double? get minIncome => _minIncome;
  double? get maxIncome => _maxIncome;
  double? get minHealth => _minHealth;
  double? get maxHealth => _maxHealth;

  // Table state getters
  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;

  Future<void> fetchAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseService.getAllProfiles(); // fetched for completeness; used via vehicles
      _allVehicles = await _supabaseService.getAllVehicles();
      _allPredictions = await _supabaseService.getAllPredictions();
      _violations = await _supabaseService.getAllViolations();
      
      applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters() {
    _filteredPredictions = _analyticsService.filterPredictions(
      predictions: _allPredictions,
      vehicles: _allVehicles,
      startDate: _startDate,
      endDate: _endDate,
      driverIdQuery: _driverIdQuery,
      carNameQuery: _carNameQuery,
      minBattery: _minBattery,
      maxBattery: _maxBattery,
      minWeight: _minWeight,
      maxWeight: _maxWeight,
      runningType: _runningType,
      vehicleCondition: _vehicleCondition,
      minSpeed: _minSpeed,
      maxSpeed: _maxSpeed,
      minIncome: _minIncome,
      maxIncome: _maxIncome,
      minHealth: _minHealth,
      maxHealth: _maxHealth,
    );

    _stats = _analyticsService.calculateStats(
      filteredPredictions: _filteredPredictions,
      allVehicles: _allVehicles,
    );
    
    // Reset to page 1 on filter recalculation
    _currentPage = 1;
  }

  // Setters for Filter Conditions (triggers immediate updates)
  void updateDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    applyFilters();
    notifyListeners();
  }

  void updateTextQueries({String? driverId, String? carName}) {
    if (driverId != null) _driverIdQuery = driverId;
    if (carName != null) _carNameQuery = carName;
    applyFilters();
    notifyListeners();
  }

  void updateNumericalFilters({
    double? minBattery, double? maxBattery,
    double? minWeight, double? maxWeight,
    double? minSpeed, double? maxSpeed,
    double? minIncome, double? maxIncome,
    double? minHealth, double? maxHealth,
    int? runningType, int? vehicleCondition,
  }) {
    if (minBattery != null || maxBattery != null) {
      _minBattery = minBattery;
      _maxBattery = maxBattery;
    }
    if (minWeight != null || maxWeight != null) {
      _minWeight = minWeight;
      _maxWeight = maxWeight;
    }
    if (minSpeed != null || maxSpeed != null) {
      _minSpeed = minSpeed;
      _maxSpeed = maxSpeed;
    }
    if (minIncome != null || maxIncome != null) {
      _minIncome = minIncome;
      _maxIncome = maxIncome;
    }
    if (minHealth != null || maxHealth != null) {
      _minHealth = minHealth;
      _maxHealth = minHealth;
    }
    if (runningType != -1) {
      _runningType = runningType;
    }
    if (vehicleCondition != -1) {
      _vehicleCondition = vehicleCondition;
    }
    applyFilters();
    notifyListeners();
  }

  void resetFilters() {
    _startDate = null;
    _endDate = null;
    _driverIdQuery = '';
    _carNameQuery = '';
    _minBattery = null;
    _maxBattery = null;
    _minWeight = null;
    _maxWeight = null;
    _runningType = null;
    _vehicleCondition = null;
    _minSpeed = null;
    _maxSpeed = null;
    _minIncome = null;
    _maxIncome = null;
    _minHealth = null;
    _maxHealth = null;
    applyFilters();
    notifyListeners();
  }

  // ==========================================
  // TABLE PAGINATION, SORTING & GETTERS
  // ==========================================

  void setSort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void changePage(int delta) {
    _currentPage = (_currentPage + delta).clamp(1, totalPages);
    notifyListeners();
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    notifyListeners();
  }

  int get totalPages {
    final Map<String, VehicleModel> uniqueVehicles = {};
    for (var v in _allVehicles) {
      // Find vehicles related to current filtered predictions
      final hasPred = _filteredPredictions.any((p) => p.driverId == v.driverId);
      if (hasPred) {
        uniqueVehicles[v.driverId] = v;
      }
    }
    final len = uniqueVehicles.length;
    return (len / _rowsPerPage).ceil().clamp(1, 99999);
  }

  List<VehicleModel> get paginatedVehiclesList {
    final Map<String, VehicleModel> vehicleMap = {};
    for (var v in _allVehicles) {
      final hasPred = _filteredPredictions.any((p) => p.driverId == v.driverId);
      if (hasPred) {
        vehicleMap[v.driverId] = v;
      }
    }

    final list = vehicleMap.values.toList();

    // Sort list
    list.sort((a, b) {
      dynamic valA;
      dynamic valB;
      switch (_sortColumn) {
        case 'driver_id_str':
          valA = a.driverIdStr;
          valB = b.driverIdStr;
          break;
        case 'driver_name':
          valA = a.driverName;
          valB = b.driverName;
          break;
        case 'email':
          valA = a.email;
          valB = b.email;
          break;
        case 'car_name':
          valA = a.carName;
          valB = b.carName;
          break;
        case 'battery_capacity':
          valA = a.batteryCapacity;
          valB = b.batteryCapacity;
          break;
        case 'vehicle_weight':
          valA = a.vehicleWeight;
          valB = b.vehicleWeight;
          break;
        case 'current_speed':
          valA = a.currentSpeed;
          valB = b.currentSpeed;
          break;
        case 'monthly_income':
          valA = a.monthlyIncome;
          valB = b.monthlyIncome;
          break;
        case 'vehicle_condition':
          valA = a.vehicleCondition;
          valB = b.vehicleCondition;
          break;
        case 'running_type':
          valA = a.runningType;
          valB = b.runningType;
          break;
        case 'created_at':
          valA = a.createdAt ?? DateTime.now();
          valB = b.createdAt ?? DateTime.now();
          break;
        default:
          valA = a.driverIdStr;
          valB = b.driverIdStr;
      }

      if (valA is String) {
        return _sortAscending
            ? valA.compareTo(valB as String)
            : (valB as String).compareTo(valA);
      } else if (valA is num) {
        return _sortAscending
            ? valA.compareTo(valB as num)
            : (valB as num).compareTo(valA);
      } else if (valA is DateTime) {
        return _sortAscending
            ? valA.compareTo(valB as DateTime)
            : (valB as DateTime).compareTo(valA);
      }
      return 0;
    });

    // Paginate list
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex >= list.length) return [];
    final endIndex = (startIndex + _rowsPerPage).clamp(0, list.length);
    return list.sublist(startIndex, endIndex);
  }

  // ==========================================
  // EXPORT / REPORT GENERATION APIS
  // ==========================================

  void exportCSV() {
    final headers = [
      'Driver ID', 'Driver Name', 'Email', 'Car Name', 'Battery (kWh)',
      'Weight (kg)', 'Current Speed (km/h)',      'Monthly Income (\$)',
      'Condition (1=Working/0=Garage)', 'Running Mode (1=Hwy/0=City)'
    ];

    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (var vehicle in _allVehicles) {
      final values = [
        '"${vehicle.driverIdStr}"',
        '"${vehicle.driverName}"',
        '"${vehicle.email}"',
        '"${vehicle.carName}"',
        vehicle.batteryCapacity,
        vehicle.vehicleWeight,
        vehicle.currentSpeed,
        vehicle.monthlyIncome,
        vehicle.vehicleCondition,
        vehicle.runningType
      ];
      buffer.writeln(values.join(','));
    }

    final bytes = utf8.encode(buffer.toString());
    web_helper.downloadFile(bytes, 'driver_management_export.csv');
  }

  void exportExcel() {
    // Standard Excel readable format (CSV is fully openable by Excel)
    exportCSV();
  }

  void exportPDFReport() {
    // Generate a simple structured text report containing all driver details
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('           DRIVE ANALYSIS PLATFORM REPORT           ');
    buffer.writeln('====================================================');
    buffer.writeln('Generated Date: ${DateTime.now().toLocal()}');
    buffer.writeln('Total Registered Drivers: ${_stats.totalDrivers}');
    buffer.writeln('Total Predictions Logged: ${_stats.totalPredictions}');
    buffer.writeln('Average Remaining Range: ${_stats.averageRange.toStringAsFixed(1)} KM');
    buffer.writeln('Average Fleet Efficiency: ${_stats.averageEfficiency.toStringAsFixed(1)}%');
    buffer.writeln('Fleet Average Income: \$${_stats.averageMonthlyIncome.toStringAsFixed(0)}/mo');
    buffer.writeln('\n================ FLEET DRIVERS LIST ================');
    
    for (var vehicle in _allVehicles) {
      buffer.writeln('ID: ${vehicle.driverIdStr} | Name: ${vehicle.driverName} | Car: ${vehicle.carName}');
      buffer.writeln('  Battery: ${vehicle.batteryCapacity} kWh | Weight: ${vehicle.vehicleWeight} kg');
      buffer.writeln('  Speed: ${vehicle.currentSpeed} km/h | Mode: ${vehicle.runningType == 1 ? "Highway" : "City"}');
      buffer.writeln('  Status: ${vehicle.vehicleCondition == 1 ? "Working" : "Garage"} | Income: \$${vehicle.monthlyIncome}');
      buffer.writeln('----------------------------------------------------');
    }

    final bytes = utf8.encode(buffer.toString());
    web_helper.downloadFile(bytes, 'fleet_report.txt');
  }

  void resetAdminState() {
    _allVehicles = [];
    _allPredictions = [];
    _violations = [];
    _filteredPredictions = [];
    _stats = AdminStatsModel.empty();
    resetFilters();
    _currentPage = 1;
    notifyListeners();
  }

  Future<void> refreshViolations() async {
    try {
      _violations = await _supabaseService.getAllViolations();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] Failed to refresh violations: $e');
    }
  }
}
