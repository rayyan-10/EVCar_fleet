import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class VisualizationsTab extends StatefulWidget {
  const VisualizationsTab({Key? key}) : super(key: key);

  @override
  State<VisualizationsTab> createState() => _VisualizationsTabState();
}

class _VisualizationsTabState extends State<VisualizationsTab> {
  int _activeCategory = 0; // 0=Overview, 1=Performance, 2=Energy, 3=Financials, 4=Maintenance

  final List<String> _categories = [
    'Fleet Overview',
    'Performance Metrics',
    'Battery & Energy',
    'Financial Analysis',
    'Health & Risk'
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category filters tab header
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_categories.length, (idx) {
              final isSelected = idx == _activeCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ChoiceChip(
                  label: Text(
                    _categories[idx].toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                  backgroundColor: Colors.white.withOpacity(0.02),
                  onSelected: (_) => setState(() => _activeCategory = idx),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryBlue.withOpacity(0.5) : AppTheme.glassBorderColor,
                      width: 0.8,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),

        // Expanded dashboard grid based on active tab
        Expanded(
          child: SingleChildScrollView(
            child: _buildChartCategoryGrid(isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCategoryGrid(bool isDesktop) {
    final columns = isDesktop ? 2 : 1;
    final double ratio = isDesktop ? 1.6 : 1.3;

    switch (_activeCategory) {
      case 0: // Fleet Overview (Charts 1-4)
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildChartCard('1. Battery Capacity Distribution', _buildBatteryCapacityDistributionChart()),
            _buildChartCard('2. Vehicle Weight Analysis', _buildVehicleWeightAnalysisChart()),
            _buildChartCard('3. City vs Highway Usage', _buildCityVsHighwayPieChart()),
            _buildChartCard('4. Vehicle Condition Distribution', _buildConditionPieChart()),
          ],
        );
      case 1: // Performance Metrics (Charts 5-8)
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildChartCard('5. Driver Growth Trend', _buildDriverGrowthTrendChart()),
            _buildChartCard('6. Monthly Prediction Trend', _buildMonthlyPredictionTrendChart()),
            _buildChartCard('7. Average Speed Analysis', _buildSpeedAnalysisChart()),
            _buildChartCard('8. Monthly Income Distribution', _buildIncomeDistributionChart()),
          ],
        );
      case 2: // Battery & Energy (Charts 9-12)
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildChartCard('9. Car-wise Performance Indices', _buildCarwisePerformanceChart()),
            _buildChartCard('10. Driver-wise Performance Indices', _buildDriverwisePerformanceChart()),
            _buildChartCard('11. Vehicle Health Score Distribution', _buildVehicleHealthDistributionChart()),
            _buildChartCard('12. Battery Health State Trend', _buildBatteryHealthTrendChart()),
          ],
        );
      case 3: // Financial Analysis (Charts 13-16)
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildChartCard('13. Cost Analysis Dashboard', _buildCostAnalysisChart()),
            _buildChartCard('14. Range Prediction Trends', _buildRangeTrendChart()),
            _buildChartCard('15. Service Requirement Forecast', _buildServiceForecastChart()),
            _buildChartCard('16. Monthly Vehicle Usage Hours', _buildVehicleUsageChart()),
          ],
        );
      case 4: // Health & Risk (Charts 17-20)
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildChartCard('17. Risk Analysis Dashboard', _buildRiskAnalysisChart()),
            _buildChartCard('18. Energy Consumption Analysis', _buildEnergyConsumptionChart()),
            _buildChartCard('19. Driver Efficiency Rankings', _buildDriverEfficiencyRankingsList()),
            _buildChartCard('20. Vehicle Performance Leaderboard', _buildVehicleLeaderboardList()),
          ],
        );
      default:
        return const Center(child: Text('Category undefined.'));
    }
  }

  Widget _buildChartCard(String title, Widget chartWidget) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.white),
          ),
          const Divider(color: AppTheme.glassBorderColor, height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: chartWidget,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CHART BUILDERS (Calculated from Controller state)
  // ==========================================

  Widget _buildBatteryCapacityDistributionChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Group battery values into buckets: <40, 40-70, 70-100
    double low = 0;
    double med = 0;
    double high = 0;
    final Set<String> processedDriverIds = {};

    for (var pred in predictions) {
      if (processedDriverIds.contains(pred.driverId)) continue;
      processedDriverIds.add(pred.driverId);

      // Find original capacity parameter
      final veh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      final cap = veh.batteryCapacity;
      if (cap < 50) low++;
      else if (cap <= 80) med++;
      else high++;
    }

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: low, color: Colors.redAccent, width: 22)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: med, color: AppTheme.primaryBlue, width: 22)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: high, color: Colors.tealAccent, width: 22)]),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                switch (val.toInt()) {
                  case 0: return const Text('<50kWh', style: TextStyle(fontSize: 10));
                  case 1: return const Text('50-80kWh', style: TextStyle(fontSize: 10));
                  case 2: return const Text('>80kWh', style: TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildVehicleWeightAnalysisChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double light = 0; // <1500kg
    double med = 0;   // 1500 - 2000kg
    double heavy = 0; // >2000kg
    final Set<String> processed = {};

    for (var pred in predictions) {
      if (processed.contains(pred.driverId)) continue;
      processed.add(pred.driverId);
      final veh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      final wt = veh.vehicleWeight;
      if (wt < 1600) light++;
      else if (wt <= 2000) med++;
      else heavy++;
    }

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: light, color: Colors.amberAccent, width: 22)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: med, color: AppTheme.primaryBlue, width: 22)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: heavy, color: Colors.deepPurpleAccent, width: 22)]),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                switch (val.toInt()) {
                  case 0: return const Text('<1.6t', style: TextStyle(fontSize: 10));
                  case 1: return const Text('1.6-2.0t', style: TextStyle(fontSize: 10));
                  case 2: return const Text('>2.0t', style: TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCityVsHighwayPieChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double city = 0;
    double hwy = 0;
    final Set<String> processed = {};

    for (var pred in predictions) {
      if (processed.contains(pred.driverId)) continue;
      processed.add(pred.driverId);
      final veh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      if (veh.runningType == 1) hwy++;
      else city++;
    }

    final total = city + hwy;
    final cityPercent = total > 0 ? (city / total * 100) : 0.0;
    final hwyPercent = total > 0 ? (hwy / total * 100) : 0.0;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 32,
        sections: [
          PieChartSectionData(color: AppTheme.primaryBlue, value: city, title: '${cityPercent.toStringAsFixed(0)}%\nCity', radius: 45, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.indigo, value: hwy, title: '${hwyPercent.toStringAsFixed(0)}%\nHwy', radius: 45, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConditionPieChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double working = 0;
    double garage = 0;
    final Set<String> processed = {};

    for (var pred in predictions) {
      if (processed.contains(pred.driverId)) continue;
      processed.add(pred.driverId);
      final veh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      if (veh.vehicleCondition == 1) working++;
      else garage++;
    }

    final total = working + garage;
    final workingP = total > 0 ? (working / total * 100) : 0.0;
    final garageP = total > 0 ? (garage / total * 100) : 0.0;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 32,
        sections: [
          PieChartSectionData(color: Colors.greenAccent, value: working, title: '${workingP.toStringAsFixed(0)}%\nActive', radius: 45, titleStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.orangeAccent, value: garage, title: '${garageP.toStringAsFixed(0)}%\nGarage', radius: 45, titleStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDriverGrowthTrendChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Group predictions by week (week 0 = oldest, ascending)
    final dates = predictions.map((p) => p.predictionDate).toList()..sort();
    if (dates.isEmpty) return _buildNoDataState();
    final minDate = dates.first;
    final Map<int, Set<String>> weekDrivers = {};
    for (final pred in predictions) {
      final week = pred.predictionDate.difference(minDate).inDays ~/ 7;
      weekDrivers.putIfAbsent(week, () => {}).add(pred.driverId);
    }
    final weeks = weekDrivers.keys.toList()..sort();
    final spots = weeks.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), weekDrivers[e.value]!.length.toDouble())
    ).toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: AppTheme.primaryBlue, isCurved: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.1)),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) => Text('Wk ${val.toInt() + 1}',
              style: const TextStyle(fontSize: 10)),
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildMonthlyPredictionTrendChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Group by month label
    final Map<String, int> monthCount = {};
    for (final pred in predictions) {
      final key = '${pred.predictionDate.year}-${pred.predictionDate.month.toString().padLeft(2, '0')}';
      monthCount[key] = (monthCount[key] ?? 0) + 1;
    }
    final months = monthCount.keys.toList()..sort();
    final monthLabels = months.map((k) {
      final parts = k.split('-');
      const names = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return names[int.parse(parts[1])];
    }).toList();

    return BarChart(BarChartData(
      barGroups: List.generate(months.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: monthCount[months[i]]!.toDouble(),
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue.withOpacity(0.6), AppTheme.primaryBlue],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ), width: 14),
      ])),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < monthLabels.length) {
              return Text(monthLabels[i], style: const TextStyle(fontSize: 10));
            }
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildSpeedAnalysisChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double slow = 0; // <50km/h
    double med = 0;  // 50-100km/h
    double fast = 0; // >100km/h
    final Set<String> processed = {};

    for (var pred in predictions) {
      if (processed.contains(pred.driverId)) continue;
      processed.add(pred.driverId);
      final veh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      final speed = veh.currentSpeed;
      if (speed < 50) slow++;
      else if (speed <= 110) med++;
      else fast++;
    }

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: slow, color: Colors.amberAccent, width: 22)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: med, color: Colors.tealAccent, width: 22)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: fast, color: Colors.redAccent, width: 22)]),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                switch (val.toInt()) {
                  case 0: return const Text('Low Speed', style: TextStyle(fontSize: 10));
                  case 1: return const Text('Cruise', style: TextStyle(fontSize: 10));
                  case 2: return const Text('High Speed', style: TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildIncomeDistributionChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double bracket1 = 0; // <5k
    double bracket2 = 0; // 5k - 10k
    double bracket3 = 0; // >10k
    final Set<String> processed = {};

    for (var pred in predictions) {
      if (processed.contains(pred.driverId)) continue;
      processed.add(pred.driverId);
      final veh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      final inc = veh.monthlyIncome;
      if (inc < 5000) bracket1++;
      else if (inc <= 10000) bracket2++;
      else bracket3++;
    }

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: bracket1, color: AppTheme.primaryBlue, width: 22)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: bracket2, color: Colors.blueAccent, width: 22)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: bracket3, color: Colors.teal, width: 22)]),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                switch (val.toInt()) {
                  case 0: return const Text('<\$5k', style: TextStyle(fontSize: 10));
                  case 1: return const Text('\$5k-\$10k', style: TextStyle(fontSize: 10));
                  case 2: return const Text('>\$10k', style: TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCarwisePerformanceChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average vehiclePerformanceScore grouped by carName
    final Map<String, List<double>> carScores = {};
    for (final pred in predictions) {
      carScores.putIfAbsent(pred.carName, () => []).add(pred.vehiclePerformanceScore);
    }
    final cars = carScores.keys.toList()..sort();
    final avgs = cars.map((c) {
      final vals = carScores[c]!;
      return vals.reduce((a, b) => a + b) / vals.length;
    }).toList();

    final colors = [AppTheme.primaryBlue, Colors.tealAccent, Colors.orangeAccent,
                    Colors.purpleAccent, Colors.amberAccent, Colors.redAccent];

    return BarChart(BarChartData(
      barGroups: List.generate(cars.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: avgs[i], color: colors[i % colors.length], width: 16),
      ])),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < cars.length) {
              final label = cars[i].split(' ').last;
              return Text(label, style: const TextStyle(fontSize: 9));
            }
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildDriverwisePerformanceChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average driverEfficiencyScore per driverIdStr
    final Map<String, List<double>> driverScores = {};
    for (final pred in predictions) {
      driverScores.putIfAbsent(pred.driverIdStr, () => []).add(pred.driverEfficiencyScore);
    }
    final drivers = driverScores.keys.toList()..sort();
    final avgs = drivers.map((d) {
      final vals = driverScores[d]!;
      return vals.reduce((a, b) => a + b) / vals.length;
    }).toList();

    final colors = [Colors.greenAccent, AppTheme.primaryBlue, Colors.orangeAccent,
                    Colors.purpleAccent, Colors.tealAccent];

    return BarChart(BarChartData(
      barGroups: List.generate(drivers.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: avgs[i], color: colors[i % colors.length], width: 14),
      ])),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < drivers.length) {
              // Show last part of driver ID for brevity
              final parts = drivers[i].split('-');
              return Text(parts.last, style: const TextStyle(fontSize: 9));
            }
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildVehicleHealthDistributionChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double bad = 0;  // <80%
    double good = 0; // 80-90%
    double excel = 0;// >90%

    for (var pred in predictions) {
      final h = pred.overallVehicleHealth;
      if (h < 80) bad++;
      else if (h <= 93) good++;
      else excel++;
    }

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: bad, color: Colors.redAccent, width: 22)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: good, color: Colors.amberAccent, width: 22)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: excel, color: Colors.greenAccent, width: 22)]),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                switch (val.toInt()) {
                  case 0: return const Text('<80% SOH', style: TextStyle(fontSize: 10));
                  case 1: return const Text('80-93% SOH', style: TextStyle(fontSize: 10));
                  case 2: return const Text('>93% SOH', style: TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBatteryHealthTrendChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average batteryHealthScore grouped by month index (chronological)
    final sorted = [...predictions]..sort((a, b) => a.predictionDate.compareTo(b.predictionDate));
    final Map<String, List<double>> monthHealth = {};
    for (final pred in sorted) {
      final key = '${pred.predictionDate.year}-${pred.predictionDate.month.toString().padLeft(2, '0')}';
      monthHealth.putIfAbsent(key, () => []).add(pred.batteryHealthScore);
    }
    final months = monthHealth.keys.toList()..sort();
    final spots = months.asMap().entries.map((e) {
      final vals = monthHealth[e.value]!;
      return FlSpot(e.key.toDouble(), vals.reduce((a, b) => a + b) / vals.length);
    }).toList();
    final labels = months.map((k) {
      final parts = k.split('-');
      const names = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return names[int.parse(parts[1])];
    }).toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: Colors.greenAccent, isCurved: false,
          dotData: const FlDotData(show: true),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < labels.length) return Text(labels[i], style: const TextStyle(fontSize: 10));
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildCostAnalysisChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average monthlyCostEstimation grouped by month
    final Map<String, List<double>> monthCost = {};
    for (final pred in predictions) {
      final key = '${pred.predictionDate.year}-${pred.predictionDate.month.toString().padLeft(2, '0')}';
      monthCost.putIfAbsent(key, () => []).add(pred.monthlyCostEstimation);
    }
    final months = monthCost.keys.toList()..sort();
    final spots = months.asMap().entries.map((e) {
      final vals = monthCost[e.value]!;
      return FlSpot(e.key.toDouble(), vals.reduce((a, b) => a + b) / vals.length);
    }).toList();
    final labels = months.map((k) {
      final parts = k.split('-');
      const names = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return names[int.parse(parts[1])];
    }).toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: Colors.amberAccent, isCurved: true,
          belowBarData: BarAreaData(show: true, color: Colors.amberAccent.withOpacity(0.05)),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < labels.length) return Text(labels[i], style: const TextStyle(fontSize: 10));
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildRangeTrendChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average estimatedRange grouped by month
    final Map<String, List<double>> monthRange = {};
    for (final pred in predictions) {
      final key = '${pred.predictionDate.year}-${pred.predictionDate.month.toString().padLeft(2, '0')}';
      monthRange.putIfAbsent(key, () => []).add(pred.estimatedRange);
    }
    final months = monthRange.keys.toList()..sort();
    final spots = months.asMap().entries.map((e) {
      final vals = monthRange[e.value]!;
      return FlSpot(e.key.toDouble(), vals.reduce((a, b) => a + b) / vals.length);
    }).toList();
    final labels = months.map((k) {
      final parts = k.split('-');
      const names = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return names[int.parse(parts[1])];
    }).toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: AppTheme.primaryBlue, isCurved: true,
          belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.07)),
        ),
      ],
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < labels.length) return Text(labels[i], style: const TextStyle(fontSize: 10));
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildServiceForecastChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double alerts = 0, soon = 0, okay = 0;
    for (final pred in predictions) {
      if (pred.nextServiceRecommendation.toLowerCase().contains('immediate')) alerts++;
      else if (pred.nextServiceRecommendation.toLowerCase().contains('30 days') ||
               pred.nextServiceRecommendation.toLowerCase().contains('3 month')) soon++;
      else okay++;
    }
    final total = alerts + soon + okay;

    return PieChart(PieChartData(
      sectionsSpace: 4,
      centerSpaceRadius: 28,
      sections: [
        if (alerts > 0) PieChartSectionData(color: Colors.redAccent, value: alerts,
          title: '${(alerts / total * 100).toStringAsFixed(0)}%\nAlert',
          radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        if (soon > 0) PieChartSectionData(color: Colors.amberAccent, value: soon,
          title: '${(soon / total * 100).toStringAsFixed(0)}%\nSoon',
          radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        if (okay > 0) PieChartSectionData(color: Colors.greenAccent, value: okay,
          title: '${(okay / total * 100).toStringAsFixed(0)}%\nOkay',
          radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    ));
  }

  Widget _buildVehicleUsageChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average vehicleUtilizationScore by month
    final Map<String, List<double>> monthUtil = {};
    for (final pred in predictions) {
      final key = '${pred.predictionDate.year}-${pred.predictionDate.month.toString().padLeft(2, '0')}';
      monthUtil.putIfAbsent(key, () => []).add(pred.vehicleUtilizationScore);
    }
    final months = monthUtil.keys.toList()..sort();
    final labels = months.map((k) {
      final parts = k.split('-');
      const names = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return names[int.parse(parts[1])];
    }).toList();

    return BarChart(BarChartData(
      barGroups: List.generate(months.length, (i) {
        final vals = monthUtil[months[i]]!;
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: avg, color: Colors.tealAccent, width: 14),
        ]);
      }),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < labels.length) return Text(labels[i], style: const TextStyle(fontSize: 10));
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildRiskAnalysisChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    double low = 0;
    double med = 0;
    double high = 0;

    for (var pred in predictions) {
      if (pred.riskLevel == 'Low') low++;
      else if (pred.riskLevel == 'Medium') med++;
      else high++;
    }

    final total = low + med + high;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 28,
        sections: [
          PieChartSectionData(color: Colors.greenAccent, value: low, title: '${(low/total*100).toStringAsFixed(0)}%\nLow', radius: 40, titleStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.orangeAccent, value: med, title: '${(med/total*100).toStringAsFixed(0)}%\nMed', radius: 40, titleStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
          PieChartSectionData(color: Colors.redAccent, value: high, title: '${(high/total*100).toStringAsFixed(0)}%\nHigh', radius: 40, titleStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEnergyConsumptionChart() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Average predictedEnergyConsumption (Wh/km) per carName
    final Map<String, List<double>> carEnergy = {};
    for (final pred in predictions) {
      carEnergy.putIfAbsent(pred.carName, () => []).add(pred.predictedEnergyConsumption);
    }
    final cars = carEnergy.keys.toList()..sort();
    final avgs = cars.map((c) {
      final vals = carEnergy[c]!;
      return vals.reduce((a, b) => a + b) / vals.length;
    }).toList();

    final colors = [Colors.blueAccent, Colors.tealAccent, Colors.orangeAccent,
                    Colors.purpleAccent, Colors.amberAccent];

    return BarChart(BarChartData(
      barGroups: List.generate(cars.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: avgs[i], color: colors[i % colors.length], width: 18),
      ])),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, _) {
            final i = val.toInt();
            if (i >= 0 && i < cars.length) {
              return Text(cars[i].split(' ').last, style: const TextStyle(fontSize: 9));
            }
            return const Text('');
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _buildDriverEfficiencyRankingsList() {
    final controller = Provider.of<AdminController>(context);
    final predictions = controller.filteredPredictions;
    if (predictions.isEmpty) return _buildNoDataState();

    // Group driver name and their highest driverEfficiencyScore
    final Map<String, double> driverScores = {};
    for (var pred in predictions) {
      final originalVeh = controller.allVehicles.firstWhere((v) => v.driverId == pred.driverId, orElse: () => controller.allVehicles.first);
      final name = originalVeh.driverName;
      final score = pred.driverEfficiencyScore;
      if (!driverScores.containsKey(name) || score > driverScores[name]!) {
        driverScores[name] = score;
      }
    }

    final sortedList = driverScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      itemCount: sortedList.length.clamp(0, 3),
      itemBuilder: (context, idx) {
        final entry = sortedList[idx];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, color: idx == 0 ? Colors.amber : (idx == 1 ? Colors.grey : Colors.brown)),
            child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          trailing: Text('${entry.value.toStringAsFixed(0)}% Eff.', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
        );
      },
    );
  }

  Widget _buildVehicleLeaderboardList() {
    final controller = Provider.of<AdminController>(context);
    final vehicles = controller.allVehicles;
    if (vehicles.isEmpty) return _buildNoDataState();

    return ListView.builder(
      itemCount: vehicles.length.clamp(0, 3),
      itemBuilder: (context, idx) {
        final veh = vehicles[idx];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.directions_car_rounded, color: AppTheme.primaryBlue, size: 20),
          title: Text(veh.carName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          subtitle: Text('Power: ${veh.motorPower.toStringAsFixed(0)} kW | Torque: ${veh.torque.toStringAsFixed(0)} Nm', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        );
      },
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Text(
        'Insufficient telemetry logs matching query.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
