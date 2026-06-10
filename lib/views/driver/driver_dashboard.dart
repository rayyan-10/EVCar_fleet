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

class _DriverDashboardState extends State<DriverDashboard> with SingleTickerProviderStateMixin {
  bool _isPredicting = false;
  String _predictionStatusText = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Fetch predictions history on startup
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

  // AI Prediction loading sequences
  Future<void> _triggerPrediction() async {
    final driverCtrl = Provider.of<DriverController>(context, listen: false);
    final predCtrl = Provider.of<PredictionController>(context, listen: false);
    
    if (driverCtrl.currentVehicle == null) return;
    
    setState(() {
      _isPredicting = true;
      _predictionStatusText = 'Establishing telemetry link...';
    });
    _animationController.repeat();

    // Sequence of loader phrases for maximum wow factor
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _predictionStatusText = 'Evaluating aerodynamic drag coefficients...');
    
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _predictionStatusText = 'Analyzing battery thermal pack temperatures...');
    
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _predictionStatusText = 'Running AI physical regression range models...');

    // Run prediction
    final success = await predCtrl.runPrediction(
      driverCtrl.currentVehicle!,
      100.0, // Default start at 100% capacity range calculation
    );

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _isPredicting = false;
      _animationController.stop();
    });

    if (success) {
      Navigator.pushNamed(context, AppRoutes.predictionResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(predCtrl.errorMessage ?? 'Prediction failed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
    buffer.writeln('Driver ID: ${vehicle.driverIdStr}');
    buffer.writeln('Car Model: ${vehicle.carName}');
    buffer.writeln('Email Address: ${vehicle.email}');
    buffer.writeln('Report Date: ${DateTime.now().toLocal()}');
    buffer.writeln('\n================ VEHICLE PARAMETERS ================');
    buffer.writeln('Battery Size: ${vehicle.batteryCapacity} kWh');
    buffer.writeln('Curb Weight: ${vehicle.vehicleWeight} kg');
    buffer.writeln('Motor Peak Power: ${vehicle.motorPower} kW');
    buffer.writeln('Max Torque: ${vehicle.torque} Nm');
    buffer.writeln('Motor Efficiency: ${vehicle.motorEfficiency}%');
    buffer.writeln('Operating Cycle: ${vehicle.runningType == 1 ? "Highway (High Drag)" : "City (Regenerative)"}');
    buffer.writeln('Speed Limit: ${vehicle.currentSpeed} km/h');
    buffer.writeln('Condition Status: ${vehicle.vehicleCondition == 1 ? "Working/Active" : "Garage/Service"}');

    if (latestPred != null) {
      buffer.writeln('\n================ LATEST AI PREDICTION ================');
      buffer.writeln('Estimated Remaining Range: ${latestPred.estimatedRange.toStringAsFixed(1)} KM');
      buffer.writeln('Battery Health Rating: ${latestPred.batteryHealthScore.toStringAsFixed(1)}%');
      buffer.writeln('Driving Efficiency Rating: ${latestPred.efficiencyScore.toStringAsFixed(1)}%');
      buffer.writeln('Energy Draw Rate: ${latestPred.predictedEnergyConsumption.toStringAsFixed(1)} Wh/km');
      buffer.writeln('Estimated Driving Cost: \$${latestPred.costPerKm.toStringAsFixed(4)}/KM');
      buffer.writeln('Risk Assessment Category: ${latestPred.riskLevel}');
      buffer.writeln('Recommended Safe Speed: ${latestPred.recommendedSpeed.toStringAsFixed(0)} km/h');
      buffer.writeln('Recommended Driving Profile: ${latestPred.recommendedDrivingMode}');
    }

    final bytes = utf8.encode(buffer.toString());
    web_helper.downloadFile(bytes, 'driver_vehicle_report_${vehicle.driverIdStr}.txt');
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    blurRadius: 150,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Row(
              children: [
                // Custom Sidebar for desktop
                if (isDesktop) _buildSidebar(context),
                
                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Navigation bar for Mobile
                        if (!isDesktop) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.driverName.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    vehicle.carName,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                onPressed: _logout,
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Greeting header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TELEMETRY DASHBOARD',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        fontSize: isDesktop ? 26 : 22,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      vehicle.location ?? 'Global Network Node',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isDesktop)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on, color: AppTheme.primaryBlue, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      vehicle.driverIdStr,
                                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // Top metrics row
                        GridView.count(
                          crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 2.1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildKPIValueCard(
                              title: 'BATTERY CAPACITY',
                              value: '${vehicle.batteryCapacity.toStringAsFixed(0)} kWh',
                              subText: 'Physical energy reservoir',
                              icon: Icons.battery_charging_full_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                            _buildKPIValueCard(
                              title: 'OPERATING SPEED',
                              value: '${vehicle.currentSpeed.toStringAsFixed(0)} km/h',
                              subText: 'Average cruise velocities',
                              icon: Icons.speed_rounded,
                              color: Colors.white,
                            ),
                            _buildKPIValueCard(
                              title: 'VEHICLE CONDITION',
                              value: vehicle.vehicleCondition == 1 ? 'WORKING' : 'GARAGE',
                              subText: vehicle.vehicleCondition == 1 ? 'Fleet active & ready' : 'Maintenance offline',
                              icon: vehicle.vehicleCondition == 1 ? Icons.check_circle_outline : Icons.build_circle_outlined,
                              color: vehicle.vehicleCondition == 1 ? Colors.greenAccent : Colors.orangeAccent,
                            ),
                            _buildKPIValueCard(
                              title: 'DRIVE TYPE CYCLE',
                              value: vehicle.runningType == 1 ? 'HIGHWAY' : 'CITY',
                              subText: vehicle.runningType == 1 ? 'Aerodynamic load cycle' : 'Regen recapture cycle',
                              icon: vehicle.runningType == 1 ? Icons.route_rounded : Icons.location_city_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Section header
                        const Text(
                          'QUICK COMMANDS',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Quick actions cards
                        GridView.count(
                          crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildQuickActionCard(
                              title: 'Update Vehicle Data',
                              description: 'Modify weight, efficiency, motor, speed, or current temporal variables.',
                              icon: Icons.edit_note_rounded,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OnboardingScreen(isEditing: true)),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              title: 'Predict Range',
                              description: 'Trigger the physics simulation engine to output 20 range metrics.',
                              icon: Icons.psychology_rounded,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.predictInput),
                              highlight: true,
                            ),
                            _buildQuickActionCard(
                              title: 'View History',
                              description: 'Browse logs of predictions and track health parameters over time.',
                              icon: Icons.history_rounded,
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.driverHistory);
                              },
                            ),
                            _buildQuickActionCard(
                              title: 'Download Report',
                              description: 'Export a copy of current telemetry parameters and range logs.',
                              icon: Icons.file_download_outlined,
                              onTap: _downloadDriverReport,
                            ),
                            _buildQuickActionCard(
                              title: 'My Analytics',
                              description: 'View trip charts, safety score, income trends and battery health.',
                              icon: Icons.bar_chart_rounded,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const DriverAnalyticsScreen())),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isPredicting) _buildPredictionOverlay(),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final vehicle = Provider.of<DriverController>(context).currentVehicle!;
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D18),
        border: Border(right: BorderSide(color: AppTheme.glassBorderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(width: 8),
              const Text(
                'DAP DRIVER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Vehicle Card Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorderColor, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.driverName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.email,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.glassBorderColor),
                const SizedBox(height: 8),
                Text(
                  vehicle.carName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // Logout button
          ListTile(
            onTap: _logout,
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            title: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIValueCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return MouseRegion(
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          opacity: highlight ? 0.12 : 0.06,
          borderColor: highlight ? AppTheme.primaryBlue.withOpacity(0.5) : AppTheme.glassBorderColor.withOpacity(0.5),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: highlight ? AppTheme.primaryBlue : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing circular loader
            RotationTransition(
              turns: _animationController,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.transparent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 24,
                    )
                  ],
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              _predictionStatusText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Running advanced physical simulations on server',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
