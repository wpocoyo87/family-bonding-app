import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../auth/presentation/auth_family_screen.dart';
import '../../auth/presentation/member_pin_login_screen.dart';
import 'family_star_goal_screen.dart';
import 'family_tasks_screen.dart';

class FamilyPublicScreen extends ConsumerStatefulWidget {
  const FamilyPublicScreen({super.key});

  @override
  ConsumerState<FamilyPublicScreen> createState() => _FamilyPublicScreenState();
}

class _FamilyPublicScreenState extends ConsumerState<FamilyPublicScreen> {
  Timer? _noteRotationTimer;
  int _activeNoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _startNoteRotationTimer();
  }

  @override
  void reassemble() {
    super.reassemble();
    _startNoteRotationTimer();
  }

  void _startNoteRotationTimer() {
    _noteRotationTimer?.cancel();
    _noteRotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final notesCount = ref.read(eratControllerProvider).diningTableNotes.length;
      if (notesCount <= 1) return;
      setState(() {
        _activeNoteIndex = (_activeNoteIndex + 1) % notesCount;
      });
    });
  }

  @override
  void dispose() {
    _noteRotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final family = appState.family;
    final activities = appState.activities;
    final diningNotes = appState.diningTableNotes;
    final activeNote = diningNotes.isEmpty
        ? null
        : diningNotes[_activeNoteIndex % diningNotes.length];
    final activeNoteText = activeNote == null
        ? strings.tr(
            'Kerjasama kecil hari ini membina kenangan terindah bersama.',
            'Small efforts today build cherished family memories.',
          )
        : (strings.isMs ? activeNote.textMs : activeNote.textEn);

    final goalProgress = family.familyGoalTargetStars > 0
        ? (family.familyGoalCurrentStars / family.familyGoalTargetStars)
            .clamp(0.0, 1.0)
        : 0.0;
    final completedTasksCount = activities
        .where((a) => a.isFullyCompleted(appState.members))
        .length;
    final taskProgress = activities.isEmpty
        ? 0.0
        : (completedTasksCount / activities.length).clamp(0.0, 1.0);
    final goalTitle =
        strings.isMs ? family.familyGoalTitleMs : family.familyGoalTitleEn;

    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    final extraBottomInset =
        bottomSafeInset >= 34.0 ? 0.0 : (34.0 - bottomSafeInset);

    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            final isTablet = viewportConstraints.maxWidth >= 600.0;
            final horizontalPad = isTablet ? 32.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 860.0 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    isTablet ? 18 : 10,
                    horizontalPad,
                    extraBottomInset + (isTablet ? 18 : 10),
                  ),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Minimal Top Bar (Matches APP-004 Header: Family Photo/Logo + Family Name + Modes Pill + 44x44 Overflow)
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showFamilySettingsSheet(context, ref);
                    },
                    child: MediaStorageService.buildFamilyAvatar(
                      photoPath: family.photoPath,
                      size: 42,
                      fallback: const EratBrandLogo(size: 42),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                family.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: Color(0xFFD97757),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              size: 12.5,
                              color: Color(0xFF8C685C),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                strings.tr(
                                  'Paparan Keluarga',
                                  'Family View',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5A463C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Clear "Modes" Switcher Pill (Matches APP-004 Pill Style, >= 44x44 pt hit area)
                  Semantics(
                    button: true,
                    label: strings.tr(
                      'Tukar mod paparan',
                      'Switch display mode',
                    ),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(appViewModeProvider.notifier).state =
                            AppViewMode.selection;
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        child: Center(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: CozyTheme.pillBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: CozyTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 15,
                                  color: CozyTheme.textDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.tr('Mod', 'Modes'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Overflow Menu (... with >= 44x44 pt hit area)
                  PopupMenuButton<String>(
                    tooltip: strings.tr('Pilihan lanjut', 'More options'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 190),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (val) {
                      if (val == 'settings') {
                        _showFamilySettingsSheet(context, ref);
                      } else if (val == 'modes') {
                        ref.read(appViewModeProvider.notifier).state =
                            AppViewMode.selection;
                      } else if (val == 'lang') {
                        ref.read(appLanguageProvider.notifier).update(
                              (l) => l == AppLanguage.ms
                                  ? AppLanguage.en
                                  : AppLanguage.ms,
                            );
                      } else if (val == 'logout') {
                        ref.read(showOnboardingFlowProvider.notifier).state =
                            true;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'settings',
                        height: 46,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: CozyTheme.textMedium,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.tr(
                                'Tetapan Keluarga',
                                'Family Settings',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CozyTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'modes',
                        height: 46,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.dashboard_customize_rounded,
                              size: 18,
                              color: CozyTheme.textMedium,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.tr(
                                'Pilih Mod Paparan',
                                'Choose Display Mode',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CozyTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'lang',
                        height: 46,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.language_rounded,
                              size: 18,
                              color: CozyTheme.textMedium,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.tr(
                                'Tukar Bahasa (EN/BM)',
                                'Switch Language (EN/BM)',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CozyTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        height: 46,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.tr('Log Keluar', 'Sign Out'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEEDAC4),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: CozyTheme.textDark,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Section Title (Clean, High-Contrast Typography)
              Center(
                child: Column(
                  children: [
                    Text(
                      strings.tr(
                        'Papan Suasana Keluarga',
                        'Family Ambient Board',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.tr(
                        'Matlamat bintang & tugasan harian bersama.',
                        'Shared star goals & daily tasks.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A463C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Balanced Adaptive Viewport Cards + Warm Family Note (Phone Stacked / iPad 2-Column Side-by-Side)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final starGoalCard = _buildGatewayCard(
                      isTablet: isTablet,
                      cardBackground: const Color(0xFFF5E4DC),
                      cardBorderColor: const Color(0xFFE5CEC2),
                      microIcon: Icons.star_rounded,
                      microIconColor: const Color(0xFF8C685C),
                      microStat:
                          '${family.familyGoalCurrentStars}/${family.familyGoalTargetStars} ${strings.tr('Bintang', 'Stars')}',
                      title: strings.tr(
                        'Matlamat Bintang',
                        'Family Star Goal',
                      ),
                      description: goalTitle,
                      progressValue: goalProgress,
                      progressColor: const Color(0xFF6D4C41),
                      progressTrackColor: const Color(0xB3FFFFFF),
                      imageAssetPath: 'assets/images/family_goal_cozy.jpg',
                      fallbackIcon: Icons.star_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const FamilyStarGoalScreen(),
                          ),
                        );
                      },
                    );

                    final dailyActivitiesCard = _buildGatewayCard(
                      isTablet: isTablet,
                      cardBackground: const Color(0xFFF5E4DC),
                      cardBorderColor: const Color(0xFFE5CEC2),
                      microIcon: Icons.checklist_rounded,
                      microIconColor: const Color(0xFF8C685C),
                      microStat:
                          '${activities.length} ${strings.tr('Aktiviti Harian', 'Daily Activities')}',
                      title: strings.tr(
                        'Aktiviti Harian',
                        'Daily Activities',
                      ),
                      description: strings.tr(
                        'Rutin, tabiat baik & tugasan bersama.',
                        'Habits, chores & family routines.',
                      ),
                      progressValue: taskProgress,
                      progressColor: const Color(0xFF6D4C41),
                      progressTrackColor: const Color(0xB3FFFFFF),
                      progressCaption: strings.tr(
                        '$completedTasksCount/${activities.length} siap hari ini',
                        '$completedTasksCount/${activities.length} done today',
                      ),
                      imageAssetPath: 'assets/images/family_task_cozy.jpg',
                      fallbackIcon: Icons.checklist_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const FamilyTasksScreen(),
                          ),
                        );
                      },
                    );

                    final diningTableNote = Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF2E8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEBDCC8),
                          width: 1.1,
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showDiningNotesSheet(context, ref);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5E4DC),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 16,
                                    color: Color(0xFF8C685C),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.tr(
                                          'Nota Keluarga',
                                          'Family Note',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 450,
                                        ),
                                        child: Text(
                                          '“$activeNoteText”',
                                          key: ValueKey(
                                            activeNote?.id ?? activeNoteText,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF5A463C),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Color(0xFF8C685C),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    // Tablet / iPad Layout (width >= 600): Balanced 2-column side-by-side cards + Family Note
                    if (isTablet) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: starGoalCard),
                                    const SizedBox(width: 20),
                                    Expanded(child: dailyActivitiesCard),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              diningTableNote,
                            ],
                          ),
                        ),
                      );
                    }

                    // On standard/tall phones, let the 2 primary cards expand gracefully to eliminate middle dead space
                    if (constraints.maxHeight >= 470) {
                      return Column(
                        children: [
                          Expanded(child: starGoalCard),
                          const SizedBox(height: 14),
                          Expanded(child: dailyActivitiesCard),
                          const SizedBox(height: 16),
                          diningTableNote,
                        ],
                      );
                    }

                    // Compact / Large Dynamic Type fallback: smooth scrollable layout
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          starGoalCard,
                          const SizedBox(height: 14),
                          dailyActivitiesCard,
                          const SizedBox(height: 16),
                          diningTableNote,
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Pinned Bottom CTA: Open Private Space (PIN Required) — Centered maxWidth on iPad
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isTablet ? 360 : double.infinity,
                    maxWidth: isTablet ? 440 : double.infinity,
                    minHeight: 54,
                  ),
                  child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const MemberPinLoginScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFBF5),
                    foregroundColor: const Color(0xFF6D4C41),
                    side: const BorderSide(
                      color: Color(0xFF6D4C41),
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: Color(0xFF6D4C41),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          strings.tr(
                            'Buka Ruang Peribadi (Perlu PIN)',
                            'Open Private Space (PIN Required)',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6D4C41),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF6D4C41),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGatewayCard({
    bool isTablet = false,
    required Color cardBackground,
    required Color cardBorderColor,
    required IconData microIcon,
    required Color microIconColor,
    required String microStat,
    required String title,
    required String description,
    double? progressValue,
    Color progressColor = const Color(0xFF6D4C41),
    Color progressTrackColor = const Color(0xB3FFFFFF),
    String? progressCaption,
    required String imageAssetPath,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    final illustrationWidget = ExcludeSemantics(
      child: Container(
        width: isTablet ? 168 : 138,
        height: isTablet ? 168 : 138,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFEEDAC4),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(120, 75, 40, 0.10),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            imageAssetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  fallbackIcon,
                  size: 42,
                  color: CozyTheme.connectorDot,
                ),
              );
            },
          ),
        ),
      ),
    );

    final copyBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clean Direct Micro-Stat Label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(microIcon, size: 15, color: microIconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                microStat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6D4C41),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Direct Bold Title + Subtle Chevron Affordance
        Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: CozyTheme.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: CozyTheme.connectorDot,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Readable Description
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isTablet ? 14.5 : 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5A463C),
            height: 1.38,
          ),
        ),

        // Visual Progress Bar + Live Caption
        if (progressValue != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 7,
              backgroundColor: progressTrackColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
        if (progressCaption != null) ...[
          const SizedBox(height: 6),
          Text(
            progressCaption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6D4C41),
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorderColor, width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(110, 70, 38, 0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 18,
              vertical: isTablet ? 26 : 24,
            ),
            child: isTablet
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: illustrationWidget),
                      const SizedBox(height: 20),
                      copyBlock,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: copyBlock),
                      const SizedBox(width: 14),
                      illustrationWidget,
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Dining Table Notes Bottom Sheet — View, Add & Delete Family Notes (Auto-rotates every 1 min)
  void _showDiningNotesSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final notes = sheetRef.watch(eratControllerProvider).diningTableNotes;
            final viewInsets = MediaQuery.viewInsetsOf(modalCtx).bottom;
            final bottomSafe = MediaQuery.viewPaddingOf(modalCtx).bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(modalCtx).height * 0.78,
                ),
                padding: EdgeInsets.fromLTRB(
                  22,
                  14,
                  22,
                  (bottomSafe >= 34.0 ? bottomSafe : 34.0) + 12,
                ),
                decoration: const BoxDecoration(
                  color: CozyTheme.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CozyTheme.connectorLine,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5E4DC),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: Color(0xFF8C685C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.tr(
                                  'Nota Keluarga',
                                  'Family Notes',
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              Text(
                                strings.tr(
                                  'Bertukar automatik setiap 5 saat.',
                                  'Rotates automatically every 5 seconds.',
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5A463C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalCtx).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: CozyTheme.textDark,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Add New Note Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: noteCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: strings.tr(
                                'Tulis nota mesra untuk keluarga...',
                                'Write a warm note for your family...',
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: CozyTheme.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: CozyTheme.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6D4C41),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (noteCtrl.text.trim().isEmpty) return;
                              HapticFeedback.lightImpact();
                              await sheetRef
                                  .read(eratControllerProvider.notifier)
                                  .addDiningTableNote(noteCtrl.text);
                              noteCtrl.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6D4C41),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: Text(
                              strings.tr('Tambah', 'Add'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Notes List from Family Database
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (itemCtx, idx) {
                          final note = notes[idx];
                          final text = strings.isMs ? note.textMs : note.textEn;
                          return Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                            decoration: BoxDecoration(
                              color: note.isPublic
                                  ? const Color(0xFFFAF2E8)
                                  : const Color(0xFFF5E4DC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: note.isPublic
                                    ? const Color(0xFFEBDCC8)
                                    : const Color(0xFFE5CEC2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.isPublic
                                            ? strings.tr(
                                                'ERAT Awam',
                                                'ERAT Public',
                                              )
                                            : strings.tr(
                                                'Nota Keluarga',
                                                'Family Note',
                                              ),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF8C685C),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '“$text”',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: CozyTheme.textDark,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!note.isPublic)
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      sheetRef
                                          .read(eratControllerProvider.notifier)
                                          .deleteDiningTableNote(note.id);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFF8C685C),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 38,
                                      minHeight: 38,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Family Settings Bottom Sheet — Edit Family Photo, Name, Star Goal Title & Target Stars (Saved to Cloud Firestore)
  void _showFamilySettingsSheet(BuildContext context, WidgetRef ref) {
    final appState = ref.read(eratControllerProvider);
    final strings = ref.read(appStringsProvider);
    final family = appState.family;

    final nameCtrl = TextEditingController(text: family.name);
    String? pendingPhotoPath = family.photoPath;
    bool clearPhoto = false;
    bool isUploadingPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickFamilyPhoto(ImageSource source) async {
              final picked = await MediaStorageService.pickImage(
                source: source,
              );
              if (picked == null) return;
              setModalState(() => isUploadingPhoto = true);
              final uploaded = await MediaStorageService.uploadFamilyPhoto(
                familyId: family.id,
                imageFile: picked,
              );
              if (!modalCtx.mounted) return;
              setModalState(() {
                isUploadingPhoto = false;
                if (uploaded != null) {
                  pendingPhotoPath = uploaded;
                  clearPhoto = false;
                }
              });
            }

            final viewInsets = MediaQuery.viewInsetsOf(modalCtx).bottom;
            final bottomSafe = MediaQuery.viewPaddingOf(modalCtx).bottom;
            final hasCustomPhoto =
                !clearPhoto &&
                pendingPhotoPath != null &&
                pendingPhotoPath!.isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  22,
                  14,
                  22,
                  (bottomSafe >= 34.0 ? bottomSafe : 34.0) + 12,
                ),
                decoration: const BoxDecoration(
                  color: CozyTheme.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CozyTheme.connectorLine,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          MediaStorageService.buildFamilyAvatar(
                            photoPath: hasCustomPhoto ? pendingPhotoPath : null,
                            size: 38,
                            fallback: const EratBrandLogo(size: 38),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.tr(
                                    'Tetapan Keluarga',
                                    'Family Settings',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                Text(
                                  strings.tr(
                                    'Disimpan automatik ke pangkalan data.',
                                    'Saved directly to your family database.',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF5A463C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(modalCtx).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: CozyTheme.textDark,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Family Photo Upload / Replace Row
                      Text(
                        strings.tr('Foto Keluarga', 'Family Photo'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: CozyTheme.border),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                MediaStorageService.buildFamilyAvatar(
                                  photoPath: hasCustomPhoto
                                      ? pendingPhotoPath
                                      : null,
                                  size: 56,
                                  fallback: const EratBrandLogo(size: 56),
                                ),
                                if (isUploadingPhoto)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          30,
                                          22,
                                          18,
                                          0.45,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: isUploadingPhoto
                                        ? null
                                        : () => pickFamilyPhoto(
                                            ImageSource.gallery,
                                          ),
                                    icon: const Icon(
                                      Icons.upload_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      strings.tr(
                                        'Muat Naik Foto',
                                        'Upload Photo',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6D4C41),
                                      side: const BorderSide(
                                        color: CozyTheme.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      minimumSize: const Size(0, 40),
                                    ),
                                  ),
                                  if (hasCustomPhoto)
                                    OutlinedButton.icon(
                                      onPressed: isUploadingPhoto
                                          ? null
                                          : () => setModalState(() {
                                                pendingPhotoPath = null;
                                                clearPhoto = true;
                                              }),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        strings.tr('Padam', 'Delete'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(
                                          color: Color(0xFFF5C2C0),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        minimumSize: const Size(0, 40),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Family Name Input
                      Text(
                        strings.tr('Nama Keluarga', 'Family Name'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: strings.tr(
                            'cth: Keluarga Bahagia',
                            'e.g. Happy Family',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: CozyTheme.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: CozyTheme.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF6D4C41),
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Family Star Goal Hub Section (Direct CTA to Create & Manage Goals)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E4DC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5CEC2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6D4C41),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.stars_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    strings.tr(
                                      'Matlamat Bintang Keluarga',
                                      'Family Star Goal',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '★ ${family.familyGoalCurrentStars}/${family.familyGoalTargetStars}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              family.familyGoalTitle(strings.isMs).isNotEmpty
                                  ? family.familyGoalTitle(strings.isMs)
                                  : strings.tr(
                                      'Belum ada matlamat aktif',
                                      'No active goal set',
                                    ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(modalCtx).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) =>
                                          const FamilyStarGoalScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_task_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  strings.tr(
                                    'Cipta & Urus Matlamat Keluarga',
                                    'Create & Manage Family Goals',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6D4C41),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFD4B8AA),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isUploadingPhoto
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  await ref
                                      .read(eratControllerProvider.notifier)
                                      .updateFamilySettings(
                                        familyName: nameCtrl.text,
                                        goalTitle: family.familyGoalTitleMs,
                                        goalTargetStars:
                                            family.familyGoalTargetStars,
                                        photoPath: pendingPhotoPath,
                                        clearPhoto: clearPhoto,
                                      );
                                  if (modalCtx.mounted) {
                                    Navigator.of(modalCtx).pop();
                                  }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF6D4C41),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  content: Text(
                                    strings.tr(
                                      'Tetapan keluarga berjaya disimpan.',
                                      'Family settings saved.',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }
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
                            strings.tr('Simpan Tetapan', 'Save Settings'),
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
            );
          },
        );
      },
    );
  }
}
