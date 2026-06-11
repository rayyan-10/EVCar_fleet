
// ── income bar chart ──────────────────────────────────────────────────────────
class _IncomeBarChart extends StatefulWidget {
  final List<DriverSummary> filtered;
  final bool isDesktop;
  const _IncomeBarChart({required this.filtered, required this.isDesktop});
  @override
  State<_IncomeBarChart> createState() => _IncomeBarChartState();
}

class _IncomeBarChartState extends State<_IncomeBarChart> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    if (widget.filtered.isEmpty) return const SizedBox.shrink();
    final sorted = [...widget.filtered]..sort((a, b) => b(color: Colors.white70, fontSize: 11)),
        ]),
      )),
    ]));
  }
}

class _Al {
  final String title, driver, car, message;
  final Color color;
  final int severity;
  const _Al(this.title, this.driver, this.car, this.message, this.color, this.severity);
}
xisAlignment.start, children: [
          Row(children: [
            Text(a.title, style: TextStyle(color: a.color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(child: Text('${a.driver.replaceAll("_", " ")} · ${a.car}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          Text(a.message, style: const TextStyle, fontSize: 13, color: Colors.pinkAccent)),
      ]),
      const Divider(color: AppTheme.glassBorderColor, height: 14),
      ...alerts.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: a.color.withOpacity(0.05), borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: a.color, width: 3))),
        child: Column(crossAxisAlignment: CrossA
      SizedBox(width: 12),
      Text('All metrics within normal thresholds.', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
    ]));

    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Icon(Icons.notifications_active_rounded, color: Colors.pinkAccent, size: 20),
        const SizedBox(width: 10),
        Text('${alerts.length} ACTIVE ALERTS',
            style: const TextStyle(fontWeight: FontWeight.bolds.driverName, s.carName,
          '${s.maxDaysSinceService} days since last service', Colors.purpleAccent, 1));
      if (s.avgBrakeWear > 25) alerts.add(_Al('🔧 Brake Wear', s.driverName, s.carName,
          'Avg ${s.avgBrakeWear.toStringAsFixed(1)}% — replacement needed', Colors.orangeAccent, 2));
    }
    alerts.sort((a, b) => b.severity.compareTo(a.severity));

    if (alerts.isEmpty) return GlassCard(child: Row(children: const [
      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),ccent, 2));
      if (s.avgBatteryHealth < 92) alerts.add(_Al('🔋 Battery Warning', s.driverName, s.carName,
          'Avg ${s.avgBatteryHealth.toStringAsFixed(1)}% · RUL: ${s.avgRUL.toStringAsFixed(0)} days', Colors.amberAccent, 1));
      if (s.avgBreakdownProb > 0.14) alerts.add(_Al('⚙️ Breakdown Risk', s.driverName, s.carName,
          'Prob ${s.avgBreakdownProb.toStringAsFixed(3)} — schedule maintenance', Colors.pinkAccent, 2));
      if (s.maxDaysSinceService > 60) alerts.add(_Al('📅 Service Overdue', urn const SizedBox.shrink();
    final alerts = <_Al>[];
    for (final s in filtered) {
      if (s.totalOverspeed >= 1500) alerts.add(_Al('🚨 CRITICAL Overspeed', s.driverName, s.carName,
          '${s.totalOverspeed} violations · Max ${s.maxSpeedKmph.toStringAsFixed(0)} km/h — immediate action needed', Colors.redAccent, 3));
      else if (s.totalOverspeed >= 300) alerts.add(_Al('⚠️ High Overspeed', s.driverName, s.carName,
          '${s.totalOverspeed} violations · Type: ${s.driverType}', Colors.orangeAAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    ]));
}

// ── fleet alerts ──────────────────────────────────────────────────────────────
class _FleetAlerts extends StatelessWidget {
  final List<DriverSummary> filtered;
  const _FleetAlerts({required this.filtered});

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) retiner(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Text('${s.driverId} (${s.carName})',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          )).toList()),
      ]));
  }

  Widget _stat(String l, String v, Color c) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: Main: AppTheme.glassBorderColor, height: 14),
        _stat('Avg Revenue',      '₹${_fmtK(avgInc)}',                 color),
        _stat('Avg Overspeed',    '${avgOv.toStringAsFixed(0)} events', Colors.orangeAccent),
        _stat('Avg Battery',      '${avgBatt.toStringAsFixed(1)}%',     Colors.tealAccent),
        _stat('Avg Driver Score', '${avgScr.toStringAsFixed(0)}',       Colors.amberAccent),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4,
          children: sums.map((s) => Conta     decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4))),
            child: Text(type.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))),
          const SizedBox(width: 8),
          Text('${sums.length} driver${sums.length > 1 ? "s" : ""}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
        const Divider(coloral avgBatt = sums.map((s) => s.avgBatteryHealth).reduce((a, b) => a + b) / sums.length;
    final avgScr  = sums.map((s) => s.baseDriverScore).reduce((a, b) => a + b) / sums.length;

    return GlassCard(
      borderColor: color.withOpacity(0.25),
      gradientColors: [color.withOpacity(0.04), Colors.transparent],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
       om: 12),
        child: _card(types[e.key], colors[e.key], byType[types[e.key]] ?? []))).toList());
  }

  Widget _card(String type, Color color, List<DriverSummary> sums) {
    if (sums.isEmpty) return GlassCard(child: Center(child:
        Text('No $type drivers', style: const TextStyle(color: AppTheme.textSecondary))));
    final avgInc  = sums.map((s) => s.totalIncome).reduce((a, b) => a + b) / sums.length;
    final avgOv   = sums.map((s) => s.totalOverspeed).reduce((a, b) => a + b) / sums.length;
    finiltered.where((s) => s.driverType == t).toList()};

    if (isDesktop) {
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: types.asMap().entries.map((e) => Expanded(
          child: Padding(padding: EdgeInsets.only(right: e.key < 2 ? 12 : 0),
            child: _card(types[e.key], colors[e.key], byType[types[e.key]] ?? [])))).toList()));
    }
    return Column(children: types.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bott─────────────────────────
class _DriverTypeInsights extends StatelessWidget {
  final List<DriverSummary> summaries;
  final List<DriverSummary> filtered;
  final bool isDesktop;
  const _DriverTypeInsights({required this.summaries, required this.filtered, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final types  = ['Safe', 'Normal', 'Aggressive'];
    final colors = [Colors.greenAccent, Colors.amberAccent, Colors.redAccent];
    final byType = {for (final t in types) t: f
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 0.25, color: Colors.white.withOpacity(0.02)),
            )]);
          }),
          titlesData: _barTitles(bottomLabels: sorted.map((s) => s.driverId).toList(), leftFmt: (v) => v.toStringAsFixed(2)),
          gridData: _grid(), borderData: FlBorderData(show: false),
        ))),
      ]));
  }
}

