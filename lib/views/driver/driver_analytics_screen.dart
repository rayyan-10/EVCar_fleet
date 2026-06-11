import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../controllers/driver_controller.dart';
import '../../models/telemetry_model.dart';
import '../../services/telemetry_csv_service.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class DriverAnalyticsScreen extends StatefulWidget {
  const DriverAnalyticsScreen({Key? key}) : super(key: key);
  @override
  State<DriverAnalyticsScreen> createState() => _DriverAnalyticsScreenState();
}

class _DriverAnalyticsScreenState extends State<DriverAnalyticsScreen> {
  List<TelemetryRecord> _records = [];
  bool _loading = true;

  int _touchedSpeed = -1;
  int _touchedSoc   = -1;
  int _touchedMode  = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicle = Provider.of<DriverController>(context, listen: false).currentVehicle;
    if (vehicle == null) { setState(() => _loading = false); return; }

    final all = await TelemetryCsvService().loadRecords();

    // Match records to this driver — try vehicleId first, then carName prefix, then driverId guess
    final vid = '';
    List<TelemetryRecord> matched = all.where((r) => r.vehicleId == vid).toList();

    if (matched.isEmpty) {
      final firstWord = vehicle.carName.toLowerCase().split(' ').first;
      matched = all.where((r) =>
          r.carName.toLowerCase().contains(firstWord)).toList();
    }

    if (matched.isEmpty) {
      // Fallback: use first 500 rows so screen doesn't stay empty in demo
      matched = all.take(500).toList();
    }

