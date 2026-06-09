import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/telemetry_model.dart';
import '../../services/telemetry_csv_service.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

// ─────────────────────────────────────────────
// Driver palette – one colour per driver ID
// ─────────────────────────────────────────────
const List<Color> _driverPalette = [
  Color(0xFF00A3FF), Color(0xFF00E5A0), Color(0xFFFFB800),
  Color(0xFFFF4D6D), Color(0xFFB57BFF), Color(0xFF00D4FF),
  Color(0xFFFF8C42), Color(0xFF6EEB83), Color(0xFFE040FB),
  Color(0xFFFFD166),
];

Color _driverColor(String driverId, List<String> allDrivers) {
  final idx = allDrivers.indexOf(driverId);
  return _driverPalette[idx % _driverPalette.length];
}

// ─────────────────────────────────────────────
// Date-range preset enum
// ─────────────────────────────────────────────
enum _DatePreset { all, last1m, last2m, last3m, custom }

extension _DatePresetLabel on _DatePreset {
  String get label {
    switch (this) {
      case _DatePreset.all:    return 'All Time';
      case _DatePreset.last1m: return 'Last 1 Month';
      case _DatePreset.last2m: return 'Last 2 Months';
      case _DatePreset.last3m: return 'Last 3 Months';
      case _DatePreset.custom: return 'Custom';
    }
  }
}

// ─────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────
class TelemetryKpiDashboard extends StatefulWidget {
  const TelemetryKpiDashboard({Key? key}) : super(key: key);
  @override
  State<TelemetryKpiDashboard> createState() => _TelemetryKpiDashboardState();
}

class _TelemetryKpiDashboardState extends State<TelemetryKpiDashboard> {
  List<TelemetryRecord> _all = [];
  List<TelemetryRecord> _filtered = [];
  bool _loading = true;

  // Multi-driver selection (empty = all)
  Set<String> _selectedDrivers = {};
  String? _selectedBrand;
  String? _selectedWeather;
  int? _selectedMode;

  // Date range
  _DatePreset _datePreset = _DatePreset.all;
  DateTime? _customStart, _customEnd;

  // Comparison mode
  bool _compareMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await TelemetryCsvService().loadRecords();
    setState(() {
      _all = records;
      _applyFilters();
      _loading = false;
    });
  }

  DateTime? get _dateStart {
    final now = _all.isNotEmpty
        ? _all.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();
    switch (_datePreset) {
      case _DatePreset.last1m: return now.subtract(const Duration(days: 30));
      case _DatePreset.last2m: return now.subtract(const Duration(days: 60));
      case _DatePreset.last3m: return now.subtract(const Duration(days: 90));
      case _DatePreset.custom: return _customStart;
      default: return null;
    }
  }

  void _applyFilters() {
    final start = _dateStart;
    _filtered = _all.where((r) {
      if (_selectedDrivers.isNotEmpty && !_selectedDrivers.contains(r.driverId)) return false;
      if (_selectedBrand   != null && r.brand             != _selectedBrand)   return false;
      if (_selectedWeather != null && r.weatherCondition  != _selectedWeather) return false;
      if (_selectedMode    != null && r.runningMode        != _selectedMode)    return false;
      if (start != null && r.timestamp.isBefore(start))                        return false;
      if (_datePreset == _DatePreset.custom && _customEnd != null &&
          r.timestamp.isAfter(_customEnd!))                                     return false;
      return true;
    }).toList();
  }

  void _resetFilters() => setState(() {
    _selectedDrivers = {};
    _selectedBrand   = null;
    _selectedWeather = null;
    _selectedMode    = null;
    _datePreset      = _DatePreset.all;
    _customStart     = null;
    _customEnd       = null;
    _applyFilters();
  });

  List<String> get _allDrivers  => _all.map((r) => r.driverId).toSet().toList()..sort();
  List<String> get _allBrands   => _all.map((r) => r.brand).toSet().toList()..sort();
  List<String> get _allWeathers => _all.map((r) => r.weatherCondition).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_all.isEmpty) {
      return const Center(
          child: Text('No telemetry data found.',
              style: TextStyle(color: AppTheme.textSecondary)));
    }
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // drivers that are actually in filtered set
    final activeDrivers = _filtered.map((r) => r.driverId).toSet().toList()..sort();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Filter panel ──────────────────────
        _FilterPanel(
          allDrivers: _allDrivers,
          allBrands: _allBrands,
          allWeathers: _allWeathers,
          selectedDrivers: _selectedDrivers,
          selectedBrand: _selectedBrand,
          selectedWeather: _selectedWeather,
          selectedMode: _selectedMode,
          datePreset: _datePreset,
          compareMode: _compareMode,
          recordCount: _filtered.length,
          onDriverToggle: (d) => setState(() {
            _selectedDrivers.contains(d) ? _selectedDrivers.remove(d) : _selectedDrivers.add(d);
            _applyFilters();
          }),
          onBrandChanged:   (v) => setState(() { _selectedBrand   = v; _applyFilters(); }),
          onWeatherChanged: (v) => setState(() { _selectedWeather = v; _applyFilters(); }),
          onModeChanged:    (v) => setState(() { _selectedMode    = v; _applyFilters(); }),
          onDatePreset:     (p) => setState(() { _datePreset      = p; _applyFilters(); }),
          onCompareModeToggle: () => setState(() => _compareMode = !_compareMode),
          onReset: _resetFilters,
        ),
        const SizedBox(height: 20),

        // ── KPI strip ─────────────────────────
        _KpiStrip(records: _filtered, isDesktop: isDesktop),
        const SizedBox(height: 24),

        // ── Charts ────────────────────────────
        if (_compareMode && activeDrivers.length >= 2)
          _ComparisonPanel(
              records: _filtered,
              drivers: activeDrivers,
              allDrivers: _allDrivers,
              isDesktop: isDesktop)
        else
          _ChartsGrid(
              records: _filtered,
              allDrivers: _allDrivers,
              isDesktop: isDesktop),

        const SizedBox(height: 24),

        // ── Leaderboard ───────────────────────
        _DriverLeaderboard(records: _filtered, allDrivers: _allDrivers),
        const SizedBox(height: 24),

        // ── Alerts ────────────────────────────
        _AlertsPanel(records: _filtered),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Panel  (multi-driver chips + date presets)
