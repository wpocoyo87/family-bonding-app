import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_strings.dart';
import 'cozy_theme.dart';

/// Shows a charming, 100% localized (EN/BM) cozy star celebration popup
/// with animated pastel confetti burst, radiant star glow, and success haptic + chime.
void showCozyStarCelebration({
  required BuildContext context,
  required int starsEarned,
  required String taskTitle,
  required int totalStars,
  String? earnerName,
  int? pointsEarned,
  int? totalPoints,
  int? familyGoalCurrentStars,
  int? familyGoalTargetStars,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
    builder: (ctx) {
      return _CozyStarCelebrationDialog(
        starsEarned: starsEarned,
        taskTitle: taskTitle,
        totalStars: totalStars,
        earnerName: earnerName,
        pointsEarned: pointsEarned,
        totalPoints: totalPoints,
        familyGoalCurrentStars: familyGoalCurrentStars,
        familyGoalTargetStars: familyGoalTargetStars,
      );
    },
  );
}

class _CozyStarCelebrationDialog extends ConsumerStatefulWidget {
  final int starsEarned;
  final String taskTitle;
  final int totalStars;
  final String? earnerName;
  final int? pointsEarned;
  final int? totalPoints;
  final int? familyGoalCurrentStars;
  final int? familyGoalTargetStars;

  const _CozyStarCelebrationDialog({
    required this.starsEarned,
    required this.taskTitle,
    required this.totalStars,
    this.earnerName,
    this.pointsEarned,
    this.totalPoints,
    this.familyGoalCurrentStars,
    this.familyGoalTargetStars,
  });

  @override
  ConsumerState<_CozyStarCelebrationDialog> createState() =>
      _CozyStarCelebrationDialogState();
}

class _CozyStarCelebrationDialogState
    extends ConsumerState<_CozyStarCelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _burstCtrl;
  late final AnimationController _ambientCtrl;
  late final Animation<double> _starScale;
  late final Animation<double> _confettiProgress;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _starScale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _burstCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );
    _confettiProgress = CurvedAnimation(
      parent: _burstCtrl,
      curve: Curves.easeOutCubic,
    );

    // Trigger celebratory success double-pulse haptic + cheerful system chime
    _triggerCelebrationFeedback();
    _burstCtrl.forward();
  }

  Future<void> _triggerCelebrationFeedback() async {
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (mounted) {
      await HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final starWordUpper = strings.tr(
      'BINTANG',
      widget.starsEarned == 1 ? 'STAR' : 'STARS',
    );
    final starWordTotal = strings.tr(
      'Bintang',
      widget.totalStars == 1 ? 'Star' : 'Stars',
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 250) {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            color: CozyTheme.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFE5CEC2),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(60, 40, 20, 0.18),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Confetti Burst + Continuously Floating/Glowing Star Emblem (60fps)
              SizedBox(
                width: 210,
                height: 132,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_burstCtrl, _ambientCtrl]),
                  builder: (context, child) {
                    final wave = math.sin(_ambientCtrl.value * 2 * math.pi);
                    final floatY = wave * 4.0;
                    final starPulse = 1.0 + (wave * 0.045);
                    final starTilt = wave * 0.07;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Continuously Twinkling & Orbiting Pastel Confetti Burst
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CozyConfettiPainter(
                              progress: _confettiProgress.value,
                              ambientPhase: _ambientCtrl.value,
                            ),
                          ),
                        ),
                        // Radiant Halo + Bouncy & Gently Floating Star Badge
                        Transform.translate(
                          offset: Offset(0, floatY),
                          child: Transform.scale(
                            scale: _starScale.value * starPulse,
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFFFFF8E1),
                                    Color(0xFFF5E4DC),
                                  ],
                                  stops: [0.35, 1.0],
                                ),
                                border: Border.all(
                                  color: const Color(0xFFF6C343),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(
                                      246,
                                      195,
                                      67,
                                      0.32 + (wave.abs() * 0.16),
                                    ),
                                    blurRadius: 22 + (wave.abs() * 8),
                                    spreadRadius: 3 + (wave.abs() * 3),
                                  ),
                                  const BoxShadow(
                                    color: Color.fromRGBO(217, 119, 6, 0.18),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Transform.rotate(
                                angle: starTilt,
                                child: const Icon(
                                  Icons.star_rounded,
                                  size: 52,
                                  color: Color(0xFFE07A16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Localized Title: +X STAR(S) & +Y PTS!
              Text(
                (widget.pointsEarned != null && widget.pointsEarned! > 0)
                    ? '+${widget.starsEarned} $starWordUpper • +${widget.pointsEarned} ${strings.tr('MATA', 'PTS')}!'
                    : '+${widget.starsEarned} $starWordUpper!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: CozyTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // High-Contrast Localized Subtitle
              Text(
                strings.tr(
                  'Tahniah! "${widget.taskTitle}" telah berjaya diselesaikan.',
                  'Great job! "${widget.taskTitle}" has been completed.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A463C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // Aesthetic 2-Column Symmetrical Stat Tiles (Individual vs. Family Goal)
              if (widget.earnerName != null &&
                  widget.familyGoalCurrentStars != null &&
                  widget.familyGoalTargetStars != null)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Tile: Individual Earned
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E4DC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE5CEC2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.earnerName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8C685C),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  (widget.pointsEarned != null &&
                                          widget.pointsEarned! > 0)
                                      ? '+${widget.pointsEarned} ${strings.tr('Mata', 'Pts')}'
                                      : '+${widget.starsEarned} ★',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: CozyTheme.textDark,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.totalPoints != null
                                    ? '${widget.totalPoints} ${strings.tr('Mata', 'Pts')} • ${widget.totalStars} ★'
                                    : '${widget.totalStars} $starWordTotal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5A463C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Right Tile: Family Star Goal with Mini Progress Bar
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF2E8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFEBDCC8),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                strings.tr('Matlamat Keluarga', 'Family Goal'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8C685C),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '+${widget.starsEarned} ★',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: CozyTheme.textDark,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: widget.familyGoalTargetStars! > 0
                                      ? (widget.familyGoalCurrentStars! /
                                              widget.familyGoalTargetStars!)
                                          .clamp(0.0, 1.0)
                                      : 0.0,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFE8D8CA),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6D4C41),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.familyGoalCurrentStars}/${widget.familyGoalTargetStars} ★',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A463C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E4DC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5CEC2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        strings.tr(
                          'Jumlah Terkini: ${widget.totalStars} $starWordTotal',
                          'Current Total: ${widget.totalStars} $starWordTotal',
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.tr(
                          'Ditambah ke matlamat impian keluarga',
                          'Added to your family dream goal',
                        ),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A463C),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Primary CTA (>= 52 pt height, WCAG AAA Cozy Mocha)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D4C41),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    strings.tr(
                      'Hebat, Terima Kasih!',
                      'Awesome, Thank You!',
                    ),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Paints a warm pastel confetti & continuously twinkling sparkle burst around the celebration star emblem.
