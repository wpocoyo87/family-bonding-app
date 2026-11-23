import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';
import '../../auth/presentation/member_pin_login_screen.dart';

class AgeAdaptiveHomeTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const AgeAdaptiveHomeTab({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final activeMember = appState.activeMember;
    final worldTheme = ref.watch(selectedWorldThemeProvider);
    final viewMode = ref.watch(appViewModeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      children: [
        // Top Greeting Row (matching Mockup Screen 3: "Hello, Alex! 👋 Happy Family, Happy Life!")
        Row(
          children: [
            GestureDetector(
              onTap: () => onNavigateTab(4),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: EratPalette.softShadow,
                  border: Border.all(
                    color: EratPalette.lavenderBorder,
                    width: 2,
                  ),
                ),
                child: activeMember.customPhotoPath != null
                    ? ClipOval(
                        child: activeMember.customPhotoPath!.startsWith('http')
                            ? Image.network(
                                activeMember.customPhotoPath!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Text(
                                  activeMember.avatarEmoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              )
                            : Image.asset(
                                activeMember.customPhotoPath!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Text(
                                  activeMember.avatarEmoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                      )
                    : Text(
                        activeMember.avatarEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Hello, ${activeMember.name.split(" ").first}! 👋',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => _showWorldThemePickerSheet(context, ref),
                    child: Text(
                      '${worldTheme.emoji} ${worldTheme.title} • ${activeMember.isParentOrGuardian ? "Parent View" : activeMember.ageBand.shortTitle}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: worldTheme.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Notification Bell with Red Badge (matching Mockup Screen 3)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: EratPalette.softShadow,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: EratPalette.textDark,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.tr(
                              '🔔 Peringatan Mesra: Masa untuk aktiviti keluarga 10 minit hari ini!',
                              '🔔 Friendly Reminder: Time for your 10-minute family bonding today!',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Status Badge: Individual Private View
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF4FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5D0FE)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                size: 16,
                color: Color(0xFFD946EF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${activeMember.name} • Ruang Peribadi Aktif (Individual View)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF86198F),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  ref.read(isPrivateSpaceUnlockedProvider.notifier).state = false;
                  ref.read(appViewModeProvider.notifier).state =
                      AppViewMode.selection;
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF5D0FE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 13,
                        color: Color(0xFF86198F),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tukar Mod',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF86198F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (viewMode == AppViewMode.private) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF4FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5D0FE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 16, color: Color(0xFFD946EF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${activeMember.name} • Ruang Peribadi Aktif (PIN: ${activeMember.pin ?? "1234"})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF86198F),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    ref.read(isPrivateSpaceUnlockedProvider.notifier).state = false;
                    ref.read(appViewModeProvider.notifier).state = AppViewMode.family;
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF5D0FE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 12, color: Color(0xFF86198F)),
                        SizedBox(width: 3),
                        Text(
                          'Kunci',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF86198F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Protected Member Switcher Bar (Tapping another member triggers PIN prompt)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: appState.members.map((m) {
              final isSelected = m.id == activeMember.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Text(m.avatarEmoji),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${m.name.split(" ").first} (${m.ageYears}y)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : EratPalette.textDark,
                        ),
                      ),
                      if (!isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: EratPalette.textMuted,
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: worldTheme.accentColor,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: EratPalette.lavenderBorder),
                  onSelected: (_) {
                    if (m.id != activeMember.id) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => MemberPinLoginScreen(
                            preselectedMemberId: m.id,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),

        // Genuinely distinct Home Layouts per Role & Age Band (Section 3 & 5 of user spec)
        if (activeMember.isParentOrGuardian)
          _buildParentHomeDashboard(context, ref, appState, strings)
        else if (activeMember.ageBand == AgeBand.littleExplorer)
          _buildLittleExplorerHome(context, ref, appState, strings)
        else if (activeMember.ageBand == AgeBand.happyHabitBuilder)
          _buildHappyHabitBuilderHome(context, ref, appState, strings)
        else if (activeMember.ageBand == AgeBand.myLifeMyGoals)
          _buildTeenMatureMinimalHome(context, ref, appState, strings)
        else if (activeMember.ageBand == AgeBand.lifelongFamilyBond)
          _buildAdultPracticalHome(context, ref, appState, strings)
        else
          _buildStandardFamilyGrowHome(context, ref, appState, strings),
      ],
    );
  }

  /// PARENT HOME = Family Command Centre.
  /// Daily overview, clear progress metrics, pending approvals only, and
  /// per-child progress WITHOUT any ranking or point comparison between siblings.
  Widget _buildParentHomeDashboard(
    BuildContext context,
    WidgetRef ref,
    EratAppState appState,
    AppStrings strings,
  ) {
    final controller = ref.read(eratControllerProvider.notifier);
    final worldTheme = ref.watch(selectedWorldThemeProvider);
    final parent = appState.activeMember;
    final family = appState.family;
    final progressPct =
        (family.familyGoalCurrentStars / family.familyGoalTargetStars)
            .clamp(0.0, 1.0);
    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final firstName = parent.name.split(' ').first;

    // Pending child verifications (the ONLY items shown in the approval card)
    final pendingList = <({BondingActivity act, FamilyMember child})>[];
    for (final act in appState.activities) {
      for (final cId in act.pendingVerificationMemberIds) {
        final matches = appState.members.where((m) => m.id == cId);
        if (matches.isEmpty) continue;
        pendingList.add((act: act, child: matches.first));
      }
    }

    var tasksCompleted = 0;
    for (final act in appState.activities) {
      for (final c in children) {
        if (act.completedByMemberIds.contains(c.id)) tasksCompleted++;
      }
    }
    final activeChallenges = appState.activities
        .where((a) => a.category == ActivityCategory.familyChallenge)
        .length;
    final familyActivities = appState.activities
        .where((a) => a.category == ActivityCategory.bonding10Min)
        .length;

    Widget statTile(String value, String label, Color tint) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: EratPalette.textMuted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget metricRow(String label, String value, Color valueColor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: EratPalette.textMuted,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    Text sectionTitle(String t) => Text(
          t,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EratPalette.textDark,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Mother's Daily Overview
        Text(
          '$greeting, $firstName!',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: EratPalette.textDark,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Here\'s your family\'s day at a glance.',
          style: TextStyle(fontSize: 13, color: EratPalette.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            statTile('$tasksCompleted', 'Tasks completed',
                const Color(0xFFE8F8EE)),
            statTile('${pendingList.length}', 'Pending approvals',
                EratPalette.warmCream),
            statTile('$activeChallenges', 'Active challenges',
                const Color(0xFFEAF4FF)),
            statTile('$familyActivities', 'Family activity today',
                EratPalette.softLavender),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Pending Approval (only items that need the parent)
        sectionTitle('Pending Approval'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: EratPalette.softShadow,
          ),
          child: pendingList.isEmpty
              ? const Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All caught up! Nothing is waiting for your approval.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: EratPalette.textDark,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: pendingList.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EratPalette.warmCream,
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: EratPalette.warmCreamBorder),
                      ),
                      child: Row(
                        children: [
                          Text(item.child.avatarEmoji,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.child.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: EratPalette.textDark,
                                  ),
                                ),
                                Text(
                                  'Completed: ${item.act.title(strings.isMs)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: EratPalette.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            EratPalette.emeraldGreen,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () =>
                                          controller.approvePendingActivity(
                                        item.act.id,
                                        item.child.id,
                                      ),
                                      child: const Text(
                                        'Approve',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _showReviewDialog(
                                        context,
                                        item.act,
                                        item.child,
                                        strings,
                                        () => controller
                                            .approvePendingActivity(
                                          item.act.id,
                                          item.child.id,
                                        ),
                                      ),
                                      child: const Text(
                                        'Review',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),

        // 3. Family Progress with three clearly separated measurements
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFFFFFFFF), worldTheme.softTint],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Progress',
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: progressPct,
                            strokeWidth: 9,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              EratPalette.emeraldGreen,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${(progressPct * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: EratPalette.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        metricRow(
                          'Family Goal Progress',
                          '${(progressPct * 100).round()}%',
                          EratPalette.textDark,
                        ),
                        metricRow(
                          'Shared Family Stars',
                          '⭐ ${family.familyGoalCurrentStars} stars',
                          EratPalette.textDark,
                        ),
                        metricRow(
                          'Weekly Growth',
                          '+12%',
                          EratPalette.emeraldGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Children progress (individual; no ranking, no point comparison)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            sectionTitle('Children'),
            TextButton(
              onPressed: () => _showAllChildrenSheet(context, appState),
              child: const Text(
                'View All Children',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: children.map((c) {
              final mine = appState.activities
                  .where((a) => c.ageYears >= a.minAge && c.ageYears <= a.maxAge)
                  .toList();
              final done =
                  mine.where((a) => a.completedByMemberIds.contains(c.id)).length;
              final waiting = mine
                  .where((a) => a.pendingVerificationMemberIds.contains(c.id))
                  .length;
              final pct = mine.isEmpty ? 0.0 : done / mine.length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Text(c.avatarEmoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${c.name} • ${c.ageYears}y',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: EratPalette.textDark,
                                  ),
                                ),
                              ),
                              if (waiting > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: EratPalette.warmCream,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$waiting waiting',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                EratPalette.primaryPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$done of ${mine.length} habits done today',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: EratPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // 5. Parent AI Insights Hub & Daily Family Reminder
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF9EE),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🧚🏻', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Family Insight & Guidance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: EratPalette.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EratPalette.primaryPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Live AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Child-specific quick behavioral insights
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3E8FF)),
                ),
                child: Column(
                  children: [
                    _buildParentChildInsightRow('👧🏻 Emmi (4y)', 'Bedtime anxiety detected in chat. Recommend 10m cuddle & storytime.'),
                    const Divider(height: 14, color: Color(0xFFF3F4F6)),
                    _buildParentChildInsightRow('👦🏻 Alex (8y)', 'Completed habits without reminder today! High intrinsic motivation.'),
                    const Divider(height: 14, color: Color(0xFFF3F4F6)),
                    _buildParentChildInsightRow('🚀 Adam (11y)', 'Frustrated with science model. Offer collaborative co-play, avoid lecturing.'),
                    const Divider(height: 14, color: Color(0xFFF3F4F6)),
                    _buildParentChildInsightRow('🎧 Hana (15y)', 'Fatigued from trial exams. Low-pressure care (hot drink/note) works best.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Today\'s Family Reminder',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '📖 10 minutes of gadget-free family reading together tonight.',
                style: TextStyle(fontSize: 12, height: 1.35, color: EratPalette.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 6. Quick Access
        sectionTitle('Quick Access'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickAccessItem(
              assetPath: 'assets/images/icon_good_deeds.jpg',
              label: 'Good Deeds',
              onTap: () => onNavigateTab(1),
            ),
            _QuickAccessItem(
              assetPath: 'assets/images/icon_milestones.jpg',
              label: 'Community',
              onTap: () => onNavigateTab(3),
            ),
            _QuickAccessItem(
              assetPath: 'assets/images/icon_ai_coach.jpg',
              label: 'AI Companion',
              onTap: () => onNavigateTab(2),
            ),
            _QuickAccessItem(
              assetPath: 'assets/images/icon_themes.jpg',
              label: 'Themes',
              onTap: () => _showWorldThemePickerSheet(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentChildInsightRow(String childHeader, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            childHeader,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: EratPalette.primaryPurple,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 11.5,
              color: EratPalette.textDark,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  void _showReviewDialog(
    BuildContext context,
    BondingActivity act,
    FamilyMember child,
    AppStrings strings,
    VoidCallback onApprove,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${child.avatarEmoji} ${child.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              act.title(strings.isMs),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(act.description(strings.isMs)),
            const SizedBox(height: 10),
            Text('Reward: +${act.points} pts • ⭐ +${act.stars}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not yet'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: EratPalette.emeraldGreen),
            onPressed: () {
              onApprove();
              Navigator.pop(ctx);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showAllChildrenSheet(BuildContext context, EratAppState appState) {
    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              children: [
                const Text(
                  'All Children',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: EratPalette.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Each child grows at their own pace. Understand their needs, not who is ahead.',
                  style: TextStyle(fontSize: 12.5, color: EratPalette.textMuted),
                ),
                const SizedBox(height: 14),
                ...children.map((c) {
                  final mine = appState.activities
                      .where((a) =>
                          c.ageYears >= a.minAge && c.ageYears <= a.maxAge)
                      .toList();
                  final done = mine
                      .where((a) => a.completedByMemberIds.contains(c.id))
                      .length;
                  final waiting = mine
                      .where((a) =>
                          a.pendingVerificationMemberIds.contains(c.id))
                      .length;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EratPalette.softLavender,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(c.avatarEmoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.name} • ${c.ageYears} years',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: EratPalette.textDark,
                                    ),
                                  ),
                                  Text(
                                    c.ageBand.label(false),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: EratPalette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '✅ $done of ${mine.length} habits completed today',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '⏳ $waiting waiting for your approval',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '🔥 ${c.streakDays}-day streak',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        if (c.milestones.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: c.milestones
                                .map(
                                  (m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '🏅 $m',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: EratPalette.primaryPurple,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mockup Screen 3 Exact Layout (Used for Parents & 10–12 Goal Achievers)
  /// Max 2–3 main cards + Quick Access row
  Widget _buildStandardFamilyGrowHome(
    BuildContext context,
    WidgetRef ref,
    EratAppState appState,
    AppStrings strings,
  ) {
    final worldTheme = ref.watch(selectedWorldThemeProvider);
    final progressPct = (appState.family.familyGoalCurrentStars /
            appState.family.familyGoalTargetStars)
        .clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CARD 1: Family Progress Card (78% Circular Ring + "+12% ↑ This Week" + House Illustration)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFFFF),
                worldTheme.softTint,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tr('Family Progress', 'Family Progress'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // 78% Circular Progress Ring
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: progressPct,
                            strokeWidth: 9,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              EratPalette.emeraldGreen,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${(progressPct * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: EratPalette.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⭐ ⭐',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.tr('This Week', 'This Week'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: EratPalette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '+12% ↑',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.emeraldGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cozy Family House Illustration
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/family_hero.jpg',
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Pre-teen Goal & Independence Insight (Adam 10-12y)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDD6FE)),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'Goal & Independence Insight',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.primaryPurple,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EratPalette.softLavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '85% Autonomy',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: EratPalette.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Wish Goal: 🚀 Solar Rover Science Kit (⭐ 75/100 Stars • 75% Funded)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: EratPalette.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI Mentor Tip: High persistence on science project! Take 15 mins chunk-by-chunk tonight and leave time for dinner.',
                style: TextStyle(fontSize: 12, color: EratPalette.textMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // CARD 2: Today's Highlights -> Family Challenge (Warm Cream Card with Trophy & "Let's Go ->")
        Text(
          strings.tr("Today's Highlights", "Today's Highlights"),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EratPalette.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EratPalette.warmCream,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: EratPalette.warmCreamBorder),
            boxShadow: EratPalette.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.tr('Family Challenge', 'Family Challenge'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: EratPalette.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.tr(
                        'Complete 2 good deeds together today!',
                        'Complete 2 good deeds together today!',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: EratPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 36,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: EratPalette.primaryPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => onNavigateTab(1),
                          child: Text(
                            strings.tr("Let's Go →", "Let's Go →"),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // SECTION 3: Quick Access (4 Icon Buttons matching Mockup Screen 3)
        Text(
          strings.tr('Quick Access', 'Quick Access'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: EratPalette.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickAccessItem(
              assetPath: 'assets/images/icon_good_deeds.jpg',
              label: strings.tr('Good Deeds', 'Good Deeds'),
              onTap: () => onNavigateTab(1),
            ),
            _QuickAccessItem(
              assetPath: 'assets/images/icon_milestones.jpg',
              label: strings.tr('Milestones', 'Milestones'),
              onTap: () => onNavigateTab(1),
            ),
            _QuickAccessItem(
              assetPath: 'assets/images/icon_ai_coach.jpg',
              label: strings.tr('AI Family Companion', 'AI Family Companion'),
              onTap: () => onNavigateTab(2),
            ),
            _QuickAccessItem(
              assetPath: 'assets/images/icon_themes.jpg',
              label: strings.tr('Themes', 'Themes'),
              onTap: () => _showWorldThemePickerSheet(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  /// 1–4 Years (Little Explorer): Simple & Visual
  /// Very little text, giant tap targets, audio guide prompt, parent-assisted
  Widget _buildLittleExplorerHome(
    BuildContext context,
    WidgetRef ref,
    EratAppState appState,
    AppStrings strings,
  ) {
    final items = [
      (emoji: '🦷', title: strings.tr('Gosok Gigi', 'Brush Teeth'), color: const Color(0xFFE0F2FE)),
      (emoji: '🧺', title: strings.tr('Simpan Mainan', 'Tidy Toys'), color: const Color(0xFFFEF3C7)),
      (emoji: '📖', title: strings.tr('Baca Cerita', 'Story Time'), color: const Color(0xFFEDE9FE)),
      (emoji: '🤗', title: strings.tr('Peluk Ibu/Ayah', 'Big Hug'), color: const Color(0xFFFCE7F3)),
    ];

    return Column(
      children: [
        // Audio & Visual Banner (1–4 yrs)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: [
              const Text('🧸 🌟 🎈', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 8),
              Text(
                strings.tr('Ketik Gambar Bersama Ibu!', 'Tap a Picture with Mom!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.tr(
                          '🔊 Suara Panduan: "Jom pilih satu gambar yang Adik Noah dah buat hari ini!"',
                          '🔊 Voice Guide: "Let\'s tap one picture you did with Mom today!"',
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(strings.tr('🔊 Dengar Suara', '🔊 Play Audio')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Giant 2x2 Visual Cards (Minimal text, huge tap area)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.0,
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: EratPalette.primaryPurple,
                    content: Text(
                      '🎉 🌟 Yeay! ${item.title} (+1 ⭐)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: EratPalette.softShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 58)),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: EratPalette.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Adorable Toddler Insight Card (Emmi 1-4y)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFFED7AA)),
            boxShadow: EratPalette.softShadow,
          ),
          child: Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adik Emmi\'s Star Basket 🧺',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '3 Stars collected today! Teddy is ready for bedtime with Mommy! Tap for Lumi\'s cheer! 🥰',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFC2410C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 5–9 Years (Happy Habit Builder): Fun & Playful
  /// Characters, stickers, coins/stars & mini celebrations
  Widget _buildHappyHabitBuilderHome(
    BuildContext context,
    WidgetRef ref,
    EratAppState appState,
    AppStrings strings,
  ) {
    final member = appState.activeMember;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Playful Mascot & Coin/Star Collector
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEDE9FE), Color(0xFFFFF0F6)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
          ),
          child: Row(
            children: [
              const Text('🦄✨', style: TextStyle(fontSize: 52)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.tr(
                        'Misi Ceria ${member.name}!',
                        '${member.name}\'s Fun Missions!',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: EratPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          backgroundColor: Colors.white,
                          label: Text(
                            '🪙 ${member.points} Coins',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Chip(
                          backgroundColor: Colors.white,
                          label: Text(
                            '⭐ ${member.stars} Stars',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gamified Growth Insight Card (Alex 5-9y)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF86EFAC)),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    '${member.name}\'s Quest Insight',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166534),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Level 2',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '🔥 ${member.streakDays} days streak! You brushed teeth and made bed without reminder today! 1 quest left to unlock the Golden Shield badge! 🛡️',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14532D),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Card 2: Chibi Illustrated Habit Cards (Brush Teeth 75 Coin & Read/Study 50 Coin)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: EratPalette.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Brush Teeth',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: EratPalette.textDark,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🪙 75 Coin',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/habit_brush_teeth.jpg',
                        height: 145,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: EratPalette.primaryPurple,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => onNavigateTab(1),
                        child: const Text(
                          'Claim Reward →',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F2FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: EratPalette.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Study & Read',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: EratPalette.textDark,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🪙 50 Coin',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/habit_study_read.jpg',
                        height: 145,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: EratPalette.primaryPurple,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => onNavigateTab(1),
                        child: const Text(
                          'Claim Reward →',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Card 3: Sticker Board Collection
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
              Text(
                strings.tr('Koleksi Stiker Minggu Ini 🎨', 'This Week\'s Sticker Board 🎨'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('🌟', style: TextStyle(fontSize: 34)),
                  Text('🌈', style: TextStyle(fontSize: 34)),
                  Text('🦋', style: TextStyle(fontSize: 34)),
                  Text('🍦', style: TextStyle(fontSize: 34)),
                  Text('🔒', style: TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(height: 16),
              EratPrimaryPillButton(
                label: strings.tr('Buka Misi & Kumpul Stiker ✨', 'Open Missions & Collect Stickers ✨'),
                onPressed: () => onNavigateTab(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 13–17 Years (My Life, My Goals): Mature & Minimal
  /// Clean interface, personal goals, privacy controls, no cartoon clutter
  Widget _buildTeenMatureMinimalHome(
    BuildContext context,
    WidgetRef ref,
    EratAppState appState,
    AppStrings strings,
  ) {
    final member = appState.activeMember;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Minimalist Personal Focus & Streak Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: EratPalette.softShadow,
            border: Border.all(color: EratPalette.lavenderBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.tr('MY LIFE, MY GOALS', 'MY LIFE, MY GOALS'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: EratPalette.primaryPurple,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: EratPalette.softLavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔒 ${member.privacyLevel.name.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EratPalette.primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                strings.tr(
                  'Fokus Peribadi & Keseimbangan Minggu Ini',
                  'Personal Focus & Weekly Balance',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MinimalMetricTile(
                      label: strings.tr('Konsistensi', 'Consistency'),
                      value: '${member.streakDays} Hari',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MinimalMetricTile(
                      label: strings.tr('Sasaran Peribadi', 'Personal Goals'),
                      value: '80%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Teen Wellbeing & Low-pressure Balance Insight (Hana 13-17y)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFDFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD1E7DD)),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'Wellness & Balance Insight',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14532D),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Balanced',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '☕ Family Warmth: Mom made hot chocolate and left it by your desk.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: EratPalette.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI Teen Whisper: You\'ve maintained an 8-day consistency streak! Exams are important, but taking 15 minutes of quiet time to recharge is just as vital. 💛',
                style: TextStyle(fontSize: 12, color: EratPalette.textMuted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 2: Teen Privacy Control Quick Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.tr('Kawalan Privasi Anda (13+)', 'Your Privacy Controls (13+)'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.tr(
                  'Anda menentukan perkara yang dikongsi dengan ibu bapa.',
                  'You decide which goals and reflections are visible to parents.',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: EratPalette.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              EratPrimaryPillButton(
                label: strings.tr('Urus Sasaran & Privasi', 'Manage Goals & Privacy'),
                onPressed: () => onNavigateTab(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 18+ Years (Lifelong Family Bond): Elegant & Practical
  /// Shared family calendar, family memories, mutual support
  Widget _buildAdultPracticalHome(
    BuildContext context,
    WidgetRef ref,
    EratAppState appState,
    AppStrings strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Shared Family Calendar & Catch-up
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EratPalette.softLavender,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: EratPalette.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tr('Kalendar Bersama Keluarga', 'Shared Family Calendar'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        Text(
                          strings.tr(
                            'Ahad, 8:00 MLM • Makan Malam & Wayang Keluarga',
                            'Sunday, 8:00 PM • Family Dinner & Movie Night',
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: EratPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EratPalette.warmCream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.tr(
                          'Kenangan Keluarga: 3 gambar baharu daripada Ibu Khadijah minggu ini.',
                          'Family Memories: 3 new moments shared by Mom this week.',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EratPalette.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EratPrimaryPillButton(
                label: strings.tr('Hantar Sokongan & Tanya Khabar Ibu Bapa', 'Send Appreciation & Check In'),
                onPressed: () => onNavigateTab(2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showWorldThemePickerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, sheetRef, _) {
            final selected = sheetRef.watch(selectedWorldThemeProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your World Theme',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap any theme to transform your app colors instantly',
                    style: TextStyle(
                      fontSize: 13,
                      color: EratPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.35,
                    children: EratWorldTheme.values.map((theme) {
                      final isSelected = theme == selected;
                      return GestureDetector(
                        onTap: () {
                          sheetRef
                              .read(selectedWorldThemeProvider.notifier)
                              .state = theme;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.softTint,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? theme.accentColor
                                  : Colors.white,
                              width: 2.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                theme.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  theme.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? theme.accentColor
                                        : EratPalette.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: EratPalette.softShadow,
              border: Border.all(color: EratPalette.lavenderBorder, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                assetPath,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: EratPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MinimalMetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EratPalette.softLavender,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: EratPalette.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: EratPalette.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

