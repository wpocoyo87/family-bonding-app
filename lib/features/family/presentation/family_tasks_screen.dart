import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_star_celebration.dart';
import '../../../core/theme/cozy_theme.dart';

class FamilyTasksScreen extends ConsumerStatefulWidget {
  const FamilyTasksScreen({super.key});

  @override
  ConsumerState<FamilyTasksScreen> createState() => _FamilyTasksScreenState();
}

enum _TaskScopeFilter { all, everyone, anyone, pendingVerify }

class _FamilyTasksScreenState extends ConsumerState<FamilyTasksScreen> {
  ActivityCategory? _selectedCategory;
  _TaskScopeFilter _selectedScopeFilter = _TaskScopeFilter.all;
  DateTime _selectedDate = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formattedDateLabel(DateTime date, AppStrings strings) {
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
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
    final d = strings.isMs ? daysMs[date.weekday - 1] : daysEn[date.weekday - 1];
    final m = strings.isMs ? monthsMs[date.month - 1] : monthsEn[date.month - 1];
    final shortDate = '$d, ${date.day} $m';
    if (_isSameDay(date, today)) {
      return strings.tr('Hari Ini • $shortDate', 'Today • $shortDate');
    }
    if (_isSameDay(date, yesterday)) {
      return strings.tr('Semalam • $shortDate', 'Yesterday • $shortDate');
    }
    if (_isSameDay(date, tomorrow)) {
      return strings.tr('Esok • $shortDate', 'Tomorrow • $shortDate');
    }
    return shortDate;
  }

