import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';
import '../../goals/presentation/wish_goals_tab.dart';

class LedgerMilestonesTab extends ConsumerStatefulWidget {
  const LedgerMilestonesTab({super.key});

  @override
  ConsumerState<LedgerMilestonesTab> createState() =>
      _LedgerMilestonesTabState();
}

class _LedgerMilestonesTabState extends ConsumerState<LedgerMilestonesTab> {
  bool _isPersonal = true;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final activeMember = appState.activeMember;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      children: [
        // Top Header (Matching Mockup Screen 6: "Milestones & Rewards / Celebrate every step!")
        Center(
          child: Column(
            children: [
              Text(
                strings.tr('Milestones & Rewards', 'Milestones & Rewards'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.tr('Celebrate every step!', 'Celebrate every step!'),
                style: const TextStyle(
                  fontSize: 13,
                  color: EratPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // CARD 1: Golden Star Medal Celebration Card (Matching Mockup Screen 6)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFBEB),
                Color(0xFFF3F0FF),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Text('🎖️', style: TextStyle(fontSize: 72)),
                  SizedBox(width: 12),
                  Text('✨', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activeMember.isParentOrGuardian
                    ? strings.tr(
                        'Tabung Bintang Keluarga\n${appState.family.familyGoalTitleMs}',
                        'Family Star Goal\n${appState.family.familyGoalTitleMs}',
                      )
                    : strings.tr(
                        "You've reached\n10 Good Habits!",
                        "You've reached\n10 Good Habits!",
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                activeMember.isParentOrGuardian
                    ? '🏡 ⭐ ${appState.family.familyGoalCurrentStars} / ${appState.family.familyGoalTargetStars} Family Stars'
                    : '⭐ ${activeMember.stars} Stars  •  💎 ${activeMember.points} Points',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: EratPalette.primaryPurple,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                height: 44,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: EratPalette.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: Text(strings.tr('Wish Goals', 'Wish Goals')),
                          ),
                          body: const WishGoalsTab(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    activeMember.isParentOrGuardian
                        ? strings.tr('Luluskan Wish Anak', 'Approve Child Wishes')
                        : strings.tr('Claim Reward', 'Claim Reward'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Personal | Family Toggle + Milestones Card (Matching Mockup Screen 6)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPersonal = true),
                      child: Column(
                        children: [
                          Text(
                            strings.tr('Personal', 'Personal'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _isPersonal
                                  ? EratPalette.primaryPurple
                                  : EratPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: _isPersonal
                                  ? EratPalette.primaryPurple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPersonal = false),
                      child: Column(
                        children: [
                          Text(
                            strings.tr('Family', 'Family'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: !_isPersonal
                                  ? EratPalette.primaryPurple
                                  : EratPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: !_isPersonal
                                  ? EratPalette.primaryPurple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),

              if (_isPersonal) ...[
                _MilestoneRow(
                  iconWidget: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(
                      Icons.check_rounded,
                      color: EratPalette.emeraldGreen,
                      size: 20,
                    ),
                  ),
                  title: strings.tr('First Week', 'First Week'),
                  subtitle: strings.tr('Build your routine', 'Build your routine'),
                ),
                const SizedBox(height: 14),
                _MilestoneRow(
                  iconWidget: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Text('🎁', style: TextStyle(fontSize: 18)),
                  ),
                  title: strings.tr('10 Good Habits', '10 Good Habits'),
                  subtitle: strings.tr('Keep going!', 'Keep going!'),
                ),
                const SizedBox(height: 14),
                _MilestoneRow(
                  iconWidget: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Text('🥈', style: TextStyle(fontSize: 18)),
                  ),
                  title: strings.tr('Family Helper', 'Family Helper'),
                  subtitle: strings.tr('Support your family', 'Support your family'),
                ),
              ] else ...[
                _MilestoneRow(
                  iconWidget: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Text('🏡', style: TextStyle(fontSize: 18)),
                  ),
                  title: appState.family.familyGoalTitleMs,
                  subtitle:
                      '⭐ ${appState.family.familyGoalCurrentStars} / ${appState.family.familyGoalTargetStars} Family Stars',
                ),
                const SizedBox(height: 14),
                _MilestoneRow(
                  iconWidget: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFEDE9FE),
                    child: Text('🤝', style: TextStyle(fontSize: 18)),
                  ),
                  title: strings.tr('Team Spirit', 'Team Spirit'),
                  subtitle: strings.tr(
                    'Aktiviti 10-Minit bersama keluarga',
                    '10-Min Bonding together as a family',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String subtitle;

  const _MilestoneRow({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: EratPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
