import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Soft Lavender + Sky Blue Design System (from user specification)
class EratPalette {
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color deepPurple = Color(0xFF5A4AD1);
  static const Color softLavender = Color(0xFFF3F0FF);
  static const Color lavenderBorder = Color(0xFFE2DCFF);
  static const Color skyBlue = Color(0xFFEAF4FF);
  static const Color softPink = Color(0xFFFFF0F6);
  static const Color warmCream = Color(0xFFFFF6E8);
  static const Color warmCreamBorder = Color(0xFFFDE2B8);
  static const Color emeraldGreen = Color(0xFF22C55E);
  static const Color textDark = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color pageBackground = Color(0xFFF7F5FF);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEDE9FE), // Soft Lavender top
      Color(0xFFF5F8FF), // Sky Blue middle
      Color(0xFFFFFFFF), // Clean White bottom
    ],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF7C69EF),
      Color(0xFF6347D1),
    ],
  );

  static const LinearGradient kindnessCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B78F6),
      Color(0xFF6C5CE7),
    ],
  );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

/// 6 Visual World Themes from Step 8 of user specification
enum EratWorldTheme {
  cozyHome,
  oceanExplorer,
  enchantedForest,
  dinoWorld,
  spaceAdventure,
  candyGalaxy,
}

final selectedWorldThemeProvider =
    StateProvider<EratWorldTheme>((ref) => EratWorldTheme.cozyHome);

extension EratWorldThemeX on EratWorldTheme {
  String get title => switch (this) {
        EratWorldTheme.cozyHome => 'Cozy Home',
        EratWorldTheme.oceanExplorer => 'Ocean Explorer',
        EratWorldTheme.enchantedForest => 'Enchanted Forest',
        EratWorldTheme.dinoWorld => 'Dino World',
        EratWorldTheme.spaceAdventure => 'Space Adventure',
        EratWorldTheme.candyGalaxy => 'Candy Galaxy',
      };

  String get emoji => switch (this) {
        EratWorldTheme.cozyHome => '🏡',
        EratWorldTheme.oceanExplorer => '🐬',
        EratWorldTheme.enchantedForest => '🧚🏻‍♀️',
        EratWorldTheme.dinoWorld => '🦕',
        EratWorldTheme.spaceAdventure => '🚀',
        EratWorldTheme.candyGalaxy => '🍭',
      };

  Color get accentColor => switch (this) {
        EratWorldTheme.cozyHome => const Color(0xFF6C5CE7),
        EratWorldTheme.oceanExplorer => const Color(0xFF0284C7),
        EratWorldTheme.enchantedForest => const Color(0xFF059669),
        EratWorldTheme.dinoWorld => const Color(0xFFD97706),
        EratWorldTheme.spaceAdventure => const Color(0xFF4F46E5),
        EratWorldTheme.candyGalaxy => const Color(0xFFDB2777),
      };

  Color get softTint => switch (this) {
        EratWorldTheme.cozyHome => const Color(0xFFEDE9FE),
        EratWorldTheme.oceanExplorer => const Color(0xFFE0F2FE),
        EratWorldTheme.enchantedForest => const Color(0xFFD1FAE5),
        EratWorldTheme.dinoWorld => const Color(0xFFFEF3C7),
        EratWorldTheme.spaceAdventure => const Color(0xFFE0E7FF),
        EratWorldTheme.candyGalaxy => const Color(0xFFFCE7F3),
      };

  LinearGradient get backgroundGradient => switch (this) {
        EratWorldTheme.cozyHome => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEDE9FE), Color(0xFFF5F8FF), Color(0xFFFFFFFF)],
          ),
        EratWorldTheme.oceanExplorer => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBAE6FD), Color(0xFFEFF8FF), Color(0xFFFFFFFF)],
          ),
        EratWorldTheme.enchantedForest => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA7F3D0), Color(0xFFECFDF5), Color(0xFFFFFFFF)],
          ),
        EratWorldTheme.dinoWorld => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDE68A), Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
          ),
        EratWorldTheme.spaceAdventure => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC7D2FE), Color(0xFFEEF2FF), Color(0xFFFFFFFF)],
          ),
        EratWorldTheme.candyGalaxy => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFBCFE8), Color(0xFFFDF2F8), Color(0xFFFFFFFF)],
          ),
      };
}

/// Reusable Primary Pill Button (Rule: One primary button per screen, adapts to World Theme!)
class EratPrimaryPillButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final Color? color;

  const EratPrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldTheme = ref.watch(selectedWorldThemeProvider);
    final baseColor = color ?? worldTheme.accentColor;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
               Color.lerp(baseColor, Colors.white, 0.12)!,
              baseColor,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean 2D Flat "Erat" Brand Logo (Like Grab / Canva — 2D wordmark + family symbol, zero 3D!)
class EratFlatAppLogo extends ConsumerWidget {
  final double size;

  const EratFlatAppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldTheme = ref.watch(selectedWorldThemeProvider);
    final primary = worldTheme.accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(primary, Colors.white, 0.18)!,
            primary,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle flat geometric arc in top-right corner
          Positioned(
            top: -size * 0.18,
            right: -size * 0.18,
            child: Container(
              width: size * 0.55,
              height: size * 0.55,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean 2D Flat Family Trio Icon (Parents + Children, NOT a couple!)
              Icon(
                Icons.family_restroom_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: size * 0.30,
              ),
              SizedBox(height: size * 0.01),
              // Clean 2D Bold "Erat" Brand Wordmark (like Grab)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Erat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
                  Container(
                    width: size * 0.065,
                    height: size * 0.065,
                    margin: EdgeInsets.only(left: 2, top: size * 0.12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE047),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


