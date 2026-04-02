import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// The MaColoc house icon logo.
///
/// Use [size] to control the overall dimensions. The icon, dots, gradient,
/// and border radius all scale proportionally.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.29; // ~28/96
    final borderWidth = size * 0.0625; // ~6/96
    final iconSize = size * 0.40; // ~38/96
    final dotSize = size * 0.104; // ~10/96
    final dotSpacing = size * 0.0625; // ~6/96
    final gradientHeight = size * 0.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.1),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.083),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: borderWidth,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle emerald gradient at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius - borderWidth),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.emerald50,
                    AppColors.emerald50.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // House icon + colored dots
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_outlined,
                size: iconSize,
                color: AppColors.slate800,
              ),
              SizedBox(height: size * 0.042),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(const Color(0xFF34D399), dotSize),
                  SizedBox(width: dotSpacing),
                  _dot(const Color(0xFF2DD4BF), dotSize),
                  SizedBox(width: dotSpacing),
                  _dot(const Color(0xFF60A5FA), dotSize),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, double dotSize) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: dotSize * 0.4,
          ),
        ],
      ),
    );
  }
}

/// AppLogo with "Ma Coloc" title text below.
class AppLogoWithTitle extends StatelessWidget {
  const AppLogoWithTitle({super.key, this.logoSize = 96});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(height: 24),
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
    );
  }
}
