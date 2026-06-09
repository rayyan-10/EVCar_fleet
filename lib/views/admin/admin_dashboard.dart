import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../widgets/glass_widgets.dart';
import 'visualizations_tab.dart';
import 'driver_table_tab.dart';
import 'insights_tab.dart';
import 'telemetry_kpi_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _activeTab = 0; // 0=Overview, 1=Charts, 2=Table, 3=Insights
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Initial fetch of telemetry lists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminController>(context, listen: false).fetchAdminData();
    });
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildFilterDrawer(context),
      drawer: !isDesktop ? _buildMobileNavigationDrawer(context) : null,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.06),
                    blurRadius: 150,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Row(
              children: [
                // Desktop sidebar navigation
                if (isDesktop) _buildDesktopSidebar(context),

                // Main Dashboard Panel
                Expanded(
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top status header
                              _buildHeader(context, isDesktop),
                              const SizedBox(height: 24),

                              // Body content based on tab
                              Expanded(
                                child: _buildActiveTabContent(),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    String tabTitle = '';
    switch (_activeTab) {
      case 0: tabTitle = 'FLEET OPERATIONS OVERVIEW'; break;
      case 1: tabTitle = '20 ADVANCED VISUALIZATIONS'; break;
      case 2: tabTitle = 'DRIVER MANAGEMENT DATASHEET'; break;
      case 3: tabTitle = 'AUTOMATED STRATEGIC INSIGHTS'; break;
      case 4: tabTitle = 'TELEMETRY KPI DASHBOARD'; break;
    }

    return Row(
      children: [
        if (!isDesktop) ...[
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tabTitle,
                style: TextStyle(
                  fontSize: isDesktop ? 22 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Enterprise-grade telemetry control center',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        
        // Filter trigger button
        ElevatedButton.icon(
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            foregroundColor: AppTheme.primaryBlue,
            side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.filter_alt_outlined, size: 16),
          label: const Text('FILTERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0: return _buildOverviewTab();
      case 1: return const VisualizationsTab();
      case 2: return const DriverTableTab();
      case 3: return const InsightsTab();
      case 4: return const TelemetryKpiDashboard();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab() {
    final controller = Provider.of<AdminController>(context);
    final stats = controller.stats;
    final size = MediaQuery.of(context).size;
    final gridCount = size.width > 1200 ? 4 : (size.width > 700 ? 2 : 1);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 8 KPI Grid cards
          GridView.count(
            crossAxisCount: gridCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildKPICard('TOTAL REGISTERED DRIVERS', '${stats.totalDrivers}', Icons.people_outline, Colors.tealAccent),
              _buildKPICard('TOTAL FLEET VEHICLES', '${stats.totalVehicles}', Icons.directions_car_rounded, AppTheme.primaryBlue),
              _buildKPICard('ACTIVE OPERATIONAL VEHICLES', '${stats.activeVehicles}', Icons.check_circle_outline, Colors.greenAccent),
              _buildKPICard('GARAGE MODE STATUS', '${stats.garageVehicles}', Icons.build_circle_outlined, Colors.orangeAccent),
              _buildKPICard('AVERAGE ESTIMATED RANGE', '${stats.averageRange.toStringAsFixed(0)} KM', Icons.bolt, AppTheme.primaryBlue),
              _buildKPICard('AVERAGE FLEET EFFICIENCY', '${stats.averageEfficiency.toStringAsFixed(0)}%', Icons.speed_rounded, Colors.tealAccent),
              _buildKPICard('FLEET MONTHLY INCOME AVG', '\$${stats.averageMonthlyIncome.toStringAsFixed(0)}', Icons.monetization_on_outlined, Colors.amberAccent),
              _buildKPICard('TOTAL RANGE PREDICTIONS', '${stats.totalPredictions}', Icons.history_rounded, Colors.white),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Fleet overview text info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SYSTEM TELEMETRY SUMMARY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5, color: AppTheme.primaryBlue),
                ),
                const Divider(color: AppTheme.glassBorderColor, height: 20),
                const SizedBox(height: 8),
                const Text(
                  'The Drive Analysis Platform is currently connected in Demo mode. Real-time predictions are simulated using dynamic motor formulas. Applying global filters on the right pane will immediately re-index the KPIs, visualizations, spreadsheet exports, and insight triggers.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                    const SizedBox(width: 8),
                    const Text('Telemetry Database Status: Synchronized (In-Memory Fallback)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D18),
        border: Border(right: BorderSide(color: AppTheme.glassBorderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(width: 8),
              const Text(
                'DAP FLEET',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Menu items
          _buildSidebarTile(0, 'KPI Dashboard', Icons.dashboard_outlined),
          _buildSidebarTile(1, '20 Visualizations', Icons.analytics_outlined),
          _buildSidebarTile(2, 'Driver Table', Icons.table_view_outlined),
          _buildSidebarTile(3, 'Automated Insights', Icons.psychology_outlined),
          _buildSidebarTile(4, 'Telemetry KPIs', Icons.insert_chart_outlined),
          
          const Spacer(),

          // Profile admin details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.glassBorderColor, width: 0.8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Administrator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('System Node', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            onTap: _logout,
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            title: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary, size: 20),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavigationDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0D0D18),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('DAP FLEET NAVIGATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)),
              const Divider(color: AppTheme.glassBorderColor),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: Colors.white),
                title: const Text('KPI Dashboard'),
                onTap: () {
                  setState(() => _activeTab = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: Colors.white),
                title: const Text('20 Visualizations'),
                onTap: () {
                  setState(() => _activeTab = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_view_outlined, color: Colors.white),
                title: const Text('Driver Table'),
                onTap: () {
                  setState(() => _activeTab = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology_outlined, color: Colors.white),
                title: const Text('Fleet Insights'),
                onTap: () {
                  setState(() => _activeTab = 3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_chart_outlined, color: Colors.white),
                title: const Text('Telemetry KPIs'),
                onTap: () {
                  setState(() => _activeTab = 4);
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slide out filter drawer panel on right
  Widget _buildFilterDrawer(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final size = MediaQuery.of(context).size;
    final width = size.width > 450 ? 400.0 : size.width * 0.85;

    final driverIdController = TextEditingController(text: controller.driverIdQuery);
    final carNameController = TextEditingController(text: controller.carNameQuery);

    return Container(
      width: width,
      height: size.height,
      color: const Color(0xFF0D0D1B),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GLOBAL FILTERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(color: AppTheme.glassBorderColor),
            
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  
                  // Text match queries
                  GlassTextField(
                    controller: driverIdController,
                    labelText: 'Driver ID',
                    hintText: 'e.g. TESLA',
                    prefixIcon: Icons.badge_outlined,
                    onChanged: (val) {
                      controller.updateTextQueries(driverId: val);
                    },
                  ),
                  const SizedBox(height: 16),

                  GlassTextField(
                    controller: carNameController,
                    labelText: 'Car Name',
                    hintText: 'e.g. Taycan',
                    prefixIcon: Icons.directions_car_outlined,
                    onChanged: (val) {
                      controller.updateTextQueries(carName: val);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Running type dropdown selector
                  const Text('Running Mode Cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: controller.runningType,
                    dropdownColor: const Color(0xFF0D0D1B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Running Cycles')),
                      DropdownMenuItem(value: 0, child: Text('City Cruise')),
                      DropdownMenuItem(value: 1, child: Text('Highway Cruise')),
                    ],
                    onChanged: (val) {
                      controller.updateNumericalFilters(runningType: val ?? -1);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Condition selector
                  const Text('Condition Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: controller.vehicleCondition,
                    dropdownColor: const Color(0xFF0D0D1B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Conditions')),
                      DropdownMenuItem(value: 1, child: Text('Working Operational')),
                      DropdownMenuItem(value: 0, child: Text('Garage Mode')),
                    ],
                    onChanged: (val) {
                      controller.updateNumericalFilters(vehicleCondition: val ?? -1);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Preset time selectors
                  const Text('Temporal Quick Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPresetChip('Day', () {
                        controller.updateDateRange(DateTime.now().subtract(const Duration(days: 1)), DateTime.now());
                      }),
                      _buildPresetChip('Week', () {
                        controller.updateDateRange(DateTime.now().subtract(const Duration(days: 7)), DateTime.now());
                      }),
                      _buildPresetChip('Month', () {
                        controller.updateDateRange(DateTime.now().subtract(const Duration(days: 30)), DateTime.now());
                      }),
                      _buildPresetChip('Year', () {
                        controller.updateDateRange(DateTime.now().subtract(const Duration(days: 365)), DateTime.now());
                      }),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bottom control buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.resetFilters();
                      driverIdController.clear();
                      carNameController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.glassBorderColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('RESET ALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    text: 'APPLY',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: false,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.glassBorderColor, width: 0.8),
      ),
    );
  }
}
