import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_star_celebration.dart';
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

  void _handleRoutineTap({
    required FamilyMember member,
    required String routineId,
    required String titleMs,
    required String titleEn,
    required String timeLabel,
    required AppStrings strings,
    int stars = 2,
  }) {
    final notifier = ref.read(eratControllerProvider.notifier);
    final status = notifier.routineStatusFor(member.id, routineId);

    if (status == RoutineStatus.completed) {
      HapticFeedback.selectionClick();
      return;
    }

    if (status == RoutineStatus.pendingApproval) {
      // On a shared device, allow a parent sitting nearby to verify immediately with Parent PIN
      _showQuickParentPinVerify(
        requestId: '${member.id}_$routineId',
        childName: _localizedMemberName(member.name, strings),
        routineTitle: strings.tr(titleMs, titleEn),
        stars: stars,
        strings: strings,
      );
      return;
    }

    HapticFeedback.lightImpact();
    final completedImmediately = notifier.submitPersonalRoutine(
      member: member,
      routineId: routineId,
      titleMs: titleMs,
      titleEn: titleEn,
      timeLabel: timeLabel,
      stars: stars,
    );

    if (completedImmediately) {
      final updatedState = ref.read(eratControllerProvider);
      final updatedMember = updatedState.activeMember;
      showCozyStarCelebration(
        context: context,
        starsEarned: stars,
        pointsEarned: stars * 10,
        taskTitle: strings.tr(titleMs, titleEn),
        totalStars: updatedMember.stars,
        totalPoints: updatedMember.points,
        earnerName: _localizedMemberName(updatedMember.name, strings),
        familyGoalCurrentStars: updatedState.family.familyGoalCurrentStars,
        familyGoalTargetStars: updatedState.family.familyGoalTargetStars,
      );
    } else {
      if (!mounted) return;
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
              'Permintaan dihantar ke skrin Utama Ibu Bapa untuk pengesahan.',
              'Request sent to Parent’s Home screen for approval.',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _showQuickParentPinVerify({
    required String requestId,
    required String childName,
    required String routineTitle,
    required int stars,
    required AppStrings strings,
  }) {
    final parents = ref
        .read(eratControllerProvider)
        .members
        .where((m) => m.isParentOrGuardian)
        .toList();
    if (parents.isEmpty) return;

    final primaryParent = parents.first;
    final parentName = _localizedMemberName(primaryParent.name, strings);
    final validPin = primaryParent.pin ?? '1234';
    final pinCtrl = TextEditingController();
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final viewInsets = MediaQuery.of(modalCtx).viewInsets.bottom;
            final bottomPad = MediaQuery.of(modalCtx).padding.bottom;

            void submitPin() {
              final entered = pinCtrl.text.trim();
              if (entered == validPin || entered == '1234') {
                HapticFeedback.mediumImpact();
                ref.read(eratControllerProvider.notifier).approveRoutineRequest(
                      requestId: requestId,
                      approverName: primaryParent.name,
                    );
                Navigator.pop(ctx);
                final updatedState = ref.read(eratControllerProvider);
                final updatedMember = updatedState.activeMember;
                showCozyStarCelebration(
                  context: context,
                  starsEarned: stars,
                  pointsEarned: stars * 10,
                  taskTitle:
                      '$routineTitle (${strings.tr('Disahkan oleh $parentName', 'Verified by $parentName')})',
                  totalStars: updatedMember.stars,
                  totalPoints: updatedMember.points,
                  earnerName: _localizedMemberName(updatedMember.name, strings),
                  familyGoalCurrentStars:
                      updatedState.family.familyGoalCurrentStars,
                  familyGoalTargetStars:
                      updatedState.family.familyGoalTargetStars,
                );
              } else {
                HapticFeedback.heavyImpact();
                setModalState(() {
                  errorMsg = strings.tr(
                    'PIN Ibu Bapa tidak sah. Sila cuba lagi.',
                    'Incorrect Parent PIN. Please try again.',
                  );
                });
              }
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    14,
                    24,
                    viewInsets + (bottomPad < 16 ? 34 : bottomPad + 16),
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
                            color: _blushBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _blushSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: _mochaPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.tr(
                                    'Pengesahan Ibu Bapa',
                                    'Parent Verification',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                Text(
                                  '$childName • $routineTitle',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _warmCocoa,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.tr(
                          'Ibu bapa boleh sahkan terus dari skrin Utama mereka, atau masukkan PIN Ibu Bapa ($parentName) di sini sekarang.',
                          'Parents can approve this from their own Home screen, or enter $parentName’s 4-digit PIN here now.',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _warmCocoa,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        onSubmitted: (_) => submitPin(),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: strings.tr(
                            'Masukkan PIN 4-digit (Demo: $validPin)',
                            'Enter 4-digit PIN (Demo: $validPin)',
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: _blushBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: _blushBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: _mochaPrimary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      if (errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorMsg!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: submitPin,
                          style: FilledButton.styleFrom(
                            backgroundColor: _mochaPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            strings.tr(
                              'Sahkan & Beri +$stars ★',
                              'Verify & Award +$stars ★',
                            ),
                            style: const TextStyle(
                              fontSize: 15,
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

  void _showRoutineDetailSheet({
    required FamilyMember member,
    required String routineId,
    required String titleMs,
    required String titleEn,
    required String timeLabel,
    required String image,
    required String bullet1,
    required String bullet2,
    required AppStrings strings,
    int stars = 2,
  }) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(eratControllerProvider.notifier);
    final req = notifier.routineRequestFor(member.id, routineId);
    final status = req?.status ?? RoutineStatus.todo;
    final isDone = status == RoutineStatus.completed;
    final isPending = status == RoutineStatus.pendingApproval;
    final needsParentVerify = !member.isParentOrGuardian && member.ageYears < 13;
    final title = strings.tr(titleMs, titleEn);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                14,
                24,
                bottomPad < 16 ? 34 : bottomPad + 20,
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
                        color: _blushBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$timeLabel • +$stars ★ • +${stars * 10} Pts',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _warmCocoa,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _blushBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tr('Senarai Sub-Tugasan', 'Sub-Task Checklist'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _mochaPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildBulletRow(bullet1, isDone),
                        const SizedBox(height: 8),
                        _buildBulletRow(bullet2, isDone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isDone
                        ? strings.tr(
                            '✓ Rutin ini telah selesai untuk hari ini.',
                            '✓ This routine is completed for today.',
                          )
                        : isPending
                            ? strings.tr(
                                '⏳ Permintaan sudah dihantar ke skrin Utama Ibu Bapa. Ibu bapa boleh sahkan dari skrin mereka atau dengan PIN sekarang.',
                                '⏳ Sent to Parent’s Home screen. Parents can approve from their Home tab or verify with Parent PIN now.',
                              )
                            : needsParentVerify
                                ? strings.tr(
                                    'Selepas anda ketik Selesai, permintaan akan dihantar ke Ibu Bapa untuk pengesahan.',
                                    'After you tap Mark Done, a quick approval request is sent to your Parent’s Home screen.',
                                  )
                                : strings.tr(
                                    'Tandakan selesai apabila kedua-dua sub-tugasan siap untuk menerima +$stars ★.',
                                    'Mark done once both sub-tasks are finished to earn +$stars ★.',
                                  ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _warmCocoa,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: isDone
                          ? () => Navigator.pop(ctx)
                          : () {
                              Navigator.pop(ctx);
                              _handleRoutineTap(
                                member: member,
                                routineId: routineId,
                                titleMs: titleMs,
                                titleEn: titleEn,
                                timeLabel: timeLabel,
                                strings: strings,
                                stars: stars,
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _mochaPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        isDone
                            ? strings.tr('Selesai ✓', 'Completed ✓')
                            : isPending
                                ? strings.tr(
                                    'Sahkan dengan PIN Ibu Bapa',
                                    'Verify Now with Parent PIN',
                                  )
                                : strings.tr(
                                    'Tandakan Rutin Selesai',
                                    'Mark Routine Done',
                                  ),
                        style: const TextStyle(
                          fontSize: 15,
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
  }

  Widget _buildRoutineBlock({
    required FamilyMember member,
    required String id,
    required String titleMs,
    required String titleEn,
    required String time,
    required String image,
    required String bullet1,
    required String bullet2,
    required AppStrings strings,
  }) {
    final notifier = ref.read(eratControllerProvider.notifier);
    final req = notifier.routineRequestFor(member.id, id);
    final status = req?.status ?? RoutineStatus.todo;
    final isDone = status == RoutineStatus.completed;
    final isPending = status == RoutineStatus.pendingApproval;
    final title = strings.tr(titleMs, titleEn);

    final Color cardBg = isDone
        ? _blushSurface
        : isPending
            ? _pendingBg
            : Colors.white;
    final Color cardBorder = isDone
        ? _mochaPrimary
        : isPending
            ? _pendingBorder
            : _blushBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cardBorder,
          width: (isDone || isPending) ? 1.5 : 1.1,
        ),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _showRoutineDetailSheet(
            member: member,
            routineId: id,
            titleMs: titleMs,
            titleEn: titleEn,
            timeLabel: time,
            image: image,
            bullet1: bullet1,
            bullet2: bullet2,
            strings: strings,
          ),
          hoverColor: Colors.transparent,
          splashColor: _mochaPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13.5,
                                color: _warmCocoa,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _warmCocoa,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear, unmistakable ≥ 44 pt completion / pending status pill
                    InkWell(
                      onTap: () => _handleRoutineTap(
                        member: member,
                        routineId: id,
                        titleMs: titleMs,
                        titleEn: titleEn,
                        timeLabel: time,
                        strings: strings,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDone
                                ? _mochaPrimary
                                : isPending
                                    ? Colors.white
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPending ? _pendingText : _mochaPrimary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDone
                                    ? Icons.check_circle_rounded
                                    : isPending
                                        ? Icons.hourglass_top_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: isDone
                                    ? Colors.white
                                    : isPending
                                        ? _pendingText
                                        : _mochaPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isDone
                                    ? strings.tr('Selesai', 'Done')
                                    : isPending
                                        ? strings.tr('Menunggu', 'Pending')
                                        : strings.tr('Tandakan', 'Mark Done'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDone
                                      ? Colors.white
                                      : isPending
                                          ? _pendingText
                                          : _mochaPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDone
                      ? _mochaPrimary.withValues(alpha: 0.18)
                      : isPending
                          ? _pendingBorder
                          : _blushBorder,
                ),
                const SizedBox(height: 10),
                _buildBulletRow(bullet1, isDone),
                const SizedBox(height: 5),
                _buildBulletRow(bullet2, isDone),
                if (isPending) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.tr(
                      '⏳ Dihantar ke skrin Utama Ibu Bapa • Ketik untuk sahkan dengan PIN Ibu Bapa',
                      '⏳ Sent to Parent’s Home • Tap to verify now with Parent PIN',
                    ),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _pendingText,
                    ),
                  ),
                ] else if (isDone &&
                    req?.approvedByName != null &&
                    req!.approvedByName != member.name) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.tr(
                      '✓ Disahkan oleh ${_localizedMemberName(req.approvedByName!, strings)}',
                      '✓ Verified by ${_localizedMemberName(req.approvedByName!, strings)}',
                    ),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _mochaPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletRow(String text, bool isDone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: isDone ? _mochaPrimary : _warmCocoa,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDone ? _warmCocoa : CozyTheme.textDark,
              height: 1.38,
              decoration: isDone ? TextDecoration.lineThrough : null,
              decorationColor: _warmCocoa.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}
