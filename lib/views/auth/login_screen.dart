import 'dart:math';
import 'dart:ui' as ui;
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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AuthMode _authMode = AuthMode.login;

  late AnimationController _bgCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgCtrl.dispose();
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
      await driverCtrl.fetchVehicleData(user.id, authUser: user);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        driverCtrl.isOnboarded ? AppRoutes.driverDashboard : AppRoutes.onboarding,
        (route) => false,
      );
    } else if (user.role == 'admin') {
      await adminCtrl.fetchAdminData();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.adminDashboard, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Provider.of<AuthController>(context);
    final isDemoMode = SupabaseService().isDemoMode;
    final size = MediaQuery.of(context).size;
    final isDriver = widget.selectedRole == 'driver';

    String headingText;
    String subText;
    if (_authMode == AuthMode.login) {
      headingText = isDriver ? 'DRIVER SIGN IN' : 'ADMIN PANEL';
      subText = 'Enter your credentials to continue';
    } else if (_authMode == AuthMode.register) {
      headingText = 'CREATE ACCOUNT';
      subText = 'Register as a ${widget.selectedRole} to begin';
    } else {
      headingText = 'RESET PASSWORD';
      subText = 'Enter your username to receive a reset link';
    }

    final accentColor = isDriver ? AppTheme.primaryBlue : AppTheme.accentPurple;
    final accentGrad = isDriver ? AppTheme.cynaToGreen : AppTheme.purpleToBlue;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ───────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: isDriver
                      ? const Alignment(-1.0, -1.0)
                      : const Alignment(1.0, -1.0),
                  radius: 1.4,
                  colors: [
                    isDriver
                        ? const Color(0xFF051A2E)
                        : const Color(0xFF12052E),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          // ── Circuit board background painter ─────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _CircuitBoardPainter(accentColor: accentColor),
            ),
          ),

          // ── Dual glow orbs ────────────────────────────────────────────────
          Positioned(
            top: -150,
            left: isDriver ? -100 : null,
            right: isDriver ? null : -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 200,
                    spreadRadius: 40,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: isDriver ? -80 : null,
            left: isDriver ? null : -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withValues(alpha: 0.12),
                    blurRadius: 160,
                    spreadRadius: 30,
                  )
                ],
              ),
            ),
          ),

          // ── Back button ───────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                      color: AppTheme.glassBorderColor.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () {
                authCtrl.clearError();
                Navigator.pop(context);
              },
            ),
          ),

          // ── Main form card ────────────────────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // Role icon with glow
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: accentGrad,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.45),
                              blurRadius: 28,
                            )
                          ],
                        ),
                        child: Icon(
                          isDriver
                              ? Icons.drive_eta_rounded
                              : Icons.admin_panel_settings_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      GradientText(
                        text: headingText,
                        gradient: accentGrad,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 26,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(subText,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 28),

                      // Glass card form
                      NeonGlassCard(
                        accentColor: accentColor,
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Demo/Live mode badge
                              Center(
                                child: NeonBadge(
                                  label: isDemoMode
                                      ? 'DEMO MODE — Mock Data'
                                      : 'LIVE — Supabase Connected',
                                  color: isDemoMode
                                      ? AppTheme.amberAlert
                                      : AppTheme.neonGreen,
                                  icon: isDemoMode
                                      ? Icons.science_outlined
                                      : Icons.cloud_done_outlined,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error banner
                              if (authCtrl.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.criticalRed.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.criticalRed.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppTheme.criticalRed, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(authCtrl.errorMessage!,
                                            style: const TextStyle(
                                                color: AppTheme.criticalRed,
                                                fontSize: 13)),
                                      ),
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
                                  if (v == null || v.trim().isEmpty)
                                    return 'Please enter your username';
                                  if (v.trim().length < 3)
                                    return 'Username must be at least 3 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              if (_authMode != AuthMode.forgotPassword) ...[
                                GlassTextField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Please enter your password';
                                    if (v.length < 6)
                                      return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),

                                if (_authMode == AuthMode.register) ...[
                                  const SizedBox(height: 16),
                                  GlassTextField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirm Password',
                                    hintText: '••••••••',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Please confirm your password';
                                      if (v != _passwordController.text)
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                ],

                                if (_authMode == AuthMode.login) ...[
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        authCtrl.clearError();
                                        setState(() =>
                                            _authMode = AuthMode.forgotPassword);
                                      },
                                      child: Text('Forgot Password?',
                                          style: TextStyle(
                                              color: accentColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ],

                              const SizedBox(height: 16),

                              // Demo autofill
                              if (_authMode == AuthMode.login) ...[
                                OutlinedButton.icon(
                                  onPressed: _autofillDemo,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: accentColor.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: Icon(Icons.flash_on, color: accentColor, size: 18),
                                  label: Text('Autofill Demo Account',
                                      style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Submit button
                              GlassButton(
                                text: _authMode == AuthMode.login
                                    ? 'SIGN IN'
                                    : _authMode == AuthMode.register
                                        ? 'CREATE ACCOUNT'
                                        : 'SEND RESET LINK',
                                isLoading: authCtrl.isLoading,
                                color: accentColor,
                                color2: isDriver
                                    ? AppTheme.neonGreen
                                    : AppTheme.accentBlue,
                                onPressed: _handleSubmit,
                              ),
                              const SizedBox(height: 20),

                              // Toggle login/register
                              if (_authMode != AuthMode.forgotPassword)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _authMode == AuthMode.login
                                          ? "Don't have an account?  "
                                          : 'Already have an account?  ',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        authCtrl.clearError();
                                        setState(() => _authMode =
                                            _authMode == AuthMode.login
                                                ? AuthMode.register
                                                : AuthMode.login);
                                      },
                                      child: Text(
                                        _authMode == AuthMode.login
                                            ? 'Register'
                                            : 'Sign In',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                          decorationColor: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              if (_authMode == AuthMode.forgotPassword) ...[
                                const SizedBox(height: 12),
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      authCtrl.clearError();
                                      setState(() => _authMode = AuthMode.login);
                                    },
                                    child: Text('Back to Sign In',
                                        style: TextStyle(
                                            color: accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
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

// ─── Circuit Board Background Painter ─────────────────────────────────────────
class _CircuitBoardPainter extends CustomPainter {
  final Color accentColor;
  _CircuitBoardPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final rng = Random(42);
    final List<Offset> nodes = [];

    // Generate circuit nodes
    for (int i = 0; i < 18; i++) {
      nodes.add(Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      ));
    }

    // Draw circuit lines (L-shaped paths)
    for (int i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i];
      final b = nodes[i + 1];
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(a.dx, b.dy) // vertical segment
        ..lineTo(b.dx, b.dy); // horizontal segment
      canvas.drawPath(path, paint);
    }

    // Draw node dots
    for (final n in nodes) {
      canvas.drawCircle(n, 2.5, dotPaint);
      // Small tick marks
      canvas.drawLine(
        Offset(n.dx - 6, n.dy),
        Offset(n.dx + 6, n.dy),
        paint..color = accentColor.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitBoardPainter old) =>
      old.accentColor != accentColor;
}