// ─────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  final List<String> allDrivers, allBrands, allWeathers;
  final Set<String> selectedDrivers;
  final String? selectedBrand, selectedWeather;
  final int? selectedMode;
  final _DatePreset datePreset;
  final bool compareMode;
  final int recordCount;
  final void Function(String) onDriverToggle;
  final ValueChanged<String?> onBrandChanged, onWeatherChanged;
  final ValueChanged<int?> onModeChanged;
  final ValueChanged<_DatePreset> onDatePreset;
  final VoidCallback onCompareModeToggle, onReset;

  const _FilterPanel({
    required this.allDrivers, required this.allBrands, required this.allWeathers,
    required this.selectedDrivers, required this.selectedBrand,
    required this.selectedWeather, required this.selectedMode,
    required this.datePreset, required this.compareMode,
    required this.recordCount, required this.onDriverToggle,
    required this.onBrandChanged, required this.onWeatherChanged,
    required this.onModeChanged, required this.onDatePreset,
    required this.onCompareModeToggle, required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(width: 8),
          const Text('FILTERS & CONTROLS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          const Spacer(),
          // Record badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            ),
            child: Text('$recordCount records',
                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 12),
          // Compare toggle
          _ToggleChip(
            label: 'Compare Mode',
            icon: Icons.compare_arrows_rounded,
            active: compareMode,
            activeColor: Colors.amberAccent,
            onTap: onCompareModeToggle,
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, size: 15, color: AppTheme.textSecondary),
            label: const Text('Reset', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ),
        ]),
        const Divider(color: AppTheme.glassBorderColor, height: 20),

        // ── Row 1: Date presets ──
        const Text('DATE RANGE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10,
            fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: _DatePreset.values.where((p) => p != _DatePreset.custom).map((p) {
          final active = datePreset == p;
          return _ToggleChip(
            label: p.label, active: active,
            activeColor: AppTheme.primaryBlue,
            onTap: () => onDatePreset(p),
          );
        }).toList()),
        const SizedBox(height: 16),

        // ── Row 2: Driver multi-select ──
        const Text('SELECT DRIVERS  (tap to toggle, select multiple to compare)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6,
          children: allDrivers.asMap().entries.map((e) {
            final d = e.value;
            final color = _driverPalette[e.key % _driverPalette.length];
            final active = selectedDrivers.contains(d);
            return GestureDetector(
              onTap: () => onDriverToggle(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? color : AppTheme.glassBorderColor,
                    width: active ? 1.5 : 0.8,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(d, style: TextStyle(
                    color: active ? color : Colors.white70,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  )),
                  if (active) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.check_rounded, size: 13, color: color),
                  ],
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // ── Row 3: Other dropdowns ──
        Wrap(spacing: 10, runSpacing: 8, children: [
          _DropFilter<String>(label: 'Brand', value: selectedBrand, items: allBrands,
              lb: (v) => v, onChanged: onBrandChanged),
          _DropFilter<String>(label: 'Weather', value: selectedWeather, items: allWeathers,
              lb: (v) => v, onChanged: onWeatherChanged),
          _DropFilter<int>(label: 'Mode', value: selectedMode, items: const [0, 1],
              lb: (v) => v == 0 ? 'City' : 'Highway', onChanged: onModeChanged),
        ]),
      ]),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final IconData? icon;
  const _ToggleChip({required this.label, required this.active, required this.activeColor,
      required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.7) : AppTheme.glassBorderColor, width: 0.8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: active ? activeColor : Colors.white60), const SizedBox(width: 5)],
          Text(label, style: TextStyle(
            color: active ? activeColor : Colors.white60,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          )),
        ]),
      ),
    );
  }
}

