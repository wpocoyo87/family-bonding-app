import 'package:flutter/material.dart';

/// Cozy Minimalist Theme Palette & Component Library
/// Inspired by warm Japanese/Korean lifestyle habit journal illustrations
class CozyTheme {
  // Soft, warm color palette
  static const Color background = Color(0xFFFAF7F2); // Warm cream paper
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF9F6F0);

  static const Color pillBackground = Color(0xFFF4E5DC); // Warm pastel peach/beige
  static const Color pillBackgroundWarm = Color(0xFFEFE6DC);
  static const Color pillBackgroundGreen = Color(0xFFE8F1EC);
  static const Color pillBackgroundBlue = Color(0xFFE8EEF5);
  static const Color pillBackgroundCompleted = Color(0xFFF9EBE4); // Soft peach blush cream for completed tasks

  static const Color textDark = Color(0xFF3E312B); // Warm espresso/mocha
  static const Color textMedium = Color(0xFF6B584E); // Soft brown
  static const Color textMuted = Color(0xFF8D7364); // Gentle taupe

  static const Color border = Color(0xFFE8DACF);
  static const Color borderLight = Color(0xFFF0E5DC);
  static const Color borderCompleted = Color(0xFFE5C8BC); // Soft terracotta border

  static const Color connectorLine = Color(0xFFD6C7BC);
  static const Color connectorDot = Color(0xFF8D6E63);

  static const Color accentHeart = Color(0xFFC48B71);
  static const Color badgeCompleted = Color(0xFFC48B71); // Soft Terracotta / Blush Rose
  static const Color badgeCompletedLight = Color(0xFFF4DFD5);
  static const Color accentStar = Color(0xFFF59E0B);
  static const Color accentGreen = Color(0xFFC48B71); // Updated from green to soft terracotta for aesthetic harmony
  static const Color accentBlue = Color(0xFF0284C7);

  // Soft shadows
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF8D6E63).withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF8D6E63).withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
}

/// A reusable cozy pill card widget (speech-bubble style with soft borders)
class CozyPillCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onInfoTap;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const CozyPillCard({
    super.key,
    required this.title,
    this.subtitle,
    this.backgroundColor = CozyTheme.pillBackground,
    this.borderColor = CozyTheme.border,
    this.onInfoTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: CozyTheme.textDark,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onInfoTap != null)
                InkWell(
                  onTap: onInfoTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: CozyTheme.textMedium,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: CozyTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A cozy bullet point item
class CozyBulletItem extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;

  const CozyBulletItem({
    super.key,
    required this.text,
    this.textColor = const Color(0xFF4A3E38),
    this.fontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: fontSize + 1,
              fontWeight: FontWeight.bold,
              color: CozyTheme.textMedium,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical timeline connector with a node dot
class CozyTimelineConnector extends StatelessWidget {
  final double height;
  final double dotSize;

  const CozyTimelineConnector({
    super.key,
    this.height = 24,
    this.dotSize = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 2,
          height: height,
          color: CozyTheme.connectorLine,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: dotSize,
          height: dotSize,
          decoration: const BoxDecoration(
            color: CozyTheme.connectorDot,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: height,
          color: CozyTheme.connectorLine,
        ),
      ],
    );
  }
}

/// Official ERAT Brand Logo — faithful family silhouette + "Erat." wordmark
/// adapted to the Warm Cozy Minimalist Mocha & Honey-Gold palette.
class EratBrandLogo extends StatelessWidget {
  final double size;

  const EratBrandLogo({
    super.key,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Semantics(
      label: 'ERAT logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8C685C), // Warm soft mocha highlight
              Color(0xFF6D4C41), // Deep cozy mocha base
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(109, 76, 65, 0.22),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle top-right decorative glow circle (faithful to original logo)
              Positioned(
                top: -size * 0.24,
                right: -size * 0.22,
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Family silhouette + "Erat." wordmark with golden dot
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.family_restroom_rounded,
                      color: Colors.white,
                      size: size * 0.36,
                    ),
                    SizedBox(height: size * 0.03),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Erat',
                            style: TextStyle(
                              fontSize: size * 0.26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.0,
                            ),
                          ),
                          Container(
                            width: size * 0.085,
                            height: size * 0.085,
                            margin: EdgeInsets.only(
                              left: size * 0.025,
                              bottom: size * 0.025,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF6C343), // Warm honey gold dot
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

