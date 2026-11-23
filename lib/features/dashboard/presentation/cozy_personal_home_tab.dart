import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../family/presentation/cozy_family_calendar_card.dart';
import 'cozy_parent_home_view.dart';

/// Cozy Minimalist Personal Home Tab for Private Space
class CozyPersonalHomeTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigateTab;

  const CozyPersonalHomeTab({
    super.key,
    required this.onNavigateTab,
  });

  @override
  ConsumerState<CozyPersonalHomeTab> createState() =>
      _CozyPersonalHomeTabState();
}

class _CozyPersonalHomeTabState extends ConsumerState<CozyPersonalHomeTab> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _pendingBg = Color(0xFFFDF4E3);
  static const Color _pendingBorder = Color(0xFFD8B17E);
  static const Color _pendingText = Color(0xFF8C5319);

  String _formattedTodayLabel(AppStrings strings) {
    final now = DateTime.now();
    const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysMs = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsMs = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
    ];
    final d = strings.isMs ? daysMs[now.weekday - 1] : daysEn[now.weekday - 1];
    final m = strings.isMs ? monthsMs[now.month - 1] : monthsEn[now.month - 1];
    return strings.tr(
      'Hari Ini • $d, ${now.day} $m',
      'Today • $d, ${now.day} $m',
    );
  }

  String _localizedMemberName(String rawName, AppStrings strings) {
    if (!strings.isMs) {
      return rawName
          .replaceAll('(Ibu)', '(Mom)')
          .replaceAll('(Ayah)', '(Dad)');
    }
    return rawName
        .replaceAll('(Mom)', '(Ibu)')
        .replaceAll('(Dad)', '(Ayah)');
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final activeMember = appState.activeMember;
    if (activeMember.isParentOrGuardian) {
      return CozyParentHomeView(onNavigateTab: widget.onNavigateTab);
    }
    final displayName = _localizedMemberName(activeMember.name, strings);
    final isParent = activeMember.isParentOrGuardian;
    final needsParentVerify = !isParent && activeMember.ageYears < 13;

    final todayDate = DateTime.now();
    final realTodayQuests = appState.activities
        .where((a) => !a.isPrivateNote && a.appliesToDate(todayDate))
        .toList();

    final int totalRoutines = realTodayQuests.length;
    final int completedCount = realTodayQuests
        .where((a) => a.completedByMemberIds.contains(activeMember.id))
        .length;
    final int pendingCount = realTodayQuests
        .where((a) => a.pendingVerificationMemberIds.contains(activeMember.id))
        .length;

    final pendingParentApprovals = appState.routineRequests
        .where((r) => r.status == RoutineStatus.pendingApproval)
        .toList();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPad = isTablet ? 28.0 : 20.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 760 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                16,
                horizontalPad,
                bottomInset + 32,
              ),
              children: [
                // 1. Greeting & Motivation Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _blushBorder, width: 1.1),
                    boxShadow: CozyTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _blushSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _blushBorder, width: 1.5),
                        ),
                        child: activeMember.customPhotoPath != null
                            ? ClipOval(
                                child: MediaStorageService.buildAdaptiveImage(
                                  activeMember.customPhotoPath,
                                  width: 54,
                                  height: 54,
                                  placeholder: Text(
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.tr(
                                'Selamat Kembali, $displayName ♡',
                                'Welcome Back, $displayName ♡',
                              ),
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strings.tr(
                                'Langkah kecil hari ini, senyuman indah selamanya.',
                                'Small steps today, bright smiles forever.',
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: _warmCocoa,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Quick Stats Strip (2 symmetrical ≥ 64 pt tappable cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: Colors.white,
                        cardBg: _blushSurface,
                        borderColor: _blushBorder,
                        title: strings.tr(
                          '${activeMember.stars} Bintang',
                          '${activeMember.stars} Stars',
                        ),
                        subtitle: strings.tr(
                          'Tebus ganjaran →',
                          'Redeem rewards →',
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onNavigateTab(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.checklist_rounded,
                        iconColor: _mochaPrimary,
                        iconBg: Colors.white,
                        cardBg: _linenSurface,
                        borderColor: _linenBorder,
                        title: strings.tr(
                          'Rutin Hari Ini',
                          'Today’s Routines',
                        ),
                        subtitle: totalRoutines == 0
                            ? strings.tr(
                                'Belum ada misi',
                                'No quests yet',
                              )
                            : pendingCount > 0
                                ? strings.tr(
                                    '$completedCount/$totalRoutines • $pendingCount menunggu',
                                    '$completedCount/$totalRoutines done • $pendingCount pending',
                                  )
                                : strings.tr(
                                    '$completedCount/$totalRoutines selesai',
                                    '$completedCount/$totalRoutines completed',
                                  ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onNavigateTab(1);
                        },
                      ),
                    ),
                  ],
                ),

                // 2B. Parent-Only Live Approval Inbox (All child routine requests update here!)
                if (isParent && pendingParentApprovals.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildParentApprovalInbox(
                    requests: pendingParentApprovals,
                    parentMember: activeMember,
                    strings: strings,
                  ),
                ],

                const SizedBox(height: 14),

                // 2C. Shared Family Event Calendar (Visible to all family members)
                const CozyFamilyCalendarCard(),

                const SizedBox(height: 12),

                // 3. Milestone Map & Rewards Banner Shortcut (≥ 64 pt hit target)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onNavigateTab(1);
                    },
                    hoverColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _blushBorder, width: 1.1),
                        boxShadow: CozyTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _blushSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child:
                                const Text('🗺️', style: TextStyle(fontSize: 21)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.tr(
                                    'Peta Milestone & Ganjaran',
                                    'Milestone Map & Rewards',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.tr(
                                    'Jelajah pulau impian & tebus bintang anda',
                                    'Explore your journey map & redeem stars',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _warmCocoa,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: _mochaPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Section Title: Daily Routine Timeline + Progress Affordance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.tr(
                              'Garis Masa Rutin Harian',
                              'Daily Routine Timeline',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: _mochaPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _formattedTodayLabel(strings),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _mochaPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            needsParentVerify
                                ? strings.tr(
                                    'Ketik blok untuk hantar pengesahan ibu bapa (+2 ★)',
                                    'Tap a block to request parent approval (+2 ★)',
                                  )
                                : strings.tr(
                                    'Ketik blok untuk tandakan keseluruhan rutin (+2 ★)',
                                    'Tap a block to check off the whole routine (+2 ★)',
                                  ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _warmCocoa,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: pendingCount > 0 && completedCount == 0
                            ? _pendingBg
                            : _blushSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pendingCount > 0 && completedCount == 0
                              ? _pendingBorder
                              : _blushBorder,
                        ),
                      ),
                      child: Text(
                        totalRoutines == 0
                            ? strings.tr('0 misi', '0 quests')
                            : pendingCount > 0
                                ? strings.tr(
                                    '$completedCount/$totalRoutines • $pendingCount menunggu',
                                    '$completedCount/$totalRoutines • $pendingCount pending',
                                  )
                                : strings.tr(
                                    '$completedCount daripada $totalRoutines selesai',
                                    '$completedCount of $totalRoutines done',
                                  ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pendingCount > 0 && completedCount == 0
                              ? _pendingText
                              : _mochaPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: totalRoutines == 0
                          ? 0.0
                          : completedCount / totalRoutines,
                    ),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: _linenBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _mochaPrimary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Real Daily Routine & Quest Timeline Cards from Firestore
                if (realTodayQuests.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _blushBorder, width: 1.1),
                      boxShadow: CozyTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: _blushSurface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('✨', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.tr(
                            'Belum Ada Rutin atau Misi Hari Ini',
                            'No Routines or Quests Today Yet',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.tr(
                            'Minta Ibu Bapa tugaskan misi harian, atau cadangkan misi anda sendiri di tab Misi!',
                            'Ask Parents to assign daily quests, or suggest your own quest in the Quests tab!',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _warmCocoa,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            widget.onNavigateTab(1);
                          },
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: Text(
                            strings.tr('Buka Tab Misi →', 'Open Quests Tab →'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mochaPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...realTodayQuests.map((act) {
                    final isDone =
                        act.completedByMemberIds.contains(activeMember.id);
                    final isPending = act.pendingVerificationMemberIds
                        .contains(activeMember.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: isDone
                            ? _blushSurface.withValues(alpha: 0.55)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (isDone) return;
                            if (isPending) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    strings.tr(
                                      'Menunggu pengesahan Ibu Bapa di skrin Utama Ibu Bapa.',
                                      'Waiting for Parent approval on Parent’s Home screen.',
                                    ),
                                  ),
                                  backgroundColor: _mochaPrimary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            ref
                                .read(eratControllerProvider.notifier)
                                .completeActivity(act.id);
                            final updatedAct = ref
                                .read(eratControllerProvider)
                                .activities
                                .firstWhere(
                                  (a) => a.id == act.id,
                                  orElse: () => act,
                                );
                            if (updatedAct.pendingVerificationMemberIds
                                .contains(activeMember.id)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    strings.tr(
                                      'Dihantar ke skrin Utama Ibu Bapa untuk pengesahan!',
                                      'Sent to Parent’s Home screen for approval!',
                                    ),
                                  ),
                                  backgroundColor: _mochaPrimary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isPending
                                    ? _pendingBorder
                                    : (isDone ? _mochaPrimary : _blushBorder),
                                width: isDone || isPending ? 1.5 : 1.1,
                              ),
                              boxShadow: CozyTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? _mochaPrimary
                                        : (isPending
                                            ? _pendingBg
                                            : _blushSurface),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: isDone
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : Text(
                                          act.iconEmoji,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        act.title(strings.isMs),
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: CozyTheme.textDark,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isDone
                                            ? strings.tr(
                                                'Selesai • +${act.stars} ★ diperoleh',
                                                'Completed • +${act.stars} ★ earned',
                                              )
                                            : isPending
                                                ? strings.tr(
                                                    '⏳ Menunggu pengesahan Ibu Bapa',
                                                    '⏳ Waiting for Parent approval',
                                                  )
                                                : act.description(strings.isMs),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isPending
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isPending
                                              ? _pendingText
                                              : _warmCocoa,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPending ? _pendingBg : _blushSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '+${act.stars} ★',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isPending
                                          ? _pendingText
                                          : _mochaPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // 6. Quick Action Banner: Voice Journal (≥ 64 pt hit target)
                Material(
                  color: _blushSurface,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onNavigateTab(3);
                    },
                    hoverColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 66),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _blushBorder, width: 1.1),
                        boxShadow: CozyTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child:
                                const Text('🎙️', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.tr(
                                    'Luahan Diari Hari Ini',
                                    'Today’s Voice Journal',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  strings.tr(
                                    'Ketik untuk rakam pesanan suara kesyukuran',
                                    'Tap to record a gratitude voice note',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _warmCocoa,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: _mochaPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParentApprovalInbox({
    required List<RoutineApprovalRequest> requests,
    required FamilyMember parentMember,
    required AppStrings strings,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pendingBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pendingBorder, width: 1.3),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 19,
                  color: _pendingText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.tr(
                        'Menunggu Pengesahan (${requests.length})',
                        'Pending Parent Approvals (${requests.length})',
                      ),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    Text(
                      strings.tr(
                        'Sahkan rutin anak untuk berikan bintang',
                        'Approve your child’s routine to award stars',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _warmCocoa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < requests.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildApprovalRequestRow(
              req: requests[i],
              parentMember: parentMember,
              strings: strings,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalRequestRow({
    required RoutineApprovalRequest req,
    required FamilyMember parentMember,
    required AppStrings strings,
  }) {
    final childName = _localizedMemberName(req.memberName, strings);
    final routineTitle = strings.tr(req.routineTitleMs, req.routineTitleEn);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blushBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: _blushSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(req.memberAvatar, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$childName • $routineTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: CozyTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${req.timeLabel} • +${req.stars} ★',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _warmCocoa,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: strings.tr('Tolak', 'Decline'),
            onPressed: () {
              HapticFeedback.selectionClick();
              ref
                  .read(eratControllerProvider.notifier)
                  .declineRoutineRequest(req.id);
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: _warmCocoa,
            ),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(eratControllerProvider.notifier).approveRoutineRequest(
                    requestId: req.id,
                    approverName: parentMember.name,
                  );
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _mochaPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  content: Text(
                    strings.tr(
                      'Disahkan! $childName menerima +${req.stars} ★.',
                      'Approved! $childName earned +${req.stars} ★.',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _mochaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(78, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              strings.tr('Sahkan', 'Approve'),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _warmCocoa,
                        ),
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