class _DropFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) lb;
  final ValueChanged<T?> onChanged;
  const _DropFilter({required this.label, required this.value, required this.items,
      required this.lb, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.glassBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: const Color(0xFF131320),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          hint: Text('All $label', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          items: [
            DropdownMenuItem<T>(value: null, child: Text('All $label')),
            ...items.map((v) => DropdownMenuItem<T>(value: v, child: Text(lb(v)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// KPI Strip
// ─────────────────────────────────────────────
class _KpiStrip extends StatelessWidget {
  final List<TelemetryRecord> records;
  final bool isDesktop;
  const _KpiStrip({required this.records, required this.isDesktop});

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final n           = records.length;
    final totalIncome = records.fold(0.0, (s, r) => s + r.incomeGenerated);
    final totalDist   = records.fold(0.0, (s, r) => s + r.tripDistanceKm);
    final totalEnergy = records.fold(0.0, (s, r) => s + r.energyConsumedKwh);
    final avgBatt     = records.map((r) => r.batteryHealthPct).reduce((a, b) => a + b) / n;
    final avgSpeed    = records.map((r) => r.avgSpeedKmph).reduce((a, b) => a + b) / n;
    final totalOver   = records.fold(0, (s, r) => s + r.overspeedEvents);
    final totalBrake  = records.fold(0, (s, r) => s + r.hardBrakingEvents);
    final avgIdle     = records.map((r) => r.idleTimeMinutes).reduce((a, b) => a + b) / n;
    final uniqueDrivers = records.map((r) => r.driverId).toSet().length;
    final avgSoc      = records.map((r) => r.socEndPct).reduce((a, b) => a + b) / n;

    final kpis = [
      _KD('TOTAL TRIPS',         '$n',                              Icons.route_rounded,              AppTheme.primaryBlue),
      _KD('TOTAL INCOME',        '₹${_fmt(totalIncome)}',          Icons.currency_rupee_rounded,     Colors.greenAccent),
      _KD('DISTANCE COVERED',    '${_fmt(totalDist)} km',          Icons.map_outlined,               Colors.tealAccent),
      _KD('ENERGY CONSUMED',     '${_fmt(totalEnergy)} kWh',       Icons.bolt_rounded,               Colors.amberAccent),
      _KD('AVG BATTERY HEALTH',  '${avgBatt.toStringAsFixed(1)}%', Icons.battery_charging_full,      Colors.lightGreenAccent),
      _KD('AVG SPEED',           '${avgSpeed.toStringAsFixed(1)} km/h', Icons.speed_rounded,         AppTheme.primaryBlue),
      _KD('SAFETY EVENTS',       '${totalOver + totalBrake}',      Icons.warning_amber_rounded,      Colors.orangeAccent),
      _KD('AVG IDLE TIME',       '${avgIdle.toStringAsFixed(1)} min', Icons.timer_off_outlined,      Colors.pinkAccent),
      _KD('AVG SOC END',         '${avgSoc.toStringAsFixed(1)}%',  Icons.electric_car_outlined,      Colors.cyanAccent),
      _KD('ACTIVE DRIVERS',      '$uniqueDrivers',                 Icons.people_outline_rounded,     Colors.purpleAccent),
    ];

    return GridView.count(
      crossAxisCount: isDesktop ? 5 : 2,
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 2.2 : 1.9,
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      gradientColors: [
        data.color.withOpacity(0.05),
        Colors.white.withOpacity(0.02),
      ],
      borderColor: data.color.withOpacity(0.2),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.label, style: const TextStyle(color: AppTheme.textSecondary,
                fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 5),
            Text(data.value, style: const TextStyle(color: Colors.white,
                fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        )),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: data.color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(data.icon, color: data.color, size: 18),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Charts Grid  (rich, interactive)
// ─────────────────────────────────────────────
class _ChartsGrid extends StatefulWidget {
  final List<TelemetryRecord> records;
  final List<String> allDrivers;
  final bool isDesktop;
  const _ChartsGrid({required this.records, required this.allDrivers, required this.isDesktop});
  @override
  State<_ChartsGrid> createState() => _ChartsGridState();
}

class _ChartsGridState extends State<_ChartsGrid> {
  int _ti = -1, _ts = -1, _tw = -1, _tm = -1; // touched indices

  List<String> get _drivers => widget.records.map((r) => r.driverId).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return GlassCard(child: const Center(child: Padding(padding: EdgeInsets.all(32),
          child: Text('No data for selected filters.',
              style: TextStyle(color: AppTheme.textSecondary)))));
    }

    return Column(children: [
      // Row A: 2 wide charts
      _row2([
        _card('💰  Revenue by Driver', _incomeChart()),
        _card('⚡  Energy Efficiency (Wh/km)', _efficiencyChart()),
      ]),
      const SizedBox(height: 20),
      // Row B: line chart full-width
      _card1('🔋  Battery Health Trend Over Time', _battTrendMultiLine()),
      const SizedBox(height: 20),
      // Row C: 2 charts
      _row2([
        _card('🌦️  Trips by Weather', _weatherDonut()),
        _card('🛣️  City vs Highway', _modeDonut()),
      ]),
      const SizedBox(height: 20),
      // Row D: income trend line
      _card1('📈  Income Trend Over Time (weekly)', _incomeTrendLine()),
      const SizedBox(height: 20),
      // Row E: 2 charts
      _row2([
        _card('🚨  Safety Events per Driver', _safetyGroupedBar()),
        _card('📉  SOC Drop Distribution', _socDropChart()),
      ]),
      const SizedBox(height: 20),
      // Row F: speed dist + idle time
      _row2([
        _card('🏎️  Speed Distribution', _speedDistChart()),
        _card('⏱️  Avg Idle Time by Driver', _idleTimeChart()),
      ]),
    ]);
  }

  Widget _row2(List<Widget> children) {
    if (widget.isDesktop) {
      return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.map((c) => Expanded(child: c)).toList()),
      );
    }
    return Column(children: [
      children[0],
      const SizedBox(height: 20),
      children[1],
    ]);
  }

  Widget _card(String title, Widget body) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        const Divider(color: AppTheme.glassBorderColor, height: 14),
        SizedBox(height: 200, child: body),
      ]),
    );
  }

  Widget _card1(String title, Widget body) {
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        const Divider(color: AppTheme.glassBorderColor, height: 14),
        SizedBox(height: 220, child: body),
      ]),
    );
  }

  // ── Chart helpers ────────────────────────────

  // 1. Revenue bar with gradient rods
  Widget _incomeChart() {
    final d = _drivers;
    final incomes = d.map((id) =>
        widget.records.where((r) => r.driverId == id).fold(0.0, (s, r) => s + r.incomeGenerated) / 1000).toList();

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${d[g.x]}\n₹${rod.toY.toStringAsFixed(1)}K',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        touchCallback: (e, r) => setState(() => _ti = r?.spot?.touchedBarGroupIndex ?? -1),
      ),
      barGroups: List.generate(d.length, (i) {
        final color = _driverColor(d[i], widget.allDrivers);
        final touched = i == _ti;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: incomes[i], width: touched ? 18 : 14,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.5), color],
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: (incomes.reduce((a, b) => a > b ? a : b) * 1.1),
              color: Colors.white.withOpacity(0.03),
            ),
          )
        ]);
      }),
      titlesData: _td(
        left: (v) => '₹${v.toStringAsFixed(0)}K',
        bottom: (v) {
          final idx = v.toInt();
          return idx >= 0 && idx < d.length ? d[idx].replaceAll('D0', 'D') : '';
        },
      ),
      gridData: _gd(), borderData: FlBorderData(show: false),
    ));
  }

  // 2. Efficiency color-coded bar
  Widget _efficiencyChart() {
    final d = _drivers;
    final effs = d.map((id) {
      final recs = widget.records.where((r) => r.driverId == id).toList();
      final e    = recs.fold(0.0, (s, r) => s + r.energyConsumedKwh);
      final dist = recs.fold(0.0, (s, r) => s + r.tripDistanceKm);
      return dist > 0 ? (e * 1000) / dist : 0.0;
    }).toList();

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${d[g.x]}\n${rod.toY.toStringAsFixed(1)} Wh/km',
            const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
      barGroups: List.generate(d.length, (i) {
        final eff = effs[i];
        final color = eff > 200 ? Colors.redAccent : eff > 150 ? Colors.orangeAccent : Colors.greenAccent;
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: eff, width: 14, color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: effs.reduce((a, b) => a > b ? a : b) * 1.1,
              color: Colors.white.withOpacity(0.03),
            ),
          )
        ]);
      }),
      titlesData: _td(
        left: (v) => '${v.toStringAsFixed(0)}',
        bottom: (v) {
          final idx = v.toInt();
          return idx >= 0 && idx < d.length ? d[idx].replaceAll('D0', 'D') : '';
        },
      ),
      gridData: _gd(), borderData: FlBorderData(show: false),
    ));
  }

  // 3. Battery health multi-line (one line per driver)
  Widget _battTrendMultiLine() {
    final d = _drivers;
    final lines = <LineChartBarData>[];

    for (final id in d) {
      final color = _driverColor(id, widget.allDrivers);
      final dayMap = <int, List<double>>{};
      for (final r in widget.records.where((r) => r.driverId == id)) {
        final day = r.timestamp.difference(DateTime(2024)).inDays;
        dayMap.putIfAbsent(day, () => []).add(r.batteryHealthPct);
      }
      final days  = (dayMap.keys.toList()..sort()).take(42).toList();
      final spots = days.asMap().entries.map((e) {
        final avg = dayMap[e.value]!.reduce((a, b) => a + b) / dayMap[e.value]!.length;
        return FlSpot(e.value.toDouble(), avg);
      }).toList();

      lines.add(LineChartBarData(
        spots: spots, color: color, isCurved: true, barWidth: 2,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: color.withOpacity(0.05)),
      ));
    }

    return Stack(children: [
      LineChart(LineChartData(
        lineBarsData: lines,
        titlesData: _td(
          left:   (v) => '${v.toStringAsFixed(0)}%',
          bottom: (v) => 'D${v.toInt() + 1}',
          bottomInterval: 7,
        ),
        gridData: _gd(), borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (ss) => ss.asMap().entries.map((e) {
              final color = e.key < d.length ? _driverColor(d[e.key], widget.allDrivers) : Colors.white;
              final dId   = e.key < d.length ? d[e.key] : '';
              return LineTooltipItem(
                '$dId: ${e.value.y.toStringAsFixed(1)}%',
                TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11));
            }).toList(),
          ),
        ),
      )),
      // Legend
      Positioned(top: 0, right: 0,
        child: Wrap(spacing: 10, children: d.asMap().entries.map((e) {
          final color = _driverColor(e.value, widget.allDrivers);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text(e.value, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ]);
        }).toList()),
      ),
    ]);
  }

  // 4. Weather donut
  Widget _weatherDonut() {
    final map = <String, int>{};
    for (final r in widget.records) map[r.weatherCondition] = (map[r.weatherCondition] ?? 0) + 1;
    final entries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total   = widget.records.length;
    final colors  = [AppTheme.primaryBlue, const Color(0xFF00E5A0), Colors.amberAccent,
                     Colors.purpleAccent, Colors.orangeAccent, Colors.pinkAccent];

    return PieChart(PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (e, r) => setState(() => _tw = r?.touchedSection?.touchedSectionIndex ?? -1),
      ),
      sectionsSpace: 3, centerSpaceRadius: 44,
      sections: List.generate(entries.length, (i) {
        final touched = i == _tw;
        final pct = entries[i].value / total * 100;
        return PieChartSectionData(
          color: colors[i % colors.length],
          value: entries[i].value.toDouble(),
          title: touched ? '${entries[i].key}\n${pct.toStringAsFixed(1)}%' : '${pct.toStringAsFixed(0)}%',
          radius: touched ? 56 : 46,
          titleStyle: TextStyle(fontSize: touched ? 11 : 9, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }),
    ));
  }

  // 5. Mode donut
  Widget _modeDonut() {
    final city  = widget.records.where((r) => r.runningMode == 0).length;
    final hwy   = widget.records.where((r) => r.runningMode == 1).length;
    final total = city + hwy;
    if (total == 0) return _nd();

    return PieChart(PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (e, r) => setState(() => _tm = r?.touchedSection?.touchedSectionIndex ?? -1),
      ),
      sectionsSpace: 4, centerSpaceRadius: 44,
      sections: [
        PieChartSectionData(
          color: AppTheme.primaryBlue, value: city.toDouble(),
          title: _tm == 0 ? 'City\n${(city/total*100).toStringAsFixed(1)}%' : '${(city/total*100).toStringAsFixed(0)}%',
          radius: _tm == 0 ? 56 : 46,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(
          color: Colors.indigoAccent, value: hwy.toDouble(),
          title: _tm == 1 ? 'Highway\n${(hwy/total*100).toStringAsFixed(1)}%' : '${(hwy/total*100).toStringAsFixed(0)}%',
          radius: _tm == 1 ? 56 : 46,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    ));
  }

  // 6. Income trend line (weekly buckets)
  Widget _incomeTrendLine() {
    final d = _drivers;
    final lines = <LineChartBarData>[];

    // Compute min timestamp
    final minTs = widget.records.map((r) => r.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);

    for (final id in d) {
      final color   = _driverColor(id, widget.allDrivers);
      final weekMap = <int, double>{};
      for (final r in widget.records.where((r) => r.driverId == id)) {
        final week = r.timestamp.difference(minTs).inDays ~/ 7;
        weekMap[week] = (weekMap[week] ?? 0) + r.incomeGenerated / 1000;
      }
      final weeks = weekMap.keys.toList()..sort();
      final spots = weeks.map((w) => FlSpot(w.toDouble(), weekMap[w]!)).toList();

      lines.add(LineChartBarData(
        spots: spots, color: color, isCurved: true, barWidth: 2,
        dotData: FlDotData(show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color)),
        belowBarData: BarAreaData(show: true, color: color.withOpacity(0.05)),
      ));
    }

    return Stack(children: [
      LineChart(LineChartData(
        lineBarsData: lines,
        titlesData: _td(
          left:   (v) => '₹${v.toStringAsFixed(0)}K',
          bottom: (v) => 'Wk${(v.toInt() + 1)}',
        ),
        gridData: _gd(), borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (ss) => ss.asMap().entries.map((e) {
              final color = e.key < d.length ? _driverColor(d[e.key], widget.allDrivers) : Colors.white;
              final dId   = e.key < d.length ? d[e.key] : '';
              return LineTooltipItem('$dId: ₹${e.value.y.toStringAsFixed(1)}K',
                  TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11));
            }).toList(),
          ),
        ),
      )),
      Positioned(top: 0, right: 0,
        child: Wrap(spacing: 10, children: d.asMap().entries.map((e) {
          final color = _driverColor(e.value, widget.allDrivers);
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text(e.value, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ]);
        }).toList()),
      ),
    ]);
  }

  // 7. Safety grouped bar
  Widget _safetyGroupedBar() {
    final d       = _drivers;
    final overspd = d.map((id) =>
        widget.records.where((r) => r.driverId == id).fold(0, (s, r) => s + r.overspeedEvents).toDouble()).toList();
    final braking = d.map((id) =>
        widget.records.where((r) => r.driverId == id).fold(0, (s, r) => s + r.hardBrakingEvents).toDouble()).toList();
    final rapid   = d.map((id) =>
        widget.records.where((r) => r.driverId == id).fold(0, (s, r) => s + r.rapidAccelerationEvents).toDouble()).toList();

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, ri) {
            final labels = ['Overspeed', 'Hard Brake', 'Rapid Accel'];
            return BarTooltipItem(
              '${d[g.x]}\n${labels[ri]}: ${rod.toY.toInt()}',
              const TextStyle(color: Colors.white, fontSize: 11));
          },
        ),
      ),
      barGroups: List.generate(d.length, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: overspd[i], width: 7, color: Colors.orangeAccent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: braking[i], width: 7, color: Colors.redAccent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: rapid[i],   width: 7, color: Colors.purpleAccent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
        ],
        barsSpace: 2,
      )),
      titlesData: _td(
        left:   (v) => v.toStringAsFixed(0),
        bottom: (v) {
          final idx = v.toInt();
          return idx >= 0 && idx < d.length ? d[idx].replaceAll('D0', 'D') : '';
        },
      ),
      gridData: _gd(), borderData: FlBorderData(show: false),
    ));
  }

  // 8. SOC drop
  Widget _socDropChart() {
    final d     = _drivers;
    final drops = d.map((id) {
      final recs = widget.records.where((r) => r.driverId == id).toList();
      return recs.isEmpty ? 0.0 : recs.map((r) => r.socDrop).reduce((a, b) => a + b) / recs.length;
    }).toList();

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${d[g.x]}\nDrop: ${rod.toY.toStringAsFixed(1)}%',
            const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
      barGroups: List.generate(d.length, (i) {
        final color = _driverColor(d[i], widget.allDrivers);
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: drops[i], width: 14,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.4), color],
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]);
      }),
      titlesData: _td(
        left:   (v) => '${v.toStringAsFixed(0)}%',
        bottom: (v) {
          final idx = v.toInt();
          return idx >= 0 && idx < d.length ? d[idx].replaceAll('D0', 'D') : '';
        },
      ),
      gridData: _gd(), borderData: FlBorderData(show: false),
    ));
  }

  // 9. Speed dist
  Widget _speedDistChart() {
    final labels = ['<30', '30-50', '50-70', '70-90', '90-110', '110+'];
    final counts = List.filled(6, 0.0);
    for (final r in widget.records) {
      final s = r.avgSpeedKmph;
      if (s < 30) counts[0]++;
      else if (s < 50) counts[1]++;
      else if (s < 70) counts[2]++;
      else if (s < 90) counts[3]++;
      else if (s < 110) counts[4]++;
      else counts[5]++;
    }
    final colors = [Colors.tealAccent, Colors.greenAccent, AppTheme.primaryBlue,
                    Colors.amberAccent, Colors.orangeAccent, Colors.redAccent];

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${labels[g.x]} km/h\n${rod.toY.toInt()} trips',
            const TextStyle(color: Colors.white, fontSize: 11)),
        ),
        touchCallback: (e, r) => setState(() => _ts = r?.spot?.touchedBarGroupIndex ?? -1),
      ),
      barGroups: List.generate(labels.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: counts[i], width: 18,
            color: i == _ts ? Colors.white : colors[i],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      ])),
      titlesData: _td(left: (v) => v.toStringAsFixed(0), bottom: (v) => labels[v.toInt()]),
      gridData: _gd(), borderData: FlBorderData(show: false),
    ));
  }

  // 10. Idle time
  Widget _idleTimeChart() {
    final d     = _drivers;
    final idles = d.map((id) {
      final recs = widget.records.where((r) => r.driverId == id).toList();
      return recs.isEmpty ? 0.0 : recs.map((r) => r.idleTimeMinutes).reduce((a, b) => a + b) / recs.length;
    }).toList();

    return BarChart(BarChartData(
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItem: (g, _, rod, __) => BarTooltipItem(
            '${d[g.x]}\n${rod.toY.toStringAsFixed(1)} min',
            const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
      barGroups: List.generate(d.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: idles[i], width: 14,
          gradient: LinearGradient(
            colors: [Colors.pinkAccent.withOpacity(0.4), Colors.pinkAccent],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ])),
      titlesData: _td(
        left: (v) => '${v.toStringAsFixed(0)}',
        bottom: (v) {
          final idx = v.toInt();
          return idx >= 0 && idx < d.length ? d[idx].replaceAll('D0', 'D') : '';
        },
      ),
      gridData: _gd(), borderData: FlBorderData(show: false),
    ));
  }

  // ── Shared chart helpers ─────────────────────
  FlTitlesData _td({
    required String Function(double) left,
    required String Function(double) bottom,
    double? bottomInterval,
  }) {
    return FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 38,
        getTitlesWidget: (v, _) =>
            Text(left(v), style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      )),
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true,
        interval: bottomInterval,
        getTitlesWidget: (v, _) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(bottom(v), style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        ),
      )),
      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _gd() => FlGridData(
    show: true, drawVerticalLine: false,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1),
  );

  Widget _nd() => const Center(
      child: Text('No data', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)));
}

