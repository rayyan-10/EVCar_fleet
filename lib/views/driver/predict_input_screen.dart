import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/driver_controller.dart';
import '../../controllers/prediction_controller.dart';
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

  // Controllers
  final _odometerCtrl    = TextEditingController();
  final _batteryCtrl     = TextEditingController();
  final _carNameCtrl     = TextEditingController();
  final _speedCtrl       = TextEditingController();

  // Drive mode selection
  int _runningType = 0; // 0=City, 1=Highway

  // Loading state
  bool _isPredicting = false;
  String _statusText = '';
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  // ML loading sequence
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

    // Pre-fill from saved vehicle data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final v = Provider.of<DriverController>(context, listen: false).currentVehicle;
      if (v != null) {
        _carNameCtrl.text = v.carName;
        _speedCtrl.text   = v.currentSpeed.toStringAsFixed(0);
        _runningType      = v.runningType;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _odometerCtrl.dispose();
    _batteryCtrl.dispose();
    _carNameCtrl.dispose();
    _speedCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    final driverCtrl = Provider.of<DriverController>(context, listen: false);
    final predCtrl   = Provider.of<PredictionController>(context, listen: false);
    final vehicle    = driverCtrl.currentVehicle;
    if (vehicle == null) return;

    final battery = double.parse(_batteryCtrl.text.trim());
    final speed   = double.parse(_speedCtrl.text.trim());
    final carName = _carNameCtrl.text.trim();

    // Build a patched vehicle with the user's overrides
    final patchedVehicle = vehicle.copyWith(
      carName:     carName,
      currentSpeed: speed,
      runningType: _runningType,
    );

    setState(() {
      _isPredicting = true;
      _statusText   = _loadingPhrases[0];
    });

    // Animate through loading phrases
    for (int i = 1; i < _loadingPhrases.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _statusText = _loadingPhrases[i]);
    }

    // Actually run the prediction
    final success = await predCtrl.runPrediction(patchedVehicle, battery);

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
        // Background ambient glow
        Positioned(
          top: -120, right: -120,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.07),
                blurRadius: 160, spreadRadius: 60,
              )],
            ),
          ),
        ),
        Positioned(
          bottom: -80, left: -80,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.05),
                blurRadius: 120, spreadRadius: 40,
              )],
            ),
          ),
        ),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? size.width * 0.2 : 20,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('PREDICT RANGE',
                            style: TextStyle(fontWeight: FontWeight.w900,
                                fontSize: 22, letterSpacing: 1.2, color: Colors.white)),
                        const Text('Enter your trip parameters below',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ]),
                    ]),
                    const SizedBox(height: 32),

                    // ── Input card ───────────────────────────
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Odometer
                          _label('ODOMETER READING  (km)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _odometerCtrl,
                            hint: 'e.g.  15 230',
                            icon: Icons.speed_outlined,
                            keyboard: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null || double.parse(v) < 0)
                                return 'Enter a valid odometer value';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Battery percentage
                          _label('CURRENT BATTERY  (%)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _batteryCtrl,
                            hint: 'e.g.  75',
                            icon: Icons.battery_charging_full_rounded,
                            keyboard: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < 1 || d > 100)
                                return 'Enter a value between 1 and 100';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Car name
                          _label('CAR NAME / MODEL'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _carNameCtrl,
                            hint: 'e.g.  Tesla Model 3',
                            icon: Icons.directions_car_rounded,
                            keyboard: TextInputType.text,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Drive mode toggle
                          _label('DRIVE MODE'),
                          const SizedBox(height: 10),
                          _DriveModeToggle(
                            value: _runningType,
                            onChanged: (v) => setState(() => _runningType = v),
                          ),
                          const SizedBox(height: 20),

                          // Speed
                          _label('TRAVEL SPEED  (km/h)'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _speedCtrl,
                            hint: 'e.g.  85',
                            icon: Icons.flash_on_rounded,
                            keyboard: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final d = double.tryParse(v);
                              if (d == null || d < 1 || d > 300)
                                return 'Enter a speed between 1 and 300 km/h';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Predict button ───────────────────────
                    _PredictButton(onTap: _runPrediction),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Loading overlay ──────────────────────
        if (_isPredicting) _LoadingOverlay(statusText: _statusText, spinAnim: _spinAnim),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: AppTheme.textSecondary,
          fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboard,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
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
      Expanded(child: _chip(0, 'City', Icons.location_city_rounded,  const Color(0xFF00E5A0))),
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
            width: active ? 1.5 : 0.8,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? color : AppTheme.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            color: active ? color : AppTheme.textSecondary,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          )),
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
          // Pulsing glow ring
          RotationTransition(
            turns: spinAnim,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 32, spreadRadius: 4,
                )],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Inner glow dot
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue,
              boxShadow: [BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.8),
                blurRadius: 16, spreadRadius: 2,
              )],
            ),
          ),
          const SizedBox(height: 36),

          // ML badge
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
