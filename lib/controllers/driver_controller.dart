import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_service.dart';

class DriverController extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  VehicleModel? _currentVehicle;
  bool _isLoading = false;
  String? _errorMessage;

  VehicleModel? get currentVehicle => _currentVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnboarded => _currentVehicle != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchVehicleData(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentVehicle = await _supabaseService.getVehicleData(driverId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkDriverIdUnique(String driverIdStr) async {
    try {
      return await _supabaseService.checkDriverIdUnique(driverIdStr);
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveVehicle(VehicleModel vehicle) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabaseService.saveVehicleData(vehicle);
      _currentVehicle = vehicle;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetDriverState() {
    _currentVehicle = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
