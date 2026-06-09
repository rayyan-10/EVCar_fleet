import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/driver_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../utils/constants.dart';
import '../widgets/glass_widgets.dart';

class LoginScreen extends StatefulWidget {
  final String selectedRole;
  const LoginScreen({super.key, required this.selectedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthMode { login, register, forgotPassword }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _authMode = AuthMode.login;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _autofillDemo() {
    if (widget.selectedRole == 'admin') {
      _usernameController.text = AppConstants.demoAdminUsername;
      _passwordController.text = AppConstants.demoAdminPassword;
    } else {
      _usernameController.text = AppConstants.demoDriverUsername;
      _passwordController.text = AppConstants.demoDriverPassword;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authCtrl = Provider.of<AuthController>(context, listen: false);
    final driverCtrl = Provider.of<DriverController>(context, listen: false);
    final adminCtrl = Provider.of<AdminController>(context, listen: false);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (_authMode == AuthMode.forgotPassword) {
      final ok = await authCtrl.forgotPassword(username);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset link sent to your registered email.'),
          backgroundColor: AppTheme.primaryBlue,
        ));
        setState(() => _authMode = AuthMode.login);
      }
      return;
    }

    bool success = false;
    if (_authMode == AuthMode.login) {
      success = await authCtrl.login(username, password);
    } else {
      success = await authCtrl.register(username, password, widget.selectedRole);
    }

    if (!success || !mounted) return;

    final user = authCtrl.currentUser;
    if (user == null) return;

    if (user.role == 'driver') {
      await driverCtrl.fetchVehicleData(user.id);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        driverCtrl.isOnboarded ? AppRoutes.driverDashboard : AppRoutes.onboarding,
        (route) => false,
      );
    } else if (user.role == 'admin') {
      await adminCtrl.fetchAdminData();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Provider.of<AuthController>(context);
    final isDemoMode = SupabaseService().isDemoMode;
    final size = MediaQuery.of(context).size;

    String headingText;
    String subText;
    if (_authMode == AuthMode.login) {
      headingText = widget.selectedRole == 'admin' ? 'ADMIN PANEL' : 'DRIVER SIGN IN';
      subText = 'Enter your username and password';
    } else if (_authMode == AuthMode.register) {
      headingText = 'CREATE ACCOUNT';
      subText = 'Register as a ${widget.selectedRole} to begin';
    } else {
      headingText = 'RESET PASSWORD';
      subText = 'Enter your username to receive a reset link';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () { authCtrl.clearError(); Navigator.pop(context); },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: size.height * 0.1,
            right: size.width * 0.1,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.12), blurRadius: 120, spreadRadius: 30)],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassCard(
                  blur: 25,
                  opacity: 0.08,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mode badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDemoMode ? Colors.orangeAccent : Colors.greenAccent).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: (isDemoMode ? Colors.orangeAccent : Colors.greenAccent).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isDemoMode ? Icons.science_outlined : Icons.cloud_done_outlined, size: 13, color: isDemoMode ? Colors.orangeAccent : Colors.greenAccent),
                                const SizedBox(width: 6),
                                Text(
                                  isDemoMode ? 'DEMO MODE — Mock Data' : 'LIVE — Supabase Connected',
                                  style: TextStyle(color: isDemoMode ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(widget.selectedRole == 'admin' ? Icons.admin_panel_settings_rounded : Icons.drive_eta_rounded, size: 36, color: AppTheme.primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(headingText, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 24), textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(subText, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 28),

                        // Error banner
                        if (authCtrl.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(authCtrl.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Username
                        GlassTextField(
                          controller: _usernameController,
                          labelText: 'Username',
                          hintText: 'e.g. john_driver',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your username';
                            if (v.trim().length < 3) return 'Username must be at least 3 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Password (not on forgot password screen)
                        if (_authMode != AuthMode.forgotPassword) ...[
                          GlassTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter your password';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),

                          // Confirm password on register
                          if (_authMode == AuthMode.register) ...[
                            const SizedBox(height: 18),
                            GlassTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please confirm your password';
                                if (v != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ],

                          // Forgot password link on login
                          if (_authMode == AuthMode.login) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () { authCtrl.clearError(); setState(() => _authMode = AuthMode.forgotPassword); },
                                child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 20),

                        // Demo autofill — login only
                        if (_authMode == AuthMode.login) ...[
                          OutlinedButton.icon(
                            onPressed: _autofillDemo,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.flash_on, color: AppTheme.primaryBlue, size: 18),
                            label: const Text('Autofill Demo Account', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit
                        GlassButton(
                          text: _authMode == AuthMode.login ? 'SIGN IN' : _authMode == AuthMode.register ? 'CREATE ACCOUNT' : 'SEND RESET LINK',
                          isLoading: authCtrl.isLoading,
                          onPressed: _handleSubmit,
                        ),
                        const SizedBox(height: 24),

                        // Toggle login/register
                        if (_authMode != AuthMode.forgotPassword)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _authMode == AuthMode.login ? "Don't have an account?  " : 'Already have an account?  ',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () { authCtrl.clearError(); setState(() => _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login); },
                                child: Text(
                                  _authMode == AuthMode.login ? 'Register' : 'Sign In',
                                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),

                        if (_authMode == AuthMode.forgotPassword) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () { authCtrl.clearError(); setState(() => _authMode = AuthMode.login); },
                              child: const Text('Back to Sign In', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
