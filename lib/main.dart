import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/driver_controller.dart';
import 'controllers/prediction_controller.dart';
import 'controllers/admin_controller.dart';
import 'services/supabase_service.dart';
import 'utils/theme.dart';
import 'utils/routes.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SupabaseService (uses local mock db by default if keys are unchanged)
  final supabaseService = SupabaseService();
  await supabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController()..tryAutoLogin(),
        ),
        ChangeNotifierProvider<DriverController>(
          create: (_) => DriverController(),
        ),
        ChangeNotifierProvider<PredictionController>(
          create: (_) => PredictionController(),
        ),
        ChangeNotifierProvider<AdminController>(
          create: (_) => AdminController(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.roleSelection,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
