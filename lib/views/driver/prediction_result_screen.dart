import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../controllers/prediction_controller.dart';
import '../../controllers/driver_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/web_helper_non_web.dart'
    if (dart.library.html) '../widgets/web_helper_web.dart' as web_helper;

class PredictionResultScreen extends StatelessWidget {
  const PredictionResultScreen({Key? key}) : super(key: key);

  void _downloadPDFReport(BuildContext context) {
    final pred = Provider.of<PredictionController>(context, listen: false).activePrediction;
    final vehicle = Provider.of<DriverController>(context, listen: false).currentVehicle;
    
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
    buffer.writeln('\n================ GENERATED AI RECOMMENDATIONS ================');
    buffer.writeln(_generateAIRecommendationsText(pred, vehicle));

    final bytes = utf8.encode(buffer.toString());
    web_helper.downloadFile(bytes, 'DAP_Prediction_Report_${pred.driverIdStr}.txt');
  }

  static String _generateAIRecommendationsText(var pred, var vehicle) {
    final buffer = StringBuffer();
    if (pred.riskLevel == 'High') {
      buffer.writeln('- ALERT: High risk conditions detected. We recommend slowing down below ${pred.recommendedSpeed.toStringAsFixed(0)} km/h immediately.');
    }
    if (pred.batteryHealthScore < 85.0) {
      buffer.writeln('- MAINTENANCE: Battery SOH is at ${pred.batteryHealthScore.toStringAsFixed(1)}%. Schedule diagnostic service for cell balancing.');
    }
    if (vehicle.currentSpeed > 115) {
      buffer.writeln('- EFFICIENCY: Speed is exceeding optimal bounds. Lowering speed to 95 km/h will increase range by up to 25%.');
    }
    if (vehicle.vehicleCondition == 0) {
      buffer.writeln('- OPERATION: Vehicle is currently marked in garage status. Range is simulated for static conditions.');
    }
    if (buffer.isEmpty) {
      buffer.writeln('- FLEET STATUS: All operational telemetry values are within normal nominal bounds. Continue normal driving patterns.');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final predCtrl = Provider.of<PredictionController>(context);
    final vehicleCtrl = Provider.of<DriverController>(context);
    final pred = predCtrl.activePrediction;
    final vehicle = vehicleCtrl.currentVehicle;

    if (pred == null || vehicle == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text('No active prediction result available.'),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Determine Risk color
    Color riskColor = Colors.greenAccent;
    if (pred.riskLevel == 'Medium') {
      riskColor = Colors.orangeAccent;
    } else if (pred.riskLevel == 'High') {
      riskColor = Colors.redAccent;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI ANALYSIS REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          // Background ambient light glows
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP Summary Panel (KM Counter + Gauges)
                    Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      children: [
                        // Predicted Range Large Card
                        Expanded(
                          flex: isDesktop ? 4 : 0,
                          child: Container(
                            height: 240,
                            child: GlassCard(
                              borderColor: AppTheme.primaryBlue.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bolt, color: AppTheme.primaryBlue, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ESTIMATED DRIVING RANGE',
                                        style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${pred.estimatedRange.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 68,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  const Text(
                                    'KILOMETERS REMAINING',
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Calculated dynamically for current speed (${vehicle.currentSpeed.toStringAsFixed(0)} km/h) and operating temperature.',
                                    style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20, height: 20),
                        
                        // Dual Gauges Card (Battery & Health)
                        Expanded(
                          flex: isDesktop ? 5 : 0,
                          child: Container(
                            height: 240,
                            child: GlassCard(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                    activeColor: Colors.tealAccent,
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

                    // Risk Indicator + Efficiency Meter row
                    Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      children: [
                        // Risk Card
                        Expanded(
                          flex: isDesktop ? 3 : 0,
                          child: Container(
                            height: 140,
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('OPERATING RISK INDEX', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: riskColor, size: 28),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pred.riskLevel.toUpperCase(),
                                            style: TextStyle(color: riskColor, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                          Text(
                                            pred.riskLevel == 'High' 
                                                ? 'Slowing down is highly recommended' 
                                                : pred.riskLevel == 'Medium'
                                                    ? 'Mild thermal stress detected'
                                                    : 'All operations normal',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20, height: 20),
                        
                        // Efficiency Meter Card
                        Expanded(
                          flex: isDesktop ? 6 : 0,
                          child: Container(
                            height: 140,
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('FLEET EFFICIENCY PROFILE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      Text('${pred.efficiencyScore.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pred.efficiencyScore / 100.0,
                                      minHeight: 10,
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Energy Draw: ${pred.predictedEnergyConsumption.toStringAsFixed(0)} Wh/km', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 11)),
                                      Text('Drain Rate: ${pred.predictedBatteryDrainRate.toStringAsFixed(1)}% / 10km', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 11)),
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

                    // Grid details: Metrics summary, recommendations, AI Insights
                    GridView.count(
                      crossAxisCount: isDesktop ? 2 : 1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: isDesktop ? 1.6 : 1.3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Left: Metric values summary (10 values of 20)
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SECONDARY TELEMETRY VALUES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                              const Divider(color: AppTheme.glassBorderColor),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView(
                                  children: [
                                    _buildListTile('Expected AC 11kW Charging Time', '${pred.expectedChargingRequirement.toStringAsFixed(1)} hrs', Icons.electrical_services_rounded),
                                    _buildListTile('Estimated cost per Kilometer', '\$${pred.costPerKm.toStringAsFixed(3)}', Icons.monetization_on_outlined),
                                    _buildListTile('Estimated Monthly Cost (1500km)', '\$${pred.monthlyCostEstimation.toStringAsFixed(2)}', Icons.payments_outlined),
                                    _buildListTile('Estimated Lifetime Carbon Savings', '${pred.carbonSavingsEstimate.toStringAsFixed(0)} kg CO2', Icons.eco_outlined),
                    _buildListTile('Predicted Range If Highway', '${pred.predictedRangeHighway.toStringAsFixed(0)} KM', Icons.route_rounded),
                                    _buildListTile('Predicted Range If City', '${pred.predictedRangeCity.toStringAsFixed(0)} KM', Icons.location_city_rounded),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Recommendations & Performance indicators
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SPEED & OPERATION GUIDELINES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                              const Divider(color: AppTheme.glassBorderColor),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView(
                                  children: [
                                    _buildListTile('Recommended Safe Speed Limit', '${pred.recommendedSpeed.toStringAsFixed(0)} km/h', Icons.speed_rounded),
                                    _buildListTile('Optimal Driving Mode Profile', pred.recommendedDrivingMode, Icons.settings_suggest_rounded),
                                    _buildListTile('Maintenance Alert Indicator', '${pred.maintenanceAlertScore.toStringAsFixed(0)}%', Icons.build_circle_outlined),
                                    _buildListTile('Service Recommendation Forecast', pred.nextServiceRecommendation, Icons.date_range_rounded),
                                    _buildListTile('Vehicle Utilization Factor', '${pred.vehicleUtilizationScore.toStringAsFixed(0)}%', Icons.hourglass_empty_rounded),
                                    _buildListTile('Driver Efficiency Rating', '${pred.driverEfficiencyScore.toStringAsFixed(0)}%', Icons.person_outline),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // AI Insights Panel
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology_rounded, color: AppTheme.primaryBlue, size: 24),
                              const SizedBox(width: 10),
                              const Text(
                                'AI INSIGHTS & REAL-TIME DIAGNOSTICS',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          const Divider(color: AppTheme.glassBorderColor),
                          const SizedBox(height: 10),
                          Text(
                            _generateAIInsightsText(pred, vehicle),
                            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.glassBorderColor),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('BACK TO DASHBOARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        GlassButton(
                          text: 'DOWNLOAD PDF REPORT',
                          icon: Icons.picture_as_pdf_outlined,
                          onPressed: () => _downloadPDFReport(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _generateAIInsightsText(var pred, var vehicle) {
    final name = vehicle.driverName;
    final car = vehicle.carName;
    final speed = vehicle.currentSpeed;
    final weight = vehicle.vehicleWeight;

    String text = "Hello $name, we have analyzed the diagnostics telemetry from your $car. ";
    
    if (pred.riskLevel == 'High') {
      text += "WARNING: Your operating risk index is currently flagged as HIGH. This is driven by your speed of ${speed.toStringAsFixed(0)} km/h and elevated motor thermal alerts. ";
    } else {
      text += "All critical systems are performing stably. ";
    }

    if (speed > 110.0) {
      text += "Your aerodynamic resistance drag is climbing quadratically due to highway cruise speed of ${speed.toStringAsFixed(0)} km/h. Lowering your cruise to 95 km/h will save ~${(speed - 90).toStringAsFixed(0)}% Wh/km energy draw, extending range significantly. ";
    }

    if (weight > 2000.0) {
      text += "As a heavy-class electric vehicle (${weight.toStringAsFixed(0)} kg), rolling friction and kinetic acceleration represent significant energy drains. City regenerative braking (B-mode) is ideal to recapture momentum energy. ";
    } else {
      text += "Your lightweight chassis optimizes Wh/km efficiency values. ";
    }

    if (pred.batteryHealthScore < 85.0) {
      text += "NOTICE: Battery state of health has slipped to ${pred.batteryHealthScore.toStringAsFixed(1)}%. We recommend scheduling diagnostic re-balancing at your next interval. ";
    } else {
      text += "Battery health parameters are excellent, displaying minimal cell degradation. ";
    }

    return text;
  }
}
