import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/prediction_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomDateRange() async {
    final predCtrl = Provider.of<PredictionController>(context, listen: false);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              surface: AppTheme.cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Set end of day for the end date
      final endOfDay = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      predCtrl.setFilterType('Custom', start: picked.start, end: endOfDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final predCtrl = Provider.of<PredictionController>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PREDICTION RECORDS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient light glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.06),
                    blurRadius: 100,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search and filter panel
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Search field
                          GlassTextField(
                            controller: _searchController,
                            labelText: 'Search logs...',
                            hintText: 'Enter Car name or Driver ID',
                            prefixIcon: Icons.search_rounded,
                            onChanged: (val) {
                              predCtrl.setSearchQuery(val);
                            },
                          ),
                          const SizedBox(height: 18),
                          
                          // Filters row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(predCtrl, 'All', 'All Logs'),
                                const SizedBox(width: 8),
                                _buildFilterChip(predCtrl, 'Today', 'Today'),
                                const SizedBox(width: 8),
                                _buildFilterChip(predCtrl, 'Week', 'This Week'),
                                const SizedBox(width: 8),
                                _buildFilterChip(predCtrl, 'Month', 'This Month'),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  predCtrl,
                                  'Custom',
                                  predCtrl.historyFilterType == 'Custom' && predCtrl.customStart != null
                                      ? '${DateFormat('MM/dd').format(predCtrl.customStart!)} - ${DateFormat('MM/dd').format(predCtrl.customEnd!)}'
                                      : 'Custom Dates',
                                  onTap: _selectCustomDateRange,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Predictions History logs list
                    Expanded(
                      child: predCtrl.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : predCtrl.filteredHistory.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  itemCount: predCtrl.filteredHistory.length,
                                  separatorBuilder: (context, idx) => const SizedBox(height: 16),
                                  itemBuilder: (context, idx) {
                                    final pred = predCtrl.filteredHistory[idx];
                                    return _buildHistoryCard(pred);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(PredictionController ctrl, String type, String label, {VoidCallback? onTap}) {
    final isSelected = ctrl.historyFilterType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue.withOpacity(0.25),
      backgroundColor: Colors.white.withOpacity(0.02),
      onSelected: (_) {
        if (onTap != null) {
          onTap();
        } else {
          ctrl.setFilterType(type);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.6) : AppTheme.glassBorderColor,
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(var pred) {
    final dateStr = DateFormat('MMMM dd, yyyy - hh:mm a').format(pred.predictionDate);
    Color riskColor = Colors.greenAccent;
    if (pred.riskLevel == 'Medium') {
      riskColor = Colors.orangeAccent;
    } else if (pred.riskLevel == 'High') {
      riskColor = Colors.redAccent;
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Left details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pred.carName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pred.riskLevel.toUpperCase(),
                        style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Battery % indicator
                    Icon(Icons.battery_charging_full_rounded, size: 14, color: AppTheme.primaryBlue.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text(
                      'Battery: ${pred.batteryPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    // Efficiency score indicator
                    Icon(Icons.speed_rounded, size: 14, color: Colors.tealAccent.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text(
                      'Efficiency: ${pred.efficiencyScore.toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right Range highlight
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${pred.estimatedRange.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Text(
                'KM RANGE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No Prediction Records Found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Refine your active filters or log a new range calculation.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