// ─────────────────────────────────────────────
// Comparison Panel  (side-by-side per driver)
// ─────────────────────────────────────────────
class _ComparisonPanel extends StatelessWidget {
  final List<TelemetryRecord> records;
  final List<String> drivers, allDrivers;
  final bool isDesktop;
  const _ComparisonPanel({
    required this.records, required this.drivers,
    required this.allDrivers, required this.isDesktop,
  });

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    // Build per-driver summary
    final summaries = drivers.map((id) {
      final recs    = records.where((r) => r.driverId == id).toList();
      final income  = recs.fold(0.0, (s, r) => s + r.incomeGenerated);
      final dist    = recs.fold(0.0, (s, r) => s + r.tripDistanceKm);
      final energy  = recs.fold(0.0, (s, r) => s + r.energyConsumedKwh);
      final avgBatt = recs.isEmpty ? 0.0 : recs.map((r) => r.batteryHealthPct).reduce((a, b) => a + b) / recs.length;
      final avgSpd  = recs.isEmpty ? 0.0 : recs.map((r) => r.avgSpeedKmph).reduce((a, b) => a + b) / recs.length;
      final overspd = recs.fold(0, (s, r) => s + r.overspeedEvents);
      final braking = recs.fold(0, (s, r) => s + r.hardBrakingEvents);
      final eff     = dist > 0 ? (energy * 1000) / dist : 0.0;
      final avgIdle = recs.isEmpty ? 0.0 : recs.map((r) => r.idleTimeMinutes).reduce((a, b) => a + b) / recs.length;
      return _DriverSummary(id: id, trips: recs.length, income: income, distKm: dist,
          efficiency: eff, avgBatt: avgBatt, avgSpeed: avgSpd, overspeed: overspd,
          hardBrake: braking, avgIdle: avgIdle, brand: recs.isNotEmpty ? recs.first.brand : '',
          carName: recs.isNotEmpty ? recs.first.carName : '');
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Header
      GlassCard(
        borderColor: Colors.amberAccent.withOpacity(0.3),
        gradientColors: [Colors.amberAccent.withOpacity(0.04), Colors.transparent],
        child: Row(children: [
          const Icon(Icons.compare_arrows_rounded, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          const Text('DRIVER COMPARISON MODE', style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 13, letterSpacing: 0.5, color: Colors.amberAccent)),
          const SizedBox(width: 8),
          Text('Comparing ${drivers.length} drivers',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),

      // Driver cards
      isDesktop
          ? IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: summaries.map((s) =>
                      Expanded(child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _DriverCompareCard(s: s, allDrivers: allDrivers)))).toList()))
          : Column(children: summaries.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DriverCompareCard(s: s, allDrivers: allDrivers))).toList()),