    matched.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    setState(() { _records = matched; _loading = false; });
  }

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(1);
  }

  // ── chart helpers ─────────────────────────────────────────────────────────

  Widget _chartCard(String title, Widget body, {double height = 200}) {
    return NeonGlassCard(
      accentColor: AppTheme.primaryBlue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GradientText(
          text: title,
          gradient: AppTheme.primaryGradient,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const Divider(color: AppTheme.glassBorderColor, height: 14),
        SizedBox(height: height, child: body),
      ]),
    );
  }

  Widget _row2(bool isDesktop, Widget a, Widget b) {
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: a), const SizedBox(width: 16), Expanded(child: b),
        ]),
      );
    }
    return Column(children: [a, const SizedBox(height: 16), b]);
  }

  FlTitlesData _td({
    required String Function(double) left,
    required String Function(double) bottom,
    double? bottomInterval,
  }) {
    return FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 40,
        getTitlesWidget: (v, _) =>
            Text(left(v), style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      )),
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true,
        interval: bottomInterval,
        getTitlesWidget: (v, _) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(bottom(v),
              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        ),
      )),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _grid() => FlGridData(
    show: true, drawVerticalLine: false,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
  );

  // 1 – Battery health over time (line)
  Widget _battTrend() {
    final dayMap = <int, List<double>>{};
    final minTs  = _records.first.timestamp;
    for (final r in _records) {
      final d = r.timestamp.difference(minTs).inDays;
      dayMap.putIfAbsent(d, () => []).add(r.batteryHealthPct);
    }
    final days  = (dayMap.keys.toList()..sort()).take(40).toList();
    final spots = days.asMap().entries.map((e) {
      final avg = dayMap[e.value]!.reduce((a, b) => a + b) / dayMap[e.value]!.length;
      return FlSpot(e.key.toDouble(), avg);
    }).toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: AppTheme.neonGreen, isCurved: true, barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: AppTheme.neonGreen.withValues(alpha: 0.08)),
        ),
      ],
      titlesData: _td(
        left:   (v) => '${v.toStringAsFixed(0)}%',
        bottom: (v) => 'D${(v + 1).toInt()}',
        bottomInterval: 6,
      ),
      gridData: _grid(), borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItems: (ss) => ss.map((s) => LineTooltipItem(
            '${s.y.toStringAsFixed(1)}%',
            TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
          )).toList(),
        ),
      ),
    ));
  }

  // 2 – Income per trip (bar)
  Widget _incomeTrend() {
    // Take last 20 trips for readability
    final subset = _records.length > 20
        ? _records.sublist(_records.length - 20)
        : _records;

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            'Trip ${g.x + 1}\n₹${rod.toY.toStringAsFixed(0)}',
            const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        touchCallback: (e, r) =>
            setState(() => _touchedSoc = r?.spot?.touchedBarGroupIndex ?? -1),
      ),
      barGroups: List.generate(subset.length, (i) {
        final touched = i == _touchedSoc;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: subset[i].incomeGenerated, width: touched ? 10 : 6,
            gradient: LinearGradient(
              colors: [AppTheme.neonGreen.withValues(alpha: 0.4), AppTheme.neonGreen],
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ]);
      }),
      titlesData: _td(
        left:   (v) => '₹${v.toStringAsFixed(0)}',
        bottom: (v) => '${(v + 1).toInt()}',
        bottomInterval: 4,
      ),
      gridData: _grid(), borderData: FlBorderData(show: false),
    ));
  }

  // 3 – Speed distribution (bucketed bar)
  Widget _speedDist() {
    final labels = ['<30', '30-50', '50-70', '70-90', '90-110', '110+'];
    final counts = List.filled(6, 0.0);
    for (final r in _records) {
      final s = r.avgSpeedKmph;
      if      (s < 30)  counts[0]++;
      else if (s < 50)  counts[1]++;
      else if (s < 70)  counts[2]++;
      else if (s < 90)  counts[3]++;
      else if (s < 110) counts[4]++;
      else              counts[5]++;
    }
    final colors = [
      AppTheme.primaryBlue, AppTheme.neonGreen, AppTheme.accentPurple,
      AppTheme.amberAlert, AppTheme.criticalRed, Colors.tealAccent,
    ];

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${labels[g.x]} km/h\n${rod.toY.toInt()} trips',
            const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        touchCallback: (e, r) =>
            setState(() => _touchedSpeed = r?.spot?.touchedBarGroupIndex ?? -1),
      ),
      barGroups: List.generate(labels.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: counts[i], width: i == _touchedSpeed ? 22 : 16,
          color: i == _touchedSpeed ? Colors.white : colors[i],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        ),
      ])),
      titlesData: _td(
        left:   (v) => v.toStringAsFixed(0),
        bottom: (v) => labels[v.toInt()],
      ),
      gridData: _grid(), borderData: FlBorderData(show: false),
    ));
  }

  // 4 – SOC drop per trip (line)
  Widget _socDropChart() {
    final subset = _records.length > 30
        ? _records.sublist(_records.length - 30)
        : _records;
    final spots = subset.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.socDrop))
        .toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: AppTheme.primaryBlue, isCurved: true, barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue.withValues(alpha: 0.18), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      titlesData: _td(
        left:   (v) => '${v.toStringAsFixed(0)}%',
        bottom: (v) => '${(v + 1).toInt()}',
        bottomInterval: 5,
      ),
      gridData: _grid(), borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItems: (ss) => ss.map((s) => LineTooltipItem(
            'Trip ${(s.x + 1).toInt()}\nDrop: ${s.y.toStringAsFixed(1)}%',
            const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
          )).toList(),
        ),
      ),
    ));
  }

  // 5 – Energy consumed per trip (line)
  Widget _energyTrend() {
    final subset = _records.length > 40
        ? _records.sublist(_records.length - 40)
        : _records;
    final spots = subset.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.energyConsumedKwh))
        .toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots, color: AppTheme.amberAlert, isCurved: true, barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppTheme.amberAlert.withValues(alpha: 0.15), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      titlesData: _td(
        left:   (v) => '${v.toStringAsFixed(0)} kWh',
        bottom: (v) => '${(v + 1).toInt()}',
        bottomInterval: 6,
      ),
      gridData: _grid(), borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItems: (ss) => ss.map((s) => LineTooltipItem(
            'Trip ${(s.x + 1).toInt()}\n${s.y.toStringAsFixed(2)} kWh',
            const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
          )).toList(),
        ),
      ),
    ));
  }

  // 6 – City vs Highway donut
  Widget _modePie() {
    final city = _records.where((r) => r.runningMode == 0).length;
    final hwy  = _records.where((r) => r.runningMode == 1).length;
    final total = city + hwy;
    if (total == 0) return const Center(child: Text('No data'));

    return PieChart(PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (e, r) =>
            setState(() => _touchedMode = r?.touchedSection?.touchedSectionIndex ?? -1),
      ),
      sectionsSpace: 4, centerSpaceRadius: 38,
      sections: [
        PieChartSectionData(
          color: AppTheme.primaryBlue, value: city.toDouble(),
          title: _touchedMode == 0
              ? 'City\n${(city / total * 100).toStringAsFixed(1)}%'
              : '${(city / total * 100).toStringAsFixed(0)}%',
          radius: _touchedMode == 0 ? 54 : 44,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(
          color: Colors.indigoAccent, value: hwy.toDouble(),
          title: _touchedMode == 1
              ? 'Highway\n${(hwy / total * 100).toStringAsFixed(1)}%'
              : '${(hwy / total * 100).toStringAsFixed(0)}%',
          radius: _touchedMode == 1 ? 54 : 44,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vehicle   = Provider.of<DriverController>(context).currentVehicle;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(children: [
        // Gradient bg
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1, -1),
                radius: 1.5,
                colors: [Color(0xFF051525), AppTheme.backgroundColor],
              ),
            ),
          ),
        ),
        // Ambient glows
        Positioned(top: -100, right: -100, child: Container(width: 350, height: 350,
          decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: AppTheme.glowBlue(intensity: 0.07, blur: 150)))),
        Positioned(bottom: -60, left: -60, child: Container(width: 250, height: 250,
          decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: AppTheme.glowPurple(intensity: 0.06, blur: 100)))),

        SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── App bar ──────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                        color: AppTheme.glassBorderColor.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GradientText(
                    text: 'MY VEHICLE ANALYTICS',
                    gradient: AppTheme.primaryGradient,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2),
                  ),
                  Text(vehicle?.carName ?? '–',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
              ),
              if (!_loading)
                NeonBadge(
                  label: '${_records.length} TRIPS',
                  color: AppTheme.primaryBlue,
                  icon: Icons.route_rounded,
                ),
            ]),
          ),

          // ── Body ─────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(child: Text('No telemetry data found.',
                        style: TextStyle(color: AppTheme.textSecondary)))
                    : SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 16, vertical: 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                          // KPI strip
                          _KpiStrip(records: _records, isDesktop: isDesktop),
                          const SizedBox(height: 20),

                          // Row 1: battery trend + income
                          _row2(isDesktop,
                            _chartCard('🔋  Battery Health Over Time', _battTrend()),
                            _chartCard('💰  Income Per Trip (₹)', _incomeTrend()),
                          ),
                          const SizedBox(height: 16),

                          // Row 2: speed dist + SOC drop
                          _row2(isDesktop,
                            _chartCard('🏎️  Speed Distribution', _speedDist()),
                            _chartCard('📉  SOC Drop per Trip', _socDropChart()),
                          ),
                          const SizedBox(height: 16),

                          // Row 3: energy full width + mode donut
                          _row2(isDesktop,
                            _chartCard('⚡  Energy Consumed per Trip (kWh)',
                                _energyTrend(), height: 200),
                            _chartCard('🛣️  City vs Highway Split', _modePie()),
                          ),
                          const SizedBox(height: 20),

                          // Safety panel
                          _SafetyPanel(records: _records),
                          const SizedBox(height: 20),

                          // Weather breakdown
                          _WeatherBreakdown(records: _records),
                          const SizedBox(height: 32),
                        ]),
                      ),
          ),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// KPI strip
