import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';
import '../../models/speed_violation_model.dart';
import '../widgets/web_helper_non_web.dart'
    if (dart.library.html) '../widgets/web_helper_web.dart' as web_helper;

class SpeedViolationsTab extends StatefulWidget {
  const SpeedViolationsTab({Key? key}) : super(key: key);

  @override
  State<SpeedViolationsTab> createState() => _SpeedViolationsTabState();
}

class _SpeedViolationsTabState extends State<SpeedViolationsTab> {
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _searchQuery = '';
  String _sortColumn = 'violated_at';
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    // Helper to resolve driver names from the loaded vehicle profiles
    String getDriverName(String driverId) {
      try {
        final vehicle = controller.allVehicles.firstWhere((v) => v.driverId == driverId);
        return vehicle.driverName;
      } catch (_) {
        return 'Unknown Driver';
      }
    }

    // Filter violations
    final query = _searchQuery.toLowerCase();
    final filteredViolations = controller.violations.where((v) {
      final driverName = getDriverName(v.driverId).toLowerCase();
      final matchesDriver = v.driverIdStr.toLowerCase().contains(query) ||
          v.driverId.toLowerCase().contains(query) ||
          driverName.contains(query);
      final matchesCar = v.carName.toLowerCase().contains(query);
      return matchesDriver || matchesCar;
    }).toList();

    // Sort violations
    filteredViolations.sort((a, b) {
      dynamic valA;
      dynamic valB;

      switch (_sortColumn) {
        case 'violated_at':
          valA = a.violatedAt;
          valB = b.violatedAt;
          break;
        case 'driver_id_str':
          valA = a.driverIdStr;
          valB = b.driverIdStr;
          break;
        case 'driver_name':
          valA = getDriverName(a.driverId);
          valB = getDriverName(b.driverId);
          break;
        case 'car_name':
          valA = a.carName;
          valB = b.carName;
          break;
        case 'speed_kmph':
          valA = a.speedKmph;
          valB = b.speedKmph;
          break;
        case 'excess_kmph':
          valA = a.excessKmph;
          valB = b.excessKmph;
          break;
        default:
          valA = a.violatedAt;
          valB = b.violatedAt;
      }

      if (valA is String) {
        return _sortAscending
            ? valA.compareTo(valB as String)
            : (valB as String).compareTo(valA);
      } else if (valA is num) {
        return _sortAscending
            ? valA.compareTo(valB as num)
            : (valB as num).compareTo(valA);
      } else if (valA is DateTime) {
        return _sortAscending
            ? valA.compareTo(valB as DateTime)
            : (valB as DateTime).compareTo(valA);
      }
      return 0;
    });

