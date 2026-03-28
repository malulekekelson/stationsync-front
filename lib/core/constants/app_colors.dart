import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Petroleum Industry Theme
  static const Color primary = Color(0xFF1A5F7A); // Deep Teal - Petroleum
  static const Color primaryDark = Color(0xFF0A3B4A); // Darker Teal
  static const Color primaryLight = Color(0xFF2E8BAF); // Light Teal

  // Secondary Colors
  static const Color secondary = Color(0xFFF4A261); // Warm Orange - Energy
  static const Color secondaryDark = Color(0xFFE76F51); // Dark Orange
  static const Color secondaryLight = Color(0xFFF9C74F); // Light Gold

  // Accent Colors
  static const Color accent = Color(0xFF2A9D8F); // Green - Sustainability
  static const Color success = Color(0xFF4CAF50); // Green - Success
  static const Color warning = Color(0xFFFF9800); // Orange - Warning
  static const Color error = Color(0xFFE63946); // Red - Error
  static const Color info = Color(0xFF2196F3); // Blue - Info

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC); // Light Grey Background
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFF1F5F9);

  // Status Colors
  static const Color statusDraft = Color(0xFF64748B);
  static const Color statusSubmitted = Color(0xFF3B82F6);
  static const Color statusUnderReview = Color(0xFFF59E0B);
  static const Color statusApproved = Color(0xFF10B981);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusInfoRequested = Color(0xFF8B5CF6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );
}