      const SizedBox(height: 20),

      // Radar-style comparison bar chart
      _CompareBarChart(summaries: summaries, allDrivers: allDrivers),
    ]);
  }
}

class _DriverSummary {
  final String id, brand, carName;
  final int trips, overspeed, hardBrake;
  final double income, distKm, efficiency, avgBatt, avgSpeed, avgIdle;
  const _DriverSummary({
    required this.id, required this.brand, required this.carName,
    required this.trips, required this.overspeed, required this.hardBrake,
    required this.income, required this.distKm, required this.efficiency,
    required this.avgBatt, required this.avgSpeed, required this.avgIdle,
  });
}

class _DriverCompareCard extends StatelessWidget {
  final _DriverSummary s;
  final List<String> allDrivers;
  const _DriverCompareCard({required this.s, required this.allDrivers});

  String _fmt(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final color = _driverColor(s.id, allDrivers);
    return GlassCard(
      borderColor: color.withOpacity(0.35),
      gradientColors: [color.withOpacity(0.06), Colors.transparent],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(s.id, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        Text('${s.brand} ${s.carName}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const Divider(color: AppTheme.glassBorderColor, height: 16),
        _stat('Trips',       '${s.trips}',                   Icons.route_rounded),
        _stat('Income',      '₹${_fmt(s.income)}',           Icons.currency_rupee_rounded),
        _stat('Distance',    '${_fmt(s.distKm)} km',         Icons.map_outlined),
        _stat('Efficiency',  '${s.efficiency.toStringAsFixed(1)} Wh/km', Icons.bolt_rounded),
        _stat('Avg Batt.',   '${s.avgBatt.toStringAsFixed(1)}%', Icons.battery_charging_full),
        _stat('Avg Speed',   '${s.avgSpeed.toStringAsFixed(1)} km/h', Icons.speed_rounded),
        _stat('Overspeed',   '${s.overspeed}',               Icons.warning_amber_rounded),
        _stat('Hard Braking','${s.hardBrake}',               Icons.car_crash_outlined),
        _stat('Avg Idle',    '${s.avgIdle.toStringAsFixed(1)} min', Icons.timer_off_outlined),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }
}

class _CompareBarChart extends StatelessWidget {
  final List<_DriverSummary> summaries;
  final List<String> allDrivers;
  const _CompareBarChart({required this.summaries, required this.allDrivers});

  @override
  Widget build(BuildContext context) {
    // Normalise 5 metrics to 0-100 for visual comparison
    final metrics = ['Income', 'Distance', 'Efficiency\n(inv)', 'Batt Health', 'Avg Speed'];

    // Normalize helper
    double norm(double v, double min, double max) =>
        max > min ? ((v - min) / (max - min) * 100).toDouble() : 50.0;

    final incomeMax = summaries.map((s) => s.income).reduce((a, b) => a > b ? a : b);
    final distMax   = summaries.map((s) => s.distKm).reduce((a, b) => a > b ? a : b);
    final effMax    = summaries.map((s) => s.efficiency).reduce((a, b) => a > b ? a : b);
    final speedMax  = summaries.map((s) => s.avgSpeed).reduce((a, b) => a > b ? a : b);

    final groups = summaries.asMap().entries.map((e) {
      final s     = e.value;
      final color = _driverColor(s.id, allDrivers);
      // efficiency is inverted (lower = better)
      final effScore = effMax > 0 ? (1 - s.efficiency / effMax) * 100.0 : 50.0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(toY: norm(s.income,   0.0, incomeMax), width: 10,
              color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: norm(s.distKm,   0.0, distMax),   width: 10,
              color: color.withOpacity(0.7), borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: effScore,                          width: 10,
              color: color.withOpacity(0.5), borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: s.avgBatt,                         width: 10,
              color: color.withOpacity(0.35), borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: norm(s.avgSpeed, 0.0, speedMax),  width: 10,
              color: color.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
        ],
        barsSpace: 2,
      );
    }).toList();

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('NORMALISED METRIC COMPARISON  (0–100 scale)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Wrap(spacing: 16, runSpacing: 4,
              children: metrics.map((m) => Text(m,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))).toList()),
        ),
        SizedBox(height: 200,
          child: BarChart(BarChartData(
            barGroups: groups,
            barTouchData: BarTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipRoundedRadius: 8,
                getTooltipItem: (g, _, rod, ri) => BarTooltipItem(
                  '${summaries[g.x].id}\n${metrics[ri]}: ${rod.toY.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) => Text('${v.toInt()}',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  return idx >= 0 && idx < summaries.length
                      ? Padding(padding: const EdgeInsets.only(top: 4),
                          child: Text(summaries[idx].id,
                              style: TextStyle(fontSize: 9,
                                  color: _driverColor(summaries[idx].id, allDrivers),
                                  fontWeight: FontWeight.bold)))
                      : const Text('');
                },
              )),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            maxY: 105,
          )),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// Driver Leaderboard
// ─────────────────────────────────────────────
class _DriverLeaderboard extends StatefulWidget {
  final List<TelemetryRecord> records;
  final List<String> allDrivers;
  const _DriverLeaderboard({required this.records, required this.allDrivers});
  @override
  State<_DriverLeaderboard> createState() => _DriverLeaderboardState();
}

class _DriverLeaderboardState extends State<_DriverLeaderboard> {
  String? _expanded;

