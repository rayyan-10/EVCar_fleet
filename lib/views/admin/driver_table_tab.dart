import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/theme.dart';
import '../widgets/glass_widgets.dart';

class DriverTableTab extends StatelessWidget {
  const DriverTableTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final vehicles = controller.paginatedVehiclesList;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action Controls row (Search + Export actions)
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Search input
              Container(
                width: isDesktop ? 300 : double.infinity,
                child: GlassTextField(
                  controller: TextEditingController(text: controller.driverIdQuery)..selection = TextSelection.collapsed(offset: controller.driverIdQuery.length),
                  labelText: 'Search Table...',
                  hintText: 'Enter Driver ID or Car name',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) {
                    controller.updateTextQueries(driverId: val);
                  },
                ),
              ),
              const SizedBox(height: 16, width: 16),
              
              // Export button group
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildExportButton(
                    label: 'Export CSV',
                    icon: Icons.grid_on_rounded,
                    onPressed: controller.exportCSV,
                  ),
                  _buildExportButton(
                    label: 'Export Excel',
                    icon: Icons.table_chart_outlined,
                    onPressed: controller.exportExcel,
                  ),
                  _buildExportButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: controller.exportPDFReport,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Responsive Scrollable Table Card
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
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 52,
                        columns: [
                          _buildHeaderCell(controller, 'driver_id_str', 'Driver ID'),
                          _buildHeaderCell(controller, 'driver_name', 'Driver Name'),
                          _buildHeaderCell(controller, 'email', 'Email Address'),
                          _buildHeaderCell(controller, 'car_name', 'Car Model'),
                          _buildHeaderCell(controller, 'battery_capacity', 'Battery (kWh)'),
                          _buildHeaderCell(controller, 'vehicle_weight', 'Weight (kg)'),
                          _buildHeaderCell(controller, 'current_speed', 'Speed (km/h)'),
                          _buildHeaderCell(controller, 'monthly_income', 'Income'),
                          _buildHeaderCell(controller, 'vehicle_condition', 'Condition'),
                          _buildHeaderCell(controller, 'running_type', 'Running Mode'),
                          _buildHeaderCell(controller, 'created_at', 'Created Date'),
                        ],
                        rows: List.generate(vehicles.length, (idx) {
                          final v = vehicles[idx];
                          final dateStr = v.createdAt != null
                              ? DateFormat('MM/dd/yyyy').format(v.createdAt!)
                              : v.currentDate;
                          return DataRow(
                            cells: [
                              DataCell(Text(v.driverIdStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                              DataCell(Text(v.driverName)),
                              DataCell(Text(v.email)),
                              DataCell(Text(v.carName)),
                              DataCell(Text('${v.batteryCapacity.toStringAsFixed(0)} kWh')),
                              DataCell(Text('${v.vehicleWeight.toStringAsFixed(0)} kg')),
                              DataCell(Text('${v.currentSpeed.toStringAsFixed(0)} km/h')),
                              DataCell(Text('\$${v.monthlyIncome.toStringAsFixed(0)}')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (v.vehicleCondition == 1 ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    v.vehicleCondition == 1 ? 'Working' : 'Garage',
                                    style: TextStyle(
                                      color: v.vehicleCondition == 1 ? Colors.greenAccent : Colors.orangeAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(v.runningType == 1 ? 'Highway' : 'City')),
                              DataCell(Text(dateStr)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                
                // Pagination panel
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
                            value: controller.rowsPerPage,
                            dropdownColor: AppTheme.cardColor,
                            underline: const SizedBox.shrink(),
                            onChanged: (val) {
                              if (val != null) controller.setRowsPerPage(val);
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
                            'Page ${controller.currentPage} of ${controller.totalPages}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: controller.currentPage > 1 ? () => controller.changePage(-1) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: controller.currentPage < controller.totalPages ? () => controller.changePage(1) : null,
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

  DataColumn _buildHeaderCell(AdminController controller, String colId, String label) {
    final isSorted = controller.sortColumn == colId;
    return DataColumn(
      onSort: (_, __) {
        controller.setSort(colId);
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (isSorted) ...[
            const SizedBox(width: 4),
            Icon(
              controller.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
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
}