    // Pagination
    final totalViolations = filteredViolations.length;
    final totalPages = (totalViolations / _rowsPerPage).ceil().clamp(1, 99999);
    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final paginatedViolations = filteredViolations.isEmpty
        ? <SpeedViolationModel>[]
        : filteredViolations.sublist(
            startIndex,
            (startIndex + _rowsPerPage).clamp(0, totalViolations),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Controls row
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search input
              Container(
                width: isDesktop ? 350 : double.infinity,
                child: GlassTextField(
                  controller: TextEditingController(text: _searchQuery)
                    ..selection = TextSelection.collapsed(offset: _searchQuery.length),
                  labelText: 'Search Violations...',
                  hintText: 'Driver ID, Name, or Car Model',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16, width: 16),
              
              // Export / Actions Group
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await controller.refreshViolations();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Speed violations data refreshed successfully.'),
                            backgroundColor: AppTheme.accentPurple,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple.withOpacity(0.12),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppTheme.accentPurple, width: 0.8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.accentPurple),
                    label: const Text('Refresh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  _buildExportButton(
                    label: 'Export CSV',
                    icon: Icons.grid_on_rounded,
                    onPressed: () => _exportViolationsCSV(filteredViolations, getDriverName),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Table Card
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.white.withOpacity(0.02)),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 56,
                        columns: [
                          _buildHeaderCell('violated_at', 'Violation Time'),
                          _buildHeaderCell('driver_id_str', 'Driver ID'),
                          _buildHeaderCell('driver_name', 'Driver Name'),
                          _buildHeaderCell('car_name', 'Car Model'),
                          _buildHeaderCell('speed_kmph', 'Recorded Speed'),
                          _buildHeaderCell('excess_kmph', 'Excess Speed'),
                          const DataColumn(
                            label: Text('Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                        rows: List.generate(paginatedViolations.length, (idx) {
                          final v = paginatedViolations[idx];
                          final timeStr = DateFormat('MM/dd/yyyy hh:mm a').format(v.violatedAt);
                          
                          // Style based on severity
                          Color severityColor;
                          String severityText = v.severityLabel;
                          
                          if (v.isCritical) {
                            severityColor = AppTheme.criticalRed;
                          } else if (v.excessKmph >= 20) {
                            severityColor = AppTheme.amberAlert;
                          } else {
                            severityColor = AppTheme.primaryBlue;
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text(timeStr, style: const TextStyle(fontSize: 13))),
                              DataCell(Text(v.driverIdStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13))),
                              DataCell(Text(getDriverName(v.driverId), style: const TextStyle(fontSize: 13))),
                              DataCell(Text(v.carName, style: const TextStyle(fontSize: 13))),
                              DataCell(
                                Text(
                                  '${v.speedKmph.toStringAsFixed(1)} km/h',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: severityColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '+${v.excessKmph.toStringAsFixed(1)} km/h',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: severityColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: severityColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: severityColor.withOpacity(0.35), width: 0.8),
                                  ),
                                  child: Text(
                                    severityText,
                                    style: TextStyle(
                                      color: severityColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Pagination Panel
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.glassBorderColor, width: 0.8)),
                    color: Color(0x0AFFFFFF),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rows per page selector
                      Row(
                        children: [
                          const Text('Rows per page:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _rowsPerPage,
                            dropdownColor: AppTheme.cardColor,
                            underline: const SizedBox.shrink(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _rowsPerPage = val;
                                  _currentPage = 1;
                                });
                              }
                            },
                            items: [5, 10, 20].map((rows) {
                              return DropdownMenuItem<int>(
                                value: rows,
                                child: Text('$rows', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                      
                      // Page indicators
                      Row(
                        children: [
                          Text(
                            'Page $_currentPage of $totalPages ($totalViolations total)',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: _currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: _currentPage < totalPages
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataColumn _buildHeaderCell(String colId, String label) {
    final isSorted = _sortColumn == colId;
    return DataColumn(
      onSort: (_, __) {
        setState(() {
          if (_sortColumn == colId) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = colId;
            _sortAscending = true;
          }
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (isSorted) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.04),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.glassBorderColor, width: 0.8),
        ),
      ),
      icon: Icon(icon, size: 16, color: AppTheme.primaryBlue),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  void _exportViolationsCSV(List<SpeedViolationModel> list, String Function(String) getDriverName) {
    final headers = [
      'Violation Time', 'Driver ID String', 'Driver Name', 'Car Model',
      'Speed (km/h)', 'Speed Limit (km/h)', 'Excess Speed (km/h)', 'Severity'
    ];

    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (var v in list) {
      final values = [
        '"${v.violatedAt.toIso8601String()}"',
        '"${v.driverIdStr}"',
        '"${getDriverName(v.driverId)}"',
        '"${v.carName}"',
        v.speedKmph,
        v.limitKmph,
        v.excessKmph,
        '"${v.severityLabel}"'
      ];
      buffer.writeln(values.join(','));
    }

    try {
      final bytes = utf8.encode(buffer.toString());
      web_helper.downloadFile(bytes, 'speed_violations_export.csv');
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }
}
