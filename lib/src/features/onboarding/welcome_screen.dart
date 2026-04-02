import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_logo.dart';
import '../../theme/app_theme.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Center logo area
              const Expanded(child: _LogoSection()),

              // Bottom buttons
              _GoogleButton(
                isLoading: authState.isLoading,
                onTap: () {
                  ref.read(authNotifierProvider.notifier).signInWithGoogle();
                },
              ),
              const SizedBox(height: 16),
              _EmailButton(
                onTap: () => context.go('/sign-in'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo section with animated blobs and house icon
// ---------------------------------------------------------------------------
class _LogoSection extends StatefulWidget {
  const _LogoSection();

  @override
  State<_LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends State<_LogoSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with blobs
          SizedBox(
            width: 144,
            height: 144,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated rotating blobs
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final angle = _controller.value * 2 * math.pi;
                    return Transform.rotate(
                      angle: angle,
                      child: child,
                    );
                  },
                  child: Stack(
                    children: [
                      // Emerald blob
                      Positioned.fill(
                        child: Transform.rotate(
                          angle: 0.26, // ~15 degrees
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6EE7B7).withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                      // Teal/coral blob
                      Positioned.fill(
                        child: Transform.rotate(
                          angle: -0.26,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF93C5FD).withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                      // Blue blob
                      Positioned.fill(
                        child: Transform.rotate(
                          angle: 0.785, // ~45 degrees
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5EEAD4).withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // House icon card (reusable logo widget)
                const AppLogo(size: 96),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Ma Coloc',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shared living, sorted.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google sign-in button
// ---------------------------------------------------------------------------
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate800.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else ...[
              // Google "G" icon
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GoogleLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Email button
// ---------------------------------------------------------------------------
class _EmailButton extends StatelessWidget {
  const _EmailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mail_outline_rounded,
                size: 20, color: AppColors.slate700),
            const SizedBox(width: 12),
            Text(
              'Log In with Email',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google "G" logo painter
// ---------------------------------------------------------------------------
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    // Blue arc (top-right)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 4,
      -math.pi / 2,
      true,
      bluePaint,
    );

    // Green arc (bottom-right)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi / 4,
      -math.pi / 4,
      true,
      greenPaint,
    );

    // Yellow arc (bottom-left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi / 4,
      math.pi / 2,
      true,
      yellowPaint,
    );

    // Red arc (top-left)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -3 * math.pi / 4,
      math.pi / 2,
      true,
      redPaint,
    );

    // White inner circle (to make the "G" shape)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, whitePaint);

    // Blue bar extending right from center
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - r * 0.15, w, cy + r * 0.15),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
