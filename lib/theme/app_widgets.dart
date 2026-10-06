import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Frosted Glassmorphism Container (Design DNA Dimension 3)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blurRadius = 16,
    this.backgroundColor = AppColors.glassSurface,
    this.borderColor = AppColors.glassBorder,
    this.borderWidth = 1.0,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows ?? AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Gradient Text with ShaderMask (Design DNA Dimension 3: Shader Effects)
class BrandGradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const BrandGradientText({
    super.key,
    required this.text,
    this.style,
    this.gradient = AppColors.primaryGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

/// Modern Tinted Pill Badge (Design DNA Dimension 1: Component Tokens)
class GradientPillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const GradientPillBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = AppColors.primarySoft,
    this.foregroundColor = AppColors.primary,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Verified Host Badge
class VerifiedBadge extends StatelessWidget {
  final String text;
  const VerifiedBadge({super.key, this.text = "Hồ sơ sinh viên"});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rating Pill Badge
class RatingPill extends StatelessWidget {
  final double rating;
  final int? reviews;

  const RatingPill({super.key, required this.rating, this.reviews});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentAmberSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: AppColors.accentAmber),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB45309), // Amber 700
            ),
          ),
          if (reviews != null) ...[
            const SizedBox(width: 3),
            Text(
              "($reviews)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compatibility Score Ring (Canvas CustomPainter, Design DNA Dimension 3)
class CompatibilityRing extends StatelessWidget {
  final int percentage;
  final double size;

  const CompatibilityRing({
    super.key,
    required this.percentage,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final Color ringColor = percentage >= 85
        ? AppColors.success
        : percentage >= 70
            ? AppColors.primary
            : AppColors.warning;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: percentage / 100.0,
              color: ringColor,
              backgroundColor: ringColor.withValues(alpha: 0.15),
              strokeWidth: 3.5,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$percentage%",
                style: TextStyle(
                  fontSize: size * 0.27,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              Text(
                "hợp",
                style: TextStyle(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * 3.141592653589793 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Floating Frosted Glass Bottom Navigation Bar (Design DNA Dimension 1 & 3)
class ModernFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernNavItem> items;

  const ModernFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xF2FFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x104F46E5),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(index),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.12 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 21,
                                color: isSelected ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                letterSpacing: isSelected ? -0.2 : 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModernNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const ModernNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Desktop Top Navigation Bar (Design DNA Responsive Desktop Web)
class DesktopTopNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final List<ModernNavItem> items;
  final String userEmail;
  final VoidCallback? onLogout;
  final VoidCallback? onPostRoom;

  const DesktopTopNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
    this.userEmail = '',
    this.onLogout,
    this.onPostRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Row(
            children: [
              // Logo & Brand Name
              InkWell(
                onTap: () => onTabSelected(0),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          BrandGradientText(
                            text: 'COCO APP',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Trọ & Ở Ghép Sinh Viên ICTU',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 32),

              // Center: Navigation Tabs
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => onTabSelected(index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primarySoft : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: AppColors.primaryContainer, width: 1)
                                : Border.all(color: Colors.transparent, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 19,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  letterSpacing: isSelected ? -0.2 : 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Right: Post Button & User Profile
              if (onPostRoom != null) ...[
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.buttonShadow,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_home_work_rounded, color: Colors.white, size: 17),
                    label: const Text(
                      'Đăng Phòng',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: onPostRoom,
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // User Info Pill
              if (userEmail.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          userEmail[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userEmail.split('@').first,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),

              if (onLogout != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
                  tooltip: 'Đăng xuất',
                  onPressed: onLogout,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nền nghệ thuật với các quầng sáng Gradient Ambient động
class ArtisticAmbientBackground extends StatelessWidget {
  final Widget child;
  final bool showFloatingOrbs;

  const ArtisticAmbientBackground({
    super.key,
    required this.child,
    this.showFloatingOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Nền chuyển sắc nhẹ nhàng
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFEEF2FF),
                  Color(0xFFF5F3FF),
                  Color(0xFFECFEFF),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Các quầng sáng nghệ thuật tỏa mờ (Artistic Blurred Orbs)
        if (showFloatingOrbs) ...[
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.14),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: 20,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentCyan.withValues(alpha: 0.12),
                    AppColors.accentCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Lớp nội dung
        child,
      ],
    );
  }
}

/// Thẻ kính mờ Nghệ thuật (Artistic Glass Card)
class ArtisticGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? glowColor;
  final Color backgroundColor;
  final double borderWidth;

  const ArtisticGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.onTap,
    this.glowColor,
    this.backgroundColor = const Color(0xE6FFFFFF),
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (glowColor ?? Colors.white).withValues(alpha: 0.6),
          width: borderWidth,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          const BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(18),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Huy hiệu Ánh sáng Nghệ thuật (Artistic Aura Badge)
class ArtisticAuraBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const ArtisticAuraBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ Thống kê Tóm tắt Nghệ thuật
class ArtisticStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const ArtisticStatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

