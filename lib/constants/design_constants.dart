import 'package:flutter/material.dart';

/// Centralized design constants for consistent styling across all widgets.
/// All widgets should reference these values instead of hardcoding.
class DesignConstants {
  DesignConstants._();

  // ============================================================
  // Border Radius
  // ============================================================
  static const double radiusSmall = 12;
  static const double radiusItem = 14;
  static const double radiusCard = 20;
  static const double radiusFeatured = 24;
  static const double radiusButton = 30;
  static const double radiusCircle = 999;

  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusItem =>
      BorderRadius.circular(radiusItem);
  static BorderRadius get borderRadiusCard =>
      BorderRadius.circular(radiusCard);
  static BorderRadius get borderRadiusFeatured =>
      BorderRadius.circular(radiusFeatured);
  static BorderRadius get borderRadiusButton =>
      BorderRadius.circular(radiusButton);

  // ============================================================
  // Padding
  // ============================================================
  static const double paddingCompact = 8;
  static const double paddingItem = 12;
  static const double paddingCard = 16;
  static const double paddingWide = 18;
  static const double paddingExtraWide = 20;

  static EdgeInsets get edgeInsetsCompact => EdgeInsets.all(paddingCompact);
  static EdgeInsets get edgeInsetsItem => EdgeInsets.all(paddingItem);
  static EdgeInsets get edgeInsetsCard => EdgeInsets.all(paddingCard);
  static EdgeInsets get edgeInsetsWide => EdgeInsets.all(paddingWide);
  static EdgeInsets get edgeInsetsExtraWide => EdgeInsets.all(paddingExtraWide);

  static EdgeInsets get edgeInsetsHorizontalItem =>
      const EdgeInsets.symmetric(horizontal: paddingItem, vertical: paddingItem);
  static EdgeInsets get edgeInsetsHorizontalCard =>
      const EdgeInsets.symmetric(horizontal: paddingCard, vertical: paddingCard);

  // ============================================================
  // Shadows
  // ============================================================
  static List<BoxShadow> cardShadow(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = color ??
        (isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08));
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: 12,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> lightCardShadow(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = color ??
        (isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05));
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // ============================================================
  // Gradients
  // ============================================================
  static LinearGradient subtleGradient(Color color,
      {AlignmentGeometry begin = Alignment.topLeft,
      AlignmentGeometry end = Alignment.bottomRight}) {
    return LinearGradient(
      colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient featuredGradient(Color startColor, Color endColor,
      {AlignmentGeometry begin = Alignment.topLeft,
      AlignmentGeometry end = Alignment.bottomRight}) {
    return LinearGradient(
      colors: [startColor, endColor],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient greetingGradientDark = LinearGradient(
    colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient greetingGradientLight(Color primary, Color success) {
    return LinearGradient(
      colors: [primary.withOpacity(0.08), success.withOpacity(0.04)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ============================================================
  // Border styling
  // ============================================================
  static Border subtleBorder(Color color, {double opacity = 0.2}) {
    return Border.all(color: color.withOpacity(opacity));
  }

  // ============================================================
  // Empty state styling
  // ============================================================
  static Widget emptyStateIcon(BuildContext context,
      {IconData icon = Icons.inbox_outlined, double size = 56}) {
    return Icon(
      icon,
      size: size,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
    );
  }

  static TextStyle emptyStateTitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium;
    if (base != null) {
      return base.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      );
    }
    return TextStyle(
      fontSize: 16,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    );
  }

  static TextStyle emptyStateSubtitleStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall;
    if (base != null) {
      return base.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      );
    }
    return TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
    );
  }

  // ============================================================
  // Awareness Banner Builder (shared pattern)
  // ============================================================
  static Widget buildAwarenessBanner({
    required BuildContext context,
    required String emoji,
    required String title,
    required String message,
    required String detail,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(paddingItem),
      decoration: BoxDecoration(
        gradient: subtleGradient(color),
        borderRadius: borderRadiusCard,
        border: subtleBorder(color),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 11)),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: borderRadiusButton,
              ),
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Shared Button Style
  // ============================================================
  static ButtonStyle actionButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: borderRadiusButton),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 0,
    );
  }

  // ============================================================
  // Shared Quote Card Builder
  // ============================================================
  static Widget buildQuoteCard({
    required String quote,
    required String icon,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(paddingItem),
      decoration: BoxDecoration(
        gradient: subtleGradient(color),
        borderRadius: borderRadiusCard,
        border: subtleBorder(color, opacity: 0.15),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: color,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Shared Animated Circle Icon Builder
  // ============================================================
  static Widget animatedCircleIcon({
    required Widget child,
    bool isDark = false,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.2)),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }

  // ============================================================
  // Shared Progress Bar Builder
  // ============================================================
  static Widget buildProgressBar({
    required double value,
    Color? backgroundColor,
    Color? progressColor,
    double height = 8,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radiusSmall),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: backgroundColor ?? Colors.white.withOpacity(0.25),
        valueColor: AlwaysStoppedAnimation<Color>(
          progressColor ?? Colors.white,
        ),
      ),
    );
  }

  // ============================================================
  // Shared Tag/Badge Builder
  // ============================================================
  static Widget buildTag({
    required String text,
    required Color color,
    Color? textColor,
    double fontSize = 10,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: borderRadiusButton,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor ?? color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // Section Header
  // ============================================================
  static Widget sectionHeader({
    required String title,
    required String emoji,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$emoji $title',
        style: style ??
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // ============================================================
  // Spacing constants
  // ============================================================
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;

  // ============================================================
  // Icon sizes
  // ============================================================
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 28;
  static const double iconXLarge = 32;

  // ============================================================
  // Font sizes
  // ============================================================
  static const double fontXs = 10;
  static const double fontSm = 11;
  static const double fontMd = 13;
  static const double fontLg = 16;
  static const double fontXl = 18;
  static const double fontXxl = 22;
}