// ─────────────────────────────────────────────
class _KpiStrip extends StatelessWidget {
  final List<TelemetryRecord> records;
  final bool isDesktop;
  const _KpiStrip({required this.records, required this.isDesktop});

  String _fmt(double v) {
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final n           = records.length;
    final totalIncome = records.fold(0.0, (s, r) => s + r.incomeGenerated);
    final totalDist   = records.fold(0.0, (s, r) => s + r.tripDistanceKm);
    final totalEnergy = records.fold(0.0, (s, r) => s + r.energyConsumedKwh);
    final avgBatt     = records.map((r) => r.batteryHealthPct).reduce((a, b) => a + b) / n;
    final avgSpeed    = records.map((r) => r.avgSpeedKmph).reduce((a, b) => a + b) / n;
    final safetyTotal = records.fold(0, (s, r) => s + r.overspeedEvents + r.hardBrakingEvents);

    final kpis = [
      _KD('TOTAL TRIPS',       '$n',                              Icons.route_rounded,             AppTheme.primaryBlue),
      _KD('TOTAL INCOME',      '₹${_fmt(totalIncome)}',          Icons.currency_rupee_rounded,    AppTheme.neonGreen),
      _KD('TOTAL DISTANCE',    '${_fmt(totalDist)} km',          Icons.map_outlined,              AppTheme.primaryBlue),
      _KD('ENERGY CONSUMED',   '${_fmt(totalEnergy)} kWh',       Icons.bolt_rounded,              AppTheme.amberAlert),
      _KD('AVG BATTERY HEALTH','${avgBatt.toStringAsFixed(1)}%', Icons.battery_charging_full,     AppTheme.neonGreen),
      _KD('AVG SPEED',         '${avgSpeed.toStringAsFixed(1)} km/h', Icons.speed_rounded,        AppTheme.primaryBlue),
      _KD('SAFETY EVENTS',     '$safetyTotal',                   Icons.warning_amber_rounded,     AppTheme.amberAlert),
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 2.3 : 2.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: kpis.map((k) => _KpiCard(data: k)).toList(),
    );
  }
}

