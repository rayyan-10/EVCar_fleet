import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../views/auth/role_selection_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/driver/onboarding_screen.dart';
import '../views/driver/driver_dashboard.dart';
import '../views/driver/prediction_result_screen.dart';
import '../views/driver/history_screen.dart';
import '../views/admin/admin_dashboard.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static const String roleSelection = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String driverDashboard = '/driver/dashboard';
  static const String predictionResult = '/driver/prediction';
  static const String driverHistory = '/driver/history';
  static const String adminDashboard = '/admin/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final authController = Provider.of<AuthController>(context, listen: false);
        final isAuthenticated = authController.isAuthenticated;
        final userRole = authController.currentUser?.role;

        // Route Guard Helper
        Widget guardRoute(Widget child, String requiredRole) {
          if (!isAuthenticated) {
            // Not authenticated, redirect to role selection
            return const RoleSelectionScreen();
          }
          if (userRole != requiredRole) {
            // Unauthorized role access, redirect to role selection
            return const RoleSelectionScreen();
          }
          return child;
        }

        switch (settings.name) {
          case roleSelection:
            return const RoleSelectionScreen();
            
          case login:
            final args = settings.arguments as Map<String, dynamic>?;
            final selectedRole = args?['role'] as String? ?? 'driver';
            return LoginScreen(selectedRole: selectedRole);
            
          case onboarding:
            return guardRoute(const OnboardingScreen(), 'driver');
            
          case driverDashboard:
            return guardRoute(const DriverDashboard(), 'driver');
            
          case predictionResult:
            return guardRoute(const PredictionResultScreen(), 'driver');
            
          case driverHistory:
            return guardRoute(const DriverHistoryScreen(), 'driver');
            
          case adminDashboard:
            return guardRoute(const AdminDashboard(), 'admin');

          default:
            return Scaffold(
              body: Center(
                child: Text('404 Route Not Found: ${settings.name}'),
              ),
            );
        }
      },
    );
  }
}
