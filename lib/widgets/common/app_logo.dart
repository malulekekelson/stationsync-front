import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const AppLogo({
    super.key,
    this.size = 60,
    this.showText = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Image
        Image.asset(
          'assets/logo/app_logo.jpeg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image not found
            return Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'SS',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'StationSync',
            style: GoogleFonts.inter(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Compliance • Oversight • Control',
            style: GoogleFonts.inter(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
