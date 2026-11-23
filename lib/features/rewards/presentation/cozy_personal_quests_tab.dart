import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
import '../../family/presentation/cozy_add_member_sheet.dart';
import 'gamified_milestone_map_view.dart';

/// Cozy Minimalist Quests, Milestones & Rewards Tab for Private Space
class CozyPersonalQuestsTab extends ConsumerStatefulWidget {
  const CozyPersonalQuestsTab({super.key});

  @override
  ConsumerState<CozyPersonalQuestsTab> createState() =>
      _CozyPersonalQuestsTabState();
}

class _CozyPersonalQuestsTabState extends ConsumerState<CozyPersonalQuestsTab> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _pendingBg = Color(0xFFFFF8E1);
  static const Color _pendingBorder = Color(0xFFE6A23C);
  static const Color _pendingText = Color(0xFF9A5B00);

  // 0 = Quests, 1 = Milestone Map, 2 = Rewards
  int _mainSection = 0;
  // 0 = All, 1 = Daily, 2 = Done
  int _activeFilter = 0;
  DateTime _selectedDate = _dateOnly(DateTime.now());

  // Keyed by '${memberId}_${yyyy-MM-dd}' so Past / Today / Upcoming have independent records
  final Map<String, Set<String>> _completedQuestsByMemberDate = {};
  final Map<String, Set<String>> _pendingQuestsByMemberDate = {};

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _isSelectedFuture =>
      _selectedDate.isAfter(_dateOnly(DateTime.now()));

  bool get _isSelectedPast =>
      _selectedDate.isBefore(_dateOnly(DateTime.now()));

  bool get _isRealAccount =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    // Real authenticated family accounts start fresh with ZERO demo quests
    if (_isRealAccount) {
      _quests.clear();
    }
  }

  Set<String> _completedQuestIdsFor(String memberId, [DateTime? forDate]) {
    final target = _dateOnly(forDate ?? _selectedDate);
    final key = '${memberId}_${_dateKey(target)}';
    return _completedQuestsByMemberDate.putIfAbsent(key, () {
      if (!_isRealAccount) {
        // Seed realistic past history on Yesterday ONLY for Demo Mode
        final yesterday = _dateOnly(DateTime.now()).subtract(
          const Duration(days: 1),
        );
        if (_isSameDay(target, yesterday)) {
          return <String>{'q_1', 'q_2'};
        }
      }
      return <String>{};
    });
  }

  Set<String> _pendingQuestIdsFor(String memberId, [DateTime? forDate]) {
    final target = _dateOnly(forDate ?? _selectedDate);
    final key = '${memberId}_${_dateKey(target)}';
    return _pendingQuestsByMemberDate.putIfAbsent(key, () => <String>{});
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
              primary: _mochaPrimary,
              onPrimary: Colors.white,
              surface: CozyTheme.background,
              onSurface: CozyTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
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

  final List<Map<String, dynamic>> _quests = const [];

  String _formattedSelectedDateLabel(AppStrings strings) {
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
    final d = strings.isMs
        ? daysMs[_selectedDate.weekday - 1]
        : daysEn[_selectedDate.weekday - 1];
    final m = strings.isMs
        ? monthsMs[_selectedDate.month - 1]
        : monthsEn[_selectedDate.month - 1];
    final shortDate = '$d, ${_selectedDate.day} $m';
    if (_isSameDay(_selectedDate, today)) {
      return strings.tr('Hari Ini • $shortDate', 'Today • $shortDate');
    }
    if (_isSameDay(_selectedDate, yesterday)) {
      return strings.tr('Semalam • $shortDate', 'Yesterday • $shortDate');
    }
    if (_isSameDay(_selectedDate, tomorrow)) {
      return strings.tr('Esok • $shortDate', 'Tomorrow • $shortDate');
    }
    return shortDate;
  }

  bool _questAppliesToSelectedDate(Map<String, dynamic> q) {
    final scheduledKey = q['scheduledDateKey'] as String?;
    if (scheduledKey == null || scheduledKey.isEmpty) {
      return true; // Recurring Every Day / flexible daily habit
    }
    return scheduledKey == _dateKey(_selectedDate);
  }

  bool _needsParentVerification(FamilyMember member) {
    return !member.isParentOrGuardian && member.ageYears < 10;
  }

  void _completeAndAward({
    required String id,
    required String title,
    required int stars,
    required String memberId,
  }) {
    final completed = _completedQuestIdsFor(memberId);
    final pending = _pendingQuestIdsFor(memberId);
    setState(() {
      pending.remove(id);
      completed.add(id);
    });
    final ctrl = ref.read(eratControllerProvider.notifier);
    final isBacked =
        ref.read(eratControllerProvider).activities.any((a) => a.id == id);
    if (isBacked) {
      ctrl.approvePendingActivity(id, memberId);
    } else {
      ctrl.addStarsToActiveMember(
        stars: stars,
        reason: title,
      );
    }
    final updatedState = ref.read(eratControllerProvider);
    final updatedMember = updatedState.activeMember;
    final strings = ref.read(appStringsProvider);
    showCozyStarCelebration(
      context: context,
      starsEarned: stars,
      pointsEarned: stars * 10,
      taskTitle: title,
      totalStars: updatedMember.stars,
      totalPoints: updatedMember.points,
      earnerName: _localizedMemberName(updatedMember.name, strings),
      familyGoalCurrentStars: updatedState.family.familyGoalCurrentStars,
      familyGoalTargetStars: updatedState.family.familyGoalTargetStars,
    );
  }

  void _handleQuestAction({
    required Map<String, dynamic> quest,
    required FamilyMember activeMember,
    required AppStrings strings,
  }) {
    if (_isSelectedFuture) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.tr(
              'Misi akan datang hanya boleh ditandakan pada tarikhnya.',
              'Upcoming quests can be marked done once that date arrives.',
            ),
          ),
          backgroundColor: CozyTheme.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final id = quest['id'] as String;
    final title = strings.tr(
      quest['titleMs'] as String,
      quest['titleEn'] as String,
    );
    final stars = quest['stars'] as int;
    final appState = ref.read(eratControllerProvider);
    final isBackedByActivity = appState.activities.any((a) => a.id == id);

    // If this quest is a real Firestore-backed BondingActivity, delegate directly to EratController
    if (isBackedByActivity) {
      final act = appState.activities.firstWhere((a) => a.id == id);
      if (act.completedByMemberIds.contains(activeMember.id)) return;
      if (act.pendingVerificationMemberIds.contains(activeMember.id)) {
        _showParentVerifySheet(
          id: id,
          title: title,
          stars: stars,
          activeMember: activeMember,
          strings: strings,
        );
        return;
      }
      ref.read(eratControllerProvider.notifier).completeActivity(id);
      final afterAct = ref
          .read(eratControllerProvider)
          .activities
          .firstWhere((a) => a.id == id, orElse: () => act);
      if (afterAct.pendingVerificationMemberIds.contains(activeMember.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.tr(
                'Permintaan pengesahan untuk "$title" dihantar ke skrin Utama Ibu Bapa!',
                'Approval request for "$title" sent to Parent’s Home screen!',
              ),
            ),
            backgroundColor: _mochaPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      } else if (afterAct.completedByMemberIds.contains(activeMember.id)) {
        final updatedState = ref.read(eratControllerProvider);
        final updatedMember = updatedState.activeMember;
        showCozyStarCelebration(
          context: context,
          starsEarned: stars,
          pointsEarned: stars * 10,
          taskTitle: title,
          totalStars: updatedMember.stars,
          totalPoints: updatedMember.points,
          earnerName: _localizedMemberName(updatedMember.name, strings),
          familyGoalCurrentStars: updatedState.family.familyGoalCurrentStars,
          familyGoalTargetStars: updatedState.family.familyGoalTargetStars,
        );
      }
      return;
    }

    final completed = _completedQuestIdsFor(activeMember.id);
    final pending = _pendingQuestIdsFor(activeMember.id);

    // Toggle off if already done
    if (completed.contains(id)) {
      setState(() => completed.remove(id));
      return;
    }

    // Child < 10 OR any non-parent marking a past date requires Parent PIN verification
    final requiresApproval =
        _needsParentVerification(activeMember) ||
        (_isSelectedPast && !activeMember.isParentOrGuardian);

    if (requiresApproval) {
      if (pending.contains(id)) {
        _showParentVerifySheet(
          id: id,
          title: title,
          stars: stars,
          activeMember: activeMember,
          strings: strings,
        );
      } else {
        setState(() => pending.add(id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSelectedPast
                  ? strings.tr(
                      'Permintaan pengesahan lewat untuk "$title" dihantar. Ketik lagi untuk sahkan dengan PIN Ibu Bapa.',
                      'Late approval requested for "$title". Tap again to verify with Parent PIN.',
                    )
                  : strings.tr(
                      'Menunggu pengesahan ibu bapa untuk "$title". Ketik lagi untuk sahkan dengan PIN Ibu Bapa.',
                      'Awaiting parent approval for "$title". Tap again to verify with Parent PIN.',
                    ),
            ),
            backgroundColor: CozyTheme.textDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
      return;
    }

    // Members 10+ and Parents complete directly
    _completeAndAward(
      id: id,
      title: title,
      stars: stars,
      memberId: activeMember.id,
    );
  }

  void _showParentVerifySheet({
    required String id,
    required String title,
    required int stars,
    required FamilyMember activeMember,
    required AppStrings strings,
  }) {
    final appState = ref.read(eratControllerProvider);
    final parent = appState.members.firstWhere(
      (m) => m.isParentOrGuardian,
      orElse: () => activeMember,
    );
    final expectedPin = parent.pin ?? '1234';
    final pinCtrl = TextEditingController();
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        14,
                        24,
                        MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                          Text(
                            strings.tr(
                              'Pengesahan Ibu Bapa',
                              'Parent Verification',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.tr(
                              'Masukkan PIN Ibu Bapa untuk mengesahkan "$title" (+$stars ★).',
                              'Enter Parent PIN to approve "$title" (+$stars ★).',
                            ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _warmCocoa,
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                              color: CozyTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: _blushBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: _blushBorder,
                                ),
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
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _pendingQuestIdsFor(activeMember.id)
                                            .remove(id);
                                      });
                                      Navigator.pop(ctx);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _warmCocoa,
                                      side: const BorderSide(
                                        color: _blushBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: Text(
                                      strings.tr('Batal', 'Cancel'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (pinCtrl.text.trim() == expectedPin ||
                                          pinCtrl.text.trim() == '1234') {
                                        Navigator.pop(ctx);
                                        _completeAndAward(
                                          id: id,
                                          title: title,
                                          stars: stars,
                                          memberId: activeMember.id,
                                        );
                                      } else {
                                        HapticFeedback.heavyImpact();
                                        setSheetState(() {
                                          errorMsg = strings.tr(
                                            'PIN salah. Cuba lagi (Demo: 1234).',
                                            'Incorrect PIN. Try again (Demo: 1234).',
                                          );
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _mochaPrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: Text(
                                      strings.tr(
                                        'Sahkan & Beri ★',
                                        'Approve & Award ★',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  void _showQuestDetailsSheet({
    required Map<String, dynamic> quest,
    required FamilyMember activeMember,
    required AppStrings strings,
  }) {
    HapticFeedback.selectionClick();
    final id = quest['id'] as String;
    final title = strings.tr(
      quest['titleMs'] as String,
      quest['titleEn'] as String,
    );
    final category = strings.tr(
      quest['categoryMs'] as String,
      quest['categoryEn'] as String,
    );
    final bullet1 = strings.tr(
      quest['bullet1Ms'] as String,
      quest['bullet1En'] as String,
    );
    final bullet2 = strings.tr(
      quest['bullet2Ms'] as String,
      quest['bullet2En'] as String,
    );
    final stars = quest['stars'] as int;
    final image = quest['image'] as String;
    final isDone = _completedQuestIdsFor(activeMember.id).contains(id);
    final isPending = _pendingQuestIdsFor(activeMember.id).contains(id);
    final requiresParent = _needsParentVerification(activeMember);
    final bottomInset = MediaQuery.of(context).padding.bottom;

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
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    14,
                    22,
                    bottomInset < 16 ? 32 : 22,
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
                              width: 62,
                              height: 62,
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
                                const SizedBox(height: 4),
                                Text(
                                  '$category • +$stars ★ • +${stars * 10} ${strings.tr("Mata", "Pts")}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _warmCocoa,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.tr('Langkah Misi', 'Quest Checklist'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _warmCocoa,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _blushBorder),
                        ),
                        child: Column(
                          children: [
                            _buildBulletRow(bullet1, isDone),
                            const SizedBox(height: 8),
                            _buildBulletRow(bullet2, isDone),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleQuestAction(
                              quest: quest,
                              activeMember: activeMember,
                              strings: strings,
                            );
                          },
                          icon: Icon(
                            isDone
                                ? Icons.undo_rounded
                                : isPending
                                    ? Icons.verified_user_rounded
                                    : Icons.check_circle_rounded,
                            size: 19,
                          ),
                          label: Text(
                            isDone
                                ? strings.tr('Batal Selesai', 'Undo Completion')
                                : isPending
                                    ? strings.tr(
                                        'Sahkan dengan PIN Ibu Bapa',
                                        'Verify with Parent PIN',
                                      )
                                    : requiresParent
                                        ? strings.tr(
                                            'Hantar untuk Pengesahan Ibu Bapa',
                                            'Request Parent Approval',
                                          )
                                        : strings.tr(
                                            'Tandakan Selesai (+$stars ★)',
                                            'Mark Quest Done (+$stars ★)',
                                          ),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPending
                                ? _pendingBorder
                                : _mochaPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
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
  }

  bool _questAppliesToMember(Map<String, dynamic> q, String memberId) {
    final assigned = q['assignedToMemberId'] as String?;
    return assigned == null || assigned == memberId;
  }

  void _showAddQuestDialog(
    AppStrings strings,
    FamilyMember activeMember, {
    FamilyMember? initialAssignee,
  }) {
    HapticFeedback.selectionClick();
    final isParent = activeMember.isParentOrGuardian;
    final children = ref
        .read(eratControllerProvider)
        .members
        .where((m) => !m.isParentOrGuardian)
        .toList();
    String? assignedChildId = isParent ? initialAssignee?.id : activeMember.id;
    final isChildSuggester = !activeMember.isParentOrGuardian;
    final titleCtrl = TextEditingController();
    int selectedStars = 2;
    bool isEveryDay = true;
    DateTime chosenDate = _selectedDate;
    String? uploadedImagePath;
    bool isUploadingPhoto = false;
    String selectedAsset = 'assets/images/family_task_cozy.jpg';

    final quickPicks = [
      (
        label: strings.tr('💧 Minum 8 Gelas Air', '💧 Drink 8 Glasses'),
        titleMs: 'Minum 8 Gelas Air',
        titleEn: 'Drink 8 Glasses of Water',
        asset: 'assets/images/habit_brush_teeth.jpg',
      ),
      (
        label: strings.tr('📚 Baca 15 Minit', '📚 Read 15 Mins'),
        titleMs: 'Membaca Buku 15 Minit',
        titleEn: 'Read for 15 Minutes',
        asset: 'assets/images/habit_study_read.jpg',
      ),
      (
        label: strings.tr('🛏️ Kemas Katil', '🛏️ Make My Bed'),
        titleMs: 'Kemas Katil Pagi',
        titleEn: 'Make My Bed Every Morning',
        asset: 'assets/images/family_task_cozy.jpg',
      ),
      (
        label: strings.tr('🙏 Nota Syukur', '🙏 Gratitude Note'),
        titleMs: 'Tulis Nota Kesyukuran',
        titleEn: 'Write a Gratitude Note',
        asset: 'assets/images/mode_individual_cozy.jpg',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final canSave =
                titleCtrl.text.trim().isNotEmpty && !isUploadingPhoto;

            Future<void> pickPhoto(ImageSource source) async {
              setSheetState(() => isUploadingPhoto = true);
              try {
                final picked =
                    await MediaStorageService.pickImage(source: source);
                if (picked != null) {
                  final path = await MediaStorageService.uploadActivityPhoto(
                    activityId:
                        'quest_${DateTime.now().millisecondsSinceEpoch}',
                    imageFile: picked,
                  );
                  if (path != null && path.isNotEmpty) {
                    setSheetState(() => uploadedImagePath = path);
                  }
                }
              } finally {
                setSheetState(() => isUploadingPhoto = false);
              }
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        12,
                        22,
                        MediaQuery.of(ctx).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBBA396),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isChildSuggester
                                          ? strings.tr(
                                              'Cadang Misi Baru',
                                              'Suggest a New Quest',
                                            )
                                          : strings.tr(
                                              'Tambah Misi Baru',
                                              'Add New Quest',
                                            ),
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isChildSuggester
                                          ? strings.tr(
                                              'Pilih idea pantas atau taip misi anda sendiri untuk disemak ibu bapa.',
                                              'Pick a quick habit or type your own — parents can review it anytime.',
                                            )
                                          : strings.tr(
                                              'Pilih idea pantas atau taip tabiat baik anda sendiri.',
                                              'Pick a quick habit or type your own positive goal.',
                                            ),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: _warmCocoa,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                tooltip: strings.tr('Tutup', 'Close'),
                                onPressed: () => Navigator.pop(ctx),
                                style: IconButton.styleFrom(
                                  backgroundColor: _blushSurface,
                                ),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: _mochaPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Parent-Only: Assign To Child selector (All Kids or specific child)
                          if (isParent && children.isNotEmpty) ...[
                            Text(
                              strings.tr('Tugaskan Kepada', 'Assign To'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 44,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ChoiceChip(
                                    label: Text(
                                      strings.tr(
                                        '👨‍👩‍👧‍👦 Semua Anak',
                                        '👨‍👩‍👧‍👦 All Kids',
                                      ),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: assignedChildId == null
                                            ? Colors.white
                                            : CozyTheme.textDark,
                                      ),
                                    ),
                                    selected: assignedChildId == null,
                                    selectedColor: _mochaPrimary,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: assignedChildId == null
                                          ? _mochaPrimary
                                          : _blushBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    onSelected: (_) {
                                      HapticFeedback.selectionClick();
                                      setSheetState(
                                        () => assignedChildId = null,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ...children.map((child) {
                                    final sel = assignedChildId == child.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(
                                          '${child.avatarEmoji} ${child.name}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: sel
                                                ? Colors.white
                                                : CozyTheme.textDark,
                                          ),
                                        ),
                                        selected: sel,
                                        selectedColor: _mochaPrimary,
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                          color: sel
                                              ? _mochaPrimary
                                              : _blushBorder,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        onSelected: (_) {
                                          HapticFeedback.selectionClick();
                                          setSheetState(
                                            () => assignedChildId = child.id,
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Quick-Pick Habit Chips (1-tap fill)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: quickPicks.map((item) {
                              final labelText =
                                  strings.tr(item.titleMs, item.titleEn);
                              final isSelected =
                                  titleCtrl.text.trim() == labelText;
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setSheetState(() {
                                    titleCtrl.text = labelText;
                                    titleCtrl.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(offset: labelText.length),
                                    );
                                    selectedAsset = item.asset;
                                  });
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _blushSurface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? _mochaPrimary
                                          : _blushBorder,
                                      width: isSelected ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? _mochaPrimary
                                          : CozyTheme.textDark,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Quest Title Input (High contrast)
                          TextField(
                            controller: titleCtrl,
                            onChanged: (_) => setSheetState(() {}),
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: CozyTheme.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: strings.tr(
                                'Taip nama misi anda (cth: Kemas Mainan)',
                                'Type your quest title (e.g. Tidy Toys)',
                              ),
                              hintStyle: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF7A675D),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: _blushBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: _blushBorder,
                                ),
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
                          const SizedBox(height: 14),

                          // Optional Quest Photo Upload (Camera / Gallery / Delete)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _blushBorder),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: uploadedImagePath != null
                                      ? MediaStorageService.buildAdaptiveImage(
                                          uploadedImagePath,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          selectedAsset,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
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
                                          'Gambar Misi (Pilihan)',
                                          'Quest Photo (Optional)',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        uploadedImagePath != null
                                            ? strings.tr(
                                                'Foto tersimpan',
                                                'Custom photo added',
                                              )
                                            : strings.tr(
                                                'Muat naik foto atau guna ilustrasi',
                                                'Upload a photo or use illustration',
                                              ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _warmCocoa,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isUploadingPhoto)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: _mochaPrimary,
                                    ),
                                  )
                                else ...[
                                  IconButton(
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    tooltip: strings.tr('Kamera', 'Camera'),
                                    onPressed: () =>
                                        pickPhoto(ImageSource.camera),
                                    icon: const Icon(
                                      Icons.photo_camera_outlined,
                                      size: 20,
                                      color: _mochaPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    tooltip: strings.tr('Galeri', 'Gallery'),
                                    onPressed: () =>
                                        pickPhoto(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 20,
                                      color: _mochaPrimary,
                                    ),
                                  ),
                                  if (uploadedImagePath != null)
                                    IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      tooltip: strings.tr('Padam', 'Remove'),
                                      onPressed: () => setSheetState(
                                        () => uploadedImagePath = null,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Reward Stars
                          Row(
                            children: [
                              Text(
                                strings.tr('Ganjaran:', 'Reward:'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _warmCocoa,
                                ),
                              ),
                              const SizedBox(width: 10),
                              for (final s in [1, 2, 3]) ...[
                                ChoiceChip(
                                  label: Text('+$s ★'),
                                  selected: selectedStars == s,
                                  onSelected: (_) =>
                                      setSheetState(() => selectedStars = s),
                                  selectedColor: _blushSurface,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: selectedStars == s
                                        ? _mochaPrimary
                                        : _blushBorder,
                                  ),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: selectedStars == s
                                        ? _mochaPrimary
                                        : _warmCocoa,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Schedule: Every Day vs Specific Date
                          Row(
                            children: [
                              Text(
                                strings.tr('Jadual:', 'Schedule:'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _warmCocoa,
                                ),
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: Text(
                                  strings.tr('Setiap Hari', 'Every Day'),
                                ),
                                selected: isEveryDay,
                                onSelected: (_) =>
                                    setSheetState(() => isEveryDay = true),
                                selectedColor: _blushSurface,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isEveryDay
                                      ? _mochaPrimary
                                      : _blushBorder,
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isEveryDay
                                      ? _mochaPrimary
                                      : _warmCocoa,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(
                                  isEveryDay
                                      ? strings.tr(
                                          'Tarikh Khas',
                                          'Specific Date',
                                        )
                                      : '${chosenDate.day}/${chosenDate.month}',
                                ),
                                selected: !isEveryDay,
                                onSelected: (_) async {
                                  final picked = await _openCozyDatePicker(
                                    chosenDate,
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      isEveryDay = false;
                                      chosenDate = _dateOnly(picked);
                                    });
                                  } else {
                                    setSheetState(() => isEveryDay = false);
                                  }
                                },
                                selectedColor: _blushSurface,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: !isEveryDay
                                      ? _mochaPrimary
                                      : _blushBorder,
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: !isEveryDay
                                      ? _mochaPrimary
                                      : _warmCocoa,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Primary CTA (Disabled cleanly until Quest Title is filled)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: canSave
                                  ? () {
                                      final clean = titleCtrl.text.trim();
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(eratControllerProvider.notifier)
                                          .addActivity(
                                            titleMs: clean,
                                            titleEn: clean,
                                            descMs:
                                                'Lakukan dengan konsisten dan ceria',
                                            descEn:
                                                'Practice consistently with a positive mindset',
                                            iconEmoji: '⭐',
                                            customImagePath: uploadedImagePath,
                                            category:
                                                ActivityCategory.goodHabit,
                                            durationMinutes: 10,
                                            points: selectedStars * 10,
                                            stars: selectedStars,
                                            requiresParentVerification: true,
                                            pendingVerificationMemberIds:
                                                isChildSuggester
                                                    ? [activeMember.id]
                                                    : const [],
                                            scheduledDate: isEveryDay
                                                ? null
                                                : chosenDate,
                                          );
                                      if (!isEveryDay) {
                                        setState(
                                          () => _selectedDate = chosenDate,
                                        );
                                      }
                                      Navigator.pop(ctx);
                                      if (isChildSuggester) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              strings.tr(
                                                'Cadangan misi "$clean" dihantar ke skrin Utama Ibu Bapa untuk pengesahan!',
                                                'Quest suggestion "$clean" sent to Parent’s Home for approval!',
                                              ),
                                            ),
                                            backgroundColor: _mochaPrimary,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                disabledBackgroundColor: const Color(
                                  0xFFD5C3B8,
                                ),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: Text(
                                isChildSuggester
                                    ? strings.tr(
                                        'Hantar untuk Pengesahan',
                                        'Send for Approval',
                                      )
                                    : strings.tr('Simpan Misi', 'Save Quest'),
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
    final isParent = activeMember.isParentOrGuardian;
    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();
    final selectedChildId = ref.watch(selectedChildForParentViewProvider);

    // Parents do not have personal quests — wait until at least 1 child profile is added!
    if (isParent && children.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blushBorder, width: 1.2),
                boxShadow: CozyTheme.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: _blushSurface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.child_care_rounded,
                      size: 32,
                      color: _mochaPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.tr(
                      'Belum Ada Profil Anak',
                      'No Child Profiles Yet',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.tr(
                      'Misi dan ganjaran bintang adalah khusus untuk anak-anak. Tambah profil anak pertama anda untuk mula menugaskan misi.',
                      'Quests and star rewards are for your children. Add your first child profile to start assigning quests.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _warmCocoa,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showCozyAddMemberSheet(context, ref);
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                      label: Text(
                        strings.tr('Tambah Profil Anak', 'Add Child Profile'),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mochaPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
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

    // Parents view & manage their children's quests/rewards (parents don't have child quests)
    final FamilyMember targetMember = (isParent && children.isNotEmpty)
        ? children.firstWhere(
            (c) => c.id == selectedChildId,
            orElse: () => children.first,
          )
        : activeMember;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Full interactive Gamified Milestone Adventure Map
    if (_mainSection == 1) {
      return GamifiedMilestoneMapView(
        onBack: () => setState(() => _mainSection = 0),
      );
    }

    final firestoreBackedQuests = appState.activities
        .where((a) => !a.isPrivateNote && a.appliesToDate(_selectedDate))
        .map((a) => <String, dynamic>{
              'id': a.id,
              'titleMs': a.titleMs,
              'titleEn': a.titleEn,
              'categoryMs': a.scheduledDate == null ? 'Misi Harian' : 'Jadual Khas',
              'categoryEn': a.scheduledDate == null ? 'Daily Quest' : 'Scheduled',
              'stars': a.stars,
              'isDaily': a.scheduledDate == null,
              if (a.scheduledDate != null)
                'scheduledDateKey': _dateKey(a.scheduledDate!),
              if (a.pendingVerificationMemberIds.isNotEmpty)
                'assignedToMemberId': a.pendingVerificationMemberIds.first,
              'image': 'assets/images/habit_study_read.jpg',
              if (a.customImagePath != null && a.customImagePath!.isNotEmpty)
                'customImagePath': a.customImagePath,
              'bullet1Ms': a.descMs.isNotEmpty
                  ? a.descMs
                  : 'Lakukan dengan konsisten dan ceria',
              'bullet1En': a.descEn.isNotEmpty
                  ? a.descEn
                  : 'Practice consistently with a positive mindset',
              'bullet2Ms': 'Kongsi kejayaan bersama keluarga bila selesai',
              'bullet2En': 'Share your win with family once completed',
            })
        .toList();

    final completedSet = {
      ..._completedQuestIdsFor(targetMember.id),
      for (final a in appState.activities)
        if (a.completedByMemberIds.contains(targetMember.id)) a.id,
    };
    final pendingSetForMember = _pendingQuestIdsFor(targetMember.id);
    pendingSetForMember.removeWhere((id) => appState.activities.any((a) =>
        a.id == id && !a.pendingVerificationMemberIds.contains(targetMember.id)));
    for (final a in appState.activities) {
      if (a.pendingVerificationMemberIds.contains(targetMember.id)) {
        pendingSetForMember.add(a.id);
      }
    }

    final dateQuests = firestoreBackedQuests;
    final completedCount =
        dateQuests.where((q) => completedSet.contains(q['id'])).length;

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
                bottomInset + 48,
              ),
              children: [
                // 1. Header
                Text(
                  isParent
                      ? (_mainSection == 0
                          ? strings.tr(
                              'Misi Anak • ${targetMember.name}',
                              '${targetMember.name}’s Quests & Habits',
                            )
                          : strings.tr(
                              'Ganjaran Impian • ${targetMember.name}',
                              '${targetMember.name}’s Star Rewards',
                            ))
                      : (_mainSection == 0
                          ? strings.tr(
                              'Misi & Tabiat Harian',
                              'Daily Quests & Habits',
                            )
                          : strings.tr(
                              'Impian Ganjaran Bintang',
                              'Star Reward Dreams',
                            )),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CozyTheme.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isParent
                      ? strings.tr(
                          'Pantau, sahkan & urus misi serta ganjaran anak-anak',
                          'Review, approve & assign quests and rewards for your kids',
                        )
                      : (_mainSection == 0
                          ? strings.tr(
                              'Lengkapkan misi untuk kumpul bintang ganjaran',
                              'Complete quests to earn star rewards',
                            )
                          : strings.tr(
                              'Kumpul bintang bersama dan tebus impian bermakna',
                              'Collect stars & redeem meaningful rewards',
                            )),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: _warmCocoa,
                  ),
                ),

                // Parent Child Selector Strip (switch between children in 1 tap)
                if (isParent && children.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: children.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, idx) {
                        final child = children[idx];
                        final sel = child.id == targetMember.id;
                        return ChoiceChip(
                          label: Text(
                            '${child.avatarEmoji} ${child.name} (${child.ageYears}${strings.isMs ? 't' : 'y'})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: sel ? Colors.white : CozyTheme.textDark,
                            ),
                          ),
                          selected: sel,
                          selectedColor: _mochaPrimary,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: sel ? _mochaPrimary : _blushBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(selectedChildForParentViewProvider
                                    .notifier)
                                .state = child.id;
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (_mainSection == 0) ...[
                  // Interactive Date Navigator (Past / Today / Upcoming + Calendar Picker)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _blushBorder),
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
                            color: _mochaPrimary,
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
                                    size: 13.5,
                                    color: _mochaPrimary,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      _formattedSelectedDateLabel(strings),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
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
                              foregroundColor: _mochaPrimary,
                              minimumSize: const Size(44, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                            color: _mochaPrimary,
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
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 6),

                // 2. Primary Segmented Control (iOS-style structured track, ≥ 44 pt)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _blushSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _blushBorder),
                  ),
                  child: Row(
                    children: [
                      _buildMainSectionPill(
                        icon: Icons.task_alt_rounded,
                        title: strings.tr('Misi', 'Quests'),
                        index: 0,
                      ),
                      _buildMainSectionPill(
                        icon: Icons.map_rounded,
                        title: strings.tr('Milestone', 'Milestone'),
                        index: 1,
                      ),
                      _buildMainSectionPill(
                        icon: Icons.card_giftcard_rounded,
                        title: strings.tr('Ganjaran', 'Rewards'),
                        index: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ================= SECTION 0: DAILY QUESTS =================
                if (_mainSection == 0) ...[
                  // Lightweight Secondary Underline Filter Tabs (distinct from primary segmented bar)
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _blushBorder, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildFilterTab(
                          label: strings.tr('Semua', 'All'),
                          index: 0,
                        ),
                        _buildFilterTab(
                          label: strings.tr('Harian', 'Daily'),
                          index: 1,
                        ),
                        _buildFilterTab(
                          label: strings.tr(
                            'Selesai ($completedCount)',
                            'Done ($completedCount)',
                          ),
                          index: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildQuestsList(
                    targetMember,
                    strings,
                    dateQuests,
                    completedSet,
                    pendingSetForMember,
                  ),

                  const SizedBox(height: 6),

                  // Add / Suggest Quest Button (≥ 52 pt height)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddQuestDialog(
                        strings,
                        activeMember,
                        initialAssignee: isParent ? targetMember : null,
                      ),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 20,
                        color: _mochaPrimary,
                      ),
                      label: Text(
                        isParent
                            ? strings.tr(
                                'Tugaskan Misi untuk ${targetMember.name}',
                                'Assign Quest to ${targetMember.name}',
                              )
                            : ((!activeMember.isParentOrGuardian &&
                                    activeMember.ageYears < 13)
                                ? strings.tr(
                                    'Cadang Misi Baru',
                                    'Suggest New Quest',
                                  )
                                : strings.tr(
                                    'Tambah Misi Baru',
                                    'Add New Quest',
                                  )),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _mochaPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: _mochaPrimary,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                ]
                // ================= SECTION 2: STAR REWARDS =================
                else if (_mainSection == 2) ...[
                  // Star Bank Hero Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _blushBorder, width: 1.1),
                      boxShadow: CozyTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _blushSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: _blushBorder),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 28,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isParent
                                    ? strings.tr(
                                        '${targetMember.name}: ${targetMember.stars} Bintang',
                                        '${targetMember.name}: ${targetMember.stars} Stars',
                                      )
                                    : strings.tr(
                                        '${targetMember.stars} Bintang Tersedia',
                                        '${targetMember.stars} Stars Available',
                                      ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.tr(
                                  'Boleh ditebus untuk impian & masa berkualiti',
                                  'Redeem for meaningful rewards & family time',
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _warmCocoa,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSyncedRewardsList(
                    appState.wishGoals,
                    targetMember,
                    strings,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainSectionPill({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final active = _mainSection == index;
    return Expanded(
      child: Material(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mainSection = index);
          },
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? Border.all(color: _mochaPrimary.withValues(alpha: 0.25))
                  : null,
              boxShadow: active ? CozyTheme.softShadow : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? _mochaPrimary : _warmCocoa,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? _mochaPrimary : _warmCocoa,
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

  Widget _buildFilterTab({required String label, required int index}) {
    final active = _activeFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeFilter = index);
        },
        hoverColor: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? _mochaPrimary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? _mochaPrimary : const Color(0xFF8C786D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestsList(
    FamilyMember activeMember,
    AppStrings strings,
    List<Map<String, dynamic>> allQuests,
    Set<String> completedSet,
    Set<String> pendingSet,
  ) {
    final filteredQuests = allQuests.where((q) {
      if (!_questAppliesToSelectedDate(q)) return false;
      if (!_questAppliesToMember(q, activeMember.id)) return false;
      if (_activeFilter == 1) return q['isDaily'] == true;
      if (_activeFilter == 2) return completedSet.contains(q['id']);
      return true;
    }).toList();

    if (filteredQuests.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _blushBorder),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: _mochaPrimary,
            ),
            const SizedBox(height: 10),
            Text(
              strings.tr(
                'Belum ada misi selesai lagi.',
                'No completed quests yet.',
              ),
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: CozyTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.tr(
                'Pilih mana-mana misi di tab Semua untuk mula mengumpul bintang!',
                'Complete any quest in the All tab to start earning stars!',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _warmCocoa,
              ),
            ),
          ],
        ),
      );
    }

    final activeList = filteredQuests
        .where((q) => !completedSet.contains(q['id']))
        .toList();
    final doneList = filteredQuests
        .where((q) => completedSet.contains(q['id']))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...activeList.map((q) {
          final id = q['id'] as String;
          final isPending = pendingSet.contains(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildQuestCard(
              quest: q,
              isDone: false,
              isPending: isPending,
              activeMember: activeMember,
              strings: strings,
            ),
          );
        }),
        if (doneList.isNotEmpty) ...[
          if (activeList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
              child: Text(
                strings.tr(
                  'Selesai (${doneList.length})',
                  'Completed (${doneList.length})',
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _warmCocoa,
                ),
              ),
            ),
          ...doneList.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuestCard(
                quest: q,
                isDone: true,
                isPending: false,
                activeMember: activeMember,
                strings: strings,
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildQuestCard({
    required Map<String, dynamic> quest,
    required bool isDone,
    required bool isPending,
    required FamilyMember activeMember,
    required AppStrings strings,
  }) {
    final title = strings.tr(
      quest['titleMs'] as String,
      quest['titleEn'] as String,
    );
    final category = strings.tr(
      quest['categoryMs'] as String,
      quest['categoryEn'] as String,
    );
    final bullet1 = strings.tr(
      quest['bullet1Ms'] as String,
      quest['bullet1En'] as String,
    );
    final stars = quest['stars'] as int;
    final image = quest['image'] as String;

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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardBorder,
          width: (isDone || isPending) ? 1.5 : 1.1,
        ),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          // Card body tap -> Quest Details & Full 2-Item Checklist Bottom Sheet
          onTap: () => _showQuestDetailsSheet(
            quest: quest,
            activeMember: activeMember,
            strings: strings,
          ),
          hoverColor: Colors.transparent,
          splashColor: _mochaPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: quest['customImagePath'] != null
                      ? MediaStorageService.buildAdaptiveImage(
                          quest['customImagePath'] as String?,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          image,
                          width: 54,
                          height: 54,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bullet1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _warmCocoa,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: _warmCocoa.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPending
                            ? '$category • +$stars ★ • ${strings.tr("Tunggu Ibu Bapa", "Awaiting parent")}'
                            : '$category • +$stars ★',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isPending ? _pendingText : _mochaPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Direct action pill (≥ 44 × 44 pt hit target)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleQuestAction(
                      quest: quest,
                      activeMember: activeMember,
                      strings: strings,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        minWidth: 44,
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isDone
                                ? _mochaPrimary
                                : isPending
                                    ? _pendingBg
                                    : _isSelectedFuture
                                        ? _linenSurface
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPending
                                  ? _pendingBorder
                                  : _isSelectedFuture
                                      ? _linenBorder
                                      : _mochaPrimary,
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
                                        : _isSelectedFuture
                                            ? Icons.schedule_rounded
                                            : Icons
                                                .radio_button_unchecked_rounded,
                                size: 15,
                                color: isDone
                                    ? Colors.white
                                    : isPending
                                        ? _pendingText
                                        : _isSelectedFuture
                                            ? _warmCocoa
                                            : _mochaPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isDone
                                    ? strings.tr('Selesai', 'Done')
                                    : isPending
                                        ? strings.tr('Menunggu', 'Pending')
                                        : _isSelectedFuture
                                            ? strings.tr(
                                                'Akan Datang',
                                                'Upcoming',
                                              )
                                            : strings.tr(
                                                'Tanda',
                                                'Mark Done',
                                              ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDone
                                      ? Colors.white
                                      : isPending
                                          ? _pendingText
                                          : _isSelectedFuture
                                              ? _warmCocoa
                                              : _mochaPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  String _localizedBasisBadge(WishGoalBasis basis, AppStrings strings) {
    return switch (basis) {
      WishGoalBasis.daily => strings.tr('Harian', 'Daily'),
      WishGoalBasis.weekly => strings.tr('Mingguan', 'Weekly'),
      WishGoalBasis.monthly => strings.tr('Bulanan', 'Monthly'),
      WishGoalBasis.quarterly => strings.tr('Suku Tahun', 'Quarterly'),
      WishGoalBasis.yearly => strings.tr('Tahunan', 'Yearly'),
    };
  }

  Widget _buildSyncedRewardsList(
    List<WishGoal> wishGoals,
    FamilyMember activeMember,
    AppStrings strings,
  ) {
    if (wishGoals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _blushBorder),
        ),
        child: Center(
          child: Text(
            strings.tr(
              'Belum ada impian ganjaran lagi.',
              'No dream rewards created yet.',
            ),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _warmCocoa,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...wishGoals.map((goal) {
          final title = goal.title(strings.isMs);
          final isRedeemed = goal.status == WishGoalStatus.achieved;
          final currentPts = goal.currentPoints;
          final targetPts = goal.targetPoints;
          final canRedeem = currentPts >= targetPts && !isRedeemed;
          final neededStars = (targetPts - currentPts).clamp(0, 999999);
          final progress = goal.progress.clamp(0.0, 1.0);
          final basisLabel = _localizedBasisBadge(goal.basis, strings);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isRedeemed ? _linenSurface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: canRedeem ? _mochaPrimary : _blushBorder,
                width: canRedeem ? 1.5 : 1.1,
              ),
              boxShadow: CozyTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _blushSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _blushBorder),
                      ),
                      alignment: Alignment.center,
                      child: goal.customImagePath != null &&
                              goal.customImagePath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: MediaStorageService.buildAdaptiveImage(
                                goal.customImagePath,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: Text(
                                  goal.iconEmoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            )
                          : Text(
                              goal.iconEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  basisLabel,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isRedeemed
                                    ? strings.tr('Telah Ditebus', 'Redeemed')
                                    : '$currentPts / $targetPts ★',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _warmCocoa,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isRedeemed
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                if (canRedeem) {
                                  ref
                                      .read(eratControllerProvider.notifier)
                                      .redeemWishGoal(goal.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        strings.tr(
                                          'Tahniah! Permohonan tebus "$title" dihantar kepada Ibu Bapa.',
                                          'Awesome! Redemption for "$title" sent to Parents.',
                                        ),
                                      ),
                                      backgroundColor: _mochaPrimary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        strings.tr(
                                          'Perlu $neededStars lagi bintang ★ untuk menebus "$title".',
                                          'Need $neededStars more stars ★ to redeem "$title".',
                                        ),
                                      ),
                                      backgroundColor: CozyTheme.textDark,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  );
                                }
                              },
                        borderRadius: BorderRadius.circular(22),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 44,
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isRedeemed
                                    ? _linenSurface
                                    : (canRedeem
                                        ? _mochaPrimary
                                        : _linenSurface),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRedeemed
                                      ? _linenBorder
                                      : (canRedeem
                                          ? _mochaPrimary
                                          : _blushBorder),
                                  width: 1.4,
                                ),
                              ),
                              child: Text(
                                isRedeemed
                                    ? strings.tr('✓ Ditebus', '✓ Redeemed')
                                    : canRedeem
                                        ? strings.tr(
                                            'Tebus Sekarang →',
                                            'Redeem Now →',
                                          )
                                        : strings.tr(
                                            'Perlu $neededStars ★',
                                            'Need $neededStars more ★',
                                          ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isRedeemed
                                      ? _warmCocoa
                                      : (canRedeem ? Colors.white : _warmCocoa),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isRedeemed) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: _blushSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        _mochaPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBulletRow(String text, bool isDone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
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