  String _fmtK(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) return const SizedBox.shrink();

    final drivers = widget.records.map((r) => r.driverId).toSet().toList()..sort();
    final rows = drivers.map((d) {
      final recs    = widget.records.where((r) => r.driverId == d).toList();
      final income  = recs.fold(0.0, (s, r) => s + r.incomeGenerated);
      final dist    = recs.fold(0.0, (s, r) => s + r.tripDistanceKm);
      final energy  = recs.fold(0.0, (s, r) => s + r.energyConsumedKwh);
      final avgBatt = recs.map((r) => r.batteryHealthPct).reduce((a, b) => a + b) / recs.length;
      final overspd = recs.fold(0, (s, r) => s + r.overspeedEvents);
      final braking = recs.fold(0, (s, r) => s + r.hardBrakingEvents);
      final eff     = dist > 0 ? (energy * 1000) / dist : 0.0;
      return _LRow(driverId: d, brand: recs.first.brand, carName: recs.first.carName,
          trips: recs.length, income: income, distKm: dist, efficiency: eff,
          avgBattHealth: avgBatt, overspeed: overspd, hardBrake: braking);
    }).toList()..sort((a, b) => b.income.compareTo(a.income));

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.leaderboard_rounded, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 10),
          const Text('DRIVER PERFORMANCE LEADERBOARD',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          const Spacer(),
          const Text('Tap row to expand', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
        const Divider(color: AppTheme.glassBorderColor, height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(width: 28),
            Expanded(flex: 2, child: Text('DRIVER',     style: _hStyle)),
            Expanded(flex: 3, child: Text('VEHICLE',    style: _hStyle)),
            Expanded(child:   Text('TRIPS',             style: _hStyle, textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text('INCOME',     style: _hStyle, textAlign: TextAlign.right)),
            Expanded(flex: 2, child: Text('DISTANCE',   style: _hStyle, textAlign: TextAlign.right)),
            Expanded(flex: 2, child: Text('EFFICIENCY', style: _hStyle, textAlign: TextAlign.right)),
            Expanded(child:   Text('BATT%',             style: _hStyle, textAlign: TextAlign.right)),
          ]),
        ),
        ...rows.asMap().entries.map((e) => _rowWidget(e.key, e.value)),
      ]),
    );
  }

  Widget _rowWidget(int rank, _LRow row) {
    final expanded  = _expanded == row.driverId;
    final color     = _driverColor(row.driverId, widget.allDrivers);
    final rankColor = [Colors.amberAccent, Colors.grey.shade300, Colors.orange.shade400]
        .elementAtOrNull(rank) ?? AppTheme.textSecondary;

    return Column(children: [
      InkWell(
        onTap: () => setState(() => _expanded = expanded ? null : row.driverId),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: expanded ? color.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: expanded ? color : Colors.transparent, width: 3)),
          ),
          child: Row(children: [
            SizedBox(width: 24, child: Text('${rank + 1}',
                style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center)),
            const SizedBox(width: 4),
            Expanded(flex: 2, child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(row.driverId, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ])),
            Expanded(flex: 3, child: Text('${row.brand} ${row.carName}',
                style: const TextStyle(fontSize: 11, color: Colors.white), overflow: TextOverflow.ellipsis)),
            Expanded(child: Text('${row.trips}', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white))),
            Expanded(flex: 2, child: Text('₹${_fmtK(row.income)}', textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text('${_fmtK(row.distKm)} km', textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Colors.white))),
            Expanded(flex: 2, child: Text('${row.efficiency.toStringAsFixed(1)} Wh/km',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12,
                    color: row.efficiency > 200 ? Colors.redAccent : Colors.tealAccent))),
            Expanded(child: Text('${row.avgBattHealth.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12,
                    color: row.avgBattHealth > 85 ? Colors.greenAccent : Colors.orangeAccent))),
          ]),
        ),
      ),
      if (expanded) _expandDetail(row, color),
      const Divider(color: AppTheme.glassBorderColor, height: 1),
    ]);
  }

  Widget _expandDetail(_LRow row, Color color) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Wrap(spacing: 24, runSpacing: 10, children: [
          _stat('Total Income',    '₹${_fmtK(row.income)}',                  Colors.greenAccent),
          _stat('Distance',        '${_fmtK(row.distKm)} km',                Colors.tealAccent),
          _stat('Efficiency',      '${row.efficiency.toStringAsFixed(1)} Wh/km', Colors.amberAccent),
          _stat('Avg Battery',     '${row.avgBattHealth.toStringAsFixed(1)}%',
              row.avgBattHealth > 85 ? Colors.greenAccent : Colors.orangeAccent),
          _stat('Overspeed',       '${row.overspeed} events',                Colors.orangeAccent),
          _stat('Hard Braking',    '${row.hardBrake} events',                Colors.redAccent),
          _stat('Total Trips',     '${row.trips}',                           color),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    ],
  );
}

