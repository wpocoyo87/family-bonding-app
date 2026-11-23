import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';
import '../../goals/presentation/wish_goals_tab.dart';
import 'gamified_milestone_map_view.dart';

class QuestsRewardsTab extends ConsumerStatefulWidget {
  const QuestsRewardsTab({super.key});

  @override
  ConsumerState<QuestsRewardsTab> createState() => _QuestsRewardsTabState();
}

class _QuestsRewardsTabState extends ConsumerState<QuestsRewardsTab> {
  // 0 = Daily Quests (Habits), 1 = Milestones (Child Only), 2 = Wish Goals, 3 = Badges & Farm, 4 = Star Ledger
  int _activeSegment = 0;
  String _selectedChildFilter = 'all';
  String? _lastMemberId;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    final isMs = strings.isMs;
    final activeMember = appState.activeMember;
    final isParent = activeMember.isParentOrGuardian;
    final worldTheme = ref.watch(selectedWorldThemeProvider);

    // Apabila bertukar profil:
    // - Ibu Bapa (Parent) TIADA milestone -> mula di Daily Quests (0)
    // - Anak-anak (Child) ADA milestone -> terus buka Full-View Milestone Map (1)
    if (_lastMemberId != activeMember.id) {
      _lastMemberId = activeMember.id;
      _activeSegment = isParent ? 0 : 1;
    } else if (isParent && _activeSegment == 1) {
      _activeSegment = 0;
    }

    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();
    final tasks = appState.activities;