class _CozyConfettiPainter extends CustomPainter {
  final double progress;
  final double ambientPhase;

  const _CozyConfettiPainter({
    required this.progress,
    required this.ambientPhase,
  });

  static const _colors = [
    Color(0xFFF6C343), // Honey gold
    Color(0xFFE07A16), // Warm amber
    Color(0xFFD97757), // Soft terracotta
    Color(0xFF6DA37F), // Soft sage
    Color(0xFFB5836D), // Warm cocoa blush
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const count = 18;
    final phaseRad = ambientPhase * 2 * math.pi;

    for (int i = 0; i < count; i++) {
      final baseAngle = (i / count) * 2 * math.pi + (i.isEven ? 0.12 : -0.08);
      final driftAngle = baseAngle + math.sin(phaseRad + i) * 0.06;
      final maxDist = (i % 3 == 0) ? 84.0 : (i.isEven ? 68.0 : 58.0);
      final bob = math.sin(phaseRad * 1.5 + i * 0.8) * 3.5;
      final dist = 30.0 + (maxDist - 30.0) * progress + bob;
      final dx = center.dx + math.cos(driftAngle) * dist;
      final dy = center.dy + math.sin(driftAngle) * dist * 0.72;

      final twinkle = 0.55 + 0.45 * math.sin(phaseRad * 2 + i * 1.1).abs();
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: twinkle)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(driftAngle + progress * 1.4 + math.sin(phaseRad + i) * 0.4);

      if (i % 3 == 0) {
        // Twinkling 4-point sparkle star
        final r = (4.2 + 2.0 * twinkle) * (0.7 + 0.3 * progress);
        final path = Path()
          ..moveTo(0, -r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..quadraticBezierTo(0, 0, 0, r)
          ..quadraticBezierTo(0, 0, -r, 0)
          ..quadraticBezierTo(0, 0, 0, -r)
          ..close();
        canvas.drawPath(path, paint);
      } else if (i % 2 == 0) {
        // Pastel confetti pill
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.5, -2.0, 9.0, 4.0),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        // Soft dot
        canvas.drawCircle(Offset.zero, 2.8 + 0.8 * twinkle, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CozyConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ambientPhase != ambientPhase;
}
