import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import '../../controllers/driver_controller.dart';
import '../../controllers/prediction_controller.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/web_helper_non_web.dart'
    if (dart.library.html) '../widgets/web_helper_web.dart' as web_helper;
import 'onboarding_screen.dart';
import 'driver_analytics_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  bool _isPredicting = false;
  String _predictionStatusText = '';
  late AnimationController _animationController;
  int _selectedNav = 0; // 0=Dashboard, 1=Analytics, 2=History

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<PredictionController>(context, listen: false)
            .fetchPredictionHistory(auth.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _triggerPrediction() async {
    final driverCtrl = Provider.of<DriverController>(context, listen: false);
    final predCtrl = Provider.of<PredictionController>(context, listen: false);
    if (driverCtrl.currentVehicle == null) return;

    setState(() {
      _isPredicting = true;
      _predictionStatusText = 'Establishing telemetry link...';
    });
    _animationController.repeat();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _predictionStatusText = 'Evaluating aerodynamic drag coefficients...');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _predictionStatusText = 'Analyzing battery thermal pack temperatures...');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _predictionStatusText = 'Running AI physical regression range models...');

    final success = await predCtrl.runPrediction(driverCtrl.currentVehicle!, 100.0);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _isPredicting = false;
      _animationController.stop();
    });

    if (success) {
      Navigator.pushNamed(context, AppRoutes.predictionResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(predCtrl.errorMessage ?? 'Prediction failed.'),
        backgroundColor: AppTheme.criticalRed,
      ));
    }
  }

  void _downloadDriverReport() {
    final vehicle = Provider.of<DriverController>(context, listen: false).currentVehicle;
    final predCtrl = Provider.of<PredictionController>(context, listen: false);
    if (vehicle == null) return;
    final latestPred = predCtrl.history.isNotEmpty ? predCtrl.history.first : null;
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('          DRIVE ANALYSIS VEHICLE REPORT             ');
    buffer.writeln('====================================================');
    buffer.writeln('Driver Name: ${vehicle.driverName}');
    buffer.writeln('Car Model: ${vehicle.carName}');
    buffer.writeln('Report Date: ${DateTime.now().toLocal()}');
    if (latestPred != null) {
      buffer.writeln('\n================ LATEST AI PREDICTION ================');
      buffer.writeln('Estimated Range: ${latestPred.estimatedRange.toStringAsFixed(1)} KM');
      buffer.writeln('Battery Health: ${latestPred.batteryHealthScore.toStringAsFixed(1)}%');
      buffer.writeln('Efficiency Score: ${latestPred.efficiencyScore.toStringAsFixed(1)}%');
    }
    final bytes = utf8.encode(buffer.toString());
    web_helper.downloadFile(bytes, 'driver_vehicle_report_${vehicle.driverIdStr}.txt');
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.roleSelection, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverCtrl = Provider.of<DriverController>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final vehicle = driverCtrl.currentVehicle;

    if (vehicle == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1.0, -1.0),
                  radius: 1.5,
                  colors: [Color(0xFF051525), AppTheme.backgroundColor],
                ),
              ),
            ),
          ),
          Positioned(
            top: -200, left: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowBlue(intensity: 0.06, blur: 200),
              ),
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                if (isDesktop) _buildSidebar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mobile top bar
                        if (!isDesktop) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.bolt_rounded,
                                    color: AppTheme.primaryBlue, size: 22),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vehicle.driverName.toUpperCase(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(vehicle.carName,
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                              ]),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded,
                                    color: AppTheme.criticalRed),
                                onPressed: _logout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── HERO BANNER ─────────────────────────────────────
                        _buildHeroBanner(context, vehicle, isDesktop),
                        const SizedBox(height: 28),

                        // ── KPI GRID ────────────────────────────────────────
                        GridView.count(
                          crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.0,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            AnimatedStatCard(
                              title: 'BATTERY CAPACITY',
                              value: '${vehicle.batteryCapacity.toStringAsFixed(0)} kWh',
                              subText: 'Physical energy reservoir',
                              icon: Icons.battery_charging_full_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                            AnimatedStatCard(
                              title: 'OPERATING SPEED',
                              value: '${vehicle.currentSpeed.toStringAsFixed(0)} km/h',
                              subText: 'Average cruise velocity',
                              icon: Icons.speed_rounded,
                              color: AppTheme.accentPurple,
                            ),
                            AnimatedStatCard(
                              title: 'VEHICLE CONDITION',
                              value: vehicle.vehicleCondition == 1 ? 'ACTIVE' : 'GARAGE',
                              subText: vehicle.vehicleCondition == 1
                                  ? 'Fleet ready & operational'
                                  : 'Maintenance offline',
                              icon: vehicle.vehicleCondition == 1
                                  ? Icons.check_circle_outline
                                  : Icons.build_circle_outlined,
                              color: vehicle.vehicleCondition == 1
                                  ? AppTheme.neonGreen
                                  : AppTheme.amberAlert,
                            ),
                            AnimatedStatCard(
                              title: 'DRIVE CYCLE',
                              value: vehicle.runningType == 1 ? 'HIGHWAY' : 'CITY',
                              subText: vehicle.runningType == 1
                                  ? 'Aerodynamic load cycle'
                                  : 'Regen recapture cycle',
                              icon: vehicle.runningType == 1
                                  ? Icons.route_rounded
                                  : Icons.location_city_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Icon(Icons.grid_view_rounded,
                                color: AppTheme.textSecondary, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'QUICK COMMANDS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── QUICK ACTIONS GRID ────────────────────────────
                        GridView.count(
                          crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            HoverActionCard(
                              title: 'Update Vehicle Data',
                              description:
                                  'Modify weight, efficiency, motor, speed, or temporal variables.',
                              icon: Icons.edit_note_rounded,
                              accentColor: AppTheme.accentPurple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        OnboardingScreen(isEditing: true)),
                              ),
                            ),
                            HoverActionCard(
                              title: 'Predict Range',
                              description:
                                  'Trigger the physics simulation engine to output 20 range metrics.',
                              icon: Icons.psychology_rounded,
                              highlight: true,
                              accentColor: AppTheme.primaryBlue,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.predictInput),
                            ),
                            HoverActionCard(
                              title: 'View History',
                              description:
                                  'Browse logs of predictions and track health parameters.',
                              icon: Icons.history_rounded,
                              accentColor: AppTheme.neonGreen,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.driverHistory),
                            ),
                            HoverActionCard(
                              title: 'Download Report',
                              description:
                                  'Export current telemetry parameters and range logs.',
                              icon: Icons.file_download_outlined,
                              accentColor: AppTheme.amberAlert,
                              onTap: _downloadDriverReport,
                            ),
                            HoverActionCard(
                              title: 'My Analytics',
                              description:
                                  'Trip charts, safety score, income trends and battery health.',
                              icon: Icons.bar_chart_rounded,
                              accentColor: AppTheme.accentPurple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DriverAnalyticsScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isPredicting) _buildPredictionOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, vehicle, bool isDesktop) {
    return NeonGlassCard(
      accentColor: AppTheme.primaryBlue,
      padding: EdgeInsets.all(isDesktop ? 28 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NeonBadge(
                      label: 'TELEMETRY DASHBOARD',
                      color: AppTheme.primaryBlue,
                      icon: Icons.bolt_rounded,
                    ),
                    const SizedBox(width: 10),
                    const PulsingDot(color: AppTheme.neonGreen, size: 8),
                    const SizedBox(width: 6),
                    const Text('LIVE',
                        style: TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 14),
                GradientText(
                  text: vehicle.driverName,
                  gradient: AppTheme.primaryGradient,
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.directions_car_outlined,
                        color: AppTheme.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Text(vehicle.carName,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(width: 14),
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(vehicle.location ?? 'Global Network Node',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 20),
            // EV Status Ring
            _EVStatusRing(batteryKwh: vehicle.batteryCapacity),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final vehicle =
        Provider.of<DriverController>(context).currentVehicle!;
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080818), Color(0xFF0A0A16)],
        ),
        border:
            Border(right: BorderSide(color: AppTheme.glassBorderColor, width: 0.8)),
      ),
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppTheme.glassBorderColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.glowBlue(intensity: 0.3, blur: 16),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('DAP DRIVER',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.0)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Nav items
          _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined),
          _buildNavItem(1, 'My Analytics', Icons.bar_chart_rounded),
          _buildNavItem(2, 'History', Icons.history_rounded),

          const SizedBox(height: 20),

          // Vehicle info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NeonGlassCard(
              accentColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.glowBlue(intensity: 0.25, blur: 10),
                        ),
                        child: Center(
                          child: Text(
                            vehicle.driverName.isNotEmpty
                                ? vehicle.driverName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.driverName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                            Text(vehicle.email,
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppTheme.glassBorderColor, height: 20),
                  GradientText(
                    text: vehicle.carName,
                    gradient: AppTheme.primaryGradient,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  NeonBadge(
                    label: vehicle.driverIdStr,
                    color: AppTheme.textSecondary,
                    icon: Icons.badge_outlined,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassButton(
              text: 'LOGOUT',
              color: AppTheme.criticalRed,
              color2: const Color(0xFFFF6B00),
              icon: Icons.logout_rounded,
              onPressed: _logout,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedNav == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () {
          setState(() => _selectedNav = index);
          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DriverAnalyticsScreen()));
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.driverHistory);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                    width: 0.8)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  color:
                      isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  size: 18),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _animationController,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowBlue(intensity: 0.5, blur: 32),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 32),
            NeonBadge(
              label: 'ML ENGINE ACTIVE',
              color: AppTheme.primaryBlue,
              icon: Icons.memory_rounded,
            ),
            const SizedBox(height: 20),
            Text(
              _predictionStatusText,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text('Running advanced physical simulations on server',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── EV Status Ring ───────────────────────────────────────────────────────────
class _EVStatusRing extends StatefulWidget {
  final double batteryKwh;
  const _EVStatusRing({required this.batteryKwh});

  @override
  State<_EVStatusRing> createState() => _EVStatusRingState();
}

class _EVStatusRingState extends State<_EVStatusRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Normalize battery: typical max 100 kWh
    final pct = (widget.batteryKwh / 100.0).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 110,
        height: 110,
        child: CustomPaint(
          painter: _RingPainter(value: pct * _anim.value),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.batteryKwh.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.0),
                ),
                const Text('kWh',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeW) / 2;
    const startAngle = -3.14159 / 2;
    const fullSweep = 2 * 3.14159;

    // Background ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, fullSweep, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Active ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, fullSweep * value, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.neonGreen],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