class _LRow {
  final String driverId, brand, carName;
  final int trips, overspeed, hardBrake;
  final double income, distKm, efficiency, avgBattHealth;
  const _LRow({
    required this.driverId, required this.brand, required this.carName,
    required this.trips, required this.overspeed, required this.hardBrake,
    required this.income, required this.distKm, required this.efficiency,
    required this.avgBattHealth,
  });
}

const _hStyle = TextStyle(
    color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5);

// ─────────────────────────────────────────────
// Alerts Panel
// ─────────────────────────────────────────────
class _AlertsPanel extends StatelessWidget {
  final List<TelemetryRecord> records;
  const _AlertsPanel({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final alerts = <_Al>[];
    final drivers = records.map((r) => r.driverId).toSet();

    for (final d in drivers) {
      final recs    = records.where((r) => r.driverId == d).toList();
      final avgBatt = recs.map((r) => r.batteryHealthPct).reduce((a, b) => a + b) / recs.length;
      final avgBrk  = recs.map((r) => r.brakeWearPct).reduce((a, b) => a + b) / recs.length;
      final avgSusp = recs.map((r) => r.suspensionHealthPct).reduce((a, b) => a + b) / recs.length;
      final maxDays = recs.map((r) => r.daysSinceLastService).reduce((a, b) => a > b ? a : b);
      final overspd = recs.fold(0, (s, r) => s + r.overspeedEvents);
      final car     = recs.first.carName;

      if (avgBatt < 85)  alerts.add(_Al('⚡ Battery Degradation', d, car, 'Avg ${avgBatt.toStringAsFixed(1)}% — below 85% threshold', Colors.redAccent));
      if (avgBrk  > 15)  alerts.add(_Al('🔧 Brake Wear High',     d, car, 'Avg ${avgBrk.toStringAsFixed(1)}% wear — service recommended', Colors.orangeAccent));
      if (avgSusp < 85)  alerts.add(_Al('🚗 Suspension Issue',     d, car, 'Avg ${avgSusp.toStringAsFixed(1)}% — inspect suspension', Colors.amberAccent));
      if (maxDays > 180) alerts.add(_Al('📅 Overdue Service',      d, car, '$maxDays days since last service — schedule immediately', Colors.pinkAccent));
      if (overspd > 20)  alerts.add(_Al('⚠️ Frequent Overspeed',  d, car, '$overspd events — driver safety coaching needed', Colors.deepOrangeAccent));
    }

    if (alerts.isEmpty) {
      return GlassCard(
        child: Row(children: const [
          Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),
          SizedBox(width: 12),
          Text('No critical alerts detected.', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 10),
          Text('FLEET ALERTS  (${alerts.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  letterSpacing: 0.5, color: Colors.orangeAccent)),
        ]),
        const Divider(color: AppTheme.glassBorderColor, height: 16),
        ...alerts.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: a.color.withOpacity(0.25)),
          ),
          child: Row(children: [
            Container(width: 4, height: 36,
                decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(a.title, style: TextStyle(color: a.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Text('${a.driverId} · ${a.carName}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Text(a.message, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
          ]),
        )),
      ]),
    );
  }
}

class _Al {
  final String title, driverId, carName, message;
  final Color color;
  const _Al(this.title, this.driverId, this.carName, this.message, this.color);
}
