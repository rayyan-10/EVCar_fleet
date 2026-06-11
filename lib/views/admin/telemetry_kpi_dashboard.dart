import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/merged_telemetry_model.dart';
import '../../services/merged_telemetry_service.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

const List<Color> _pal = [
  Color(0xFF00A3FF), Color(0xFF00E5A0), Color(0xFFFFB800),
  Color(0xFFFF4D6D), Color(0xFFB57BFF), Color(0xFF00D4FF),
  Color(0xFFFF8C42), Color(0xFF6EEB83), Color(0xFFE040FB),
  Color(0xFFFFD166),
];
Color _pc(int i) => _pal[i % _pal.length];

String _fmt(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

FlGridData _grid() => FlGridData(
  show: true, drawVerticalLine: false,
  getDrawingHorizontalLine: (_) =>
      FlLine(color: AppTheme.glassBorderColor.withOpacity(0.4), strokeWidth: 0.6),
);

FlTitlesData _bt({required List<String> bl, required String Function(double) lf}) =>
    FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 48,
        getTitlesWidget: (v, _) =>
            Text(lf(v), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
      )),
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 28,
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= bl.length) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(bl[i],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                  overflow: TextOverflow.ellipsis));
        },
      )),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );

Widget _sh(String t, {IconData? icon}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(children: [
    if (icon != null) ...[Icon(icon, color: AppTheme.primaryBlue, size: 18), const SizedBox(width: 8)],
    Text(t, style: const TextStyle(color: Colors.white, fontSize: 13,
        fontWeight: FontWeight.bold, letterSpacing: 0.8)),
  ]),
);

Widget _dot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
  Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
  const SizedBox(width: 4),
  Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
]);