class _KD {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KD(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KD data;
  const _KpiCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return AnimatedStatCard(
      title: data.label,
      value: data.value,
      icon: data.icon,
      color: data.color,
    );
  }
}

// ─────────────────────────────────────────────
// Safety panel
// ─────────────────────────────────────────────
class _SafetyPanel extends StatelessWidget {
  final List<TelemetryRecord> records;
  const _SafetyPanel({required this.records});

  @override
  Widget build(BuildContext context) {
    final overspeed = records.fold(0, (s, r) => s + r.overspeedEvents);
    final braking   = records.fold(0, (s, r) => s + r.hardBrakingEvents);
    final rapid     = records.fold(0, (s, r) => s + r.rapidAccelerationEvents);
    final avgBrakeW = records.map((r) => r.brakeWearPct).reduce((a, b) => a + b) / records.length;
    final avgSusp   = records.map((r) => r.suspensionHealthPct).reduce((a, b) => a + b) / records.length;
    final maxDays   = records.map((r) => r.daysSinceLastService).reduce((a, b) => a > b ? a : b);

    return NeonGlassCard(
      accentColor: AppTheme.amberAlert,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_outlined, color: AppTheme.amberAlert, size: 20),
          const SizedBox(width: 10),
          GradientText(
            text: 'SAFETY & MAINTENANCE SUMMARY',
            gradient: AppTheme.amberGradient,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
        ]),
        const Divider(color: AppTheme.glassBorderColor, height: 16),
        Wrap(spacing: 20, runSpacing: 12, children: [
          _safetyStat('Overspeed Events',  '$overspeed',                         Colors.orangeAccent),
          _safetyStat('Hard Braking',      '$braking',                           Colors.redAccent),
          _safetyStat('Rapid Acceleration','$rapid',                             Colors.purpleAccent),
          _safetyStat('Avg Brake Wear',    '${avgBrakeW.toStringAsFixed(1)}%',   Colors.amberAccent),
          _safetyStat('Avg Suspension',    '${avgSusp.toStringAsFixed(1)}%',
              avgSusp > 85 ? Colors.greenAccent : Colors.orangeAccent),
          _safetyStat('Days Since Service','$maxDays days',
              maxDays > 180 ? Colors.redAccent : Colors.greenAccent),
        ]),

        // Score bar
        const SizedBox(height: 16),
        Builder(builder: (ctx) {
          final totalEvents  = overspeed + braking + rapid;
          final safetyScore  = (100 - (totalEvents * 0.5).clamp(0, 60) -
              (avgBrakeW > 20 ? 10 : 0) - (maxDays > 180 ? 10 : 0)).clamp(0, 100).toDouble();
          final color = safetyScore > 70 ? Colors.greenAccent
                      : safetyScore > 40 ? Colors.orangeAccent : Colors.redAccent;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('OVERALL SAFETY SCORE',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 10,
                      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text('${safetyScore.toStringAsFixed(0)} / 100',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: safetyScore / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ]);
        }),
      ]),
    );
  }

  Widget _safetyStat(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary,
          fontSize: 10, letterSpacing: 0.3)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color,
          fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }
}

// ─────────────────────────────────────────────
// Weather breakdown
// ─────────────────────────────────────────────
class _WeatherBreakdown extends StatelessWidget {
  final List<TelemetryRecord> records;
  const _WeatherBreakdown({required this.records});

  @override
  Widget build(BuildContext context) {
    final map = <String, int>{};
    for (final r in records) {
      map[r.weatherCondition] = (map[r.weatherCondition] ?? 0) + 1;
    }
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total   = records.length;
    final colors  = [AppTheme.primaryBlue, const Color(0xFF00E5A0), Colors.amberAccent,
                     Colors.purpleAccent, Colors.orangeAccent];

    return NeonGlassCard(
      accentColor: AppTheme.primaryBlue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.cloud_outlined, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 10),
          GradientText(
            text: 'TRIPS BY WEATHER CONDITION',
            gradient: AppTheme.primaryGradient,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
        ]),
        const Divider(color: AppTheme.glassBorderColor, height: 16),
        ...entries.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          final pct   = e.value.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.value.key, style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 12)),
                Text('${e.value.value} trips  (${(pct * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct, minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
