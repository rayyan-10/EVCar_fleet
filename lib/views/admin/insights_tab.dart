import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    final allVehicles = controller.allVehicles;

    if (predictions.isEmpty) {
      return const Center(
        child: Text(
          'Insufficient data logs to generate automated insights.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // 1. Process Top Drivers
    final List<Map<String, dynamic>> topDrivers = [];
    final Set<String> topSeen = {};
    final sortedByDriverEff = List.from(predictions)
      ..sort((a, b) => b.driverEfficiencyScore.compareTo(a.driverEfficiencyScore));
    for (var p in sortedByDriverEff) {
      if (topSeen.contains(p.driverId)) continue;
      topSeen.add(p.driverId);
      final veh = allVehicles.firstWhere((v) => v.driverId == p.driverId, orElse: () => allVehicles.first);
      topDrivers.add({'name': veh.driverName, 'score': p.driverEfficiencyScore, 'car': p.carName});
    }

    // 2. Process Lowest Efficiency Vehicles
    final List<Map<String, dynamic>> lowEffVehicles = [];
    final Set<String> lowSeen = {};
    final sortedByEff = List.from(predictions)
      ..sort((a, b) => a.efficiencyScore.compareTo(b.efficiencyScore));
    for (var p in sortedByEff) {
      if (lowSeen.contains(p.driverId)) continue;
      lowSeen.add(p.driverId);
      final veh = allVehicles.firstWhere((v) => v.driverId == p.driverId, orElse: () => allVehicles.first);
      lowEffVehicles.add({'name': veh.driverName, 'score': p.efficiencyScore, 'car': p.carName, 'draw': p.predictedEnergyConsumption});
    }

    // 3. Process Vehicles Requiring Maintenance
    final List<Map<String, dynamic>> maintenanceRequired = [];
    for (var p in predictions) {
      if (p.maintenanceAlertScore > 50.0) {
        final veh = allVehicles.firstWhere((v) => v.driverId == p.driverId, orElse: () => allVehicles.first);
        if (!maintenanceRequired.any((m) => m['id'] == p.driverId)) {
          maintenanceRequired.add({
            'id': p.driverId,
            'name': veh.driverName,
            'car': p.carName,
            'score': p.maintenanceAlertScore,
            'reason': p.nextServiceRecommendation,
          });
        }
      }
    }

    // 4. Process Battery SOH Warnings (< 85%)
    final List<Map<String, dynamic>> batteryWarnings = [];
    for (var p in predictions) {
      if (p.batteryHealthScore < 85.0) {
        final veh = allVehicles.firstWhere((v) => v.driverId == p.driverId, orElse: () => allVehicles.first);
        if (!batteryWarnings.any((w) => w['id'] == p.driverId)) {
          batteryWarnings.add({
            'id': p.driverId,
            'name': veh.driverName,
            'car': p.carName,
            'score': p.batteryHealthScore,
          });
        }
      }
    }

    // 5. Process High Risk Vehicles
    final List<Map<String, dynamic>> highRiskAlerts = [];
    for (var p in predictions) {
      if (p.riskLevel == 'High') {
        final veh = allVehicles.firstWhere((v) => v.driverId == p.driverId, orElse: () => allVehicles.first);
        if (!highRiskAlerts.any((r) => r['id'] == p.driverId)) {
          highRiskAlerts.add({
            'id': p.driverId,
            'name': veh.driverName,
            'car': p.carName,
            'speed': veh.currentSpeed,
            'health': p.overallVehicleHealth,
          });
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fleet Level Energy & Carbon Trends card
          _buildSummaryTrendsCard(predictions),
          const SizedBox(height: 24),

          // Main insights cards grid
          GridView.count(
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: isDesktop ? 1.6 : 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. Top Performing Drivers card
              _buildListInsightCard(
                title: 'Top Performing Drivers',
                subtitle: 'Highest driver efficiency ratings',
                icon: Icons.emoji_events_outlined,
                iconColor: Colors.amberAccent,
                items: topDrivers.take(3).map((item) {
                  return _buildInsightRow(
                    title: item['name'] as String,
                    subtitle: item['car'] as String,
                    value: '${(item['score'] as double).toStringAsFixed(0)}% score',
                    valueColor: Colors.greenAccent,
                  );
                }).toList(),
              ),

              // 2. Lowest Efficiency Vehicles card
              _buildListInsightCard(
                title: 'Lowest Efficiency Vehicles',
                subtitle: 'Highest Wh/km energy consumption draw rates',
                icon: Icons.trending_down_rounded,
                iconColor: Colors.orangeAccent,
                items: lowEffVehicles.take(3).map((item) {
                  return _buildInsightRow(
                    title: item['car'] as String,
                    subtitle: 'Driver: ${item['name']}',
                    value: '${(item['draw'] as double).toStringAsFixed(0)} Wh/km',
                    valueColor: Colors.orangeAccent,
                  );
                }).toList(),
              ),

              // 3. Maintenance alerts
              _buildListInsightCard(
                title: 'Vehicles Requiring Maintenance',
                subtitle: 'Maintenance score threshold exceeded (>50%)',
                icon: Icons.handyman_outlined,
                iconColor: Colors.redAccent,
                items: maintenanceRequired.isEmpty
                    ? [_buildEmptyRow('No vehicles currently flagged for service.')]
                    : maintenanceRequired.take(3).map((item) {
                        return _buildInsightRow(
                          title: item['car'] as String,
                          subtitle: 'Driver: ${item['name']}',
                          value: '${(item['score'] as double).toStringAsFixed(0)}% alert',
                          valueColor: Colors.redAccent,
                        );
                      }).toList(),
              ),

              // 4. Battery cells alerts
              _buildListInsightCard(
                title: 'Battery Cell Health SOH Alerts',
                subtitle: 'Pack capacity fallen below nominal limits (<85%)',
                icon: Icons.battery_alert_rounded,
                iconColor: Colors.redAccent,
                items: batteryWarnings.isEmpty
                    ? [_buildEmptyRow('All fleet batteries display healthy state of charge.')]
                    : batteryWarnings.take(3).map((item) {
                        return _buildInsightRow(
                          title: item['car'] as String,
                          subtitle: 'Driver: ${item['name']}',
                          value: '${(item['score'] as double).toStringAsFixed(1)}% SOH',
                          valueColor: Colors.redAccent,
                        );
                      }).toList(),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // High Risk Warnings box (critical alert)
          if (highRiskAlerts.isNotEmpty) ...[
            const Text(
              'CRITICAL RISK WARNINGS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0, color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            Column(
              children: highRiskAlerts.map((alert) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HIGH VELOCITY / STRESS DISCOVERED ON ${alert['car'].toString().toUpperCase()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Driver ${alert['name']} is operating at a cruise velocity of ${alert['speed'].toStringAsFixed(0)} km/h. High kinetic workloads increase thermal stresses on power arrays.',
                                style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.9), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryTrendsCard(List<dynamic> predictions) {
    double energySum = 0;
    double carbonSum = 0;
    for (var p in predictions) {
      energySum += p.predictedEnergyConsumption;
      carbonSum += p.carbonSavingsEstimate;
    }

    final avgEnergy = energySum / predictions.length;
    final totalCarbonSaved = carbonSum;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 10),
              const Text(
                'FLEET ANOMALIES & ENERGY OUTLOOK',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
            ],
          ),
          const Divider(color: AppTheme.glassBorderColor, height: 20),
          const SizedBox(height: 8),
          Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrendStat('Fleet Average Draw', '${avgEnergy.toStringAsFixed(0)} Wh/km', 'Ideal EV benchmark: 150 Wh/km', Icons.electric_car_outlined),
              _buildTrendStat('Total Net CO2 Saved', '${totalCarbonSaved.toStringAsFixed(0)} kg', 'Equivalent to 45 trees planted', Icons.eco_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, String subText, IconData icon) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryBlue.withOpacity(0.08)),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subText, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildListInsightCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.08), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              )
            ],
          ),
          const Divider(color: AppTheme.glassBorderColor, height: 20),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: items,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required String title,
    required String subtitle,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: valueColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
