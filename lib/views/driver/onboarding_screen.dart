import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/driver_controller.dart';
import '../../models/vehicle_model.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../widgets/glass_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isEditing; // Support editing existing data

  const OnboardingScreen({Key? key, this.isEditing = false}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers
  final _driverIdStrController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _carNameController = TextEditingController();
  final _vehicleWeightController = TextEditingController();
  final _motorPowerController = TextEditingController();
  final _torqueController = TextEditingController();
  final _currentSpeedController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Custom Date/Time
  final _currentDateController = TextEditingController();
  final _currentTimeController = TextEditingController();
  final _currentMonthController = TextEditingController();

  double _batteryCapacity = 75.0; // Slider: 10 - 100 kWh
  double _motorEfficiency = 90.0; // Slider: 50 - 100 %
  int _runningType = 0; // 0 = City, 1 = Highway
  int _vehicleCondition = 1; // 1 = Working, 0 = Garage

  // Driver ID validation states
  bool _isCheckingDriverId = false;
  bool? _isDriverIdUnique;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _emailController.text = Provider.of<AuthController>(context, listen: false).currentUser?.fakeEmail ?? '';
    
    // Autofill current date/time info
    final now = DateTime.now();
    _currentDateController.text = DateFormat('yyyy-MM-dd').format(now);
    _currentTimeController.text = DateFormat('hh:mm a').format(now);
    _currentMonthController.text = DateFormat('MMMM').format(now);

    // If editing, load existing values
    final currentVehicle = Provider.of<DriverController>(context, listen: false).currentVehicle;
    if (widget.isEditing && currentVehicle != null) {
      _driverIdStrController.text = currentVehicle.driverIdStr;
      _driverNameController.text = currentVehicle.driverName;
      _emailController.text = currentVehicle.email;
      _carNameController.text = currentVehicle.carName;
      _batteryCapacity = currentVehicle.batteryCapacity;
      _vehicleWeightController.text = currentVehicle.vehicleWeight.toString();
      _motorPowerController.text = currentVehicle.motorPower.toString();
      _torqueController.text = currentVehicle.torque.toString();
      _motorEfficiency = currentVehicle.motorEfficiency;
      _runningType = currentVehicle.runningType;
      _vehicleCondition = currentVehicle.vehicleCondition;
      _currentSpeedController.text = currentVehicle.currentSpeed.toString();
      _monthlyIncomeController.text = currentVehicle.monthlyIncome.toString();
      _currentDateController.text = currentVehicle.currentDate;
      _currentTimeController.text = currentVehicle.currentTime;
      _currentMonthController.text = currentVehicle.currentMonth;
      _locationController.text = currentVehicle.location ?? '';
      _isDriverIdUnique = true; // Since it matches their own ID
    }
  }

  @override
  void dispose() {
    _driverIdStrController.dispose();
    _driverNameController.dispose();
    _emailController.dispose();
    _carNameController.dispose();
    _vehicleWeightController.dispose();
    _motorPowerController.dispose();
    _torqueController.dispose();
    _currentSpeedController.dispose();
    _monthlyIncomeController.dispose();
    _locationController.dispose();
    _currentDateController.dispose();
    _currentTimeController.dispose();
    _currentMonthController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onDriverIdChanged(String val) {
    if (val.trim().isEmpty) {
      setState(() {
        _isDriverIdUnique = null;
        _isCheckingDriverId = false;
      });
      return;
    }
    
    setState(() {
      _isCheckingDriverId = true;
      _isDriverIdUnique = null;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final driverController = Provider.of<DriverController>(context, listen: false);
      final isUnique = await driverController.checkDriverIdUnique(val.trim());
      if (mounted) {
        setState(() {
          _isDriverIdUnique = isUnique;
          _isCheckingDriverId = false;
        });
      }
    });
  }

  Future<void> _saveOnboardingData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isDriverIdUnique == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unique Driver ID.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final driverController = Provider.of<DriverController>(context, listen: false);

    final newVehicle = VehicleModel(
      driverId: authController.currentUser!.id,
      driverIdStr: _driverIdStrController.text.trim(),
      driverName: _driverNameController.text.trim(),
      email: _emailController.text.trim(),
      carName: _carNameController.text.trim(),
      batteryCapacity: _batteryCapacity,
      vehicleWeight: double.parse(_vehicleWeightController.text.trim()),
      motorPower: double.parse(_motorPowerController.text.trim()),
      torque: double.parse(_torqueController.text.trim()),
      motorEfficiency: _motorEfficiency,
      runningType: _runningType,
      vehicleCondition: _vehicleCondition,
      currentSpeed: double.parse(_currentSpeedController.text.trim()),
      monthlyIncome: double.parse(_monthlyIncomeController.text.trim()),
      currentDate: _currentDateController.text.trim(),
      currentTime: _currentTimeController.text.trim(),
      currentMonth: _currentMonthController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    );

    final success = await driverController.saveVehicle(newVehicle);
    if (success && mounted) {
      if (widget.isEditing) {
        Navigator.pop(context); // Go back if we are editing
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate first step inputs
      if (_driverIdStrController.text.trim().isEmpty ||
          _driverNameController.text.trim().isEmpty ||
          _carNameController.text.trim().isEmpty ||
          _monthlyIncomeController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required profile fields.'), backgroundColor: Colors.redAccent),
        );
        return;
      }
      if (_isDriverIdUnique != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver ID is not validated or already taken.'), backgroundColor: Colors.redAccent),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate physical specs
      if (_vehicleWeightController.text.trim().isEmpty ||
          _motorPowerController.text.trim().isEmpty ||
          _torqueController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all motor specifications.'), backgroundColor: Colors.redAccent),
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverController = Provider.of<DriverController>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.12),
                    blurRadius: 100,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: GlassCard(
                  blur: 20,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isEditing ? 'EDIT VEHICLE DETAILS' : 'VEHICLE ONBOARDING',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.isEditing
                                      ? 'Modify parameters below and re-predict'
                                      : 'Complete onboarding to access Driver Dashboard',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            if (widget.isEditing)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Error indicator
                        if (driverController.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              driverController.errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Custom Step indicator
                        _buildStepIndicator(),
                        const SizedBox(height: 32),

                        // Form Steps
                        if (_currentStep == 0) _buildProfileStep(),
                        if (_currentStep == 1) _buildSpecsStep(),
                        if (_currentStep == 2) _buildOperatingStep(),

                        const SizedBox(height: 36),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentStep > 0)
                              OutlinedButton(
                                onPressed: _prevStep,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.glassBorderColor),
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('BACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            else
                              const SizedBox.shrink(),
                            
                            GlassButton(
                              text: _currentStep < 2
                                  ? 'CONTINUE'
                                  : (widget.isEditing ? 'SAVE CHANGES' : 'COMPLETE ONBOARDING'),
                              isLoading: driverController.isLoading,
                              onPressed: _currentStep < 2 ? _nextStep : _saveOnboardingData,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Profile', 'Vehicle Specs', 'Operating State'];
    return Row(
      children: List.generate(steps.length, (idx) {
        final isActive = idx == _currentStep;
        final isCompleted = idx < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.primaryBlue
                      : isCompleted
                          ? AppTheme.primaryBlue.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isActive ? AppTheme.primaryBlue : AppTheme.glassBorderColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: AppTheme.primaryBlue)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  steps[idx],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (idx < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    width: 30,
                    height: 1,
                    color: isCompleted ? AppTheme.primaryBlue : AppTheme.glassBorderColor,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Driver ID str validator
        GlassTextField(
          controller: _driverIdStrController,
          labelText: 'Driver ID (Unique identifier)*',
          hintText: 'e.g. DRV-ELON-88',
          prefixIcon: Icons.badge_outlined,
          onChanged: _onDriverIdChanged,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Driver ID is required';
            if (_isDriverIdUnique == false) return 'This Driver ID is already taken';
            return null;
          },
          suffixIcon: Container(
            width: 40,
            alignment: Alignment.center,
            child: _isCheckingDriverId
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue)),
                  )
                : _isDriverIdUnique == true
                    ? const Icon(Icons.check_circle_outline, color: Colors.greenAccent)
                    : _isDriverIdUnique == false
                        ? const Icon(Icons.cancel_outlined, color: Colors.redAccent)
                        : null,
          ),
        ),
        const SizedBox(height: 18),
        
        GlassTextField(
          controller: _driverNameController,
          labelText: 'Full Name*',
          hintText: 'e.g. John Doe',
          prefixIcon: Icons.person_outline,
          validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 18),
        
        GlassTextField(
          controller: _emailController,
          labelText: 'Email Address',
          prefixIcon: Icons.email_outlined,
          validator: (val) => val == null || val.trim().isEmpty ? 'Email is required' : null,
        ),
        const SizedBox(height: 18),

        GlassTextField(
          controller: _carNameController,
          labelText: 'Vehicle Car Name*',
          hintText: 'e.g. Tesla Model 3',
          prefixIcon: Icons.directions_car_outlined,
          validator: (val) => val == null || val.trim().isEmpty ? 'Car name is required' : null,
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: _monthlyIncomeController,
                labelText: 'Monthly Income (\$)*',
                hintText: 'e.g. 5000',
                prefixIcon: Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Income is required';
                  if (double.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassTextField(
                controller: _locationController,
                labelText: 'Location (Optional)',
                hintText: 'e.g. Austin, TX',
                prefixIcon: Icons.location_on_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Battery Capacity slider
        Text(
          'Battery Capacity: ${_batteryCapacity.toStringAsFixed(0)} kWh',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Slider(
          value: _batteryCapacity,
          min: 10,
          max: 100,
          divisions: 90,
          label: '${_batteryCapacity.toStringAsFixed(0)} kWh',
          activeColor: AppTheme.primaryBlue,
          inactiveColor: AppTheme.glassBorderColor,
          onChanged: (val) {
            setState(() {
              _batteryCapacity = val;
            });
          },
        ),
        const SizedBox(height: 18),

        GlassTextField(
          controller: _vehicleWeightController,
          labelText: 'Vehicle Weight (kg)*',
          hintText: 'e.g. 1850',
          prefixIcon: Icons.monitor_weight_outlined,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Weight is required';
            if (double.tryParse(val) == null) return 'Enter a valid weight';
            return null;
          },
        ),
        const SizedBox(height: 24),

        const Text(
          'Motor Specifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5),
        ),
        const Divider(color: AppTheme.glassBorderColor),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: _motorPowerController,
                labelText: 'Motor Power (kW)*',
                hintText: 'e.g. 250',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Error';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassTextField(
                controller: _torqueController,
                labelText: 'Torque (Nm)*',
                hintText: 'e.g. 450',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (double.tryParse(val) == null) return 'Error';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          'Motor Efficiency: ${_motorEfficiency.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Slider(
          value: _motorEfficiency,
          min: 50,
          max: 100,
          divisions: 50,
          label: '${_motorEfficiency.toStringAsFixed(0)}%',
          activeColor: AppTheme.primaryBlue,
          inactiveColor: AppTheme.glassBorderColor,
          onChanged: (val) {
            setState(() {
              _motorEfficiency = val;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOperatingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Running Type Selector
        const Text('Running Operating Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectCard(
                title: 'City Cruise',
                description: 'Lower drag speed, higher regenerative braking',
                icon: Icons.location_city_rounded,
                isSelected: _runningType == 0,
                onTap: () => setState(() => _runningType = 0),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelectCard(
                title: 'Highway Cruise',
                description: 'High aerodynamic resistance drag, constant speed loads',
                icon: Icons.route_rounded,
                isSelected: _runningType == 1,
                onTap: () => setState(() => _runningType = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Vehicle Condition Selector
        const Text('Current Vehicle Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSelectCard(
                title: 'Working Normal',
                description: 'Road active, fully operational',
                icon: Icons.check_circle_outline_rounded,
                isSelected: _vehicleCondition == 1,
                onTap: () => setState(() => _vehicleCondition = 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelectCard(
                title: 'Garage Mode',
                description: 'Under maintenance or offline storage status',
                icon: Icons.build_circle_outlined,
                isSelected: _vehicleCondition == 0,
                onTap: () => setState(() => _vehicleCondition = 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        GlassTextField(
          controller: _currentSpeedController,
          labelText: 'Current Operational Speed (km/h)*',
          hintText: 'e.g. 80',
          prefixIcon: Icons.speed_outlined,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Speed is required';
            if (double.tryParse(val) == null) return 'Enter a valid speed';
            return null;
          },
        ),
        const SizedBox(height: 24),

        const Text(
          'Temporal Parameters (Auto-populated)',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5),
        ),
        const Divider(color: AppTheme.glassBorderColor),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: _currentDateController,
                labelText: 'Current Date',
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassTextField(
                controller: _currentTimeController,
                labelText: 'Current Time',
                prefixIcon: Icons.access_time_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GlassTextField(
                controller: _currentMonthController,
                labelText: 'Month',
                prefixIcon: Icons.calendar_month_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.glassBorderColor,
            width: isSelected ? 1.5 : 0.8,
          ),
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary.withOpacity(0.8),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
