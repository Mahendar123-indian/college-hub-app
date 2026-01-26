import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary/Accent Colors
  static const Color accentColor = Color(0xFFFF6B6B); // Coral
  static const Color accentLight = Color(0xFFFF8787);
  static const Color accentDark = Color(0xFFEE5A52);

  // Success Colors
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  // Warning Colors
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  // Error Colors
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  // Info Colors
  static const Color infoColor = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Border Colors
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Colors
  static const Color categoryMidExam = Color(0xFF8B5CF6); // Purple
  static const Color categorySemesterExam = Color(0xFF3B82F6); // Blue
  static const Color categoryPreviousYear = Color(0xFFEC4899); // Pink
  static const Color categoryNotes = Color(0xFF10B981); // Green
  static const Color categorySyllabus = Color(0xFFF59E0B); // Amber
  static const Color categoryReference = Color(0xFF6366F1); // Indigo
  static const Color categoryAssignment = Color(0xFFEF4444); // Red
  static const Color categoryLab = Color(0xFF14B8A6); // Teal

  // Badge Colors
  static const Color badgeNew = Color(0xFFEF4444);
  static const Color badgeTrending = Color(0xFFF59E0B);
  static const Color badgeFeatured = Color(0xFF8B5CF6);

  // Rating Colors
  static const Color ratingActive = Color(0xFFFBBF24);
  static const Color ratingInactive = Color(0xFFE5E7EB);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);
}