import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/services/voice_audio_service.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../family/presentation/cozy_add_member_sheet.dart';
import '../../family/presentation/cozy_family_calendar_card.dart';

/// Parent Home Dashboard (Command Center):
/// - Unified Pending Approvals Inbox (Routines + Quests + Suggested Rewards)
/// - Shared Child Journals (ONLY entries where child opted-in `isSharedWithParents`)
/// - Children Overview with quick "+ Praise ★" bonus stars & "View Quests"
/// - Tonight's 10-Min Family Bonding Idea
class CozyParentHomeView extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigateTab;

  const CozyParentHomeView({
    super.key,
    required this.onNavigateTab,
  });

  @override
  ConsumerState<CozyParentHomeView> createState() => _CozyParentHomeViewState();
}

class _CozyParentHomeViewState extends ConsumerState<CozyParentHomeView> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _pendingBg = Color(0xFFFDF4E3);
  static const Color _pendingBorder = Color(0xFFD8B17E);
  static const Color _pendingText = Color(0xFF8C5319);
  static const Color _dragHandle = Color(0xFFBBA396);

  final VoiceAudioService _voiceService = VoiceAudioService();
  String? _playingJournalId;

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _toggleSharedJournalAudio(JournalEntry entry) async {
    HapticFeedback.lightImpact();
    if (_playingJournalId == entry.id) {
      await _voiceService.stopPlayback();
      if (mounted) setState(() => _playingJournalId = null);
      return;
    }
    setState(() => _playingJournalId = entry.id);
    final played = await _voiceService.play(
      entry.audioUrl,
      onComplete: () {
        if (mounted) setState(() => _playingJournalId = null);
      },
    );
    if (!played && mounted) {
      // Seeded demo voice entry without audio file: reset gracefully after brief visual cue
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _playingJournalId == entry.id) {
          setState(() => _playingJournalId = null);
        }
      });
    }
  }

  void _showSharedJournalReader(
    BuildContext context,
    JournalEntry entry,
    bool isMs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                bottomInset > 34 ? bottomInset + 8 : 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: _dragHandle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        entry.moodEmoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            Text(
                              isMs
                                  ? 'Dikongsi oleh ${entry.memberName}'
                                  : 'Shared by ${entry.memberName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _mochaPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: CozyTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    entry.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _warmCocoa,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(eratControllerProvider.notifier)
                            .awardBonusStarsToChild(
                              memberId: entry.memberId,
                              stars: 1,
                              reasonMs: 'Terima kasih kongsi diari hati',
                              reasonEn: 'Thank you for sharing your journal',
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isMs
                                  ? '+1 ★ ucapan terima kasih dihantar kepada ${entry.memberName} ♡'
                                  : '+1 ★ warm thank-you star sent to ${entry.memberName} ♡',
                            ),
                            backgroundColor: _mochaPrimary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite_rounded, size: 18),
                      label: Text(
                        isMs
                            ? 'Hantar Pujian Hangat (+1 ★)'
                            : 'Send Warm Praise (+1 ★)',
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
                          borderRadius: BorderRadius.circular(24),
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

  void _showPraiseChildSheet(
    BuildContext context,
    WidgetRef ref,
    FamilyMember child,
    AppStrings strings,
  ) {
    final isMs = strings.isMs;
    final presets = [
      {
        'stars': 2,
        'en': 'Kind & Respectful Adab',
        'ms': 'Adab Lembut & Hormat',
        'emoji': '💛',
      },
      {
        'stars': 2,
        'en': 'Helped a Sibling',
        'ms': 'Membantu Adik-Beradik',
        'emoji': '🤝',
      },
      {
        'stars': 3,
        'en': 'Great Effort Studying',
        'ms': 'Usaha Gigih Belajar',
        'emoji': '📚',
      },
      {
        'stars': 2,
        'en': 'Helped Parents at Home',
        'ms': 'Menolong Ibu Ayah di Rumah',
        'emoji': '🏡',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                bottomInset > 34 ? bottomInset + 8 : 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: _dragHandle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isMs
                              ? 'Hadiah Bintang Pujian untuk ${child.name}'
                              : 'Send Praise Stars to ${child.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: CozyTheme.textDark,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: CozyTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMs
                        ? 'Raikan kebaikan spontan & akhlak terpuji hari ini.'
                        : 'Celebrate spontaneous kindness and good manners today.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: _warmCocoa,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...presets.map((p) {
                    final stars = p['stars'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(eratControllerProvider.notifier)
                                .awardBonusStarsToChild(
                                  memberId: child.id,
                                  stars: stars,
                                  reasonMs: p['ms'] as String,
                                  reasonEn: p['en'] as String,
                                );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMs
                                      ? '+$stars ★ dihantar kepada ${child.name}!'
                                      : '+$stars ★ praise sent to ${child.name}!',
                                ),
                                backgroundColor: _mochaPrimary,
                              ),
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _blushBorder),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  p['emoji'] as String,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isMs
                                        ? p['ms'] as String
                                        : p['en'] as String,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _blushSurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+$stars ★',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _mochaPrimary,
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
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final isMs = strings.isMs;
    final parent = appState.activeMember;
    final parentName = _localizedMemberName(parent.name, strings);
    final notifier = ref.read(eratControllerProvider.notifier);
    final sharedJournals = appState.journalEntries
        .where((e) => e.isSharedWithParents)
        .toList();

    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();
    final totalChildrenStars =
        children.fold<int>(0, (sum, m) => sum + m.stars);

    // 1. Pending Routine Approvals
    final pendingRoutines = appState.routineRequests
        .where((r) => r.status == RoutineStatus.pendingApproval)
        .toList();

    // 2. Pending Quest / Activity Verifications (pair of activity + child)
    final pendingActivities = <({BondingActivity activity, FamilyMember child})>[];
    for (final act in appState.activities) {
      for (final cid in act.pendingVerificationMemberIds) {
        final match = children.where((c) => c.id == cid);
        if (match.isNotEmpty) {
          pendingActivities.add((activity: act, child: match.first));
        }
      }
    }

    // 3. Pending Suggested Dream Rewards
    final pendingRewards = appState.wishGoals
        .where((g) => g.status == WishGoalStatus.pendingApproval)
        .toList();

    final totalPendingCount = pendingRoutines.length +
        pendingActivities.length +
        pendingRewards.length;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 36),
          children: [
            // 1. Parent Greeting Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blushBorder, width: 1.2),
                boxShadow: CozyTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _blushSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _blushBorder, width: 1.8),
                    ),
                    child: (parent.customPhotoPath != null &&
                            parent.customPhotoPath!.trim().isNotEmpty)
                        ? ClipOval(
                            child: MediaStorageService.buildAdaptiveImage(
                              parent.customPhotoPath,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              placeholder: Text(
                                parent.avatarEmoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          )
                        : Text(
                            parent.avatarEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMs
                              ? 'Selamat Kembali, $parentName ♡'
                              : 'Welcome Back, $parentName ♡',
                          style: const TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            color: CozyTheme.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalPendingCount > 0
                              ? (isMs
                                  ? '$totalPendingCount tugasan anak menunggu semakan anda'
                                  : '$totalPendingCount child submissions waiting for your approval')
                              : (isMs
                                  ? 'Semua tugasan anak sudah disemak hari ini ✨'
                                  : 'All caught up with your children’s tasks today ✨'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
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

            // 1B. Shared Family Event Calendar (Visible to all family members)
            const CozyFamilyCalendarCard(),
            const SizedBox(height: 14),

            // 2. Parent KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: totalPendingCount > 0 ? _pendingBg : _blushSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: totalPendingCount > 0
                            ? _pendingBorder
                            : _blushBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.task_alt_rounded,
                            size: 20,
                            color: totalPendingCount > 0
                                ? _pendingText
                                : _mochaPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMs
                                    ? '$totalPendingCount Menunggu'
                                    : '$totalPendingCount Pending',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              Text(
                                isMs ? 'Kelulusan anak' : 'To approve',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _warmCocoa,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _linenSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _linenBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 22,
                            color: Color(0xFFD9822B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$totalChildrenStars ★',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              Text(
                                isMs
                                    ? '${children.length} anak aktif'
                                    : '${children.length} kids active',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _warmCocoa,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Unified Pending Approvals Inbox (Primary Parent Responsibility)
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMs
                        ? 'Semakan & Kelulusan Anak'
                        : 'Pending Child Approvals',
                    style: const TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.textDark,
                    ),
                  ),
                ),
                if (totalPendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pendingBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _pendingBorder),
                    ),
                    child: Text(
                      '$totalPendingCount',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: _pendingText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (totalPendingCount == 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _blushBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: _blushSurface,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('✨', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMs
                                ? 'Semua Sudah Disemak!'
                                : 'All Caught Up!',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isMs
                                ? 'Apabila anak menghantar rutin, misi atau cadangan ganjaran, ia akan muncul di sini.'
                                : 'When your children submit routines, quests, or dream rewards, they will appear right here.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _warmCocoa,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // 3A. Pending Routines
              ...pendingRoutines.map(
                (req) => _buildApprovalCard(
                  avatar: req.memberAvatar,
                  childName: req.memberName,
                  typeBadge: isMs ? 'Rutin Harian' : 'Daily Routine',
                  title: isMs ? req.routineTitleMs : req.routineTitleEn,
                  subtitle: '${req.timeLabel} • +${req.stars} ★',
                  approveLabel:
                      isMs ? 'Lulus (+${req.stars} ★)' : 'Approve (+${req.stars} ★)',
                  declineLabel: isMs ? 'Cuba Lagi' : 'Ask to Redo',
                  onApprove: () {
                    HapticFeedback.mediumImpact();
                    notifier.approveRoutineRequest(
                      requestId: req.id,
                      approverName: parentName,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMs
                              ? '${req.memberName} menerima +${req.stars} ★!'
                              : '${req.memberName} earned +${req.stars} ★!',
                        ),
                        backgroundColor: _mochaPrimary,
                      ),
                    );
                  },
                  onDecline: () {
                    HapticFeedback.lightImpact();
                    notifier.declineRoutineRequest(req.id);
                  },
                ),
              ),

              // 3B. Pending Quests / Activities
              ...pendingActivities.map(
                (pair) => _buildApprovalCard(
                  avatar: pair.child.avatarEmoji,
                  childName: pair.child.name,
                  typeBadge: isMs ? 'Misi Dihantar' : 'Submitted Quest',
                  title: pair.activity.title(isMs),
                  subtitle: '+${pair.activity.stars} ★ • ${pair.activity.durationMinutes} min',
                  approveLabel: isMs
                      ? 'Lulus (+${pair.activity.stars} ★)'
                      : 'Approve (+${pair.activity.stars} ★)',
                  declineLabel: isMs ? 'Cuba Lagi' : 'Ask to Redo',
                  onApprove: () {
                    HapticFeedback.mediumImpact();
                    notifier.approvePendingActivity(
                      pair.activity.id,
                      pair.child.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMs
                              ? '${pair.child.name} menerima +${pair.activity.stars} ★!'
                              : '${pair.child.name} earned +${pair.activity.stars} ★!',
                        ),
                        backgroundColor: _mochaPrimary,
                      ),
                    );
                  },
                  onDecline: () {
                    HapticFeedback.lightImpact();
                    notifier.declinePendingActivity(
                      pair.activity.id,
                      pair.child.id,
                    );
                  },
                ),
              ),

              // 3C. Pending Suggested Dream Rewards
              ...pendingRewards.map(
                (goal) => _buildApprovalCard(
                  avatar: goal.iconEmoji,
                  childName: goal.memberName,
                  typeBadge: isMs ? 'Cadangan Ganjaran' : 'Dream Reward Idea',
                  title: goal.title(isMs),
                  subtitle: isMs
                      ? 'Sasaran: ${goal.targetPoints} ★'
                      : 'Target: ${goal.targetPoints} ★',
                  approveLabel: isMs ? 'Lulus Ganjaran' : 'Approve Reward',
                  declineLabel: isMs ? 'Tolak' : 'Decline',
                  onApprove: () {
                    HapticFeedback.mediumImpact();
                    notifier.approveWishGoal(goal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMs
                              ? 'Ganjaran "${goal.title(true)}" diluluskan!'
                              : 'Reward "${goal.title(false)}" approved!',
                        ),
                        backgroundColor: _mochaPrimary,
                      ),
                    );
                  },
                  onDecline: () {
                    HapticFeedback.lightImpact();
                    notifier.declineWishGoal(goal.id);
                  },
                ),
              ),
            ],
            const SizedBox(height: 22),

            // 3D. Shared Child Journals (ONLY entries where child turned ON "Share with Parents")
            if (sharedJournals.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isMs ? 'Diari Dikongsi Anak' : 'Shared Child Journals',
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _blushSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sharedJournals.length}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: _mochaPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isMs
                    ? 'Hanya catatan yang dipilih anak untuk dikongsi dengan ibu bapa.'
                    : 'Only reflections your children explicitly chose to share with you.',
                style: const TextStyle(fontSize: 13, color: _warmCocoa),
              ),
              const SizedBox(height: 10),
              ...sharedJournals.take(5).map((entry) {
                final isPlaying = _playingJournalId == entry.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isPlaying ? _blushSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPlaying ? _mochaPrimary : _blushBorder,
                      width: 1.2,
                    ),
                    boxShadow: CozyTheme.cardShadow,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showSharedJournalReader(context, entry, isMs),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _linenSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _linenBorder),
                            ),
                            child: Text(
                              entry.moodEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.memberName} • ${entry.isVoiceEntry ? (isMs ? 'Suara (${entry.voiceDuration ?? '0:15'})' : 'Voice (${entry.voiceDuration ?? '0:15'})') : (isMs ? 'Tulisan' : 'Written')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _mochaPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _warmCocoa,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.isVoiceEntry)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: _mochaPrimary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _toggleSharedJournalAudio(entry),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _mochaPrimary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),
            ],

            // 4. Children Overview Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMs ? 'Perkembangan Anak-Anak' : 'Children Overview',
                    style: const TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.textDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    showCozyAddMemberSheet(context, ref);
                  },
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 18,
                    color: _mochaPrimary,
                  ),
                  label: Text(
                    isMs ? 'Tambah Anak' : 'Add Child',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _mochaPrimary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isMs
                  ? 'Ketik untuk lihat misi anak atau beri bintang pujian spontan.'
                  : 'Inspect each child’s quests or send spontaneous praise stars.',
              style: const TextStyle(
                fontSize: 13,
                color: _warmCocoa,
              ),
            ),
            const SizedBox(height: 12),

            if (children.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _blushBorder, width: 1.2),
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
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 26,
                        color: _mochaPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isMs
                          ? 'Tambah Anak Pertama Anda'
                          : 'Add Your First Child',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMs
                          ? 'Setelah profil anak ditambah, tugasan, permintaan kelulusan, dan kemajuan bintang mereka akan muncul di sini.'
                          : 'Once you add a child profile, their quests, approval requests, and star progress will appear here.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _warmCocoa,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showCozyAddMemberSheet(context, ref);
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isMs ? 'Tambah Profil Anak' : 'Add Child Profile',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mochaPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ...children.map((child) {
              final childTodayQuests = appState.activities
                  .where((a) =>
                      !a.isPrivateNote &&
                      a.appliesToDate(DateTime.now()) &&
                      (a.pendingVerificationMemberIds.contains(child.id) ||
                          a.completedByMemberIds.contains(child.id) ||
                          a.participationMode == ParticipationMode.everyone ||
                          a.participationMode == ParticipationMode.anyone))
                  .toList();
              final doneRoutines = childTodayQuests
                  .where((a) => a.completedByMemberIds.contains(child.id))
                  .length;
              final pendingChildRoutines = childTodayQuests
                  .where((a) => a.pendingVerificationMemberIds.contains(child.id))
                  .length;
              final routineStatusText = childTodayQuests.isEmpty
                  ? (isMs
                      ? '${child.stars} ★ • Belum ada rutin ditugaskan'
                      : '${child.stars} ★ • No routines assigned yet')
                  : (isMs
                      ? '${child.stars} ★ • $doneRoutines/${childTodayQuests.length} rutin hari ini'
                      : '${child.stars} ★ • $doneRoutines/${childTodayQuests.length} routines today');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _blushBorder, width: 1.2),
                  boxShadow: CozyTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _blushSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: _blushBorder),
                          ),
                          child: (child.customPhotoPath != null &&
                                  child.customPhotoPath!.trim().isNotEmpty)
                              ? ClipOval(
                                  child: MediaStorageService.buildAdaptiveImage(
                                    child.customPhotoPath,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    placeholder: Text(
                                      child.avatarEmoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                )
                              : Text(
                                  child.avatarEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${child.name} • ${child.ageYears}${isMs ? ' thn' : 'y'}',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                routineStatusText,
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showPraiseChildSheet(
                                  context,
                                  ref,
                                  child,
                                  strings,
                                );
                              },
                              icon: const Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: Color(0xFFD9822B),
                              ),
                              label: Text(
                                isMs ? 'Pujian ★' : 'Praise ★',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _linenSurface,
                                side: const BorderSide(color: _linenBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(selectedChildForParentViewProvider
                                        .notifier)
                                    .state = child.id;
                                widget.onNavigateTab(1);
                              },
                              icon: const Icon(
                                Icons.checklist_rounded,
                                size: 17,
                              ),
                              label: Text(
                                isMs ? 'Lihat Misi' : 'View Quests',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),

            // 5. Tonight's 10-Min Family Bonding Idea
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _blushSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _blushBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('💛', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMs
                              ? 'Idea 10-Minit Bonding Malam Ini'
                              : 'Tonight’s 10-Min Family Bonding Idea',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isMs
                              ? 'Duduk tanpa skrin dan tanya setiap anak: "Apakah satu perkara baik yang berlaku hari ini?"'
                              : 'Sit screen-free and ask each child: "What is one kind thing that happened today?"',
                          style: const TextStyle(
                            fontSize: 13,
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
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required String avatar,
    required String childName,
    required String typeBadge,
    required String title,
    required String subtitle,
    required String approveLabel,
    required String declineLabel,
    required VoidCallback onApprove,
    required VoidCallback onDecline,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pendingBorder, width: 1.3),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _pendingBg,
                child: Text(avatar, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _pendingBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            typeBadge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _pendingText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _warmCocoa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _blushBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      declineLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      approveLabel,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mochaPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
