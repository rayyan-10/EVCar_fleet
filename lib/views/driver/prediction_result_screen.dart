import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../controllers/prediction_controller.dart';
import '../../controllers/driver_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/web_helper_non_web.dart'
    if (dart.library.html) '../widgets/web_helper_web.dart' as web_helper;

class PredictionResultScreen extends StatefulWidget {
  const PredictionResultScreen({Key? key}) : super(key: key);

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _kmCtrl;
  late Animation<double> _kmAnim;

  @override
  void initState() {
    super.initState();
    _kmCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _kmAnim = CurvedAnimation(parent: _kmCtrl, curve: Curves.easeOutCubic);
    _kmCtrl.forward();
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    super.dispose();
  }

  void _downloadReport(BuildContext context) {
    final pred =
        Provider.of<PredictionController>(context, listen: false).activePrediction;
    final vehicle =
        Provider.of<DriverController>(context, listen: false).currentVehicle;
    if (pred == null || vehicle == null) return;

    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('          DRIVE ANALYSIS PREDICTION REPORT          ');
    buffer.writeln('====================================================');
    buffer.writeln('Report Reference: PRE-${pred.predictionDate.millisecondsSinceEpoch}');
    buffer.writeln('Generated On: ${pred.predictionDate.toLocal()}');
    buffer.writeln('Driver Profile: ${pred.driverIdStr} | Car: ${pred.carName}');
    buffer.writeln('Weight Spec: ${vehicle.vehicleWeight} kg | Power: ${vehicle.motorPower} kW');
    buffer.writeln('\n================ RANGE & CHARGING ANALYSIS ================');
    buffer.writeln('1. Estimated Remaining Range: ${pred.estimatedRange.toStringAsFixed(1)} KM');
    buffer.writeln('2. Predicted Battery Drain Rate: ${pred.predictedBatteryDrainRate.toStringAsFixed(2)}% per 10km');
    buffer.writeln('3. Current Battery Percentage: ${pred.batteryPercentage.toStringAsFixed(0)}%');
    buffer.writeln('4. Expected AC 11kW Charging Time: ${pred.expectedChargingRequirement.toStringAsFixed(1)} hours');
    buffer.writeln('5. Estimated Range If Highway: ${pred.predictedRangeHighway.toStringAsFixed(1)} KM');
    buffer.writeln('6. Estimated Range If City: ${pred.predictedRangeCity.toStringAsFixed(1)} KM');
    buffer.writeln('\n================ ENERGY & EFFICIENCY ================');
    buffer.writeln('7. Fleet Efficiency Score: ${pred.efficiencyScore.toStringAsFixed(1)}%');
    buffer.writeln('8. Predicted Energy Draw: ${pred.predictedEnergyConsumption.toStringAsFixed(1)} Wh/km');
    buffer.writeln('9. Estimated Energy Cost: \$${pred.costPerKm.toStringAsFixed(4)} / km');
    buffer.writeln('10. Monthly Energy cost (1500km): \$${pred.monthlyCostEstimation.toStringAsFixed(2)}');
    buffer.writeln('11. Driver Efficiency Score: ${pred.driverEfficiencyScore.toStringAsFixed(1)}%');
    buffer.writeln('12. Life carbon savings estimate: ${pred.carbonSavingsEstimate.toStringAsFixed(1)} kg CO2');
    buffer.writeln('\n================ PERFORMANCE & MAINTENANCE ================');
    buffer.writeln('13. Vehicle Performance Score: ${pred.vehiclePerformanceScore.toStringAsFixed(1)}%');
    buffer.writeln('14. Battery Cell Health Score: ${pred.batteryHealthScore.toStringAsFixed(1)}%');
    buffer.writeln('15. Overall Vehicle Health Rating: ${pred.overallVehicleHealth.toStringAsFixed(1)}%');
    buffer.writeln('16. Maintenance Alert Score: ${pred.maintenanceAlertScore.toStringAsFixed(1)}%');
    buffer.writeln('17. Service Status Forecast: ${pred.nextServiceRecommendation}');
    buffer.writeln('18. Vehicle Utilization Score: ${pred.vehicleUtilizationScore.toStringAsFixed(1)}%');
    buffer.writeln('\n================ RISK & CONTROL LIMITS ================');
    buffer.writeln('19. Operating Risk Level: ${pred.riskLevel.toUpperCase()}');
    buffer.writeln('20. Recommended Safe Velocity: ${pred.recommendedSpeed.toStringAsFixed(0)} km/h');
    buffer.writeln('21. Recommended Drive Mode: ${pred.recommendedDrivingMode}');

    final bytes = utf8.encode(buffer.toString());
    web_helper.downloadFile(bytes, 'DAP_Prediction_Report_${pred.driverIdStr}.txt');
  }

