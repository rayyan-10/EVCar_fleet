import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../widgets/glass_widgets.dart';

// ─── Particle data ───────────────────────────────────────────────────────────
class _Particle {
  Offset pos;
  Offset vel;
  final double radius;
  final double baseOpacity;

  _Particle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.baseOpacity,
  });
}

// ─── Painter ─────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.baseOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.pos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _hoveredRole;

  // Particle system
  static const int _particleCount = 60;
  static const double _repelRadius = 120.0;
  static const double _repelStrength = 6.0;
  static const double _friction = 0.88;

  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Offset _mouse = Offset.zero;
  late final AnimationController _controller;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 999),
    )..addListener(_onTick)..forward();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    _canvasSize = size;
    _mouse = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        pos: Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        vel: Offset((_rng.nextDouble() - 0.5) * 0.4, (_rng.nextDouble() - 0.5) * 0.4),
        radius: _rng.nextDouble() * 2.0 + 1.0,
        baseOpacity: _rng.nextDouble() * 0.25 + 0.08,
      ));
    }
  }

  void _onTick() {
    if (_canvasSize == Size.zero || !mounted) return;
    setState(() {
      for (final p in _particles) {
        final dx = _mouse.dx - p.pos.dx;
        final dy = _mouse.dy - p.pos.dy;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < _repelRadius && dist > 0) {
          final force = (_repelRadius - dist) / _repelRadius * _repelStrength;
          p.vel = Offset(p.vel.dx - (dx / dist) * force, p.vel.dy - (dy / dist) * force);
        }

        p.vel = Offset(p.vel.dx * _friction, p.vel.dy * _friction);

        p.pos = Offset(
          (p.pos.dx + p.vel.dx).clamp(0, _canvasSize.width),
          (p.pos.dy + p.vel.dy).clamp(0, _canvasSize.height),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    // Init particles once we know the canvas size
    WidgetsBinding.instance.addPostFrameCallback((_) => _initParticles(size));

    return Scaffold(
      body: MouseRegion(
        onHover: (e) => _mouse = e.localPosition,
        onExit: (_) => _mouse = Offset(size.width / 2, size.height / 2),
        child: Stack(
          children: [
            // ── Ambient glows ─────────────────────────────────────────
            Positioned(
              top: -100, left: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 50)],
                ),
              ),
            ),
            Positioned(
              bottom: -50, right: -50,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.accentBlue.withValues(alpha: 0.1), blurRadius: 150, spreadRadius: 50)],
                ),
              ),
            ),

            // ── Particle canvas ───────────────────────────────────────
            if (_particles.isNotEmpty)
              CustomPaint(
                size: size,
                painter: _ParticlePainter(_particles, AppTheme.primaryBlue),
              ),

            // ── Foreground content ────────────────────────────────────
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_graph_rounded, size: 72, color: AppTheme.primaryBlue),
                    const SizedBox(height: 16),
                    Text(
                      'DRIVE ANALYSIS PLATFORM',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered electric vehicle analytics & fleet intelligence',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRoleCard(context: context, roleId: 'driver', title: 'LOGIN AS DRIVER', description: 'Onboard vehicle parameters, track performance metrics, calculate real-time AI driving ranges, and download efficiency logs.', icon: Icons.drive_eta_rounded),
                        const SizedBox(width: 24, height: 24),
                        _buildRoleCard(context: context, roleId: 'admin', title: 'LOGIN AS ADMIN', description: 'Access fleet dashboards, monitor overall driver efficiency rankings, query data tables, and generate monthly energy reports.', icon: Icons.admin_panel_settings_rounded),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Powered by Supabase DB & Flutter Web Engine',
                      style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String roleId,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final cardWidth = isDesktop ? 340.0 : double.infinity;
    final isHovered = _hoveredRole == roleId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRole = roleId),
      onExit: (_) => setState(() => _hoveredRole = null),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.login, arguments: {'role': roleId}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: cardWidth,
          height: 280,
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0.0, isHovered ? -10.0 : 0.0, 0.0),
          child: GlassCard(
            blur: 20,
            opacity: isHovered ? 0.14 : 0.07,
            borderColor: isHovered ? AppTheme.primaryBlue.withValues(alpha: 0.7) : AppTheme.glassBorderColor.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHovered ? AppTheme.primaryBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Icon(icon, size: 48, color: isHovered ? AppTheme.primaryBlue : Colors.white),
                ),
                const SizedBox(height: 20),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: isHovered ? Colors.white.withValues(alpha: 0.9) : AppTheme.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