    // Full-screen Gamified Milestone Map Canvas HANYA untuk Anak-anak (!isParent)
    if (!isParent && _activeSegment == 1) {
      return GamifiedMilestoneMapView(
        onBack: () => setState(() => _activeSegment = 0),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      children: [
        // Top Header: Quests & Rewards
        Center(
          child: Column(
            children: [
              Text(
                strings.tr('Quests & Rewards', 'Quests & Rewards'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isParent
                    ? 'Complete good deeds, harvest stars & celebrate together!'
                    : 'Complete daily quests to earn coins & unlock dream rewards! 🎮✨',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: EratPalette.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // FarmVille-Style Garden / Family Tree Harvest Card
        _buildFarmVilleHarvestHero(appState, worldTheme, isParent),
        const SizedBox(height: 16),

        // Segment Tabs: 🎮 Quests (Habits) | 🏆 Milestones | 🎁 Wish Goals | 🏅 Badges | 📜 Ledger
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EratPalette.lavenderBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSegmentButton(0, '🎮 Daily Quests', worldTheme),
                if (!isParent)
                  _buildSegmentButton(1, '🏆 Milestones', worldTheme),
                _buildSegmentButton(2, '🎁 Wish Goals', worldTheme),
                _buildSegmentButton(3, '🏅 Badges & Farm', worldTheme),
                _buildSegmentButton(4, '📜 Star Ledger', worldTheme),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Body Content based on active segment
        switch (_activeSegment) {
          0 => _buildDailyQuestsView(appState, controller, children, tasks, isParent, worldTheme, isMs, strings),
          1 => _buildMilestonesView(appState, worldTheme, isParent),
          2 => const WishGoalsTab(),
          3 => _buildBadgesAndHarvestView(appState, worldTheme),
          _ => _buildLedgerAuditView(appState, worldTheme),
        },
      ],
    );
  }

  Widget _buildSegmentButton(int index, String label, EratWorldTheme worldTheme) {
    final isSelected = _activeSegment == index;
    return InkWell(
      onTap: () => setState(() => _activeSegment = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? worldTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : EratPalette.textDark,
          ),
        ),
      ),
    );
  }

  /// FarmVille-Style Harvest & Growth Hero Banner
  Widget _buildFarmVilleHarvestHero(EratAppState appState, EratWorldTheme worldTheme, bool isParent) {
    final family = appState.family;
    final progressPct = (family.familyGoalCurrentStars / family.familyGoalTargetStars).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFEAF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: EratPalette.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: EratPalette.softShadow,
                ),
                alignment: Alignment.center,
                child: const Text('🏡🌻', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Harvest: Level 4 🌾',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      family.familyGoalTitleEn,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: EratPalette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${family.familyGoalCurrentStars}/${family.familyGoalTargetStars}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: EratPalette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🌱 ${(progressPct * 100).toInt()}% Grown',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
              Text(
                'Harvest Reward: Family Pizza & Movie Night! 🍕🎬',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Segment 0: Daily Quests (Habits with completion, stars/coin rewards, individual approval)
  Widget _buildDailyQuestsView(
    EratAppState appState,
    EratController controller,
    List<FamilyMember> children,
    List<BondingActivity> tasks,
    bool isParent,
    EratWorldTheme worldTheme,
    bool isMs,
    AppStrings strings,
  ) {
    FamilyMember? currentSelectedChild;
    if (isParent && _selectedChildFilter != 'all') {
      currentSelectedChild = children.firstWhere(
        (c) => c.id == _selectedChildFilter,
        orElse: () => children.first,
      );
    }
    final targetMemberId = isParent
        ? (currentSelectedChild?.id ?? appState.activeMember.id)
        : appState.activeMember.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Child filter chips if Parent
        if (isParent) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  avatar: const Text('👨‍👩‍👧‍👦'),
                  label: const Text('All Children'),
                  selected: _selectedChildFilter == 'all',
                  selectedColor: worldTheme.accentColor,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: EratPalette.lavenderBorder),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedChildFilter == 'all' ? Colors.white : EratPalette.textDark,
                  ),
                  onSelected: (_) => setState(() => _selectedChildFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ...children.map((c) {
                  final isSelected = _selectedChildFilter == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Text(c.avatarEmoji),
                      label: Text(c.name.split(' ').first),
                      selected: isSelected,
                      selectedColor: worldTheme.accentColor,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: EratPalette.lavenderBorder),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : EratPalette.textDark,
                      ),
                      onSelected: (_) => setState(() => _selectedChildFilter = c.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Quests List Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Quest Checklist 🎯',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                    ),
                  ),
                  Text(
                    '${tasks.where((t) => t.completedByMemberIds.contains(targetMemberId)).length} / ${tasks.length} Done',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: EratPalette.primaryPurple),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...tasks.map((task) {
                final isDone = task.completedByMemberIds.contains(targetMemberId);
                final isPending = task.pendingVerificationMemberIds.contains(targetMemberId);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: EratPalette.softLavender,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(task.iconEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title(isMs),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: EratPalette.textDark,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              '🪙 +${task.points} Coins • ⭐ +${task.stars} Family Stars',
                              style: const TextStyle(fontSize: 11, color: EratPalette.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: EratPalette.emeraldGreen),
                              SizedBox(width: 4),
                              Text('Harvested',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: EratPalette.emeraldGreen)),
                            ],
                          ),
                        )
                      else if (isPending)
                        isParent
                            ? FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  foregroundColor: const Color(0xFFD97706),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  controller.approvePendingActivity(task.id, targetMemberId);
                                },
                                child: const Text('Approve ⭐',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Pending',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFD97706))),
                              )
                      else
                        InkWell(
                          onTap: () => controller.completeActivity(task.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: worldTheme.softTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isParent ? 'Complete' : 'Do Quest',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: worldTheme.accentColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Segment 1: FarmVille Style Badges, Stickers & Farm Tree
  Widget _buildBadgesAndHarvestView(EratAppState appState, EratWorldTheme worldTheme) {
    final activeMember = appState.activeMember;

    final badges = [
      (title: 'Early Bird', desc: 'Woke up on time 5 days', emoji: '🌅', unlocked: true),
      (title: 'Book Worm', desc: 'Read 30 mins quiet study', emoji: '📚', unlocked: true),
      (title: 'Kind Helper', desc: 'Helped clean room', emoji: '🧹', unlocked: true),
      (title: 'Star Gardener', desc: 'Harvested 50 Family Stars', emoji: '🌻', unlocked: true),
      (title: '7-Day Streak', desc: 'Consistent habits for a week', emoji: '🔥', unlocked: true),
      (title: 'Master Chef Jr', desc: 'Helped prepare dinner', emoji: '🍳', unlocked: false),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: EratPalette.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${activeMember.name}\'s Badge Album 🏆',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (ctx, i) {
              final b = badges[i];
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: b.unlocked ? EratPalette.softLavender : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: b.unlocked ? EratPalette.lavenderBorder : Colors.transparent,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      b.emoji,
                      style: TextStyle(
                        fontSize: 30,
                        color: b.unlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: b.unlocked ? EratPalette.textDark : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.unlocked ? 'Unlocked ✨' : 'Locked 🔒',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: b.unlocked ? EratPalette.primaryPurple : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Segment 1: Family & Individual Milestones View
  Widget _buildMilestonesView(EratAppState appState, EratWorldTheme worldTheme, bool isParent) {
    final familyMilestones = [
      (
        title: '⭐ 100 Family Stars Reached',
        desc: 'Family collected 100 collective stars through mutual support.',
        unlocked: true,
        date: 'Achieved: 05 Nov 2026',
        icon: '🏆',
      ),
      (
        title: '🌱 Level 4 Harvest Hero',
        desc: 'Unlocked Pizza & Movie Night feast in Family Farm Garden.',
        unlocked: true,
        date: 'Achieved: 03 Nov 2026',
        icon: '🌾',
      ),
      (
        title: '💖 25 Kindness Deeds Challenge',
        desc: 'Complete 25 random acts of kindness across all family members.',
        unlocked: false,
        date: 'Progress: 18 / 25 acts (72%)',
        icon: '💖',
      ),
      (
        title: '📚 14-Day Family Reading Hour',
        desc: '14 consecutive evenings of 10-minute family storytime.',
        unlocked: false,
        date: 'Progress: 10 / 14 days',
        icon: '📖',
      ),
    ];

    final children = appState.members.where((m) => !m.isParentOrGuardian).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. GAMIFIED ADVENTURE ISLAND / ROADMAP MAP VIEW (5 Themes + Summit Award Image)
        const GamifiedMilestoneMapView(),
        const SizedBox(height: 20),

        // Family Collective Milestones
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🏡 Family Shared Milestones',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '2 Unlocked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Celebrated together as a team — no sibling comparison or competition.',
                style: TextStyle(fontSize: 12, color: EratPalette.textMuted),
              ),
              const SizedBox(height: 14),
              ...familyMilestones.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m.unlocked ? const Color(0xFFFAF5FF) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: m.unlocked ? const Color(0xFFE9D5FF) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: m.unlocked ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(m.icon, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: m.unlocked ? EratPalette.textDark : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.desc,
                              style: const TextStyle(fontSize: 11.5, color: EratPalette.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.date,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: m.unlocked ? EratPalette.primaryPurple : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (m.unlocked)
                        const Icon(Icons.check_circle_rounded, color: EratPalette.emeraldGreen, size: 22),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Individual Growth Milestones per Child
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌟 Individual Personal Milestones',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Personal growth records and badges earned by each child.',
                style: TextStyle(fontSize: 12, color: EratPalette.textMuted),
              ),
              const SizedBox(height: 14),
              ...children.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EratPalette.softLavender,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EratPalette.lavenderBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c.avatarEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            '${c.name} (${c.ageYears}y)',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: EratPalette.textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '🔥 ${c.streakDays}d Streak • ⭐ ${c.stars}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: EratPalette.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: c.milestones.map((ms) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDD6FE)),
                            ),
                            child: Text(
                              '🏅 $ms',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: EratPalette.textDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  /// Segment 3: Transparent Ledger
  Widget _buildLedgerAuditView(EratAppState appState, EratWorldTheme worldTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: EratPalette.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family Points & Stars Audit 📜',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: EratPalette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Transparent ledger of every good deed and family reward recorded.',
            style: TextStyle(fontSize: 12, color: EratPalette.textMuted),
          ),
          const SizedBox(height: 14),
          ...appState.ledger.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EratPalette.pageBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(entry.starsEarned > 0 ? '⭐' : '🪙', style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.memberName}: ${entry.reasonEn}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        Text(
                          '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: EratPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+${entry.pointsEarned} pts / +${entry.starsEarned} ⭐',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.primaryPurple,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