  Future<DateTime?> _openCozyDatePicker(DateTime initial) {
    final today = _dateOnly(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today.subtract(const Duration(days: 90)),
      lastDate: today.add(const Duration(days: 180)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6D4C41),
              onPrimary: Colors.white,
              surface: Color(0xFFFAF7F2),
              onSurface: Color(0xFF3E2E26),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Localizes parenthetical member labels cleanly (e.g. "Sarah (Mom)" -> "Sarah (Ibu)" in BM).
  static String _localizedMemberName(FamilyMember member, AppStrings strings) {
    if (strings.isMs) {
      return member.name
          .replaceAll('(Mom)', '(Ibu)')
          .replaceAll('(Dad)', '(Ayah)');
    }
    return member.name
        .replaceAll('(Ibu)', '(Mom)')
        .replaceAll('(Ayah)', '(Dad)');
  }

  static String _localizedMemberRole(FamilyMember member, AppStrings strings) {
    if (member.isParentOrGuardian) {
      return switch (member.role) {
        MemberRole.owner => strings.tr('Ibu Bapa', 'Parent'),
        MemberRole.coparent => strings.tr('Co-Parent', 'Co-Parent'),
        MemberRole.caregiver => strings.tr('Penjaga', 'Caregiver'),
        _ => strings.tr('Ibu Bapa', 'Parent'),
      };
    }
    final stage = switch (member.ageBand) {
      AgeBand.littleExplorer =>
        strings.tr('Peneroka Kecil', 'Little Explorer'),
      AgeBand.happyHabitBuilder =>
        strings.tr('Pembina Tabiat', 'Habit Builder'),
      AgeBand.goalAchiever =>
        strings.tr('Pencapai Matlamat', 'Goal Achiever'),
      AgeBand.myLifeMyGoals =>
        strings.tr('Matlamat Remaja', 'Teen Goals'),
      AgeBand.lifelongFamilyBond =>
        strings.tr('Ikatan Keluarga', 'Family Bond'),
    };
    final ageUnit = strings.tr('${member.ageYears} thn', '${member.ageYears}y');
    return '$stage • $ageUnit';
  }

  /// Clean Activity Details sheet triggered by the subtle ⓘ icon on each card
  void _showActivityDetailModal({
    required BuildContext context,
    required BondingActivity activity,
    required List<FamilyMember> allMembers,
    required List<FamilyMember> completedMembers,
    required AppStrings strings,
  }) {
    final title = strings.isMs ? activity.titleMs : activity.titleEn;
    final desc = strings.isMs ? activity.descMs : activity.descEn;
    final isEveryone =
        activity.participationMode == ParticipationMode.everyone;
    final targets = activity.targetMembers(allMembers);
    final completedTargetCount = targets
        .where((m) => activity.completedByMemberIds.contains(m.id))
        .length;
    final modeText = isEveryone
        ? strings.tr(
            'Semua Ahli ($completedTargetCount/${targets.length})',
            'Everyone ($completedTargetCount/${targets.length})',
          )
        : strings.tr('Wakil / 1+ Ahli', 'Anyone (1+ Helper)');
    final categoryText = switch (activity.category) {
      ActivityCategory.goodHabit => strings.tr('Tabiat Baik', 'Good Habits'),
      ActivityCategory.bonding10Min =>
        strings.tr('Masa Bersama', 'Family Bonding'),
      ActivityCategory.familyChallenge =>
        strings.tr('Cabaran Keluarga', 'Challenges'),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        final bottomSafe = MediaQuery.viewPaddingOf(modalCtx).bottom;
        final extraBottom = bottomSafe >= 34.0 ? bottomSafe : 34.0;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: EdgeInsets.fromLTRB(22, 14, 22, extraBottom + 12),
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
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
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E4DC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5CEC2)),
                        ),
                        alignment: Alignment.center,
                        child: activity.customImagePath != null &&
                                activity.customImagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: MediaStorageService.buildAdaptiveImage(
                                  activity.customImagePath,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  placeholder: Text(
                                    activity.iconEmoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              )
                            : Text(
                                activity.iconEmoji,
                                style: const TextStyle(fontSize: 28),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$categoryText • $modeText',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A463C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(modalCtx).pop(),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: CozyTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF2E8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBDCC8)),
                    ),
                    child: Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CozyTheme.textDark,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFF6D4C41),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        strings.tr(
                          '+${activity.stars} Bintang • +${activity.points} Mata • ~${activity.durationMinutes} minit',
                          '+${activity.stars} ${activity.stars == 1 ? 'Star' : 'Stars'} • +${activity.points} Pts • ~${activity.durationMinutes} mins',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6D4C41),
                        ),
                      ),
                    ],
                  ),
                  if (completedMembers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      strings.tr('Disiapkan oleh:', 'Completed by:'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A463C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: completedMembers.map((m) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5CEC2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m.avatarEmoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _localizedMemberName(m, strings),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(modalCtx).pop();
                        _showWhoDoneItModal(
                          context: context,
                          activity: activity,
                          members: allMembers,
                          strings: strings,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        strings.tr('Tanda Siap', 'Mark Done'),
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

  /// Step 2b: Require the chosen verifier's 4-digit PIN so kids on shared Family View cannot self-approve
  void _showVerifierPinDialog({
    required BuildContext context,
    required BondingActivity activity,
    required FamilyMember requester,
    required FamilyMember verifier,
    required AppStrings strings,
  }) {
    final pinCtrl = TextEditingController();
    final requesterName = _localizedMemberName(requester, strings);
    final verifierName = _localizedMemberName(verifier, strings);
    final expectedPin = (verifier.pin != null && verifier.pin!.isNotEmpty)
        ? verifier.pin!
        : '1234';
    String? errorMsg;

    showDialog(
      context: context,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.55),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: CozyTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: Color(0xFF6D4C41),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.tr(
                        'PIN $verifierName',
                        '$verifierName’s PIN',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tr(
                      'Masukkan PIN 4-digit $verifierName untuk sahkan tugasan $requesterName.',
                      'Enter $verifierName’s 4-digit PIN to verify $requesterName’s task.',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A463C),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: CozyTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: CozyTheme.border),
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
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMsg!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    strings.tr('Batal', 'Cancel'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A463C),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pinCtrl.text.trim() != expectedPin) {
                      HapticFeedback.heavyImpact();
                      setDialogState(() {
                        errorMsg = strings.tr(
                          'PIN salah. Minta $verifierName masukkan PIN.',
                          'Incorrect PIN. Ask $verifierName to enter their PIN.',
                        );
                      });
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    ref
                        .read(eratControllerProvider.notifier)
                        .approveActivityVerification(
                          activityId: activity.id,
                          memberId: requester.id,
                          verifiedByMemberId: verifier.id,
                        );
                    Navigator.of(dialogCtx).pop();

                    final latestState = ref.read(eratControllerProvider);
                    final updatedMember = latestState.members.firstWhere(
                      (x) => x.id == requester.id,
                      orElse: () => requester,
                    );
                    final activityTitle =
                        strings.isMs ? activity.titleMs : activity.titleEn;
                    showCozyStarCelebration(
                      context: context,
                      starsEarned: activity.stars,
                      earnerName: requesterName,
                      pointsEarned: updatedMember.isParentOrGuardian
                          ? 0
                          : activity.points,
                      taskTitle:
                          '$activityTitle (${strings.tr('disahkan', 'verified by')} $verifierName)',
                      totalStars: updatedMember.stars,
                      totalPoints: updatedMember.isParentOrGuardian
                          ? null
                          : updatedMember.points,
                      familyGoalCurrentStars:
                          latestState.family.familyGoalCurrentStars,
                      familyGoalTargetStars:
                          latestState.family.familyGoalTargetStars,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D4C41),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    strings.tr('Sahkan', 'Verify'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Step 2 Picker: Choose which OTHER family member verifies a pending request to award stars & points
  void _showVerifierPickerModal({
    required BuildContext context,
    required BondingActivity activity,
    required FamilyMember requester,
    required List<FamilyMember> allMembers,
    required AppStrings strings,
  }) {
    final activityTitle = strings.isMs ? activity.titleMs : activity.titleEn;
    final requesterName = _localizedMemberName(requester, strings);
    final eligibleVerifiers =
        allMembers.where((m) => m.id != requester.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        final bottomSafe = MediaQuery.viewPaddingOf(modalCtx).bottom;
        final extraBottom = bottomSafe >= 34.0 ? bottomSafe : 34.0;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: EdgeInsets.fromLTRB(22, 14, 22, extraBottom + 10),
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E4DC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5CEC2)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 24,
                          color: Color(0xFF6D4C41),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.tr(
                                'Sahkan Tugasan $requesterName',
                                'Verify $requesterName’s Task',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            Text(
                              activityTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A463C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(modalCtx).pop(),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: CozyTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.tr(
                      'Pilih ahli keluarga lain untuk mengesahkan & anugerah +${activity.stars} Bintang & +${activity.points} Mata:',
                      'Choose another family member to verify & award +${activity.stars} Stars & +${activity.points} Pts:',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A463C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 330),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: eligibleVerifiers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final verifier = eligibleVerifiers[idx];
                        final verifierName =
                            _localizedMemberName(verifier, strings);
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFE5CEC2),
                              width: 1.1,
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              hoverColor: Colors.transparent,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(modalCtx).pop();
                                _showVerifierPinDialog(
                                  context: context,
                                  activity: activity,
                                  requester: requester,
                                  verifier: verifier,
                                  strings: strings,
                                );
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF5E4DC),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        verifier.avatarEmoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            verifierName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: CozyTheme.textDark,
                                            ),
                                          ),
                                          Text(
                                            _localizedMemberRole(
                                              verifier,
                                              strings,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF5A463C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6D4C41),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        strings.tr('Sahkan ✓', 'Verify ✓'),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  // Modal "Who completed this?" — 2-Step Request -> Verify by Another Family Member -> Earn Stars
  void _showWhoDoneItModal({
    required BuildContext context,
    required BondingActivity activity,
    required List<FamilyMember> members,
    required AppStrings strings,
  }) {
    final activityTitle = strings.isMs ? activity.titleMs : activity.titleEn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        final bottomSafe = MediaQuery.viewPaddingOf(modalCtx).bottom;
        final extraBottom = bottomSafe >= 34.0 ? bottomSafe : 34.0;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: EdgeInsets.fromLTRB(22, 14, 22, extraBottom + 10),
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
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
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E4DC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5CEC2)),
                        ),
                        alignment: Alignment.center,
                        child: activity.customImagePath != null &&
                                activity.customImagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: MediaStorageService.buildAdaptiveImage(
                                  activity.customImagePath,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: Text(
                                    activity.iconEmoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              )
                            : Text(
                                activity.iconEmoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.tr(
                                'Siapa yang siapkan?',
                                'Who completed this?',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activityTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5A463C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(modalCtx).pop(),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: CozyTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.tr(
                      'Ketik nama anda bila siap — ahli lain akan sahkan dengan PIN untuk beri +${activity.points} Mata & +${activity.stars} Bintang:',
                      'Tap your name when done — another member will verify with PIN to award +${activity.points} Pts & +${activity.stars} Stars:',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A463C),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Members List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final m = members[idx];
                        final displayName = _localizedMemberName(m, strings);
                        final hasAlreadyCompleted =
                            activity.completedByMemberIds.contains(m.id);
                        final isWaitingVerify =
                            activity.pendingVerificationMemberIds
                                .contains(m.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: hasAlreadyCompleted
                                ? const Color(0xFFF2ECE6)
                                : isWaitingVerify
                                    ? const Color(0xFFFAF2E8)
                                    : const Color(0xFFFFFDF9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: hasAlreadyCompleted || isWaitingVerify
                                  ? const Color(0xFF6D4C41)
                                  : const Color(0xFFE5CEC2),
                              width: (hasAlreadyCompleted || isWaitingVerify)
                                  ? 1.4
                                  : 1.1,
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              hoverColor: Colors.transparent,
                              onTap: hasAlreadyCompleted
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      if (isWaitingVerify) {
                                        // Step 2: Open verifier picker (another family member verifies!)
                                        Navigator.of(modalCtx).pop();
                                        _showVerifierPickerModal(
                                          context: context,
                                          activity: activity,
                                          requester: m,
                                          allMembers: members,
                                          strings: strings,
                                        );
                                      } else {
                                        // Step 1: Submit verification request (no stars until verified)
                                        ref
                                            .read(
                                              eratControllerProvider.notifier,
                                            )
                                            .requestActivityVerification(
                                              activityId: activity.id,
                                              memberId: m.id,
                                            );
                                        Navigator.of(modalCtx).pop();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                const Color(0xFF6D4C41),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            content: Text(
                                              strings.tr(
                                                'Dihantar untuk pengesahan! Minta ahli keluarga lain sahkan $displayName.',
                                                'Sent for verification! Ask another member to verify $displayName.',
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
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF5E4DC),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: m.customPhotoPath != null
                                          ? ClipOval(
                                              child: MediaStorageService
                                                  .buildAdaptiveImage(
                                                m.customPhotoPath,
                                                width: 44,
                                                height: 44,
                                                placeholder: Text(
                                                  m.avatarEmoji,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              m.avatarEmoji,
                                              style: const TextStyle(
                                                fontSize: 22,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w900,
                                              color: CozyTheme.textDark,
                                            ),
                                          ),
                                          Text(
                                            isWaitingVerify
                                                ? strings.tr(
                                                    'Menunggu pengesahan ahli lain',
                                                    'Waiting for another member to verify',
                                                  )
                                                : _localizedMemberRole(
                                                    m,
                                                    strings,
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasAlreadyCompleted
                                            ? const Color(0xFFF5E4DC)
                                            : isWaitingVerify
                                                ? const Color(0xFF6D4C41)
                                                : const Color(0xFFFFFDF9),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFF6D4C41),
                                          width: hasAlreadyCompleted ? 0.8 : 1.4,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasAlreadyCompleted
                                                ? Icons.check_rounded
                                                : isWaitingVerify
                                                    ? Icons
                                                        .verified_user_outlined
                                                    : Icons.send_rounded,
                                            color: isWaitingVerify
                                                ? Colors.white
                                                : const Color(0xFF6D4C41),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasAlreadyCompleted
                                                ? strings.tr(
                                                    'Disahkan',
                                                    'Verified',
                                                  )
                                                : isWaitingVerify
                                                    ? strings.tr(
                                                        'Sahkan',
                                                        'Verify',
                                                      )
                                                    : strings.tr(
                                                        'Saya Buat',
                                                        'I Did It',
                                                      ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: isWaitingVerify
                                                  ? Colors.white
                                                  : const Color(0xFF6D4C41),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

  // Modal to Create New Daily Activity (100% localized + category picker + iPad constrained)
  void _showCreateTaskModal(BuildContext context, AppStrings strings) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '🍽️';
    String? uploadedImagePath;
    bool isUploadingPhoto = false;
    ActivityCategory selectedCategory =
        _selectedCategory ?? ActivityCategory.goodHabit;
    ParticipationMode selectedParticipation = ParticipationMode.anyone;
    bool isEveryDay = true;
    DateTime chosenScheduleDate = _selectedDate;
    int selectedPoints = 15;
    int selectedStars = 2;

    const emojis = ['🍽️', '🗑️', '🪴', '🛏️', '🧹', '🧸', '🧺', '📖', '🐾', '🥗'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickActivityPhoto(ImageSource source) async {
              final picked = await MediaStorageService.pickImage(
                source: source,
              );
              if (picked == null) return;
              setModalState(() => isUploadingPhoto = true);
              final uploaded = await MediaStorageService.uploadActivityPhoto(
                activityId: 'act_${DateTime.now().millisecondsSinceEpoch}',
                imageFile: picked,
              );
              if (!modalCtx.mounted) return;
              setModalState(() {
                isUploadingPhoto = false;
                if (uploaded != null) {
                  uploadedImagePath = uploaded;
                }
              });
            }

            final viewInsets = MediaQuery.viewInsetsOf(modalCtx).bottom;
            final bottomSafe = MediaQuery.viewPaddingOf(modalCtx).bottom;
            final extraBottom = bottomSafe >= 34.0 ? bottomSafe : 34.0;

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Padding(
                  padding: EdgeInsets.only(bottom: viewInsets),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(22, 14, 22, extraBottom + 12),
                    decoration: const BoxDecoration(
                      color: CozyTheme.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
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
                              Expanded(
                                child: Text(
                                  strings.tr(
                                    'Tambah Aktiviti Harian',
                                    'Add Daily Activity',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(modalCtx).pop(),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                icon: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5E4DC),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE5CEC2),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Activity Name Field (Explicit Placeholder + Live Validation Trigger)
                          Text(
                            strings.tr('Nama Aktiviti', 'Activity Name'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setModalState(() {}),
                            scrollPadding: const EdgeInsets.only(bottom: 140),
                            decoration: InputDecoration(
                              hintText: strings.tr(
                                'cth: Siram pokok bunga di balkoni',
                                'e.g., Water the balcony plants',
                              ),
                              hintStyle: const TextStyle(
                                color: Color(0xFF9C897E),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
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
                          const SizedBox(height: 12),

                          // Short Description Field
                          Text(
                            strings.tr(
                              'Penerangan Ringkas',
                              'Short Description',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                            scrollPadding: const EdgeInsets.only(bottom: 140),
                            decoration: InputDecoration(
                              hintText: strings.tr(
                                'cth: Susun mainan dalam kotak sebelum tidur.',
                                'e.g., Put toys back in the basket before bed.',
                              ),
                              hintStyle: const TextStyle(
                                color: Color(0xFF9C897E),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
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
                          const SizedBox(height: 14),

                          // Category Selector (Compact 1-Row)
                          Text(
                            strings.tr('Kategori', 'Category'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCategoryChip(
                                  label: strings.tr('Tabiat', 'Habits'),
                                  isSelected: selectedCategory ==
                                      ActivityCategory.goodHabit,
                                  onTap: () => setModalState(
                                    () => selectedCategory =
                                        ActivityCategory.goodHabit,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCategoryChip(
                                  label: strings.tr('Bersama', 'Bonding'),
                                  isSelected: selectedCategory ==
                                      ActivityCategory.bonding10Min,
                                  onTap: () => setModalState(
                                    () => selectedCategory =
                                        ActivityCategory.bonding10Min,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCategoryChip(
                                  label: strings.tr('Cabaran', 'Challenges'),
                                  isSelected: selectedCategory ==
                                      ActivityCategory.familyChallenge,
                                  onTap: () => setModalState(
                                    () => selectedCategory =
                                        ActivityCategory.familyChallenge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Participation Mode Selector (Compact 1-Row)
                          Text(
                            strings.tr('Penyertaan', 'Who Participates?'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCategoryChip(
                                  label: strings.tr(
                                    'Wakil (1+)',
                                    'Anyone (1+)',
                                  ),
                                  isSelected: selectedParticipation ==
                                      ParticipationMode.anyone,
                                  onTap: () => setModalState(
                                    () => selectedParticipation =
                                        ParticipationMode.anyone,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCategoryChip(
                                  label: strings.tr('Semua Ahli', 'Everyone'),
                                  isSelected: selectedParticipation ==
                                      ParticipationMode.everyone,
                                  onTap: () => setModalState(
                                    () => selectedParticipation =
                                        ParticipationMode.everyone,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Activity Photo (Capture or Upload)
                          Text(
                            strings.tr(
                              'Foto Aktiviti (Pilihan)',
                              'Activity Photo (Optional)',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: CozyTheme.border),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5E4DC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE5CEC2),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: uploadedImagePath != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              child: MediaStorageService
                                                  .buildAdaptiveImage(
                                                uploadedImagePath,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                placeholder: Text(
                                                  selectedEmoji,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              selectedEmoji,
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: isUploadingPhoto
                                            ? null
                                            : () => pickActivityPhoto(
                                                ImageSource.camera,
                                              ),
                                        icon: const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 16,
                                        ),
                                        label: Text(
                                          strings.tr('Kamera', 'Capture'),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF6D4C41),
                                          side: const BorderSide(
                                            color: CozyTheme.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          minimumSize: const Size(0, 38),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: isUploadingPhoto
                                            ? null
                                            : () => pickActivityPhoto(
                                                ImageSource.gallery,
                                              ),
                                        icon: const Icon(
                                          Icons.upload_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          strings.tr('Muat Naik', 'Upload'),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF6D4C41),
                                          side: const BorderSide(
                                            color: CozyTheme.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          minimumSize: const Size(0, 38),
                                        ),
                                      ),
                                      if (uploadedImagePath != null)
                                        OutlinedButton.icon(
                                          onPressed: isUploadingPhoto
                                              ? null
                                              : () => setModalState(
                                                    () => uploadedImagePath =
                                                        null,
                                                  ),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            strings.tr('Padam', 'Delete'),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: const BorderSide(
                                              color: Color(0xFFF5C2C0),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            minimumSize: const Size(0, 38),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Balanced 5x2 Emoji Picker Grid (>= 44x44 pt + High-Contrast Selection Ring)
                          Text(
                            strings.tr('Pilih Ikon', 'Choose Icon'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.15,
                            ),
                            itemCount: emojis.length,
                            itemBuilder: (gridCtx, i) {
                              final em = emojis[i];
                              final isSel = selectedEmoji == em;
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => selectedEmoji = em);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? const Color(0xFFF5E4DC)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSel
                                            ? const Color(0xFF6D4C41)
                                            : CozyTheme.border,
                                        width: isSel ? 2.2 : 1.0,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      em,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Intuitive Minus / Plus Steppers for Points & Stars (No Ambiguous Dropdowns)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStepperControl(
                                  label: strings.tr('Mata', 'Points'),
                                  valueText:
                                      '+$selectedPoints ${strings.tr('Mata', 'Pts')}',
                                  canDecrement: selectedPoints > 5,
                                  canIncrement: selectedPoints < 50,
                                  onDecrement: () => setModalState(
                                    () => selectedPoints =
                                        (selectedPoints - 5).clamp(5, 50),
                                  ),
                                  onIncrement: () => setModalState(
                                    () => selectedPoints =
                                        (selectedPoints + 5).clamp(5, 50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStepperControl(
                                  label: strings.tr('Bintang', 'Stars'),
                                  valueText: '★ $selectedStars',
                                  canDecrement: selectedStars > 1,
                                  canIncrement: selectedStars < 10,
                                  onDecrement: () => setModalState(
                                    () => selectedStars =
                                        (selectedStars - 1).clamp(1, 10),
                                  ),
                                  onIncrement: () => setModalState(
                                    () => selectedStars =
                                        (selectedStars + 1).clamp(1, 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Schedule Selector: Every Day vs Specific Date
                          Text(
                            strings.tr('Jadual Aktiviti', 'Schedule'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setModalState(() => isEveryDay = true),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isEveryDay
                                          ? const Color(0xFF6D4C41)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isEveryDay
                                            ? const Color(0xFF6D4C41)
                                            : const Color(0xFFE5CEC2),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      strings.tr('Setiap Hari', 'Every Day'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isEveryDay
                                            ? Colors.white
                                            : const Color(0xFF5A463C),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await _openCozyDatePicker(
                                      chosenScheduleDate,
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        isEveryDay = false;
                                        chosenScheduleDate = _dateOnly(picked);
                                      });
                                    } else {
                                      setModalState(() => isEveryDay = false);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !isEveryDay
                                          ? const Color(0xFF6D4C41)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: !isEveryDay
                                            ? const Color(0xFF6D4C41)
                                            : const Color(0xFFE5CEC2),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: !isEveryDay
                                              ? Colors.white
                                              : const Color(0xFF5A463C),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            isEveryDay
                                                ? strings.tr(
                                                    'Tarikh Tertentu',
                                                    'Specific Date',
                                                  )
                                                : '${chosenScheduleDate.day}/${chosenScheduleDate.month}/${chosenScheduleDate.year}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: !isEveryDay
                                                  ? Colors.white
                                                  : const Color(0xFF5A463C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Create Button (Disabled/Muted until valid Activity Name is entered)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (isUploadingPhoto ||
                                      titleController.text.trim().isEmpty)
                                  ? null
                                  : () {
                                      final title = titleController.text.trim();
                                      if (title.isEmpty) return;

                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(eratControllerProvider.notifier)
                                          .addActivity(
                                            titleMs: title,
                                            titleEn: title,
                                            descMs: descController.text
                                                    .trim()
                                                    .isEmpty
                                                ? 'Aktiviti harian bersama keluarga.'
                                                : descController.text.trim(),
                                            descEn: descController.text
                                                    .trim()
                                                    .isEmpty
                                                ? 'Daily family activity together.'
                                                : descController.text.trim(),
                                            iconEmoji: selectedEmoji,
                                            customImagePath: uploadedImagePath,
                                            category: selectedCategory,
                                            participationMode:
                                                selectedParticipation,
                                            durationMinutes: 10,
                                            points: selectedPoints,
                                            stars: selectedStars,
                                            requiresParentVerification: false,
                                            scheduledDate: isEveryDay
                                                ? null
                                                : chosenScheduleDate,
                                          );

                                      Navigator.of(modalCtx).pop();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              const Color(0xFF6D4C41),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          content: Text(
                                            strings.tr(
                                              'Aktiviti "$title" berjaya ditambah.',
                                              'Activity "$title" added.',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D4C41),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0xFFD8CBC3),
                                disabledForegroundColor:
                                    const Color(0xFF8C7B72),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                strings.tr(
                                  'Simpan Aktiviti',
                                  'Save Activity',
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
    final members = appState.members;
    final activities = appState.activities;
    final pendingVerifyCount = activities
        .where((a) => a.pendingVerificationMemberIds.isNotEmpty)
        .length;

    final filteredActivities = activities.where((a) {
      final matchesCategory =
          _selectedCategory == null || a.category == _selectedCategory;
      final matchesScope = switch (_selectedScopeFilter) {
        _TaskScopeFilter.all => true,
        _TaskScopeFilter.everyone =>
          a.participationMode == ParticipationMode.everyone,
        _TaskScopeFilter.anyone =>
          a.participationMode == ParticipationMode.anyone,
        _TaskScopeFilter.pendingVerify =>
          a.pendingVerificationMemberIds.isNotEmpty,
      };
      return matchesCategory && matchesScope && a.appliesToDate(_selectedDate);
    }).toList()
      ..sort((a, b) {
        final aDone = a.isFullyCompleted(members) ? 1 : 0;
        final bDone = b.isFullyCompleted(members) ? 1 : 0;
        return aDone.compareTo(bDone); // Pending tasks first, Completed below
      });

    final completedCount =
        activities.where((a) => a.isFullyCompleted(members)).length;
    final remainingCount =
        (activities.length - completedCount).clamp(0, activities.length);
    final completionProgress = activities.isEmpty
        ? 0.0
        : (completedCount / activities.length).clamp(0.0, 1.0);

    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    final extraBottomInset =
        bottomSafeInset >= 34.0 ? 0.0 : (34.0 - bottomSafeInset);

    return Scaffold(
      backgroundColor: CozyTheme.background,
      appBar: AppBar(
        backgroundColor: CozyTheme.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: CozyTheme.textDark,
            size: 20,
          ),
          tooltip: strings.tr('Kembali', 'Back'),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            strings.tr('Aktiviti Harian', 'Daily Activities'),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: CozyTheme.textDark,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: extraBottomInset),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showCreateTaskModal(context, strings);
          },
          backgroundColor: const Color(0xFF6D4C41),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            strings.tr('Aktiviti Baharu', 'New Family Task'),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600.0;
            final horizontalPad = isTablet ? 32.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 860.0 : double.infinity,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    10,
                    horizontalPad,
                    extraBottomInset + 96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interactive Date Navigator (Past / Today / Upcoming)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5CEC2)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: strings.tr('Hari Sebelum', 'Previous Day'),
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFF6D4C41),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedDate = _selectedDate.subtract(
                                    const Duration(days: 1),
                                  );
                                });
                              },
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  final picked = await _openCozyDatePicker(
                                    _selectedDate,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = _dateOnly(picked);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 44,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: Color(0xFF6D4C41),
                                      ),
                                      const SizedBox(width: 7),
                                      Flexible(
                                        child: Text(
                                          _formattedDateLabel(
                                            _selectedDate,
                                            strings,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: CozyTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!_isSameDay(
                              _selectedDate,
                              _dateOnly(DateTime.now()),
                            ))
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedDate = _dateOnly(DateTime.now());
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF6D4C41),
                                  minimumSize: const Size(44, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: Text(
                                  strings.tr('Hari Ini', 'Today'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              tooltip: strings.tr('Hari Berikut', 'Next Day'),
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF6D4C41),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedDate = _selectedDate.add(
                                    const Duration(days: 1),
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // Hero Progress Summary Card (Matches APP-005 & APP-006 #F5E4DC + #6D4C41)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E4DC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE5CEC2),
                            width: 1.3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(110, 70, 38, 0.06),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFDF9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE5CEC2),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.checklist_rounded,
                                    size: 23,
                                    color: Color(0xFF6D4C41),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isSameDay(
                                          _selectedDate,
                                          _dateOnly(DateTime.now()),
                                        )
                                            ? strings.tr(
                                                'Kemajuan Hari Ini',
                                                'Today’s Progress',
                                              )
                                            : _selectedDate.isAfter(
                                                _dateOnly(DateTime.now()),
                                              )
                                                ? strings.tr(
                                                    'Jadual Akan Datang',
                                                    'Upcoming Schedule',
                                                  )
                                                : strings.tr(
                                                    'Rekod Terdahulu',
                                                    'Past Progress',
                                                  ),
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w900,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        remainingCount == 0
                                            ? strings.tr(
                                                'Semua aktiviti hari ini selesai!',
                                                'All daily activities done!',
                                              )
                                            : strings.tr(
                                                '$remainingCount berbaki • ketik untuk tanda',
                                                '$remainingCount left • tap to complete',
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF5A463C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFDF9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5CEC2),
                                    ),
                                  ),
                                  child: Text(
                                    '$completedCount/${activities.length} ${strings.tr('Siap', 'Done')}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: completionProgress),
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                builder: (context, animatedVal, _) {
                                  return LinearProgressIndicator(
                                    value: animatedVal,
                                    minHeight: 9,
                                    backgroundColor: const Color(0xB3FFFFFF),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6D4C41),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full-Width Category Filter Row (Flush Left-to-Right Alignment with Cards Below)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildCategoryChip(
                              label: strings.tr('Semua', 'All'),
                              isSelected: _selectedCategory == null,
                              onTap: () =>
                                  setState(() => _selectedCategory = null),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _buildCategoryChip(
                              label: strings.tr('Tabiat', 'Habits'),
                              isSelected: _selectedCategory ==
                                  ActivityCategory.goodHabit,
                              onTap: () => setState(
                                () => _selectedCategory =
                                    ActivityCategory.goodHabit,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: _buildCategoryChip(
                              label: strings.tr('Bersama', 'Bonding'),
                              isSelected: _selectedCategory ==
                                  ActivityCategory.bonding10Min,
                              onTap: () => setState(
                                () => _selectedCategory =
                                    ActivityCategory.bonding10Min,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _buildCategoryChip(
                              label: strings.tr('Cabaran', 'Challenges'),
                              isSelected: _selectedCategory ==
                                  ActivityCategory.familyChallenge,
                              onTap: () => setState(
                                () => _selectedCategory =
                                    ActivityCategory.familyChallenge,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Compact Scope & Verification Filter Bar (All / Everyone / Anyone / Verify)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEBDCC8)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildParticipationFilterTab(
                                label: strings.tr('Semua', 'All'),
                                isSelected:
                                    _selectedScopeFilter == _TaskScopeFilter.all,
                                onTap: () => setState(
                                  () => _selectedScopeFilter =
                                      _TaskScopeFilter.all,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _buildParticipationFilterTab(
                                icon: Icons.groups_rounded,
                                label: strings.tr('Semua Ahli', 'Everyone'),
                                isSelected: _selectedScopeFilter ==
                                    _TaskScopeFilter.everyone,
                                onTap: () => setState(
                                  () => _selectedScopeFilter =
                                      _TaskScopeFilter.everyone,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _buildParticipationFilterTab(
                                icon: Icons.person_outline_rounded,
                                label: strings.tr('Wakil', 'Anyone'),
                                isSelected: _selectedScopeFilter ==
                                    _TaskScopeFilter.anyone,
                                onTap: () => setState(
                                  () => _selectedScopeFilter =
                                      _TaskScopeFilter.anyone,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _buildParticipationFilterTab(
                                icon: Icons.verified_user_outlined,
                                label: pendingVerifyCount > 0
                                    ? '${strings.tr('Sahkan', 'Verify')} ($pendingVerifyCount)'
                                    : strings.tr('Sahkan', 'Verify'),
                                isSelected: _selectedScopeFilter ==
                                    _TaskScopeFilter.pendingVerify,
                                onTap: () => setState(
                                  () => _selectedScopeFilter =
                                      _TaskScopeFilter.pendingVerify,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Grouped Activity Cards: "To Do (N)" + "Completed Today (N)" (1-Col Phone / 2-Col iPad)
                      ...() {
                        final pendingList = filteredActivities
                            .where((a) => !a.isFullyCompleted(members))
                            .toList();
                        final doneList = filteredActivities
                            .where((a) => a.isFullyCompleted(members))
                            .toList();

                        Widget buildSectionCards(List<BondingActivity> items) {
                          if (isTablet) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 2.1,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, idx) {
                                final act = items[idx];
                                final completedMembers = members
                                    .where(
                                      (m) => act.completedByMemberIds
                                          .contains(m.id),
                                    )
                                    .toList();
                                return _buildActivityCard(
                                  activity: act,
                                  allMembers: members,
                                  completedMembers: completedMembers,
                                  strings: strings,
                                  onInfoTap: () => _showActivityDetailModal(
                                    context: context,
                                    activity: act,
                                    allMembers: members,
                                    completedMembers: completedMembers,
                                    strings: strings,
                                  ),
                                  onTap: () => _showWhoDoneItModal(
                                    context: context,
                                    activity: act,
                                    members: members,
                                    strings: strings,
                                  ),
                                );
                              },
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final act = items[idx];
                              final completedMembers = members
                                  .where(
                                    (m) => act.completedByMemberIds
                                        .contains(m.id),
                                  )
                                  .toList();
                              return _buildActivityCard(
                                activity: act,
                                allMembers: members,
                                completedMembers: completedMembers,
                                strings: strings,
                                onInfoTap: () => _showActivityDetailModal(
                                  context: context,
                                  activity: act,
                                  allMembers: members,
                                  completedMembers: completedMembers,
                                  strings: strings,
                                ),
                                onTap: () => _showWhoDoneItModal(
                                  context: context,
                                  activity: act,
                                  members: members,
                                  strings: strings,
                                ),
                              );
                            },
                          );
                        }

                        return <Widget>[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.03),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey(
                                '${_selectedCategory?.name}_${_selectedScopeFilter.name}_${pendingList.length}_${doneList.length}',
                              ),
                              child: (pendingList.isEmpty && doneList.isEmpty)
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 28,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF2E8),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFFEBDCC8),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5E4DC),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFE5CEC2),
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              _selectedScopeFilter ==
                                                      _TaskScopeFilter
                                                          .pendingVerify
                                                  ? Icons
                                                      .verified_user_rounded
                                                  : Icons.celebration_rounded,
                                              size: 28,
                                              color: const Color(0xFF6D4C41),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _selectedScopeFilter ==
                                                    _TaskScopeFilter
                                                        .pendingVerify
                                                ? strings.tr(
                                                    'Semua sudah disahkan!',
                                                    'All caught up!',
                                                  )
                                                : strings.tr(
                                                    'Tiada tugasan tertangguh!',
                                                    'All clear in this view!',
                                                  ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: CozyTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedScopeFilter ==
                                                    _TaskScopeFilter
                                                        .pendingVerify
                                                ? strings.tr(
                                                    'Tiada tugasan menunggu pengesahan buat masa ini.',
                                                    'No tasks are waiting for verification right now.',
                                                  )
                                                : strings.tr(
                                                    'Hebat! Anda boleh tukar penapis atau tambah aktiviti baharu.',
                                                    'Great job! Switch filters or add a new family task below.',
                                                  ),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF5A463C),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          OutlinedButton(
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _selectedCategory = null;
                                                _selectedScopeFilter =
                                                    _TaskScopeFilter.all;
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFF6D4C41),
                                              side: const BorderSide(
                                                color: Color(0xFF6D4C41),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              minimumSize: const Size(120, 44),
                                            ),
                                            child: Text(
                                              strings.tr(
                                                'Lihat Semua',
                                                'Show All',
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (pendingList.isNotEmpty) ...[
                                          _buildStatusSectionHeader(
                                            label: strings.tr(
                                              'Belum Siap (${pendingList.length})',
                                              'To Do (${pendingList.length})',
                                            ),
                                            isCompleted: false,
                                          ),
                                          const SizedBox(height: 10),
                                          buildSectionCards(pendingList),
                                        ],
                                        if (pendingList.isNotEmpty &&
                                            doneList.isNotEmpty)
                                          const SizedBox(height: 20),
                                        if (doneList.isNotEmpty) ...[
                                          _buildStatusSectionHeader(
                                            label: strings.tr(
                                              'Selesai Hari Ini (${doneList.length})',
                                              'Completed Today (${doneList.length})',
                                            ),
                                            isCompleted: true,
                                          ),
                                          const SizedBox(height: 10),
                                          buildSectionCards(doneList),
                                        ],
                                      ],
                                    ),
                            ),
                          ),
                        ];
                      }(),
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

  /// Uniform, high-contrast Daily Activity Card with distinct Pending vs Completed visual states,
  /// ParticipationMode chips (Everyone vs Anyone), and Assignee Micro-Avatars.
  Widget _buildActivityCard({
    required BondingActivity activity,
    required List<FamilyMember> allMembers,
    required List<FamilyMember> completedMembers,
    required AppStrings strings,
    required VoidCallback onInfoTap,
    required VoidCallback onTap,
  }) {
    final isEveryoneMode =
        activity.participationMode == ParticipationMode.everyone;
    final targets = activity.targetMembers(allMembers);
    final completedTargetCount = targets
        .where((m) => activity.completedByMemberIds.contains(m.id))
        .length;
    final pendingVerifyMembers = allMembers
        .where((m) => activity.pendingVerificationMemberIds.contains(m.id))
        .toList();
    final hasPendingVerify = pendingVerifyMembers.isNotEmpty;
    final isDone = activity.isFullyCompleted(allMembers);
    final title = strings.isMs ? activity.titleMs : activity.titleEn;
    final rewardLine = strings.tr(
      '+${activity.stars} Bintang • +${activity.points} Mata',
      '+${activity.stars} ${activity.stars == 1 ? 'Star' : 'Stars'} • +${activity.points} Pts',
    );
    final completedNames = completedMembers
        .map((m) => _localizedMemberName(m, strings))
        .join(', ');

    final participationLabel = isEveryoneMode
        ? '$completedTargetCount/${targets.length}'
        : strings.tr('Wakil', 'Anyone');

    return Semantics(
      button: true,
      label:
          '$title, $rewardLine, ${isDone ? 'Completed by $completedNames' : 'Pending, tap to complete'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          // Completed: soft muted warm linen-grey; Pending: vibrant bright cream
          color: isDone ? const Color(0xFFF2ECE6) : const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDone
                ? const Color(0xFFDED4CB)
                : const Color(0xFFDCC3B4),
            width: isDone ? 1.1 : 1.5,
          ),
          boxShadow: isDone
              ? const []
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(110, 70, 38, 0.07),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            hoverColor: Colors.transparent,
            splashColor: const Color(0x146D4C41),
            highlightColor: const Color(0x0D6D4C41),
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Consistent Left Icon Squircle (Muted slightly when Completed)
                  Opacity(
                    opacity: isDone ? 0.72 : 1.0,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFFEAE1D9)
                            : const Color(0xFFF5E4DC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFFDED4CB)
                              : const Color(0xFFE5CEC2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: activity.customImagePath != null &&
                              activity.customImagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: MediaStorageService.buildAdaptiveImage(
                                activity.customImagePath,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: Text(
                                  activity.iconEmoji,
                                  style: const TextStyle(fontSize: 25),
                                ),
                              ),
                            )
                          : Text(
                              activity.iconEmoji,
                              style: const TextStyle(fontSize: 25),
                            ),
                    ),
                  ),
                  const SizedBox(width: 13),

                  // Center Copy Block: Clean Title + ⓘ Info Icon + Participation/Assignee Chips + Reward
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDone
                                      ? const Color(0xFF7B6960)
                                      : CozyTheme.textDark,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: const Color(0xFF9C897E),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Semantics(
                              button: true,
                              label: strings.tr(
                                'Lihat butiran aktiviti',
                                'View activity details',
                              ),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onInfoTap();
                                },
                                borderRadius: BorderRadius.circular(22),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: Color(0xFF8C685C),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Compact Meta Row: Mode Pill + Member DP Avatars (✓ Verified vs ⏳ Pending)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (!isDone)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E4DC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5CEC2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEveryoneMode
                                          ? Icons.groups_rounded
                                          : Icons.person_outline_rounded,
                                      size: 13,
                                      color: const Color(0xFF6D4C41),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      participationLabel,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF6D4C41),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Pending Verification Member DPs (Amber/Mocha Ring + ⏳ mini badge)
                            ...pendingVerifyMembers.take(4).map(
                                  (m) => _buildMemberStatusAvatar(
                                    member: m,
                                    isVerified: false,
                                    strings: strings,
                                  ),
                                ),
                            // Verified / Done Member DPs (Solid Mocha Ring + ✓ mini badge)
                            ...completedMembers.take(4).map(
                                  (m) => _buildMemberStatusAvatar(
                                    member: m,
                                    isVerified: true,
                                    strings: strings,
                                  ),
                                ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: isDone
                                  ? const Color(0xFF8C7B72)
                                  : const Color(0xFF6D4C41),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rewardLine,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDone
                                    ? const Color(0xFF8C7B72)
                                    : const Color(0xFF6D4C41),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Right Clear State Pill:
                  // Pending -> "Mark Done" | Has Pending Verify -> "Verify" | Completed -> "✓ Done"
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 78,
                      minHeight: 44,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF6D4C41)
                          : hasPendingVerify
                              ? const Color(0xFFF5E4DC)
                              : const Color(0xFFFFFDF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6D4C41),
                        width: isDone ? 1.0 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_rounded
                              : hasPendingVerify
                                  ? Icons.verified_user_outlined
                                  : Icons.radio_button_unchecked_rounded,
                          size: 15,
                          color:
                              isDone ? Colors.white : const Color(0xFF6D4C41),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isDone
                              ? strings.tr('Siap', 'Done')
                              : hasPendingVerify
                                  ? strings.tr('Sahkan', 'Verify')
                                  : strings.tr('Tanda Siap', 'Mark Done'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDone
                                ? Colors.white
                                : const Color(0xFF6D4C41),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compact circular member DP with unmistakable Done (✓) vs Pending Verify (⏳) corner badge
  Widget _buildMemberStatusAvatar({
    required FamilyMember member,
    required bool isVerified,
    required AppStrings strings,
  }) {
    final name = _localizedMemberName(member, strings);
    final tooltipText = isVerified
        ? '$name (${strings.tr('Disahkan', 'Verified')})'
        : '$name (${strings.tr('Menunggu pengesahan', 'Pending verification')})';

    return Tooltip(
      message: tooltipText,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xFFF5E4DC)
                    : const Color(0xFFFAF2E8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isVerified
                      ? const Color(0xFF6D4C41)
                      : const Color(0xFFD97706),
                  width: 1.6,
                ),
              ),
              alignment: Alignment.center,
              child: member.customPhotoPath != null
                  ? ClipOval(
                      child: MediaStorageService.buildAdaptiveImage(
                        member.customPhotoPath,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                        placeholder: Text(
                          member.avatarEmoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                  : Text(
                      member.avatarEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFF6D4C41)
                      : const Color(0xFFD97706),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFFDF9),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isVerified
                      ? Icons.check_rounded
                      : Icons.hourglass_top_rounded,
                  size: 8.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tactile iOS-style minus / plus stepper with >= 44x44 pt hit targets
  Widget _buildStepperControl({
    required String label,
    required String valueText,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: CozyTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CozyTheme.border),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: canDecrement
                    ? () {
                        HapticFeedback.selectionClick();
                        onDecrement();
                      }
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: canDecrement
                        ? const Color(0xFF6D4C41)
                        : const Color(0xFFCBBDB4),
                  ),
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.textDark,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: canIncrement
                    ? () {
                        HapticFeedback.selectionClick();
                        onIncrement();
                      }
                    : null,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: canIncrement
                        ? const Color(0xFF6D4C41)
                        : const Color(0xFFCBBDB4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSectionHeader({
    required String label,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: isCompleted ? const Color(0xFF7B6960) : CozyTheme.textDark,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE6DDD5),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipationFilterTab({
    IconData? icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D4C41) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13.5,
                    color: isSelected ? Colors.white : const Color(0xFF5A463C),
                  ),
                  const SizedBox(width: 3),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF5A463C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6D4C41)
                : const Color(0xFFF5E4DC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6D4C41)
                  : const Color(0xFFE5CEC2),
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : CozyTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