  static String _aiInsightsText(dynamic pred, dynamic vehicle) {
    final name = vehicle.driverName;
    final car = vehicle.carName;
    final speed = vehicle.currentSpeed;
    final weight = vehicle.vehicleWeight;

    String text = 'Hello $name, we have analyzed diagnostics telemetry from your $car. ';
    if (pred.riskLevel == 'High') {
      text += 'WARNING: Your operating risk is flagged HIGH. This is driven by your speed of ${speed.toStringAsFixed(0)} km/h and elevated thermal alerts. ';
    } else {
      text += 'All critical systems are performing stably. ';
    }
    if (speed > 110.0) {
      text += 'Aerodynamic drag is climbing quadratically. Lowering cruise to 95 km/h will extend range significantly. ';
    }
    if (weight > 2000.0) {
      text += 'As a heavy-class EV (${weight.toStringAsFixed(0)} kg), city regenerative braking (B-mode) is ideal to recapture kinetic energy. ';
    } else {
      text += 'Your lightweight chassis optimizes Wh/km efficiency values. ';
    }
    if (pred.batteryHealthScore < 85.0) {
      text += 'NOTICE: Battery SOH has slipped to ${pred.batteryHealthScore.toStringAsFixed(1)}%. Schedule diagnostic re-balancing at your next service interval. ';
    } else {
      text += 'Battery health parameters are excellent with minimal cell degradation detected. ';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final pred = Provider.of<PredictionController>(context).activePrediction;
    final vehicle = Provider.of<DriverController>(context).currentVehicle;

    if (pred == null || vehicle == null) {
      return Scaffold(
        body: const Center(child: Text('No active prediction result.')),
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    Color riskColor = AppTheme.neonGreen;
    if (pred.riskLevel == 'Medium') riskColor = AppTheme.amberAlert;
    else if (pred.riskLevel == 'High') riskColor = AppTheme.criticalRed;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.5, -1.0),
                  radius: 1.6,
                  colors: [Color(0xFF051525), AppTheme.backgroundColor],
                ),
              ),
            ),
          ),
          // Ambient glows
          Positioned(
            top: -100, left: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowBlue(intensity: 0.10, blur: 200),
              ),
            ),
          ),
          Positioned(
            bottom: -80, right: -80,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowPurple(intensity: 0.08, blur: 150),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 20, vertical: 16),
                  child: Row(
                    children: [
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
                              text: 'AI ANALYSIS REPORT',
                              gradient: AppTheme.primaryGradient,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: 1.2),
                            ),
                            Text('${pred.carName} · ${pred.driverIdStr}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      NeonBadge(
                          label: pred.riskLevel.toUpperCase(),
                          color: riskColor,
                          icon: Icons.shield_outlined),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _downloadReport(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                            border: Border.all(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.file_download_outlined,
                              color: AppTheme.primaryBlue, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── KM Hero + Gauges ────────────────────────
                            Flex(
                              direction:
                                  isDesktop ? Axis.horizontal : Axis.vertical,
                              children: [
                                // Animated KM counter
                                Expanded(
                                  flex: isDesktop ? 4 : 0,
                                  child: SizedBox(
                                    height: 240,
                                    child: NeonGlassCard(
                                      accentColor: AppTheme.primaryBlue,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(children: [
                                            const PulsingDot(
                                                color: AppTheme.primaryBlue,
                                                size: 8),
                                            const SizedBox(width: 8),
                                            const NeonBadge(
                                                label: 'ESTIMATED DRIVING RANGE',
                                                color: AppTheme.primaryBlue),
                                          ]),
                                          const SizedBox(height: 14),
                                          AnimatedBuilder(
                                            animation: _kmAnim,
                                            builder: (_, __) => GradientText(
                                              text:
                                                  '${(pred.estimatedRange * _kmAnim.value).toStringAsFixed(0)}',
                                              gradient: AppTheme.cynaToGreen,
                                              style: const TextStyle(
                                                  fontSize: 68,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.0),
                                            ),
                                          ),
                                          const Text(
                                            'KILOMETERS REMAINING',
                                            style: TextStyle(
                                              color: AppTheme.primaryBlue,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.8,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Calculated for ${vehicle.currentSpeed.toStringAsFixed(0)} km/h cruise · current temp conditions',
                                            style: TextStyle(
                                                color: AppTheme.textSecondary
                                                    .withValues(alpha: 0.8),
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20, height: 20),
                                // Dual gauges
                                Expanded(
                                  flex: isDesktop ? 5 : 0,
                                  child: SizedBox(
                                    height: 240,
                                    child: NeonGlassCard(
                                      accentColor: AppTheme.accentPurple,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          CircularGauge(
                                            value: pred.batteryPercentage,
                                            title: 'Capacity',
                                            unit: '%',
                                            activeColor: AppTheme.primaryBlue,
                                            size: 150,
                                          ),
                                          CircularGauge(
                                            value: pred.batteryHealthScore,
                                            title: 'SOH Health',
                                            unit: '%',
                                            activeColor: AppTheme.neonGreen,
                                            size: 150,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Risk + Efficiency ────────────────────────
                            Flex(
                              direction:
                                  isDesktop ? Axis.horizontal : Axis.vertical,
                              children: [
                                // Risk card with pulsing ring
                                Expanded(
                                  flex: isDesktop ? 3 : 0,
                                  child: SizedBox(
                                    height: 140,
                                    child: NeonGlassCard(
                                      accentColor: riskColor,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('OPERATING RISK INDEX',
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8)),
                                          const SizedBox(height: 10),
                                          Row(children: [
                                            PulsingDot(
                                                color: riskColor, size: 10),
                                            const SizedBox(width: 10),
                                            Icon(Icons.shield_outlined,
                                                color: riskColor, size: 24),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pred.riskLevel.toUpperCase(),
                                                  style: TextStyle(
                                                      color: riskColor,
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                  pred.riskLevel == 'High'
                                                      ? 'Slowing down is strongly recommended'
                                                      : pred.riskLevel == 'Medium'
                                                          ? 'Mild thermal stress detected'
                                                          : 'All systems nominal',
                                                  style: const TextStyle(
                                                      color:
                                                          AppTheme.textSecondary,
                                                      fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20, height: 20),
                                // Efficiency meter
                                Expanded(
                                  flex: isDesktop ? 6 : 0,
                                  child: SizedBox(
                                    height: 140,
                                    child: NeonGlassCard(
                                      accentColor: AppTheme.neonGreen,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                  'FLEET EFFICIENCY PROFILE',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.textSecondary,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5)),
                                              GradientText(
                                                text:
                                                    '${pred.efficiencyScore.toStringAsFixed(0)}%',
                                                gradient: AppTheme.cynaToGreen,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: LinearProgressIndicator(
                                              value: pred.efficiencyScore / 100.0,
                                              minHeight: 10,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.05),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(AppTheme.neonGreen),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  'Energy: ${pred.predictedEnergyConsumption.toStringAsFixed(0)} Wh/km',
                                                  style: TextStyle(
                                                      color: AppTheme.textSecondary
                                                          .withValues(alpha: 0.8),
                                                      fontSize: 11)),
                                              Text(
                                                  'Drain: ${pred.predictedBatteryDrainRate.toStringAsFixed(1)}%/10km',
                                                  style: TextStyle(
                                                      color: AppTheme.textSecondary
                                                          .withValues(alpha: 0.8),
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Detail grids ─────────────────────────────
                            GridView.count(
                              crossAxisCount: isDesktop ? 2 : 1,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: isDesktop ? 1.6 : 1.3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                NeonGlassCard(
                                  accentColor: AppTheme.primaryBlue,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GradientText(
                                        text: 'RANGE & COST ANALYSIS',
                                        gradient: AppTheme.primaryGradient,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            letterSpacing: 0.5),
                                      ),
                                      const Divider(
                                          color: AppTheme.glassBorderColor),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: ListView(children: [
                                          _tile('AC 11kW Charging Time',
                                              '${pred.expectedChargingRequirement.toStringAsFixed(1)} hrs',
                                              Icons.electrical_services_rounded,
                                              AppTheme.primaryBlue),
                                          _tile('Cost per Kilometer',
                                              '\$${pred.costPerKm.toStringAsFixed(3)}',
                                              Icons.monetization_on_outlined,
                                              AppTheme.neonGreen),
                                          _tile('Monthly Cost (1500km)',
                                              '\$${pred.monthlyCostEstimation.toStringAsFixed(2)}',
                                              Icons.payments_outlined,
                                              AppTheme.amberAlert),
                                          _tile('Carbon Savings',
                                              '${pred.carbonSavingsEstimate.toStringAsFixed(0)} kg CO₂',
                                              Icons.eco_outlined,
                                              AppTheme.neonGreen),
                                          _tile('Range Highway',
                                              '${pred.predictedRangeHighway.toStringAsFixed(0)} KM',
                                              Icons.route_rounded,
                                              AppTheme.primaryBlue),
                                          _tile('Range City',
                                              '${pred.predictedRangeCity.toStringAsFixed(0)} KM',
                                              Icons.location_city_rounded,
                                              AppTheme.accentPurple),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                                NeonGlassCard(
                                  accentColor: AppTheme.accentPurple,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GradientText(
                                        text: 'OPERATION GUIDELINES',
                                        gradient: AppTheme.purpleToBlue,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            letterSpacing: 0.5),
                                      ),
                                      const Divider(
                                          color: AppTheme.glassBorderColor),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: ListView(children: [
                                          _tile('Recommended Speed',
                                              '${pred.recommendedSpeed.toStringAsFixed(0)} km/h',
                                              Icons.speed_rounded,
                                              AppTheme.primaryBlue),
                                          _tile('Drive Mode',
                                              pred.recommendedDrivingMode,
                                              Icons.settings_suggest_rounded,
                                              AppTheme.accentPurple),
                                          _tile('Maintenance Alert',
                                              '${pred.maintenanceAlertScore.toStringAsFixed(0)}%',
                                              Icons.build_circle_outlined,
                                              AppTheme.amberAlert),
                                          _tile('Service Forecast',
                                              pred.nextServiceRecommendation,
                                              Icons.date_range_rounded,
                                              AppTheme.neonGreen),
                                          _tile('Utilization Score',
                                              '${pred.vehicleUtilizationScore.toStringAsFixed(0)}%',
                                              Icons.hourglass_empty_rounded,
                                              AppTheme.primaryBlue),
                                          _tile('Driver Efficiency',
                                              '${pred.driverEfficiencyScore.toStringAsFixed(0)}%',
                                              Icons.person_outline,
                                              AppTheme.neonGreen),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── AI Insights ──────────────────────────────
                            NeonGlassCard(
                              accentColor: AppTheme.accentPurple,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.psychology_rounded,
                                        color: AppTheme.accentPurple, size: 22),
                                    const SizedBox(width: 10),
                                    GradientText(
                                      text: 'AI INSIGHTS & REAL-TIME DIAGNOSTICS',
                                      gradient: AppTheme.purpleToBlue,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.5),
                                    ),
                                  ]),
                                  const Divider(color: AppTheme.glassBorderColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    _aiInsightsText(pred, vehicle),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Actions ──────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: AppTheme.glassBorderColor
                                            .withValues(alpha: 0.8)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 28),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('BACK TO DASHBOARD',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                GlassButton(
                                  text: 'DOWNLOAD REPORT',
                                  icon: Icons.file_download_outlined,
                                  color: AppTheme.primaryBlue,
                                  color2: AppTheme.accentPurple,
                                  onPressed: () => _downloadReport(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