// ── driver type insights ─────────────────────────────BarGroupIndex ?? -1),
          ),
          barGroups: List.generate(sorted.length, (i) {
            final v = sorted[i].avgBreakdownProb;
            final c = v > 0.15 ? Colors.redAccent : v > 0.1 ? Colors.orangeAccent : Colors.amberAccent;
            return BarChartGroupData(x: i, barRods: [BarChartRodData(
              toY: v, width: i == _touched ? 26 : 20,
              gradient: LinearGradient(colors: [c.withOpacity(0.3), c],
                  begin: Alignment.bottomCenter, end: Alignment.topCenter), {
                final s = sorted[g.x];
                return BarTooltipItem(
                  '${s.driverName.replaceAll("_", " ")}\n'
                  'Breakdown Prob: ${s.avgBreakdownProb.toStringAsFixed(4)}\n'
                  'Degradation: ${s.avgDegRate.toStringAsFixed(4)}\n'
                  'Type: ${s.driverType}',
                  const TextStyle(color: Colors.white, fontSize: 11, height: 1.5));
              }),
            touchCallback: (e, r) => setState(() => _touched = r?.spot?.touched       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        const Text('Higher = more risk · tap bar for details',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const Divider(color: AppTheme.glassBorderColor, height: 14),
        SizedBox(height: 220, child: BarChart(BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(tooltipRoundedRadius: 8,
              getTooltipItem: (g, _, rod, __)skPanelState extends State<_BreakdownRiskPanel> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    if (widget.filtered.isEmpty) return const SizedBox.shrink();
    final sorted = [...widget.filtered]..sort((a, b) => b.avgBreakdownProb.compareTo(a.avgBreakdownProb));

    return GlassCard(borderColor: Colors.amberAccent.withOpacity(0.2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('AVG BREAKDOWN PROBABILITY  (0–1 scale)',
     d', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ]),
        );
      }),
    ]));
  }
}

// ── breakdown risk panel ──────────────────────────────────────────────────────
class _BreakdownRiskPanel extends StatefulWidget {
  final List<DriverSummary> filtered;
  final bool isDesktop;
  const _BreakdownRiskPanel({required this.filtered, required this.isDesktop});
  @override
  State<_BreakdownRiskPanel> createState() => _BreakdownRiskPanelState();
}

class _BreakdownRiow(children: [
            SizedBox(width: 60, child: Text(s.driverId, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.04),
                  valueColor: AlwaysStoppedAnimation<Color>(color)))),
            const SizedBox(width: 8),
            Text('${s.avgRUL.toStringAsFixed(0)}show: false),
      ))),
      const SizedBox(height: 14),
      const Text('REMAINING USEFUL LIFE (days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
      const SizedBox(height: 8),
      ...sorted.map((s) {
        final pct   = (s.avgRUL / 1000).clamp(0, 1).toDouble();
        final color = s.avgRUL > 500 ? Colors.greenAccent : s.avgRUL > 200 ? Colors.amberAccent : Colors.redAccent;
        return Padding(padding: const EdgeInsets.only(bottom: 8),
          child: R[c.withOpacity(0.3), c],
                begin: Alignment.bottomCenter, end: Alignment.topCenter),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.white.withOpacity(0.02)),
          )]);
        }),
        minY: 85,
        titlesData: _barTitles(bottomLabels: sorted.map((s) => s.driverId).toList(), leftFmt: (v) => '${v.toStringAsFixed(0)}%'),
        gridData: _grid(), borderData: FlBorderData(e: 11, height: 1.5));
            }),
          touchCallback: (e, r) => setState(() => _touched = r?.spot?.touchedBarGroupIndex ?? -1),
        ),
        barGroups: List.generate(sorted.length, (i) {
          final v = sorted[i].avgBatteryHealth;
          final c = v > 93 ? Colors.greenAccent : v > 88 ? Colors.amberAccent : Colors.redAccent;
          return BarChartGroupData(x: i, barRods: [BarChartRodData(
            toY: v, width: i == _touched ? 26 : 20,
            gradient: LinearGradient(colors: ld: BarChart(BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(tooltipRoundedRadius: 8,
            getTooltipItem: (g, _, rod, __) {
              final s = sorted[g.x];
              return BarTooltipItem(
                '${s.driverName.replaceAll("_", " ")}\n${s.carName}\n'
                'Battery: ${s.avgBatteryHealth.toStringAsFixed(1)}%\n'
                'RUL: ${s.avgRUL.toStringAsFixed(0)} days',
                const TextStyle(color: Colors.white, fontSizfiltered]..sort((a, b) => b.avgBatteryHealth.compareTo(a.avgBatteryHealth));

    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('AVG BATTERY HEALTH (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
      const Text('Green >93% · Amber 88–93% · Red <88%', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      const Divider(color: AppTheme.glassBorderColor, height: 14),
      SizedBox(height: 220, chiass _BatteryHealthPanel extends StatefulWidget {
  final List<DriverSummary> filtered;
  final bool isDesktop;
  const _BatteryHealthPanel({required this.filtered, required this.isDesktop});
  @override
  State<_BatteryHealthPanel> createState() => _BatteryHealthPanelState();
}

class _BatteryHealthPanelState extends State<_BatteryHealthPanel> {
  int _touched = -1;
  @override
  Widget build(BuildContext context) {
    if (widget.filtered.isEmpty) return const SizedBox.shrink();
    final sorted = [...widget.ed(1)}%', Colors.amberAccent),
          _tag('Max Speed',   '${s.maxSpeedKmph.toStringAsFixed(0)} km/h', Colors.pinkAccent),
        ]),
      ]),
    );
  }

  Widget _tag(String l, String v, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$l: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    Text(v, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 10)),
  ]);
}

// ── battery health panel ──────────────────────────────────────────────────────
cllors.white.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color))),
        const SizedBox(height: 5),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _tag('Overspeed',   '${s.totalOverspeed}',                Colors.redAccent),
          _tag('Hard Brake',  '${s.totalHardBraking}',              Colors.orangeAccent),
          _tag('Rapid Accel', '${s.totalRapidAccel}',               Colors.purpleAccent),
          _tag('Brake Wear',  '${s.avgBrakeWear.toStringAsFixrRadius: BorderRadius.circular(8)),
            child: Text(s.driverType, style: TextStyle(color: tc, fontSize: 9, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Text('${score.toStringAsFixed(0)}/100', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: score / 100, minHeight: 6,
              backgroundColor: Co + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text('${s.driverName.replaceAll("_", " ")}  ·  ${s.carName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: tc.withOpacity(0.12), borde       : s.driverType == 'Normal' ? Colors.amberAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${rankies.map((e) => _row(e.key, e.value)).toList()));
  }

  Widget _row(int rank, DriverSummary s) {
    final total = s.totalOverspeed + s.totalHardBraking + s.totalRapidAccel;
    final score = (100 - (total * 0.02).clamp(0, 70)
        - (s.avgBrakeWear > 20 ? 10 : 0)
        - (s.maxDaysSinceService > 180 ? 10 : 0)).clamp(0, 100).toDouble();
    final color = score > 70 ? Colors.greenAccent : score > 40 ? Colors.orangeAccent : Colors.redAccent;
    final tc    = s.driverType == 'Safe' ? Colors.greenAccent
 sDesktop;
  const _SafetyScorecard({required this.filtered, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) return const SizedBox.shrink();
    final sorted = [...filtered]
      ..sort((a, b) => (b.totalOverspeed + b.totalHardBraking + b.totalRapidAccel)
          .compareTo(a.totalOverspeed + a.totalHardBraking + a.totalRapidAccel));

    return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sorted.asMap().entrminHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(color))),
                  ],
                ))),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── safety scorecard ──────────────────────────────────────────────────────────
class _SafetyScorecard extends StatelessWidget {
  final List<DriverSummary> filtered;
  final bool i               DataCell(SizedBox(width: 80, child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 3),
                    ClipRRect(borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: pct / 100, ph.toStringAsFixed(0)} km/h', style: const TextStyle(fontSize: 12))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.4))),
                  child: Text(_tier(s.totalOverspeed), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)))),
 ld: Text(s.driverType, style: TextStyle(color: tc, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Text('${s.totalOverspeed}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
                DataCell(Text('${s.totalHardBraking}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12))),
                DataCell(Text('${s.totalRapidAccel}',  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12))),
                DataCell(Text('${s.maxSpeedKmeight.bold))),
                DataCell(Text(s.driverName.replaceAll('_', ' '),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12))),
                DataCell(Text(s.carName, style: const TextStyle(fontSize: 12))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: tc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  chi            rows: sorted.asMap().entries.map((e) {
              final rank = e.key; final s = e.value;
              final color = _tc(s.totalOverspeed);
              final pct   = maxOv > 0 ? s.totalOverspeed / maxOv * 100 : 0.0;
              final tc    = s.driverType == 'Safe' ? Colors.greenAccent
                  : s.driverType == 'Normal' ? Colors.amberAccent : Colors.redAccent;
              return DataRow(cells: [
                DataCell(Text('#${rank + 1}', style: const TextStyle(fontWeight: FontW   DataColumn(label: Text('Rapid Accel',  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              DataColumn(label: Text('Max Speed',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              DataColumn(label: Text('Risk Tier',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('% of Worst',   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
            ],
tSize: 11))),
              DataColumn(label: Text('Car',          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Type',         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Violations',   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              DataColumn(label: Text('Hard Brake',   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
           10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.03)),
            dataRowMinHeight: 48, dataRowMaxHeight: 58, columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Rank',        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Driver',       style: TextStyle(fontWeight: FontWeight.bold, fon.compareTo(a.totalOverspeed));
    final maxOv  = sorted.first.totalOverspeed;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text('OVERSPEED VIOLATIONS TABLE  —  DESCENDING ORDER',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
        const Divider(color: AppTheme.glassBorderColor, height: get {
  final List<DriverSummary> filtered;
  const _OverspeedTable({required this.filtered});

  Color _tc(int n) => n >= 1500 ? Colors.redAccent : n >= 300 ? Colors.orangeAccent
      : n >= 50 ? Colors.amberAccent : Colors.greenAccent;
  String _tier(int n) => n >= 1500 ? 'CRITICAL' : n >= 300 ? 'HIGH' : n >= 50 ? 'MEDIUM' : 'SAFE';

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) return const SizedBox.shrink();
    final sorted = [...filtered]..sort((a, b) => b.totalOverspeed<50',       Colors.greenAccent),
        ]),
      ]),
    );
  }

  Widget _pill(String l, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(l, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
  ]);
}

// ── overspeed table ───────────────────────────────────────────────────────────
class _OverspeedTable extends StatelessWidData: _barTitles(
                bottomLabels: sorted.map((s) => s.driverId).toList(),
                leftFmt: (v) => v.toStringAsFixed(0)),
            gridData: _grid(), borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 4, children: [
          _pill('CRITICAL ≥1500', Colors.redAccent),
          _pill('HIGH ≥300',      Colors.orangeAccent),
          _pill('MEDIUM ≥50',     Colors.amberAccent),
          _pill('SAFE ouble(), width: touched ? 28 : 22,
                  gradient: LinearGradient(colors: [color.withOpacity(0.3), color],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: maxVal * 1.15, color: Colors.white.withOpacity(0.02)),
                ),
              ]);
            }),
            titlese: 11, height: 1.5, fontWeight: FontWeight.bold),
                  );
                },
              ),
              touchCallback: (e, r) => setState(() => _touched = r?.spot?.touchedBarGroupIndex ?? -1),
            ),
            barGroups: List.generate(sorted.length, (i) {
              final s = sorted[i]; final color = _tc(s.totalOverspeed); final touched = i == _touched;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: s.totalOverspeed.toDRadius: 8,
                getTooltipItem: (g, _, rod, __) {
                  final s = sorted[g.x];
                  return BarTooltipItem(
                    '${s.driverName.replaceAll("_", " ")}\n'
                    '${s.carName}  ·  ${s.driverType}\n'
                    'Violations: ${s.totalOverspeed}\n'
                    'Max Speed: ${s.maxSpeedKmph.toStringAsFixed(0)} km/h\n'
                    'Risk Tier: ${_tier(s.totalOverspeed)}',
                    const TextStyle(color: Colors.white, fontSizs  ·  Max ${worst.maxSpeedKmph.toStringAsFixed(0)} km/h',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        const Divider(color: AppTheme.glassBorderColor, height: 14),
        SizedBox(height: 260,
          child: BarChart(BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.crisis_alert_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'WORST OFFENDER: ${worst.driverName.replaceAll("_", " ")} (${worst.driverId})  ·  '
              '${worst.carName}  ·  ${worst.totalOverspeed} violationsAlignment.stretch, children: [
        const Text('OVERSPEED VIOLATIONS PER DRIVER',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        const Text('CRITICAL ≥1500 · HIGH ≥300 · MEDIUM ≥50 · SAFE <50',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.red => n >= 1500 ? 'CRITICAL' : n >= 300 ? 'HIGH' : n >= 50 ? 'MEDIUM' : 'SAFE';

  @override
  Widget build(BuildContext context) {
    if (widget.filtered.isEmpty) return const SizedBox.shrink();
    final sorted = [...widget.filtered]..sort((a, b) => b.totalOverspeed.compareTo(a.totalOverspeed));
    final maxVal = sorted.first.totalOverspeed.toDouble();
    final worst  = sorted.first;

    return GlassCard(
      borderColor: Colors.redAccent.withOpacity(0.2),
      child: Column(crossAxisAlignment: CrossAxiedBarChart extends StatefulWidget {
  final List<DriverSummary> filtered;
  final bool isDesktop;
  const _OverspeedBarChart({required this.filtered, required this.isDesktop});
  @override
  State<_OverspeedBarChart> createState() => _OverspeedBarChartState();
}

class _OverspeedBarChartState extends State<_OverspeedBarChart> {
  int _touched = -1;

  Color _tc(int n) => n >= 1500 ? Colors.redAccent : n >= 300 ? Colors.orangeAccent
      : n >= 50 ? Colors.amberAccent : Colors.greenAccent;
  String _tier(int n)cent, fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12))),
                DataCell(Text('₹${s.incomePerKm.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12))),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── overspeed bar chart ───────────────────────────────────────────────────────
class _Overspedecoration: BoxDecoration(color: tc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(s.driverType, style: TextStyle(color: tc, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Text('${s.trips}',               style: const TextStyle(fontSize: 12))),
                DataCell(Text(_fmtK(s.totalDistKm),       style: const TextStyle(fontSize: 12))),
                DataCell(Text('₹${_fmtK(s.totalIncome)}', style: const TextStyle(color: Colors.greenAc           const SizedBox(width: 6),
                  Text(s.driverName.replaceAll('_', ' '),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                ])),
                DataCell(Text(s.carName,  style: const TextStyle(fontSize: 12))),
                DataCell(Text(s.brand,    style: const TextStyle(fontSize: 12))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                   * 100 : 0.0;
              final tc    = s.driverType == 'Safe' ? Colors.greenAccent
                  : s.driverType == 'Normal' ? Colors.amberAccent : Colors.redAccent;
              return DataRow(cells: [
                DataCell(Text(rank < 3 ? medals[rank] : '#${rank + 1}', style: const TextStyle(fontSize: 14))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
       numeric: true),
              DataColumn(label: Text('% Fleet',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              DataColumn(label: Text('₹/km',       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
            ],
            rows: sorted.asMap().entries.map((e) {
              final rank = e.key; final s = e.value;
              final color = _pc(filtered.indexOf(s));
              final pct   = totalInc > 0 ? s.totalIncome / totalIncFontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Type',       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Trips',      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              DataColumn(label: Text('Dist (km)',  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), numeric: true),
              DataColumn(label: Text('Revenue ₹',  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),   dataRowMinHeight: 44, dataRowMaxHeight: 52, columnSpacing: 18,
            columns: const [
              DataColumn(label: Text('Rank',      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Driver',     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Car',        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Brand',      style: TextStyle(fontWeight:  children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text('INCOME RANKING TABLE  —  DESCENDING ORDER',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
        const Divider(color: AppTheme.glassBorderColor, height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.03)),
          {
  final List<DriverSummary> filtered;
  const _IncomeTable({required this.filtered});

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) return const SizedBox.shrink();
    final sorted   = [...filtered]..sort((a, b) => b.totalIncome.compareTo(a.totalIncome));
    final totalInc = sorted.fold(0.0, (s, r) => s + r.totalIncome);
    final medals   = ['🥇', '🥈', '🥉'];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,dth: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('${e.value.driverId}  ${e.value.driverName.replaceAll("_", " ")}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

// ── income table ──────────────────────────────────────────────────────────────
class _IncomeTable extends StatelessWidget          ]);
            }),
            titlesData: _barTitles(bottomLabels: labels, leftFmt: (v) => '₹${v.toStringAsFixed(0)}K'),
            gridData: _grid(), borderData: FlBorderData(show: false),
          )),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 6,
          children: sorted.asMap().entries.map((e) {
            final color = _pc(widget.filtered.indexOf(e.value));
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(wi  toY: sorted[i].totalIncome / 1000,
                  width: touched ? 28 : 22,
                  gradient: LinearGradient(colors: [color.withOpacity(0.35), color],
                      begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                      show: true, toY: maxVal * 1.15, color: Colors.white.withOpacity(0.02)),
                ),
      fontSize: 11, height: 1.5, fontWeight: FontWeight.bold),
                  );
                },
              ),
              touchCallback: (e, r) => setState(() => _touched = r?.spot?.touchedBarGroupIndex ?? -1),
            ),
            barGroups: List.generate(sorted.length, (i) {
              final color   = _pc(widget.filtered.indexOf(sorted[i]));
              final touched = i == _touched;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                      final pct = totalInc > 0 ? s.totalIncome / totalInc * 100 : 0.0;
                  return BarTooltipItem(
                    '${s.driverName.replaceAll("_", " ")}\n'
                    '${s.carName}  ·  ${s.brand}\n'
                    '₹${_fmtK(s.totalIncome)}  (${pct.toStringAsFixed(1)}%)\n'
                    '${s.trips} trips  ·  ${_fmtK(s.totalDistKm)} km\n'
                    '₹${s.incomePerKm.toStringAsFixed(1)}/km  ·  ${s.driverType}',
                    const TextStyle(color: Colors.white,   const Text('Sorted descending · tap any bar for full tooltip',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const Divider(color: AppTheme.glassBorderColor, height: 14),
        SizedBox(height: 260,
          child: BarChart(BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItem: (g, _, rod, __) {
                  final s = sorted[g.x];
            .totalIncome.compareTo(a.totalIncome));
    final maxVal = sorted.first.totalIncome / 1000;
    final labels = sorted.map((s) => s.driverId).toList();
    final totalInc = sorted.fold(0.0, (s, r) => s + r.totalIncome);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('REVENUE PER DRIVER  (₹ thousands)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        const SizedBox(height: 4),
     