import 'package:flutter/material.dart';
import '../models/vehicle_model.dart';
import '../models/user_model.dart';
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

  Future<void> fetchVehicleData(String driverId, {UserModel? authUser}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentVehicle = await _supabaseService.getVehicleData(driverId);

      // Patch: if driverName is blank, derive it from the auth username
      if (_currentVehicle != null &&
          _currentVehicle!.driverName.trim().isEmpty &&
          authUser != null) {
        final formatted = authUser.username
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .split(' ')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
        _currentVehicle = _currentVehicle!.copyWith(driverName: formatted);
      }
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
