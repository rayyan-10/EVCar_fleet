import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/driver_controller.dart';
import '../../controllers/prediction_controller.dart';
import '../../data/vehicle_catalog.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../widgets/glass_widgets.dart';

class PredictInputScreen extends StatefulWidget {
  const PredictInputScreen({Key? key}) : super(key: key);

  @override
  State<PredictInputScreen> createState() => _PredictInputScreenState();
}

class _PredictInputScreenState extends State<PredictInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _odometerCtrl      = TextEditingController();
  final _batteryCtrl       = TextEditingController();
  final _energyCtrl        = TextEditingController();
  final _batteryHealthCtrl = TextEditingController();
  final _speedCtrl         = TextEditingController();

  CatalogVehicle? _selectedVehicle;
  int _runningType = 0; // 0=City, 1=Highway

  bool _isPredicting = false;
  String _statusText = '';
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  static const List<String> _loadingPhrases = [
    'Establishing telemetry link...',
    'Loading neural weight matrices...',
    'Evaluating aerodynamic drag coefficients...',
    'Analysing battery thermal pack temperatures...',
    'Running physics regression on odometer data...',
    'Computing city/highway energy consumption curves...',
    'Applying motor efficiency correction factors...',
    'Calibrating speed-range degradation model...',
    'Generating AI range prediction result...',
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _spinAnim = CurvedAnimation(parent: _spinCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _odometerCtrl.dispose();
    _batteryCtrl.dispose();
    _energyCtrl.dispose();
    _batteryHealthCtrl.dispose();
    _speedCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  void _showVehiclePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VehiclePickerSheet(
        selected: _selectedVehicle,
        onSelect: (v) {
          setState(() => _selectedVehicle = v);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _runPrediction() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a vehicle model first.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final driverCtrl = Provider.of<DriverController>(context, listen: false);
    final predCtrl   = Provider.of<PredictionController>(context, listen: false);
    final vehicle    = driverCtrl.currentVehicle;
    if (vehicle == null) return;

    final battery       = double.parse(_batteryCtrl.text.trim());
    final odometer      = double.parse(_odometerCtrl.text.trim());
    final energyUsed    = double.parse(_energyCtrl.text.trim());
    final batteryHealth = double.parse(_batteryHealthCtrl.text.trim());
    final speedKmph     = double.parse(_speedCtrl.text.trim());

    // Patch vehicle with catalog specs + user drive mode
    final patchedVehicle = vehicle.copyWith(
      carName:         _selectedVehicle!.displayName,
      batteryCapacity: _selectedVehicle!.batteryCapacityKwh,
      runningType:     _runningType,
    );

    setState(() {
      _isPredicting = true;
      _statusText   = _loadingPhrases[0];
    });

    for (int i = 1; i < _loadingPhrases.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _statusText = _loadingPhrases[i]);
    }

    final success = await predCtrl.runPrediction(
      patchedVehicle,
      battery,
      odometerKm:        odometer,
      runningMode:       _runningType.toDouble(),
      energyConsumedKwh: energyUsed,
      maxRangeKm:        _selectedVehicle!.maxRangeKm,
      batteryHealthPct:  batteryHealth,
      speedKmph:         speedKmph,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() => _isPredicting = false);

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.predictionResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(predCtrl.errorMessage ?? 'Prediction failed. Please try again.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size      = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Stack(children: [
        Positioned(
          top: -120, right: -120,
          child: Container(width: 400, height: 400,
            decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.07),
                blurRadius: 160, spreadRadius: 60)])),
        ),
        Positioned(
          bottom: -80, left: -80,
          child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.05),
                blurRadius: 120, spreadRadius: 40)])),
        ),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? size.width * 0.18 : 20,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                                color: AppTheme.glassBorderColor
                                    .withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GradientText(
                                text: 'PREDICT RANGE',
                                gradient: AppTheme.primaryGradient,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                    letterSpacing: 1.2),
                              ),
                              const Text(
                                  'Select your vehicle and enter trip data',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ]),
                      ),
                      NeonBadge(
                        label: 'AI ENGINE',
                        color: AppTheme.accentPurple,
                        icon: Icons.psychology_rounded,
                      ),
                    ]),
                    const SizedBox(height: 28),


                    // Vehicle selector
                    NeonBadge(
                      label: 'SELECT VEHICLE MODEL',
                      color: AppTheme.textSecondary,
                      icon: Icons.directions_car_outlined,
                    ),
                    const SizedBox(height: 10),

                    _VehicleSelectorTile(
                      selected: _selectedVehicle,
                      onTap: _showVehiclePicker,
                    ),
                    const SizedBox(height: 24),

                    // Input card
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('CURRENT BATTERY  (%)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _batteryCtrl,
                            hint: 'e.g.  80',
                            icon: Icons.battery_charging_full_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < 1 || d > 100)
                                return 'Enter a value between 1 and 100';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _label('BATTERY HEALTH  (%)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _batteryHealthCtrl,
                            hint: 'e.g.  91.5',
                            icon: Icons.health_and_safety_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < 1 || d > 100)
                                return 'Enter a value between 1 and 100';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _label('ODOMETER READING  (km)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _odometerCtrl,
                            hint: 'e.g.  12000',
                            icon: Icons.speed_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null || double.parse(v) < 0)
                                return 'Enter a valid odometer value';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _label('ENERGY CONSUMED  (kWh)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _energyCtrl,
                            hint: 'e.g.  7.8',
                            icon: Icons.bolt_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < 0) return 'Enter a valid energy value';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _label('DRIVE MODE'),
                          const SizedBox(height: 10),
                          _DriveModeToggle(
                            value: _runningType,
                            onChanged: (v) => setState(() => _runningType = v),
                          ),
                          const SizedBox(height: 20),

                          _label('CURRENT SPEED  (km/h)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _speedCtrl,
                            hint: 'e.g.  85',
                            icon: Icons.speed_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < 0 || d > 300)
                                return 'Enter a speed between 0 and 300 km/h';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _PredictButton(onTap: _runPrediction),
                    const SizedBox(height: 52),

                  ],
                ),
              ),
            ),
          ),
        ),

        if (_isPredicting) _LoadingOverlay(statusText: _statusText, spinAnim: _spinAnim),
      ]),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(text,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0)),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }
}

