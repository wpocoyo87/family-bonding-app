import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';

class BondingTab extends ConsumerStatefulWidget {
  const BondingTab({super.key});

  @override
  ConsumerState<BondingTab> createState() => _BondingTabState();
}

class _BondingTabState extends ConsumerState<BondingTab> {
  String _selectedChildId = 'all';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    final isMs = strings.isMs;
    final activeMember = appState.activeMember;
    final isParent = activeMember.isParentOrGuardian;
    final worldTheme = ref.watch(selectedWorldThemeProvider);

    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();

    final tasks = appState.activities;

    FamilyMember? currentSelectedChild;
    if (isParent && _selectedChildId != 'all') {
      currentSelectedChild = children.firstWhere(
        (c) => c.id == _selectedChildId,
        orElse: () => children.first,
      );
    }

    final targetMemberId = isParent
        ? (currentSelectedChild?.id ?? activeMember.id)
        : activeMember.id;

    final completedCount = isParent && _selectedChildId == 'all'
        ? tasks.where((t) => t.completedByMemberIds.isNotEmpty).length
        : tasks.where((t) => t.completedByMemberIds.contains(targetMemberId)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 36),
            Expanded(
              child: Column(
                children: [
                  Text(
                    strings.tr('Good Deeds & Habits', 'Good Deeds & Habits'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isParent
                        ? 'Guide, encourage and celebrate your children\'s progress.'
                        : strings.tr(
                            'Small actions. Big changes!',
                            'Small actions. Big changes!',
                          ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: EratPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: strings.tr('Tambah Habit', 'Add Habit'),
              onPressed: () => _showAddHabitSheet(context, ref, strings),
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: EratPalette.textDark,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // If Parent: Show Child Selector Chips (All Children, Emmi, Alex, Adam, Hana)
        if (isParent) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: const Text('👨‍👩‍👧‍👦'),
                    label: const Text('All Children'),
                    selected: _selectedChildId == 'all',
                    selectedColor: worldTheme.accentColor,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: EratPalette.lavenderBorder),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _selectedChildId == 'all'
                          ? Colors.white
                          : EratPalette.textDark,
                    ),
                    onSelected: (_) => setState(() => _selectedChildId = 'all'),
                  ),
                ),
                ...children.map((c) {
                  final isSelected = _selectedChildId == c.id;
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
                      onSelected: (_) =>
                          setState(() => _selectedChildId = c.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Illustrated Habit Cards Carousel
        SizedBox(
          height: 295,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _IllustratedHabitHeroCard(
                title: strings.tr('Brush Teeth', 'Brush Teeth'),
                rewardLabel: isParent ? '🏡 +2 Stars' : '🪙 75 Coin',
                assetPath: 'assets/images/habit_brush_teeth.jpg',
                cardBg: const Color(0xFFEBE6FF),
                buttonLabel: isParent
                    ? 'View Habit Details →'
                    : strings.tr('Claim Reward →', 'Claim Reward →'),
                onTap: () {
                  _showHabitDetailsModal(
                    context,
                    title: 'Brush Teeth Daily',
                    desc: 'Encourage brushing teeth twice a day for 2 minutes.',
                    stars: 2,
                    coins: 75,
                  );
                },
              ),
              const SizedBox(width: 14),
              _IllustratedHabitHeroCard(
                title: strings.tr('Read & Study', 'Read & Study'),
                rewardLabel: isParent ? '🏡 +3 Stars' : '🪙 50 Coin',
                assetPath: 'assets/images/habit_study_read.jpg',
                cardBg: const Color(0xFFE6F2FF),
                buttonLabel: isParent
                    ? 'View Habit Details →'
                    : strings.tr('Claim Reward →', 'Claim Reward →'),
                onTap: () {
                  _showHabitDetailsModal(
                    context,
                    title: 'Read & Study 15 Mins',
                    desc: 'Build focus and curiosity with 15 minutes of quiet reading.',
                    stars: 3,
                    coins: 50,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // CARD: Today's Overview Checklist Card
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
                  Text(
                    isParent ? "Today's Overview" : "Today's Tasks",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.textDark,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EratPalette.softLavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount of ${tasks.length} completed',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: EratPalette.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...tasks.map((task) {
                final isDone = isParent && _selectedChildId == 'all'
                    ? task.completedByMemberIds.isNotEmpty
                    : task.completedByMemberIds.contains(targetMemberId);

                final isPending = isParent && _selectedChildId == 'all'
                    ? task.pendingVerificationMemberIds.isNotEmpty
                    : task.pendingVerificationMemberIds.contains(targetMemberId);

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
                        child: Text(
                          task.iconEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title(isMs),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: EratPalette.textDark,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              isParent
                                  ? '⭐ +${task.stars} Family Stars'
                                  : '+${task.points} pts • ⭐ +${task.stars}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: EratPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: EratPalette.emeraldGreen),
                              SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: EratPalette.emeraldGreen,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isPending)
                        isParent
                            ? FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  foregroundColor: const Color(0xFFD97706),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  controller.approvePendingActivity(
                                    task.id,
                                    targetMemberId,
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Approve ⭐',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              )
                      else
                        isParent
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Not completed',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: EratPalette.textMuted,
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () =>
                                    controller.completeActivity(task.id),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: worldTheme.softTint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Do Habit',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
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
        const SizedBox(height: 20),

        // Action Buttons: If Parent, replace "Mark All Done" with Create New Habit & Create Challenge
        if (isParent) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: EratPalette.lavenderBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: EratPalette.primaryPurple),
                  label: const Text(
                    '+ Create New Habit',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.primaryPurple,
                    ),
                  ),
                  onPressed: () => _showAddHabitSheet(context, ref, strings),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: worldTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events_rounded, size: 18),
                  label: const Text(
                    'Create Challenge',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () => _showAddHabitSheet(context, ref, strings),
                ),
              ),
            ],
          ),
        ] else ...[
          // For Child: Claim habits reward
          EratPrimaryPillButton(
            label: strings.tr('Complete Today\'s Habit ✨', 'Complete Today\'s Habit ✨'),
            onPressed: () {
              if (tasks.isNotEmpty) {
                controller.completeActivity(tasks.first.id);
              }
            },
          ),
        ],
      ],
    );
  }

  void _showHabitDetailsModal(
    BuildContext context, {
    required String title,
    required String desc,
    required int stars,
    required int coins,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: EratPalette.textMuted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: EratPalette.softLavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('🏡 +$stars Family Stars',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: EratPalette.primaryPurple)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('🪙 $coins Coins for Child',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EratPalette.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddHabitSheet(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) {
    final titleCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tr('Tambah Tabiat / Kebaikan Baru', 'Add New Good Deed / Habit'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: strings.tr(
                    'Cth: Baca buku 15 minit bersama',
                    'E.g., Read for 15 mins together',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EratPrimaryPillButton(
                label: strings.tr('Simpan', 'Save Habit'),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  ref.read(eratControllerProvider.notifier).addActivity(
                        titleMs: titleCtrl.text.trim(),
                        titleEn: titleCtrl.text.trim(),
                        descMs: 'Good deed & family habit',
                        descEn: 'Good deed & family habit',
                        iconEmoji: '🌟',
                        category: ActivityCategory.goodHabit,
                        durationMinutes: 10,
                        points: 15,
                        stars: 2,
                        requiresParentVerification: false,
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IllustratedHabitHeroCard extends StatelessWidget {
  final String title;
  final String rewardLabel;
  final String assetPath;
  final Color cardBg;
  final String buttonLabel;
  final VoidCallback onTap;

  const _IllustratedHabitHeroCard({
    required this.title,
    required this.rewardLabel,
    required this.assetPath,
    required this.cardBg,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: EratPalette.softShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: EratPalette.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  rewardLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: EratPalette.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                assetPath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: EratPalette.primaryPurple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: onTap,
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
