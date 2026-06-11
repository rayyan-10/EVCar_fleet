import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../widgets/glass_widgets.dart';

// ─── Particle ────────────────────────────────────────────────────────────────
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
    // Draw connecting lines between nearby particles
    final linePaint = Paint()..strokeWidth = 0.4;
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].pos.dx - particles[j].pos.dx;
        final dy = particles[i].pos.dy - particles[j].pos.dy;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 90) {
          linePaint.color = color.withValues(alpha: (1 - dist / 90) * 0.12);
          canvas.drawLine(particles[i].pos, particles[j].pos, linePaint);
        }
      }
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
    with TickerProviderStateMixin {
  String? _hoveredRole;

  static const int _particleCount = 70;
  static const double _repelRadius = 130.0;
  static const double _repelStrength = 6.5;
  static const double _friction = 0.88;

  final List<_Particle> _particles = [];
  final Random _rng = Random();
  Offset _mouse = Offset.zero;
  late final AnimationController _particleCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _logoGlowCtrl;
  Size _canvasSize = Size.zero;

  final List<String> _typewriterPhrases = [
    'Analyzing fleet telemetry...',
    'Loading AI range models...',
    'Syncing battery diagnostics...',
    'Connecting to network nodes...',
    'Fleet intelligence ready.',
  ];
  int _phraseIndex = 0;
  String _displayedText = '';
  Timer? _typeTimer;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(days: 999),
    )
      ..addListener(_onTick)
      ..forward();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _startTypewriter();
  }

  void _startTypewriter() {
    _displayedText = '';
    int charIdx = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 45), (t) {
      final phrase = _typewriterPhrases[_phraseIndex];
      if (charIdx < phrase.length) {
        setState(() => _displayedText = phrase.substring(0, ++charIdx));
      } else {
        t.cancel();
        _phraseTimer = Timer(const Duration(milliseconds: 1800), () {
          _phraseIndex = (_phraseIndex + 1) % _typewriterPhrases.length;
          _startTypewriter();
        });
      }
    });
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    _canvasSize = size;
    _mouse = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        pos: Offset(
            _rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
        vel: Offset(
            (_rng.nextDouble() - 0.5) * 0.5, (_rng.nextDouble() - 0.5) * 0.5),
        radius: _rng.nextDouble() * 1.8 + 0.6,
        baseOpacity: _rng.nextDouble() * 0.2 + 0.06,
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
          p.vel = Offset(p.vel.dx - (dx / dist) * force,
              p.vel.dy - (dy / dist) * force);
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
    _particleCtrl.dispose();
    _fadeCtrl.dispose();
    _logoGlowCtrl.dispose();
    _typeTimer?.cancel();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    WidgetsBinding.instance.addPostFrameCallback((_) => _initParticles(size));

    return Scaffold(
      body: MouseRegion(
        onHover: (e) => _mouse = e.localPosition,
        onExit: (_) => _mouse = Offset(size.width / 2, size.height / 2),
        child: Stack(
          children: [
            // ── Gradient mesh background ──────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.8, -0.8),
                    radius: 1.2,
                    colors: [Color(0xFF0A0522), AppTheme.backgroundColor],
                  ),
                ),
              ),
            ),

            // ── Ambient glow orbs ─────────────────────────────────────────
            Positioned(
              top: -120, left: -120,
              child: _GlowOrb(color: AppTheme.primaryBlue, size: 400, intensity: 0.18),
            ),
            Positioned(
              bottom: -100, right: -100,
              child: _GlowOrb(color: AppTheme.accentPurple, size: 500, intensity: 0.14),
            ),
            Positioned(
              top: size.height * 0.4, left: size.width * 0.5,
              child: _GlowOrb(color: AppTheme.neonGreen, size: 200, intensity: 0.07),
            ),

            // ── Particle canvas ───────────────────────────────────────────
            if (_particles.isNotEmpty)
              CustomPaint(
                size: size,
                painter: _ParticlePainter(_particles, AppTheme.primaryBlue),
              ),

            // ── Foreground content ────────────────────────────────────────
            FadeTransition(
              opacity: _fadeCtrl,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated logo icon
                      AnimatedBuilder(
                        animation: _logoGlowCtrl,
                        builder: (_, __) => Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryBlue, AppTheme.accentPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.2 + _logoGlowCtrl.value * 0.3),
                                blurRadius: 30 + _logoGlowCtrl.value * 20,
                              ),
                              BoxShadow(
                                color: AppTheme.accentPurple.withValues(
                                    alpha: 0.15 + _logoGlowCtrl.value * 0.2),
                                blurRadius: 50,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.bolt_rounded, size: 48, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Gradient title
                      GradientText(
                        text: 'DRIVE ANALYSIS PLATFORM',
                        gradient: AppTheme.primaryGradient,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              fontSize: isDesktop ? 34 : 22,
                            ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'AI-powered electric vehicle analytics & fleet intelligence',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Typewriter status line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PulsingDot(color: AppTheme.neonGreen, size: 8),
                          const SizedBox(width: 8),
                          Text(
                            _displayedText,
                            style: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 52),

                      // Role cards
                      Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRoleCard(
                            context: context,
                            roleId: 'driver',
                            title: 'LOGIN AS DRIVER',
                            description:
                                'Onboard vehicle parameters, track performance metrics, calculate real-time AI driving ranges, and download efficiency logs.',
                            icon: Icons.drive_eta_rounded,
                            accentColor: AppTheme.primaryBlue,
                            accentGradient: AppTheme.cynaToGreen,
                          ),
                          SizedBox(width: isDesktop ? 28 : 0, height: isDesktop ? 0 : 20),
                          _buildRoleCard(
                            context: context,
                            roleId: 'admin',
                            title: 'LOGIN AS ADMIN',
                            description:
                                'Access fleet dashboards, monitor overall driver efficiency rankings, query data tables, and generate monthly energy reports.',
                            icon: Icons.admin_panel_settings_rounded,
                            accentColor: AppTheme.accentPurple,
                            accentGradient: AppTheme.purpleToBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),

                      // Footer badge
                      NeonBadge(
                        label: 'Powered by Supabase · Flutter Web Engine',
                        color: AppTheme.textSecondary,
                        icon: Icons.cloud_done_outlined,
                      ),
                    ],
                  ),
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
    required Color accentColor,
    required Gradient accentGradient,
  }) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final cardWidth = isDesktop ? 340.0 : double.infinity;
    final isHovered = _hoveredRole == roleId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRole = roleId),
      onExit: (_) => setState(() => _hoveredRole = null),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.login,
            arguments: {'role': roleId}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: cardWidth,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(isHovered ? -0.04 : 0.0)
            ..translate(0.0, isHovered ? -12.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.30),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHovered
                        ? accentColor.withValues(alpha: 0.6)
                        : AppTheme.glassBorderColor.withValues(alpha: 0.5),
                    width: isHovered ? 1.2 : 0.8,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: isHovered ? 0.12 : 0.06),
                      Colors.white.withValues(alpha: isHovered ? 0.04 : 0.02),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Top accent bar
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          gradient: isHovered
                              ? accentGradient
                              : LinearGradient(colors: [
                                  accentColor.withValues(alpha: 0.0),
                                  accentColor.withValues(alpha: 0.3),
                                  accentColor.withValues(alpha: 0.0),
                                ]),
                        ),
                      ),
                    ),
                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isHovered
                                  ? accentGradient
                                  : LinearGradient(colors: [
                                      Colors.white.withValues(alpha: 0.06),
                                      Colors.white.withValues(alpha: 0.03),
                                    ]),
                              boxShadow: isHovered
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.4),
                                        blurRadius: 24,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Icon(icon, size: 44, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isHovered
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Glow Orb ─────────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double intensity;

  const _GlowOrb({required this.color, required this.size, required this.intensity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: intensity),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
