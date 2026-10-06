import 'package:flutter/material.dart';

/// Professional Design System Colors for COCO APP
/// Derived from COCO Design DNA Profile (Dimension 1 & Dimension 3)
class AppColors {
  // Brand Primary & Gradients (Indigo Spectrum)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600 (Core Brand Action)
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primarySoft = Color(0xFFEEF2FF); // Indigo 50
  static const Color primaryContainer = Color(0xFFE0E7FF); // Indigo 100

  // Secondary & Accents (Vibrant Violet, Cyan, Amber, Rose)
  static const Color secondary = Color(0xFF7C3AED); // Violet 600 (Community & Energy)
  static const Color secondaryLight = Color(0xFF8B5CF6); // Violet 500
  static const Color secondarySoft = Color(0xFFF5F3FF); // Violet 50
  static const Color secondaryContainer = Color(0xFFEDE9FE); // Violet 100

  static const Color accentCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color accentCyanSoft = Color(0xFFECFEFF);
  static const Color accentAmber = Color(0xFFF59E0B); // Amber 500 (Ratings, Highlights)
  static const Color accentAmberSoft = Color(0xFFFFFBEB);
  static const Color accentRose = Color(0xFFF43F5E); // Rose 500 (Likes, Urgent)
  static const Color accentRoseSoft = Color(0xFFFFF1F2);

  // Neutral Spectrum (Slate 50 -> Slate 950)
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color borderFocused = Color(0xFF4F46E5);
  static const Color divider = Color(0xFFE2E8F0);

  // Glassmorphic Colors (Dimension 3: Frosted Layers)
  static const Color glassSurface = Color(0xD8FFFFFF); // 85% opacity white
  static const Color glassSurfaceLight = Color(0xF2FFFFFF); // 95% opacity white
  static const Color glassBorder = Color(0x66FFFFFF); // 40% translucent white border
  static const Color glassShadow = Color(0x0C0F172A);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Colors.white;

  // Status & Semantic Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald 500 (Verified, Available)
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoSoft = Color(0xFFEFF6FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF), Color(0xFFECFEFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows (Multi-level depth cues from Design DNA)
  static List<BoxShadow> get shadowLow => const [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowHigh => const [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 25,
      offset: Offset(0, 15),
    ),
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 10,
      offset: Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get buttonShadow => const [
    BoxShadow(
      color: Color(0x384F46E5),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get glowViolet => const [
    BoxShadow(
      color: Color(0x337C3AED),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingNavShadow => const [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