// ── Vehicle selector tile ────────────────────────────────────────────────────
class _VehicleSelectorTile extends StatelessWidget {
  final CatalogVehicle? selected;
  final VoidCallback onTap;
  const _VehicleSelectorTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null
                ? AppTheme.primaryBlue.withOpacity(0.6)
                : AppTheme.glassBorderColor,
            width: selected != null ? 1.5 : 0.8,
          ),
        ),
        child: Row(children: [
          Icon(Icons.directions_car_rounded,
              color: selected != null ? AppTheme.primaryBlue : AppTheme.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: selected == null
                ? const Text('Tap to select a vehicle',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(selected!.displayName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${selected!.batteryCapacityKwh} kWh  ·  ${selected!.maxRangeKm.toInt()} km range',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ]),
          ),
          Icon(Icons.expand_more_rounded,
              color: AppTheme.textSecondary, size: 20),
        ]),
      ),
    );
  }
}

// ── Vehicle picker bottom sheet ──────────────────────────────────────────────
class _VehiclePickerSheet extends StatelessWidget {
  final CatalogVehicle? selected;
  final ValueChanged<CatalogVehicle> onSelect;
  const _VehiclePickerSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Group by brand
    final brands = VehicleCatalog.vehicles.map((v) => v.brand).toSet().toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.glassBorderColor),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('SELECT VEHICLE MODEL',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                  fontSize: 14, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: brands.map((brand) {
                final list = VehicleCatalog.vehicles.where((v) => v.brand == brand).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(brand.toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10, fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ),
                    ...list.map((v) => _VehicleTile(
                          vehicle: v,
                          isSelected: selected?.vehicleId == v.vehicleId,
                          onTap: () => onSelect(v),
                        )),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final CatalogVehicle vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  const _VehicleTile({required this.vehicle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.glassBorderColor,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vehicle.carName,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                '${vehicle.batteryCapacityKwh} kWh  ·  ${vehicle.maxRangeKm.toInt()} km  ·  ${vehicle.motorPowerKw.toInt()} kW',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ]),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.primaryBlue, size: 20),
        ]),
      ),
    );
  }
}

// ── Drive mode toggle ────────────────────────────────────────────────────────
class _DriveModeToggle extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DriveModeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _chip(0, 'City', Icons.location_city_rounded, const Color(0xFF00E5A0))),
      const SizedBox(width: 12),
      Expanded(child: _chip(1, 'Highway', Icons.route_rounded, AppTheme.primaryBlue)),
    ]);
  }

  Widget _chip(int v, String label, IconData icon, Color color) {
    final active = value == v;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? color : AppTheme.glassBorderColor,
              width: active ? 1.5 : 0.8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? color : AppTheme.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
              color: active ? color : AppTheme.textSecondary,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
          if (active) ...[
            const SizedBox(width: 6),
            Icon(Icons.check_circle_rounded, color: color, size: 14),
          ],
        ]),
      ),
    );
  }
}

// ── Animated predict button ──────────────────────────────────────────────────
class _PredictButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PredictButton({required this.onTap});
  @override
  State<_PredictButton> createState() => _PredictButtonState();
}

class _PredictButtonState extends State<_PredictButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: _hovered
                  ? [AppTheme.primaryBlue, const Color(0xFF0052FF)]
                  : [AppTheme.primaryBlue.withOpacity(0.85), const Color(0xFF0052FF).withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(_hovered ? 0.5 : 0.25),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 6),
            )],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text('PREDICT RANGE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 16, letterSpacing: 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading overlay ──────────────────────────────────────────────────────────
class _LoadingOverlay extends StatelessWidget {
  final String statusText;
  final Animation<double> spinAnim;
  const _LoadingOverlay({required this.statusText, required this.spinAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          RotationTransition(
            turns: spinAnim,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 32, spreadRadius: 4)]),
              child: const CircularProgressIndicator(strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue)),
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 12, height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: AppTheme.primaryBlue,
              boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.8),
                  blurRadius: 16, spreadRadius: 2)])),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.memory_rounded, color: AppTheme.primaryBlue, size: 14),
              SizedBox(width: 6),
              Text('ML ENGINE  ACTIVE',
                  style: TextStyle(color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
            ]),
          ),
          const SizedBox(height: 20),
          Text(statusText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 15, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          const Text('Running advanced physical simulations',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}
