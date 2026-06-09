import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/prediction_model.dart';
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Replace with your actual Supabase project credentials
  // Found at: https://supabase.com/dashboard → Project Settings → API
  static const String _supabaseUrl = 'https://qvabpnzlrofqadwvlvaj.supabase.co';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2YWJwbnpscm9mcWFkd3ZsdmFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4OTY5OTEsImV4cCI6MjA5NjQ3Mjk5MX0.ArA3GrlmrRrG_Hn0oFnQq4e0KSNK1FWDktwLiG9aiac';

  bool _isDemoMode = true;
  bool get isDemoMode => _isDemoMode;

  static bool get _isConfigured =>
      !_supabaseUrl.contains('your-project') && _supabaseKey != 'your-anon-key';

  // Mock database in-memory storage (pre-populated with diverse data for amazing charts)
  final List<UserModel> _mockUsers = [];
  final List<VehicleModel> _mockVehicles = [];
  final List<PredictionModel> _mockPredictions = [];

  UserModel? _currentMockUser;

  Future<void> initialize() async {
    if (_isConfigured) {
      try {
        await Supabase.initialize(
          url: _supabaseUrl,
          anonKey: _supabaseKey,
        );
        _isDemoMode = false;
        if (kDebugMode) print('[DAP] Supabase initialized — live mode active.');
      } catch (e) {
        if (kDebugMode) print('[DAP] Supabase init failed, falling back to Demo Mode: $e');
        _isDemoMode = true;
      }
    } else {
      _isDemoMode = true;
      if (kDebugMode) print('[DAP] Running in Demo Mode (mock data).');
    }

    if (_isDemoMode) {
      _prepopulateMockData();
    }
  }


  void _prepopulateMockData() {
    _mockUsers.addAll([
      UserModel(id: 'admin-uuid-123', username: 'admin', role: 'admin', createdAt: DateTime.now().subtract(const Duration(days: 90))),
      UserModel(id: 'driver-1', username: 'elon_musk', role: 'driver', createdAt: DateTime.now().subtract(const Duration(days: 60))),
      UserModel(id: 'driver-2', username: 'sarah_jenkins', role: 'driver', createdAt: DateTime.now().subtract(const Duration(days: 45))),
      UserModel(id: 'driver-3', username: 'kenji_sato', role: 'driver', createdAt: DateTime.now().subtract(const Duration(days: 30))),
      UserModel(id: 'driver-4', username: 'hans_schmidt', role: 'driver', createdAt: DateTime.now().subtract(const Duration(days: 20))),
      UserModel(id: 'driver-5', username: 'pierre_dubois', role: 'driver', createdAt: DateTime.now().subtract(const Duration(days: 10))),
    ]);

    // Pre-populate vehicles corresponding to these drivers
    _mockVehicles.addAll([
      VehicleModel(id: 'veh-1', driverId: 'driver-1', driverIdStr: 'DRV-TESLA-01', driverName: 'Elon Musk', email: 'elon_musk@dap.local', carName: 'Tesla Model 3 Long Range', batteryCapacity: 82.0, vehicleWeight: 1847.0, motorPower: 258.0, torque: 493.0, motorEfficiency: 94.0, runningType: 1, vehicleCondition: 1, currentSpeed: 110.0, monthlyIncome: 9500.0, currentDate: '2026-06-08', currentTime: '10:00 AM', currentMonth: 'June', location: 'Palo Alto, CA', createdAt: DateTime.now().subtract(const Duration(days: 60))),
      VehicleModel(id: 'veh-2', driverId: 'driver-2', driverIdStr: 'DRV-BOLT-02', driverName: 'Sarah Jenkins', email: 'sarah_jenkins@dap.local', carName: 'Chevrolet Bolt EV', batteryCapacity: 66.0, vehicleWeight: 1616.0, motorPower: 150.0, torque: 360.0, motorEfficiency: 88.0, runningType: 0, vehicleCondition: 1, currentSpeed: 45.0, monthlyIncome: 4200.0, currentDate: '2026-06-07', currentTime: '02:30 PM', currentMonth: 'June', location: 'Chicago, IL', createdAt: DateTime.now().subtract(const Duration(days: 45))),
      VehicleModel(id: 'veh-3', driverId: 'driver-3', driverIdStr: 'DRV-LEAF-03', driverName: 'Kenji Sato', email: 'kenji_sato@dap.local', carName: 'Nissan Leaf e+', batteryCapacity: 62.0, vehicleWeight: 1680.0, motorPower: 160.0, torque: 340.0, motorEfficiency: 85.0, runningType: 0, vehicleCondition: 0, currentSpeed: 0.0, monthlyIncome: 3500.0, currentDate: '2026-06-06', currentTime: '09:00 AM', currentMonth: 'June', location: 'Seattle, WA', createdAt: DateTime.now().subtract(const Duration(days: 30))),
      VehicleModel(id: 'veh-4', driverId: 'driver-4', driverIdStr: 'DRV-ETRON-04', driverName: 'Hans Schmidt', email: 'hans_schmidt@dap.local', carName: 'Audi e-tron GT', batteryCapacity: 93.0, vehicleWeight: 2276.0, motorPower: 350.0, torque: 630.0, motorEfficiency: 92.0, runningType: 1, vehicleCondition: 1, currentSpeed: 130.0, monthlyIncome: 12000.0, currentDate: '2026-06-05', currentTime: '04:15 PM', currentMonth: 'June', location: 'Munich, Germany', createdAt: DateTime.now().subtract(const Duration(days: 20))),
      VehicleModel(id: 'veh-5', driverId: 'driver-5', driverIdStr: 'DRV-TAYCAN-05', driverName: 'Pierre Dubois', email: 'pierre_dubois@dap.local', carName: 'Porsche Taycan Turbo S', batteryCapacity: 93.4, vehicleWeight: 2295.0, motorPower: 560.0, torque: 1050.0, motorEfficiency: 95.0, runningType: 1, vehicleCondition: 1, currentSpeed: 140.0, monthlyIncome: 15000.0, currentDate: '2026-06-04', currentTime: '11:45 PM', currentMonth: 'June', location: 'Paris, France', createdAt: DateTime.now().subtract(const Duration(days: 10))),
    ]);

    // Pre-populate prediction logs spanning different dates to create beautiful trendlines
    final referenceDate = DateTime.now();

    // Driver 1 predictions (Tesla)
    for (int i = 0; i < 8; i++) {
      final daysAgo = 50 - (i * 6);
      final date = referenceDate.subtract(Duration(days: daysAgo));
      // Simulate improving battery degradation slightly over time (just demo numbers)
      final batteryHealth = 99.0 - (i * 0.2);
      final efficiency = 88.0 + (i * 1.2);
      _mockPredictions.add(PredictionModel(
        id: 'pred-t-$i',
        driverId: 'driver-1',
        driverIdStr: 'DRV-TESLA-01',
        carName: 'Tesla Model 3 Long Range',
        predictionDate: date,
        batteryPercentage: 90.0 - (i % 3) * 10,
        estimatedRange: 420.0 - (i % 3) * 45,
        predictedBatteryDrainRate: 145.0 + (i % 3) * 12,
        batteryHealthScore: batteryHealth,
        expectedChargingRequirement: 6.5,
        efficiencyScore: efficiency,
        vehiclePerformanceScore: 92.0,
        predictedEnergyConsumption: 155.0 - (i * 2),
        costPerKm: 0.03,
        monthlyCostEstimation: 45.0,
        riskLevel: 'Low',
        recommendedSpeed: 95.0,
        recommendedDrivingMode: 'Eco-Plus',
        maintenanceAlertScore: 12.0,
        carbonSavingsEstimate: 120.0 + (i * 25),
        predictedRangeHighway: 390.0,
        predictedRangeCity: 445.0,
        nextServiceRecommendation: 'Sept 2026',
        vehicleUtilizationScore: 84.0,
        driverEfficiencyScore: 89.0,
        overallVehicleHealth: 96.0,
      ));
    }

    // Driver 2 predictions (Chevrolet Bolt)
    for (int i = 0; i < 6; i++) {
      final daysAgo = 40 - (i * 7);
      final date = referenceDate.subtract(Duration(days: daysAgo));
      final efficiency = 75.0 + (i * 1.5);
      _mockPredictions.add(PredictionModel(
        id: 'pred-b-$i',
        driverId: 'driver-2',
        driverIdStr: 'DRV-BOLT-02',
        carName: 'Chevrolet Bolt EV',
        predictionDate: date,
        batteryPercentage: 85.0 - (i % 2) * 15,
        estimatedRange: 320.0 - (i % 2) * 50,
        predictedBatteryDrainRate: 165.0 + (i % 2) * 10,
        batteryHealthScore: 97.0,
        expectedChargingRequirement: 8.0,
        efficiencyScore: efficiency,
        vehiclePerformanceScore: 78.0,
        predictedEnergyConsumption: 175.0 - (i * 3),
        costPerKm: 0.035,
        monthlyCostEstimation: 52.0,
        riskLevel: 'Medium',
        recommendedSpeed: 60.0,
        recommendedDrivingMode: 'Eco Mode',
        maintenanceAlertScore: 18.0,
        carbonSavingsEstimate: 90.0 + (i * 18),
        predictedRangeHighway: 290.0,
        predictedRangeCity: 350.0,
        nextServiceRecommendation: 'Aug 2026',
        vehicleUtilizationScore: 68.0,
        driverEfficiencyScore: 79.0,
        overallVehicleHealth: 92.0,
      ));
    }

    // Add random predictions for other drivers to populate admin graphs nicely
    // Driver 3 (Leaf - Needs Maintenance)
    _mockPredictions.add(PredictionModel(
      id: 'pred-l-1',
      driverId: 'driver-3',
      driverIdStr: 'DRV-LEAF-03',
      carName: 'Nissan Leaf e+',
      predictionDate: referenceDate.subtract(const Duration(days: 15)),
      batteryPercentage: 45.0,
      estimatedRange: 130.0,
      predictedBatteryDrainRate: 190.0,
      batteryHealthScore: 78.0, // Low battery health
      expectedChargingRequirement: 7.2,
      efficiencyScore: 65.0,
      vehiclePerformanceScore: 60.0,
      predictedEnergyConsumption: 210.0,
      costPerKm: 0.045,
      monthlyCostEstimation: 75.0,
      riskLevel: 'High', // High Risk
      recommendedSpeed: 50.0,
      recommendedDrivingMode: 'B-Mode Eco',
      maintenanceAlertScore: 82.0, // High Maintenance flag
      carbonSavingsEstimate: 62.0,
      predictedRangeHighway: 110.0,
      predictedRangeCity: 145.0,
      nextServiceRecommendation: 'Immediate Action Required',
      vehicleUtilizationScore: 45.0,
      driverEfficiencyScore: 60.0,
      overallVehicleHealth: 74.0,
    ));

    // Driver 4 (Audi e-tron - Heavy & High energy usage)
    _mockPredictions.add(PredictionModel(
      id: 'pred-e-1',
      driverId: 'driver-4',
      driverIdStr: 'DRV-ETRON-04',
      carName: 'Audi e-tron GT',
      predictionDate: referenceDate.subtract(const Duration(days: 8)),
      batteryPercentage: 95.0,
      estimatedRange: 380.0,
      predictedBatteryDrainRate: 230.0, // High drain
      batteryHealthScore: 98.0,
      expectedChargingRequirement: 9.5,
      efficiencyScore: 72.0,
      vehiclePerformanceScore: 94.0,
      predictedEnergyConsumption: 240.0,
      costPerKm: 0.05,
      monthlyCostEstimation: 90.0,
      riskLevel: 'Medium',
      recommendedSpeed: 100.0,
      recommendedDrivingMode: 'Comfort',
      maintenanceAlertScore: 22.0,
      carbonSavingsEstimate: 140.0,
      predictedRangeHighway: 360.0,
      predictedRangeCity: 410.0,
      nextServiceRecommendation: 'Dec 2026',
      vehicleUtilizationScore: 80.0,
      driverEfficiencyScore: 70.0,
      overallVehicleHealth: 94.0,
    ));

    // Driver 5 (Porsche Taycan - High Speed & High Risk)
    _mockPredictions.add(PredictionModel(
      id: 'pred-p-1',
      driverId: 'driver-5',
      driverIdStr: 'DRV-TAYCAN-05',
      carName: 'Porsche Taycan Turbo S',
      predictionDate: referenceDate.subtract(const Duration(days: 3)),
      batteryPercentage: 80.0,
      estimatedRange: 310.0,
      predictedBatteryDrainRate: 250.0,
      batteryHealthScore: 96.0,
      expectedChargingRequirement: 7.8,
      efficiencyScore: 58.0, // Low efficiency due to aggressive speed
      vehiclePerformanceScore: 98.0,
      predictedEnergyConsumption: 265.0,
      costPerKm: 0.06,
      monthlyCostEstimation: 110.0,
      riskLevel: 'High', // High Speed High Risk
      recommendedSpeed: 90.0,
      recommendedDrivingMode: 'Range Mode',
      maintenanceAlertScore: 35.0,
      carbonSavingsEstimate: 160.0,
      predictedRangeHighway: 290.0,
      predictedRangeCity: 330.0,
      nextServiceRecommendation: 'Nov 2026',
      vehicleUtilizationScore: 88.0,
      driverEfficiencyScore: 55.0,
      overallVehicleHealth: 93.0,
    ));
  }

  // ==========================================
  // AUTHENTICATION APIs
  // ==========================================

  // In-memory session for live mode
  UserModel? _currentLiveUser;

  // ==========================================
  // AUTHENTICATION APIs (custom — no Supabase Auth)
  // ==========================================

  Future<UserModel> signUp(String username, String password, String role) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (_mockUsers.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
        throw Exception("Username already taken. Please choose another.");
      }
      final newUser = UserModel(id: 'usr-${DateTime.now().millisecondsSinceEpoch}', username: username, role: role, createdAt: DateTime.now());
      _mockUsers.add(newUser);
      _currentMockUser = newUser;
      return newUser;
    } else {
      try {
        final result = await Supabase.instance.client.rpc('sign_up', params: {
          'p_username': username,
          'p_password': password,
          'p_role': role,
        });
        final user = UserModel.fromJson(Map<String, dynamic>.from(result as Map));
        _currentLiveUser = user;
        return user;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('USERNAME_TAKEN')) throw Exception("Username already taken.");
        rethrow;
      }
    }
  }

  Future<UserModel> signIn(String username, String password) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      final idx = _mockUsers.indexWhere((u) => u.username.toLowerCase() == username.toLowerCase());
      if (idx == -1) throw Exception("Username not found. Check your credentials.");
      _currentMockUser = _mockUsers[idx];
      return _currentMockUser!;
    } else {
      try {
        final result = await Supabase.instance.client.rpc('sign_in', params: {
          'p_username': username,
          'p_password': password,
        });
        final user = UserModel.fromJson(Map<String, dynamic>.from(result as Map));
        _currentLiveUser = user;
        return user;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('INVALID_CREDENTIALS')) throw Exception("Invalid username or password.");
        rethrow;
      }
    }
  }

  Future<void> signOut() async {
    _isDemoMode ? _currentMockUser = null : _currentLiveUser = null;
  }

  Future<void> sendPasswordResetEmail(String username) async {
    if (_isDemoMode) {
      if (!_mockUsers.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
        throw Exception("No account found with that username.");
      }
      return;
    }
    throw Exception("Password reset requires admin access. Contact your administrator.");
  }

  Future<UserModel?> getCurrentUser() async {
    return _isDemoMode ? _currentMockUser : _currentLiveUser;
  }

  // ==========================================
  // VEHICLE DATABASE APIs
  // ==========================================

  Future<bool> checkDriverIdUnique(String driverIdStr) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      // Exclude current driver's existing ID if they are updating it
      final currentDriverVeh = _mockVehicles.firstWhere(
        (v) => v.driverId == _currentMockUser?.id,
        orElse: () => VehicleModel(
          driverId: '', driverIdStr: '', driverName: '', email: '', carName: '',
          batteryCapacity: 0, vehicleWeight: 0, motorPower: 0, torque: 0, motorEfficiency: 0,
          runningType: 0, vehicleCondition: 0, currentSpeed: 0, monthlyIncome: 0,
          currentDate: '', currentTime: '', currentMonth: '',
        ),
      );
      if (currentDriverVeh.driverIdStr == driverIdStr) return true;
      
      return !_mockVehicles.any((v) => v.driverIdStr.toLowerCase() == driverIdStr.toLowerCase());
    } else {
      final currentUserId = _currentLiveUser?.id;
      final res = await Supabase.instance.client
          .from('vehicles')
          .select('driver_id_str, driver_id')
          .eq('driver_id_str', driverIdStr);
      if (res.isEmpty) return true;
      if (currentUserId != null && res[0]['driver_id'] == currentUserId) return true;
      return false;
    }
  }

  Future<void> saveVehicleData(VehicleModel vehicle) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = _mockVehicles.indexWhere((v) => v.driverId == vehicle.driverId);
      final updated = vehicle.copyWith(
        id: vehicle.id ?? 'veh-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: vehicle.createdAt ?? DateTime.now(),
      );
      if (idx == -1) {
        _mockVehicles.add(updated);
      } else {
        _mockVehicles[idx] = updated;
      }
    } else {
      final map = vehicle.toJson();
      // Use upsert matching the driver_id or driver_id_str
      final selectRes = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('driver_id', vehicle.driverId);
      
      if (selectRes.isEmpty) {
        await Supabase.instance.client.from('vehicles').insert(map);
      } else {
        final id = selectRes[0]['id'];
        await Supabase.instance.client.from('vehicles').update(map).eq('id', id);
      }
    }
  }

  Future<VehicleModel?> getVehicleData(String driverId) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final idx = _mockVehicles.indexWhere((v) => v.driverId == driverId);
      return idx == -1 ? null : _mockVehicles[idx];
    } else {
      try {
        final data = await Supabase.instance.client
            .from('vehicles')
            .select()
            .eq('driver_id', driverId)
            .maybeSingle();
        return data == null ? null : VehicleModel.fromJson(data);
      } catch (e) {
        return null;
      }
    }
  }

  // ==========================================
  // PREDICTIONS DATABASE APIs
  // ==========================================

  Future<void> savePrediction(PredictionModel prediction) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final finalPred = PredictionModel(
        id: 'pred-${DateTime.now().millisecondsSinceEpoch}',
        driverId: prediction.driverId,
        driverIdStr: prediction.driverIdStr,
        carName: prediction.carName,
        predictionDate: prediction.predictionDate,
        batteryPercentage: prediction.batteryPercentage,
        estimatedRange: prediction.estimatedRange,
        predictedBatteryDrainRate: prediction.predictedBatteryDrainRate,
        batteryHealthScore: prediction.batteryHealthScore,
        expectedChargingRequirement: prediction.expectedChargingRequirement,
        efficiencyScore: prediction.efficiencyScore,
        vehiclePerformanceScore: prediction.vehiclePerformanceScore,
        predictedEnergyConsumption: prediction.predictedEnergyConsumption,
        costPerKm: prediction.costPerKm,
        monthlyCostEstimation: prediction.monthlyCostEstimation,
        riskLevel: prediction.riskLevel,
        recommendedSpeed: prediction.recommendedSpeed,
        recommendedDrivingMode: prediction.recommendedDrivingMode,
        maintenanceAlertScore: prediction.maintenanceAlertScore,
        carbonSavingsEstimate: prediction.carbonSavingsEstimate,
        predictedRangeHighway: prediction.predictedRangeHighway,
        predictedRangeCity: prediction.predictedRangeCity,
        nextServiceRecommendation: prediction.nextServiceRecommendation,
        vehicleUtilizationScore: prediction.vehicleUtilizationScore,
        driverEfficiencyScore: prediction.driverEfficiencyScore,
        overallVehicleHealth: prediction.overallVehicleHealth,
      );
      _mockPredictions.add(finalPred);
    } else {
      await Supabase.instance.client.from('predictions').insert(prediction.toJson());
    }
  }

  Future<List<PredictionModel>> getPredictions(String driverId) async {
    if (_isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final list = _mockPredictions.where((p) => p.driverId == driverId).toList();
      // Sort predictions descending (most recent first)
      list.sort((a, b) => b.predictionDate.compareTo(a.predictionDate));
      return list;
    } else {
      final List<dynamic> data = await Supabase.instance.client
          .from('predictions')
          .select()
          .eq('driver_id', driverId)
          .order('prediction_date', ascending: false);
      return data.map((json) => PredictionModel.fromJson(json)).toList();
    }
  }

  // ==========================================
  // ADMIN DASHBOARD CRUDs
  // ==========================================

  Future<List<UserModel>> getAllProfiles() async {
    if (_isDemoMode) {
      return _mockUsers;
    } else {
      final List<dynamic> data = await Supabase.instance.client
          .from('users')
          .select('id, username, role, created_at');
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
  }

  Future<List<VehicleModel>> getAllVehicles() async {
    if (_isDemoMode) {
      return _mockVehicles;
    } else {
      final List<dynamic> data = await Supabase.instance.client
          .from('vehicles')
          .select();
      return data.map((json) => VehicleModel.fromJson(json)).toList();
    }
  }

  Future<List<PredictionModel>> getAllPredictions() async {
    if (_isDemoMode) {
      return _mockPredictions;
    } else {
      final List<dynamic> data = await Supabase.instance.client
          .from('predictions')
          .select();
      return data.map((json) => PredictionModel.fromJson(json)).toList();
    }
  }
}