Widget _chip(String type) {
  final c = type == 'Safe' ? const Color(0xFF00E5A0)
      : type == 'Aggressive' ? const Color(0xFFFF4D6D) : const Color(0xFFFFB800);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4))),
    child: Text(type, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

class TelemetryKpiDashboard extends StatefulWidget {
  const TelemetryKpiDashboard({super.key});
  @override
  State<TelemetryKpiDashboard> createState() => _State();
}

class _State extends State<TelemetryKpiDashboard> {
  List<DriverSummary> _sum = [];
  List<MergedRecord>  _rec = [];
  bool    _loading = true;
  String? _err;
  Set<String> _sel = {};
  String? _brand, _type;
  int?    _mode;
  bool    _cmp = false;

  List<DriverSummary> get _f => _sum.where((s) {
    if (_sel.isNotEmpty && !_sel.contains(s.driverId)) return false;
    if (_brand != null && s.brand      != _brand) return false;
    if (_type  != null && s.driverType != _type)  return false;
    if (_mode  != null && !_rec.where((r) => r.driverId == s.driverId).any((r) => r.runningMode == _mode)) return false;
    return true;
  }).toList();

  List<MergedRecord> get _fr {
    final ids = _f.map((s) => s.driverId).toSet();
    return _rec.where((r) => ids.contains(r.driverId)).toList();
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        MergedTelemetryService().loadSummaries(),
        MergedTelemetryService().loadRecords(),
      ]);
      if (mounted) setState(() {
        _sum = r[0] as List<DriverSummary>;
        _rec = r[1] as List<MergedRecord>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  void _reset() => setState(() { _sel = {}; _brand = null; _type = null; _mode = null; _cmp = false; });

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    if (_err != null) return Center(child: Text('Error: $_err', style: const TextStyle(color: Colors.redAccent)));
    final desktop = MediaQuery.of(context).size.width >= 900;
    final f = _f;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _filters(desktop),
        const SizedBox(height: 16),
        if (_cmp && _sel.length >= 2)
          _compare(desktop, f)
        else ...[
          _kpis(desktop, f),
          const SizedBox(height: 16),
          _status(desktop),
          const SizedBox(height: 16),
          _revenue(desktop, f),
          const SizedBox(height: 16),
          _trend(desktop, f),
          const SizedBox(height: 16),
          _overspeed(desktop, f),
          const SizedBox(height: 16),
          _safety(f),
          const SizedBox(height: 16),
          _battery(desktop, f),
          const SizedBox(height: 16),
          _breakdown(f),
          const SizedBox(height: 16),
          _driverTypes(desktop, f),
          const SizedBox(height: 16),
          _alerts(f),
          const SizedBox(height: 32),
        ],
      ]),
    );
  }

  // FILTER BAR
  Widget _filters(bool desktop) {
    final brands = _sum.map((s) => s.brand).toSet().toList()..sort();
    final types  = ['Safe', 'Normal', 'Aggressive'];
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('FILTERS & CONTROLS',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3))),
            child: Text('${_fr.length} records',
                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _cmp = !_cmp),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cmp ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cmp ? AppTheme.primaryBlue : AppTheme.glassBorderColor)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.compare_arrows, size: 12,
                    color: _cmp ? AppTheme.primaryBlue : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('Compare', style: TextStyle(
                    color: _cmp ? AppTheme.primaryBlue : AppTheme.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 13, color: AppTheme.textSecondary),
            label: const Text('Reset', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6,
          children: _sum.asMap().entries.map((e) {
            final s = e.value; final on = _sel.contains(s.driverId);
            return GestureDetector(
              onTap: () => setState(() => on ? _sel.remove(s.driverId) : _sel.add(s.driverId)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: on ? _pc(e.key).withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? _pc(e.key) : AppTheme.glassBorderColor)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(color: _pc(e.key), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('${s.driverId} - ${s.carName}',
                      style: TextStyle(
                          color: on ? _pc(e.key) : AppTheme.textSecondary,
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          }).toList()),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _dd<String>('Brand', _brand, brands, (b) => b, (v) => setState(() => _brand = v)),
          _dd<String>('Driver Type', _type, types, (t) => t, (v) => setState(() => _type = v)),
          _dd<int>('Mode', _mode, const [0, 1],
              (m) => m == 0 ? 'City' : 'Highway', (v) => setState(() => _mode = v)),
        ]),
      ]),
    );
  }

  Widget _dd<T>(String label, T? value, List<T> items,
      String Function(T) lb, ValueChanged<T?> onChange) =>
      Container(
        height: 32, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.glassBorderColor)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            iconEnabledColor: AppTheme.textSecondary,
            iconSize: 16, isDense: true,
            items: [
              DropdownMenuItem<T>(value: null, child: Text('All $label',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
              ...items.map((i) => DropdownMenuItem<T>(value: i,
                  child: Text(lb(i), style: const TextStyle(color: Colors.white, fontSize: 11)))),
            ],
            onChanged: onChange,
          ),
        ),
      );

  // KPI STRIP
  Widget _kpis(bool desktop, List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    final trips   = f.fold(0,   (s, d) => s + d.trips);
    final rev     = f.fold(0.0, (s, d) => s + d.totalIncome);
    final dist    = f.fold(0.0, (s, d) => s + d.totalDistKm);
    final energy  = f.fold(0.0, (s, d) => s + d.totalEnergyKwh);
    final batt    = f.map((d) => d.avgBatteryHealth).reduce((a, b) => a + b) / f.length;
    final spd     = f.map((d) => d.avgSpeedKmph).reduce((a, b) => a + b) / f.length;
    final ovs     = f.fold(0, (s, d) => s + d.totalOverspeed);
    final rul     = f.map((d) => d.avgRUL).reduce((a, b) => a + b) / f.length;
    final aggCnt  = f.where((d) => d.driverType == 'Aggressive').length;
    final co2     = dist * 0.105;

    final items = [
      ('TRIPS',       _fmt(trips.toDouble()),          Icons.route,                AppTheme.primaryBlue),
      ('REVENUE',     'Rs.${_fmt(rev)}',                Icons.currency_rupee,       const Color(0xFF00E5A0)),
      ('DISTANCE',    '${_fmt(dist)} km',               Icons.speed,                const Color(0xFFFFB800)),
      ('ENERGY',      '${_fmt(energy)} kWh',            Icons.bolt,                 const Color(0xFFB57BFF)),
      ('AVG BATTERY', '${batt.toStringAsFixed(1)}%',    Icons.battery_charging_full,const Color(0xFF00D4FF)),
      ('AVG SPEED',   '${spd.toStringAsFixed(1)} km/h', Icons.directions_car,       const Color(0xFFFF8C42)),
      ('OVERSPEEDS',  _fmt(ovs.toDouble()),             Icons.warning_amber,        const Color(0xFFFF4D6D)),
      ('AVG RUL',     '${rul.toStringAsFixed(0)} days', Icons.timer,                const Color(0xFF6EEB83)),
      ('AGGRESSIVE',  '$aggCnt',                        Icons.local_fire_department,const Color(0xFFFF4D6D)),
      ('CO2 SAVED',   '${_fmt(co2)} kg',                Icons.eco,                  const Color(0xFF00E5A0)),
    ];

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: desktop ? 5 : 2,
        childAspectRatio: 2.2, mainAxisSpacing: 8, crossAxisSpacing: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final k = items[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Icon(k.$3, color: k.$4, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(k.$1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, letterSpacing: 0.8)),
              const SizedBox(height: 3),
              Text(k.$2, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      },
    );
  }

  // FLEET STATUS
  Widget _status(bool desktop) {
    final Map<String, MergedRecord> latest = {};
    for (final r in _rec) latest[r.vehicleId] = r;
    final run = <MergedRecord>[], chg = <MergedRecord>[], gar = <MergedRecord>[];
    for (final r in latest.values) {
      if (r.breakdownRiskLevel == 'Critical')  gar.add(r);
      else if (r.breakdownRiskLevel == 'High') chg.add(r);
      else                                      run.add(r);
    }
    const green = Color(0xFF00E5A0), amber = Color(0xFFFFB800), slate = Color(0xFF8F9BB3);
    final total = latest.length;

    Widget badge(String lbl, int cnt, Color c, IconData icon) => Expanded(
      child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Icon(icon, color: c, size: 18), const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lbl, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            Text('$cnt', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
        ])));

    Widget chips(List<MergedRecord> recs, Color c) => Wrap(spacing: 6, runSpacing: 6,
      children: recs.map((r) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.3))),
        child: Text('${r.vehicleId} - ${r.carName} - ${r.socEndPct.toStringAsFixed(0)}%',
            style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)))).toList());

    final pie = PieChartData(sectionsSpace: 2, centerSpaceRadius: 44, sections: [
      PieChartSectionData(value: run.length.toDouble(), color: green, title: '${run.length}', radius: 44,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      PieChartSectionData(value: chg.length.toDouble(), color: amber, title: '${chg.length}', radius: 44,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      PieChartSectionData(value: gar.length.toDouble(), color: slate, title: '${gar.length}', radius: 44,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('FLEET STATUS  -  $total vehicles', icon: Icons.directions_car),
        if (desktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 160, height: 160, child: PieChart(pie)),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                badge('RUNNING', run.length, green, Icons.play_circle),
                const SizedBox(width: 8),
                badge('CHARGING', chg.length, amber, Icons.battery_charging_full),
                const SizedBox(width: 8),
                badge('MAINTENANCE', gar.length, slate, Icons.build),
              ]),
              const SizedBox(height: 12),
              if (run.isNotEmpty) ...[
                Text('RUNNING', style: TextStyle(color: green, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4), chips(run, green), const SizedBox(height: 8)],
              if (chg.isNotEmpty) ...[
                Text('HIGH-RISK / NEEDS CHARGE', style: TextStyle(color: amber, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4), chips(chg, amber), const SizedBox(height: 8)],
              if (gar.isNotEmpty) ...[
                Text('CRITICAL / MAINTENANCE', style: TextStyle(color: slate, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4), chips(gar, slate)],
            ])),
          ])
        else
          Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 160, child: PieChart(pie)),
            const SizedBox(height: 12),
            Row(children: [
              badge('RUNNING', run.length, green, Icons.play_circle),
              const SizedBox(width: 8),
              badge('CHARGING', chg.length, amber, Icons.battery_charging_full),
              const SizedBox(width: 8),
              badge('MAINTENANCE', gar.length, slate, Icons.build),
            ]),
            const SizedBox(height: 12),
            chips([...run, ...chg, ...gar], AppTheme.primaryBlue),
          ]),
        const SizedBox(height: 10),
        Row(children: [
          _dot(green, 'Running'), const SizedBox(width: 12),
          _dot(amber, 'Charging'), const SizedBox(width: 12),
          _dot(slate, 'Maintenance'), const Spacer(),
          Text('$total vehicles', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }

  // REVENUE
  Widget _revenue(bool desktop, List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    final sorted = [...f]..sort((a, b) => b.totalIncome.compareTo(a.totalIncome));
    final total  = sorted.fold(0.0, (s, d) => s + d.totalIncome);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('INCOME & REVENUE ANALYSIS', icon: Icons.currency_rupee),
        SizedBox(height: 260, child: BarChart(BarChartData(
          barGroups: sorted.asMap().entries.map((e) {
            final idx = _sum.indexWhere((s) => s.driverId == e.value.driverId);
            return BarChartGroupData(x: e.key, barRods: [BarChartRodData(
              toY: e.value.totalIncome,
              gradient: LinearGradient(colors: [_pc(idx), _pc(idx).withOpacity(0.5)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              width: desktop ? 22 : 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )]);
          }).toList(),
          gridData: _grid(), borderData: FlBorderData(show: false),
          titlesData: _bt(bl: sorted.map((s) => s.driverId).toList(),
              lf: (v) => 'Rs.${_fmt(v)}'),
          barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.cardColor,
            getTooltipItem: (g, _, rod, __) {
              final s = sorted[g.x];
              final pct = total > 0 ? (s.totalIncome / total * 100).toStringAsFixed(1) : '0';
              return BarTooltipItem(
                '${s.driverName}\n${s.carName} - ${s.brand}\nRs.${_fmt(s.totalIncome)} ($pct%)\n'
                '${s.trips} trips - ${_fmt(s.totalDistKm)} km\nRs.${s.incomePerKm.toStringAsFixed(2)}/km - ${s.driverType}',
                const TextStyle(color: Colors.white, fontSize: 10));
            })),
        ))),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 6,
          children: sorted.asMap().entries.map((e) {
            final idx = _sum.indexWhere((s) => s.driverId == e.value.driverId);
            return _dot(_pc(idx), e.value.driverId);
          }).toList()),
        const SizedBox(height: 16),
        GlassCard(padding: EdgeInsets.zero, child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.04)),
            dataRowColor: WidgetStateProperty.all(Colors.transparent),
            columnSpacing: 16, horizontalMargin: 12,
            headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 0.8),
            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 11),
            columns: const [
              DataColumn(label: Text('RNK')),
              DataColumn(label: Text('DRIVER')),
              DataColumn(label: Text('CAR')),
              DataColumn(label: Text('BRAND')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('TRIPS'),   numeric: true),
              DataColumn(label: Text('DIST km'), numeric: true),
              DataColumn(label: Text('REVENUE'), numeric: true),
              DataColumn(label: Text('%FLEET'),  numeric: true),
              DataColumn(label: Text('/km'),      numeric: true),
            ],
            rows: sorted.asMap().entries.map((e) {
              final rank = e.key + 1; final s = e.value;
              final idx  = _sum.indexWhere((x) => x.driverId == s.driverId);
              final pct  = total > 0 ? s.totalIncome / total * 100 : 0.0;
              final medal = rank == 1 ? '#1' : rank == 2 ? '#2' : rank == 3 ? '#3' : '$rank';
              return DataRow(cells: [
                DataCell(Text(medal, style: TextStyle(
                    color: rank == 1 ? const Color(0xFFFFD700)
                        : rank == 2 ? Colors.grey.shade300
                        : rank == 3 ? Colors.orange.shade400 : Colors.white,
                    fontWeight: FontWeight.bold))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: _pc(idx), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(s.driverName, overflow: TextOverflow.ellipsis),
                ])),
                DataCell(Text(s.carName, overflow: TextOverflow.ellipsis)),
                DataCell(Text(s.brand,   overflow: TextOverflow.ellipsis)),
                DataCell(_chip(s.driverType)),
                DataCell(Text('${s.trips}')),
                DataCell(Text(_fmt(s.totalDistKm))),
                DataCell(Text('Rs.${_fmt(s.totalIncome)}',
                    style: const TextStyle(color: Color(0xFF00E5A0), fontWeight: FontWeight.bold))),
                DataCell(Text('${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppTheme.primaryBlue))),
                DataCell(Text('Rs.${s.incomePerKm.toStringAsFixed(2)}')),
              ]);
            }).toList(),
          ),
        )),
      ]),
    );
  }

  // REVENUE TREND
  Widget _trend(bool desktop, List<DriverSummary> f) {
    if (f.isEmpty || _rec.isEmpty) return const SizedBox.shrink();
    final ids = f.map((s) => s.driverId).toSet();
    final byD = <String, List<MergedRecord>>{};
    for (final r in _rec.where((r) => ids.contains(r.driverId))) {
      byD.putIfAbsent(r.driverId, () => []).add(r);
    }
    const ws = 50;
    final lines = f.asMap().entries.map((e) {
      final idx  = _sum.indexWhere((s) => s.driverId == e.value.driverId);
      final recs = byD[e.value.driverId] ?? [];
      final spots = <FlSpot>[];
      for (int w = 0; w * ws < recs.length; w++) {
        final chunk = recs.skip(w * ws).take(ws);
        spots.add(FlSpot(w.toDouble(), chunk.fold(0.0, (s, r) => s + r.incomeGenerated) / 1000));
      }
      return LineChartBarData(spots: spots, isCurved: true, color: _pc(idx), barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: _pc(idx).withOpacity(0.06)));
    }).toList();

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('REVENUE TREND (WEEKLY)', icon: Icons.show_chart),
        SizedBox(height: 220, child: LineChart(LineChartData(
          lineBarsData: lines, gridData: _grid(), borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 52,
                getTitlesWidget: (v, _) => Text('Rs.${v.toStringAsFixed(0)}K',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) => Text('W${v.toInt() + 1}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)))),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ))),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 6,
          children: f.map((s) {
            final idx = _sum.indexWhere((x) => x.driverId == s.driverId);
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 20, height: 3,
                  decoration: BoxDecoration(color: _pc(idx), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Text(s.driverId, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ]);
          }).toList()),
      ]),
    );
  }

  // OVERSPEED
  Widget _overspeed(bool desktop, List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    final sorted = [...f]..sort((a, b) => b.totalOverspeed.compareTo(a.totalOverspeed));
    final worst  = sorted.first;
    Color rc(int v) => v >= 1500 ? const Color(0xFFFF4D6D)
        : v >= 300 ? const Color(0xFFFF8C42) : v >= 50 ? const Color(0xFFFFB800) : const Color(0xFF00E5A0);
    String rt(int v) => v >= 1500 ? 'CRITICAL' : v >= 300 ? 'HIGH' : v >= 50 ? 'MEDIUM' : 'LOW';

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('OVERSPEED VIOLATIONS', icon: Icons.speed),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFF4D6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.4))),
          child: Row(children: [
            const Icon(Icons.warning, color: Color(0xFFFF4D6D), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'WORST: ${worst.driverName} - ${worst.totalOverspeed} violations - Max ${worst.maxSpeedKmph.toStringAsFixed(0)} km/h',
              style: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: BarChart(BarChartData(
          barGroups: sorted.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value.totalOverspeed.toDouble(), color: rc(e.value.totalOverspeed),
                width: desktop ? 22 : 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          ])).toList(),
          gridData: _grid(), borderData: FlBorderData(show: false),
          titlesData: _bt(bl: sorted.map((s) => s.driverId).toList(), lf: (v) => _fmt(v)),
          barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.cardColor,
            getTooltipItem: (g, _, rod, __) {
              final s = sorted[g.x];
              return BarTooltipItem(
                '${s.driverName}\n${s.totalOverspeed} violations\nTier: ${rt(s.totalOverspeed)}',
                const TextStyle(color: Colors.white, fontSize: 10));
            })),
        ))),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 4, children: [
          _dot(const Color(0xFFFF4D6D), 'Critical >=1500'),
          _dot(const Color(0xFFFF8C42), 'High >=300'),
          _dot(const Color(0xFFFFB800), 'Medium >=50'),
          _dot(const Color(0xFF00E5A0), 'Low <50'),
        ]),
        const SizedBox(height: 16),
        GlassCard(padding: EdgeInsets.zero, child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.04)),
            dataRowColor: WidgetStateProperty.all(Colors.transparent),
            columnSpacing: 14, horizontalMargin: 12,
            headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 11),
            columns: const [
              DataColumn(label: Text('RNK')),
              DataColumn(label: Text('DRIVER')),
              DataColumn(label: Text('CAR')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('VIOLATIONS'), numeric: true),
              DataColumn(label: Text('HARD BRK'),   numeric: true),
              DataColumn(label: Text('RAPID ACC'),  numeric: true),
              DataColumn(label: Text('MAX SPD'),    numeric: true),
              DataColumn(label: Text('TIER')),
              DataColumn(label: Text('% WORST')),
            ],
            rows: sorted.asMap().entries.map((e) {
              final rank = e.key + 1; final s = e.value;
              final tier = rt(s.totalOverspeed); final tc = rc(s.totalOverspeed);
              final pctW = worst.totalOverspeed > 0 ? s.totalOverspeed / worst.totalOverspeed : 0.0;
              return DataRow(cells: [
                DataCell(Text('$rank')),
                DataCell(Text(s.driverName, overflow: TextOverflow.ellipsis)),
                DataCell(Text(s.carName,    overflow: TextOverflow.ellipsis)),
                DataCell(_chip(s.driverType)),
                DataCell(Text('${s.totalOverspeed}',
                    style: TextStyle(color: tc, fontWeight: FontWeight.bold))),
                DataCell(Text('${s.totalHardBraking}',
                    style: const TextStyle(color: Color(0xFFFF8C42)))),
                DataCell(Text('${s.totalRapidAccel}',
                    style: const TextStyle(color: Color(0xFFB57BFF)))),
                DataCell(Text('${s.maxSpeedKmph.toStringAsFixed(0)} km/h')),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: tc.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tc.withOpacity(0.4))),
                  child: Text(tier, style: TextStyle(color: tc, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(SizedBox(width: 80, child: LinearProgressIndicator(value: pctW,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(tc), minHeight: 6))),
              ]);
            }).toList(),
          ),
        )),
      ]),
    );
  }

  // SAFETY SCORECARD
  Widget _safety(List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    double sc(DriverSummary s) => (100.0
        - (s.totalOverspeed / 30).clamp(0, 25)
        - (s.totalHardBraking / 20).clamp(0, 20)
        - (s.totalRapidAccel / 20).clamp(0, 15)
        - (s.avgBrakeWear / 5).clamp(0, 15)
        - ((s.maxSpeedKmph - 80) / 10).clamp(0, 15)).clamp(0, 100);
    final sorted = [...f]..sort((a, b) => sc(b).compareTo(sc(a)));

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('SAFETY SCORECARD', icon: Icons.shield),
        ...sorted.asMap().entries.map((e) {
          final s = e.value; final score = sc(s);
          final idx = _sum.indexWhere((x) => x.driverId == s.driverId);
          final c = score >= 75 ? const Color(0xFF00E5A0)
              : score >= 50 ? const Color(0xFFFFB800) : const Color(0xFFFF4D6D);
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            SizedBox(width: 22, child: Text('${e.key + 1}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: _pc(idx), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.driverName, style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text(s.carName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
                  overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            _chip(s.driverType),
            const SizedBox(width: 10),
            Text(score.toStringAsFixed(0),
                style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: score / 100,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(c), minHeight: 6))),
            const SizedBox(width: 10),
            Wrap(spacing: 5, children: [
              _badge('Ov: ${s.totalOverspeed}',               const Color(0xFFFF4D6D)),
              _badge('HB: ${s.totalHardBraking}',              const Color(0xFFFF8C42)),
              _badge('RA: ${s.totalRapidAccel}',               const Color(0xFFB57BFF)),
              _badge('${s.maxSpeedKmph.toStringAsFixed(0)}k', const Color(0xFF00D4FF)),
            ]),
          ]));
        }),
      ]),
    );
  }

  Widget _badge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3))),
    child: Text(l, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));

  // COMPARE MODE
  Widget _compare(bool desktop, List<DriverSummary> f) {
    final sel = f.where((s) => _sel.contains(s.driverId)).toList();
    if (sel.length < 2) return GlassCard(child: const Center(child:
        Text('Select 2+ drivers to compare', style: TextStyle(color: AppTheme.textSecondary))));

    Widget card(DriverSummary s) {
      final idx = _sum.indexWhere((x) => x.driverId == s.driverId);
      return Expanded(child: GlassCard(borderColor: _pc(idx),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: _pc(idx), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: Text(s.driverName, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
          ]),
          Text(s.carName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          Text('${s.brand} - ${s.driverType}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
          const SizedBox(height: 10),
          ...<(String, String)>[
            ('Trips',        '${s.trips}'),
            ('Revenue',      'Rs.${_fmt(s.totalIncome)}'),
            ('Distance',     '${_fmt(s.totalDistKm)} km'),
            ('Energy',       '${_fmt(s.totalEnergyKwh)} kWh'),
            ('Overspeeds',   '${s.totalOverspeed}'),
            ('Hard Brake',   '${s.totalHardBraking}'),
            ('Rapid Accel',  '${s.totalRapidAccel}'),
            ('Avg Battery',  '${s.avgBatteryHealth.toStringAsFixed(1)}%'),
            ('Avg RUL',      '${s.avgRUL.toStringAsFixed(0)} days'),
            ('Avg Speed',    '${s.avgSpeedKmph.toStringAsFixed(1)} km/h'),
            ('Max Speed',    '${s.maxSpeedKmph.toStringAsFixed(0)} km/h'),
            ('Driver Score', s.baseDriverScore.toStringAsFixed(1)),
            ('Brake Wear',   '${s.avgBrakeWear.toStringAsFixed(1)}%'),
            ('Breakdown',    '${(s.avgBreakdownProb * 100).toStringAsFixed(1)}%'),
          ].map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.$1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                Text(r.$2, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ]))),
        ]),
      ));
    }

    final mxI = sel.map((s) => s.totalIncome).reduce((a, b) => a > b ? a : b);
    final mxD = sel.map((s) => s.totalDistKm).reduce((a, b) => a > b ? a : b);
    final mxE = sel.map((s) => s.efficiencyWhPerKm).reduce((a, b) => a > b ? a : b);
    final mxB = sel.map((s) => s.avgBatteryHealth).reduce((a, b) => a > b ? a : b);
    final mxS = sel.map((s) => s.avgSpeedKmph).reduce((a, b) => a > b ? a : b);
    const mc  = [Color(0xFF00A3FF), Color(0xFF00E5A0), Color(0xFFFFB800), Color(0xFF00D4FF), Color(0xFFB57BFF)];

    final normBars = sel.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
      BarChartRodData(toY: mxI > 0 ? e.value.totalIncome / mxI * 100 : 0,              color: mc[0], width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
      BarChartRodData(toY: mxD > 0 ? e.value.totalDistKm / mxD * 100 : 0,              color: mc[1], width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
      BarChartRodData(toY: mxE > 0 ? (1 - e.value.efficiencyWhPerKm / mxE) * 100 : 0, color: mc[2], width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
      BarChartRodData(toY: mxB > 0 ? e.value.avgBatteryHealth / mxB * 100 : 0,         color: mc[3], width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
      BarChartRodData(toY: mxS > 0 ? e.value.avgSpeedKmph / mxS * 100 : 0,             color: mc[4], width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
    ])).toList();

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('COMPARISON MODE  -  ${sel.length} DRIVERS', icon: Icons.compare_arrows),
        if (desktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: sel.map(card).toList())
        else
          Column(children: sel.map((s) =>
              Padding(padding: const EdgeInsets.only(bottom: 12), child: card(s))).toList()),
        const SizedBox(height: 20),
        _sh('NORMALISED COMPARISON (0-100 scale)', icon: Icons.bar_chart),
        SizedBox(height: 220, child: BarChart(BarChartData(
          barGroups: normBars, gridData: _grid(), borderData: FlBorderData(show: false), maxY: 105,
          titlesData: _bt(bl: sel.map((s) => s.driverId).toList(),
              lf: (v) => v.toStringAsFixed(0)),
        ))),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 6, children: [
          _dot(mc[0], 'Income'), _dot(mc[1], 'Distance'),
          _dot(mc[2], 'Efficiency (inv)'), _dot(mc[3], 'Battery'), _dot(mc[4], 'Speed'),
        ]),
      ]),
    );
  }

  // BATTERY + RUL
  Widget _battery(bool desktop, List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    final sorted = [...f]..sort((a, b) => b.avgBatteryHealth.compareTo(a.avgBatteryHealth));
    Color bc(double v) => v >= 95 ? const Color(0xFF00E5A0) : v >= 90 ? const Color(0xFFFFB800) : const Color(0xFFFF4D6D);
    final maxRUL = sorted.map((s) => s.avgRUL).fold(0.0, (a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('BATTERY HEALTH & REMAINING USEFUL LIFE', icon: Icons.battery_full),
        SizedBox(height: 220, child: BarChart(BarChartData(
          minY: 85, maxY: 100,
          barGroups: sorted.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value.avgBatteryHealth, color: bc(e.value.avgBatteryHealth),
                width: desktop ? 22 : 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          ])).toList(),
          gridData: _grid(), borderData: FlBorderData(show: false),
          titlesData: _bt(bl: sorted.map((s) => s.driverId).toList(),
              lf: (v) => '${v.toStringAsFixed(0)}%'),
          barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.cardColor,
            getTooltipItem: (g, _, rod, __) {
              final s = sorted[g.x];
              return BarTooltipItem(
                '${s.driverName}\n${s.avgBatteryHealth.toStringAsFixed(1)}%\nRUL: ${s.avgRUL.toStringAsFixed(0)} days',
                const TextStyle(color: Colors.white, fontSize: 10));
            })),
        ))),
        const SizedBox(height: 14),
        const Text('REMAINING USEFUL LIFE (days)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        ...sorted.map((s) {
          final frac = maxRUL > 0 ? s.avgRUL / maxRUL : 0.0;
          final idx  = _sum.indexWhere((x) => x.driverId == s.driverId);
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
            SizedBox(width: 70, child: Text(s.driverId,
                style: TextStyle(color: _pc(idx), fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: frac,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(_pc(idx)), minHeight: 8))),
            const SizedBox(width: 10),
            Text('${s.avgRUL.toStringAsFixed(0)} days',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ]));
        }),
      ]),
    );
  }

  // BREAKDOWN RISK
  Widget _breakdown(List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    final sorted = [...f]..sort((a, b) => b.avgBreakdownProb.compareTo(a.avgBreakdownProb));
    Color rc(double v) => v >= 0.14 ? const Color(0xFFFF4D6D)
        : v >= 0.10 ? const Color(0xFFFFB800) : const Color(0xFF00E5A0);

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('BREAKDOWN PROBABILITY RISK', icon: Icons.report_problem),
        SizedBox(height: 220, child: BarChart(BarChartData(
          barGroups: sorted.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value.avgBreakdownProb * 100, color: rc(e.value.avgBreakdownProb),
                width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          ])).toList(),
          gridData: _grid(), borderData: FlBorderData(show: false),
          titlesData: _bt(bl: sorted.map((s) => s.driverId).toList(),
              lf: (v) => '${v.toStringAsFixed(1)}%'),
          barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.cardColor,
            getTooltipItem: (g, _, rod, __) {
              final s = sorted[g.x];
              return BarTooltipItem(
                '${s.driverName}\n${(s.avgBreakdownProb * 100).toStringAsFixed(2)}% risk',
                const TextStyle(color: Colors.white, fontSize: 10));
            })),
        ))),
      ]),
    );
  }

  // DRIVER TYPE INSIGHTS
  Widget _driverTypes(bool desktop, List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();

    Widget card(String type, List<DriverSummary> drivers) {
      if (drivers.isEmpty) return Expanded(child: const SizedBox.shrink());
      final c = type == 'Safe' ? const Color(0xFF00E5A0)
          : type == 'Aggressive' ? const Color(0xFFFF4D6D) : const Color(0xFFFFB800);
      final avgInc   = drivers.fold(0.0, (s, d) => s + d.totalIncome) / drivers.length;
      final avgOs    = drivers.fold(0.0, (s, d) => s + d.totalOverspeed) / drivers.length;
      final avgBatt  = drivers.fold(0.0, (s, d) => s + d.avgBatteryHealth) / drivers.length;
      final avgScore = drivers.fold(0.0, (s, d) => s + d.baseDriverScore) / drivers.length;

      return Expanded(child: GlassCard(borderColor: c,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withOpacity(0.4))),
                child: Text(type.toUpperCase(),
                    style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold))),
            const Spacer(),
            Text('${drivers.length} drivers',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ]),
          const SizedBox(height: 12),
          ...<(String, String)>[
            ('Avg Revenue',  'Rs.${_fmt(avgInc)}'),
            ('Avg Overspd',  avgOs.toStringAsFixed(0)),
            ('Avg Battery',  '${avgBatt.toStringAsFixed(1)}%'),
            ('Avg Score',    avgScore.toStringAsFixed(1)),
          ].map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.$1, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                Text(r.$2, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
              ]))),
          const SizedBox(height: 10),
          Wrap(spacing: 5, runSpacing: 5,
            children: drivers.map((d) {
              final idx = _sum.indexWhere((x) => x.driverId == d.driverId);
              return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: _pc(idx).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _pc(idx).withOpacity(0.3))),
                  child: Text(d.driverId,
                      style: TextStyle(color: _pc(idx), fontSize: 9, fontWeight: FontWeight.bold)));
            }).toList()),
        ]),
      ));
    }

    final safe   = f.where((s) => s.driverType == 'Safe').toList();
    final normal = f.where((s) => s.driverType == 'Normal').toList();
    final agg    = f.where((s) => s.driverType == 'Aggressive').toList();

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('DRIVER TYPE INSIGHTS', icon: Icons.people),
        if (desktop)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            card('Safe', safe), const SizedBox(width: 12),
            card('Normal', normal), const SizedBox(width: 12),
            card('Aggressive', agg),
          ])
        else
          Column(children: [
            card('Safe', safe), const SizedBox(height: 10),
            card('Normal', normal), const SizedBox(height: 10),
            card('Aggressive', agg),
          ]),
      ]),
    );
  }

  // FLEET ALERTS
  Widget _alerts(List<DriverSummary> f) {
    if (f.isEmpty) return const SizedBox.shrink();
    final list = <_Al>[];
    for (final s in f) {
      if (s.totalOverspeed >= 1500) list.add(_Al(3, 'CRITICAL: Extreme Overspeed',
          '${s.driverName} - ${s.totalOverspeed} violations', const Color(0xFFFF4D6D), Icons.speed));
      else if (s.totalOverspeed >= 300) list.add(_Al(2, 'HIGH: Overspeed Risk',
          '${s.driverName} - ${s.totalOverspeed} violations', const Color(0xFFFF8C42), Icons.warning_amber));
      if (s.avgBatteryHealth < 92) list.add(_Al(2, 'HIGH: Low Battery Health',
          '${s.driverName} - ${s.avgBatteryHealth.toStringAsFixed(1)}%', const Color(0xFFFFB800), Icons.battery_alert));
      if (s.avgBreakdownProb > 0.14) list.add(_Al(3, 'CRITICAL: Breakdown Risk',
          '${s.driverName} - ${(s.avgBreakdownProb * 100).toStringAsFixed(1)}%', const Color(0xFFFF4D6D), Icons.report_problem));
      if (s.maxDaysSinceService > 60) list.add(_Al(2, 'HIGH: Overdue Service',
          '${s.carName} - ${s.maxDaysSinceService} days since service', const Color(0xFFFF8C42), Icons.build));
      if (s.avgBrakeWear > 25) list.add(_Al(1, 'MEDIUM: Brake Wear',
          '${s.driverName} - ${s.avgBrakeWear.toStringAsFixed(1)}%', const Color(0xFFFFB800), Icons.disc_full));
    }
    list.sort((a, b) => b.sev.compareTo(a.sev));

    if (list.isEmpty) return GlassCard(child: Row(children: const [
      Icon(Icons.check_circle, color: Color(0xFF00E5A0), size: 18), SizedBox(width: 8),
      Text('No active alerts.', style: TextStyle(color: Color(0xFF00E5A0), fontSize: 12)),
    ]));

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _sh('FLEET ALERTS  (${list.length})', icon: Icons.notifications_active),
        ...list.map((a) => Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(color: a.col.withOpacity(0.07), borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: a.col, width: 3))),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Icon(a.icon, color: a.col, size: 16), const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: TextStyle(color: a.col, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(a.msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ))),
      ]),
    );
  }
}

class _Al {
  final int sev;
  final String title, msg;
  final Color col;
  final IconData icon;
  const _Al(this.sev, this.title, this.msg, this.col, this.icon);
}
