import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';

enum AdventureMapTheme {
  island, // Island Castle
  space, // Space Mission
  jungle, // Jungle Quest
  cyber, // Cyber Quest
}

class GamifiedMilestoneMapView extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const GamifiedMilestoneMapView({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<GamifiedMilestoneMapView> createState() =>
      _GamifiedMilestoneMapViewState();
}

class _GamifiedMilestoneMapViewState
    extends ConsumerState<GamifiedMilestoneMapView>
    with TickerProviderStateMixin {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);

  AdventureMapTheme _selectedTheme = AdventureMapTheme.space;
  String _selectedGoalId = 'goal_1';
  String? _customUploadedImage;
  final Map<String, String> _submittedProofByStep = {};

  late AnimationController _shakeCtrl;
  Timer? _shakeTimer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _shakeTimer = Timer.periodic(const Duration(milliseconds: 3600), (timer) {
      if (mounted) {
        _shakeCtrl.forward(from: 0.0);
      }
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
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

  Widget _buildMemberAvatar(
    FamilyMember member, {
    required double size,
    required double emojiSize,
  }) {
    final path = member.customPhotoPath?.trim();
    if (path != null && path.isNotEmpty) {
      return ClipOval(
        child: MediaStorageService.buildAdaptiveImage(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: Text(
            member.avatarEmoji,
            style: TextStyle(fontSize: emojiSize),
          ),
        ),
      );
    }
    return Text(
      member.avatarEmoji,
      style: TextStyle(fontSize: emojiSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final rawMember = appState.activeMember;
    final selectedChildId = ref.watch(selectedChildForParentViewProvider);
    final children =
        appState.members.where((m) => !m.isParentOrGuardian).toList();
    final activeMember = (rawMember.isParentOrGuardian && children.isNotEmpty)
        ? children.firstWhere(
            (m) => m.id == selectedChildId,
            orElse: () => children.first,
          )
        : rawMember;

    final memberGoals =
        appState.wishGoals.where((g) => g.memberId == activeMember.id).toList();
    final poolGoals = memberGoals.isNotEmpty ? memberGoals : appState.wishGoals;
    final activeGoal = poolGoals.firstWhere(
      (g) => g.id == _selectedGoalId,
      orElse: () => poolGoals.isNotEmpty
          ? poolGoals.first
          : WishGoal(
              id: 'empty_goal',
              memberId: activeMember.id,
              memberName: activeMember.name,
              titleMs: 'Ketik untuk Cipta Ganjaran Impian',
              titleEn: 'Tap to Create Dream Reward',
              iconEmoji: '🎁',
              targetPoints: 20,
              currentPoints: 0,
              status: WishGoalStatus.active,
            ),
    );

    final themeConfig = _getThemeConfig(_selectedTheme, strings);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FULL BACKGROUND ILLUSTRATION
          Positioned.fill(
            child: Image.asset(
              themeConfig.bgAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: themeConfig.fallbackGradient,
                  ),
                );
              },
            ),
          ),

          // 2. ATMOSPHERIC SCRIM FOR HIGH CONTRAST OVER BUSY ARTWORK
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeConfig.overlayColor.withValues(alpha: 0.48),
                    themeConfig.overlayColor.withValues(alpha: 0.22),
                    themeConfig.overlayColor.withValues(alpha: 0.62),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. SCROLLABLE ADVENTURE MAP TRAIL CANVAS (Centered for iPad)
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 640 : double.infinity,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        78,
                        16,
                        bottomInset + 40,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),

                          // ACTIVE WISH GOAL & BASIS CAPSULE (Full legible title, no clipping)
                          _buildActiveWishHeaderCapsule(
                            activeGoal,
                            appState,
                            strings,
                          ),
                          const SizedBox(height: 10),

                          if (activeGoal.hasFocusActivity) ...[
                            _buildFocusActivityPracticeBanner(
                              activeGoal: activeGoal,
                              rawMember: rawMember,
                              appState: appState,
                              strings: strings,
                            ),
                            const SizedBox(height: 10),
                          ],

                          // CLEAN 2-ACTION BAR (Quests | Rewards — no duplicate Theme button or crowding rail)
                          _buildQuickActionRow(appState, strings),
                          const SizedBox(height: 18),

                          // TOP SUMMIT GRAND AWARD CARD
                          _buildSummitAwardCard(
                            activeGoal,
                            themeConfig,
                            appState,
                            strings,
                          ),
                          const SizedBox(height: 28),

                          // CIRCULAR CHECKPOINT TRAIL
                          _buildSimplifiedAdventureTrail(
                            activeMember,
                            appState,
                            themeConfig,
                            activeGoal,
                            strings,
                          ),
                          const SizedBox(height: 18),

                          // BOTTOM CELEBRATION PROGRESS CARD
                          _buildBottomCelebrationCard(
                            themeConfig,
                            activeGoal,
                            strings,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. FLOATING TOP STATUS BAR (Back, Avatar, Star Progress, Theme Picker)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildTopStatusBar(
                    activeMember,
                    themeConfig,
                    activeGoal,
                    strings,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. THEME DEFINITIONS (100% EN/BM)
  // ===========================================================================
  ({
    String title,
    String subtitle,
    String bgAsset,
    LinearGradient fallbackGradient,
    Color overlayColor,
    Color nodeBorderDone,
    Color nodeBgDone,
    Color nodeBorderActive,
    Color nodeBgActive,
    Color nodeBorderLocked,
    Color nodeBgLocked,
    Color pathColor,
    String fontEmoji,
  }) _getThemeConfig(AdventureMapTheme theme, AppStrings strings) {
    switch (theme) {
      case AdventureMapTheme.island:
        return (
          title: strings.tr('Pulau Istana 🏰', 'Island Castle 🏰'),
          subtitle: strings.tr(
            'Bukit hijau ceria & istana dongeng',
            'Sunny green hills & fairytale castle',
          ),
          bgAsset: 'assets/images/milestone_bg_island.jpg',
          fallbackGradient: const LinearGradient(
            colors: [Color(0xFFBAE6FD), Color(0xFFDCFCE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          overlayColor: const Color(0xFF0C4A6E),
          nodeBorderDone: const Color(0xFF16A34A),
          nodeBgDone: const Color(0xFF4ADE80),
          nodeBorderActive: const Color(0xFFF59E0B),
          nodeBgActive: const Color(0xFFFBBF24),
          nodeBorderLocked: const Color(0xFF94A3B8),
          nodeBgLocked: const Color(0xFFCBD5E1),
          pathColor: const Color(0xFFFBBF24),
          fontEmoji: '🏰',
        );

      case AdventureMapTheme.space:
        return (
          title: strings.tr('Misi Angkasa 🚀', 'Space Mission 🚀'),
          subtitle: strings.tr(
            'Galaksi bintang & planet angkasa lepas',
            'Starry galaxy & cosmic planets',
          ),
          bgAsset: 'assets/images/milestone_bg_space.jpg',
          fallbackGradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          overlayColor: const Color(0xFF090D16),
          nodeBorderDone: const Color(0xFF10B981),
          nodeBgDone: const Color(0xFF34D399),
          nodeBorderActive: const Color(0xFFFACC15),
          nodeBgActive: const Color(0xFFFDE047),
          nodeBorderLocked: const Color(0xFF64748B),
          nodeBgLocked: const Color(0xFF94A3B8),
          pathColor: const Color(0xFF818CF8),
          fontEmoji: '🚀',
        );

      case AdventureMapTheme.jungle:
        return (
          title: strings.tr('Kembara Rimba 🌿', 'Jungle Quest 🌿'),
          subtitle: strings.tr(
            'Hutan rimba tropika & batu sungai',
            'Lush tropical rainforest & river trail',
          ),
          bgAsset: 'assets/images/milestone_bg_jungle.jpg',
          fallbackGradient: const LinearGradient(
            colors: [Color(0xFF166534), Color(0xFF86EFAC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          overlayColor: const Color(0xFF052E16),
          nodeBorderDone: const Color(0xFF16A34A),
          nodeBgDone: const Color(0xFF4ADE80),
          nodeBorderActive: const Color(0xFFEAB308),
          nodeBgActive: const Color(0xFFFDE047),
          nodeBorderLocked: const Color(0xFF94A3B8),
          nodeBgLocked: const Color(0xFFCBD5E1),
          pathColor: const Color(0xFFCA8A04),
          fontEmoji: '🌿',
        );

      case AdventureMapTheme.cyber:
        return (
          title: strings.tr('Cyber Quest ⚡', 'Cyber Quest ⚡'),
          subtitle: strings.tr(
            'Litar grid neon futuristik sci-fi',
            'Futuristic neon sci-fi grid',
          ),
          bgAsset: 'assets/images/milestone_bg_cyber.jpg',
          fallbackGradient: const LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          overlayColor: const Color(0xFF030712),
          nodeBorderDone: const Color(0xFF06B6D4),
          nodeBgDone: const Color(0xFF22D3EE),
          nodeBorderActive: const Color(0xFFF97316),
          nodeBgActive: const Color(0xFFFB923C),
          nodeBorderLocked: const Color(0xFF475569),
          nodeBgLocked: const Color(0xFF64748B),
          pathColor: const Color(0xFF06B6D4),
          fontEmoji: '⚡',
        );
    }
  }

  // ===========================================================================
  // 2. TOP STATUS BAR (≥ 44 × 44 pt Touch Targets, High Contrast)
  // ===========================================================================
  Widget _buildTopStatusBar(
    FamilyMember member,
    dynamic themeConfig,
    WishGoal activeGoal,
    AppStrings strings,
  ) {
    final displayName = _localizedMemberName(member.name, strings);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (44 × 44 pt)
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: strings.tr('Kembali', 'Back'),
            onPressed: () {
              HapticFeedback.selectionClick();
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 6),

          // Child Avatar & Crisp Level Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blushSurface,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: _buildMemberAvatar(
                  member,
                  size: 34,
                  emojiSize: 20,
                ),
              ),
              Positioned(
                bottom: -5,
                left: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: const Text(
                    'Lv.5',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Name + Progress Stars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeGoal.hasFocusActivity
                          ? '${activeGoal.currentPoints}/${activeGoal.targetPoints}x'
                          : '${activeGoal.currentPoints}/${activeGoal.targetPoints} ★',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFDE047),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: activeGoal.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.24),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF22C55E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Single Theme Picker Button (≥ 44 pt hit target — no duplicate in side rail)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _showThemeSelectionSheet(strings);
              },
              borderRadius: BorderRadius.circular(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF5E4DC).withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeConfig.fontEmoji as String,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          strings.tr('Tema', 'Theme'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
    );
  }

  // ===========================================================================
  // 3. ACTIVE WISH HEADER CAPSULE (Full Readable Title — No Truncation)
  // ===========================================================================
  Widget _buildActiveWishHeaderCapsule(
    WishGoal activeGoal,
    EratAppState appState,
    AppStrings strings,
  ) {
    final goalTitle = activeGoal.title(strings.isMs);
    final basisLabel = _localizedBasisBadge(activeGoal.basis, strings);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _showSelectGoalDialog(appState, strings);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeGoal.customImagePath != null &&
                  activeGoal.customImagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MediaStorageService.buildAdaptiveImage(
                    activeGoal.customImagePath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    placeholder: Text(
                      activeGoal.iconEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                )
              else
                Text(activeGoal.iconEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  goalTitle,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  basisLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusActivityPracticeBanner({
    required WishGoal activeGoal,
    required FamilyMember rawMember,
    required EratAppState appState,
    required AppStrings strings,
  }) {
    final focusTitle = activeGoal.focusActivity ?? '';
    final isDone = activeGoal.currentPoints >= activeGoal.targetPoints;
    final pendingCount = appState.routineRequests
        .where(
          (r) =>
              r.routineId == 'focus_goal_${activeGoal.id}' &&
              r.status == RoutineStatus.pendingApproval,
        )
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFDCFCE7) : _blushSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              isDone ? '🎉' : '🎯',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  focusTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: CozyTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pendingCount > 0
                      ? strings.tr(
                          '${activeGoal.currentPoints}/${activeGoal.targetPoints}x disahkan • $pendingCount menunggu pengesahan',
                          '${activeGoal.currentPoints}/${activeGoal.targetPoints}x verified • $pendingCount pending approval',
                        )
                      : strings.tr(
                          '${activeGoal.currentPoints}/${activeGoal.targetPoints} kali latihan disahkan',
                          '${activeGoal.currentPoints}/${activeGoal.targetPoints} practices verified',
                        ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _warmCocoa,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDone)
            ElevatedButton(
              onPressed: activeGoal.status == WishGoalStatus.achieved
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(eratControllerProvider.notifier)
                          .redeemWishGoal(activeGoal.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.tr(
                              'Tahniah! Ganjaran "${activeGoal.title(true)}" telah ditebus!',
                              'Awesome! "${activeGoal.title(false)}" has been redeemed!',
                            ),
                          ),
                          backgroundColor: _mochaPrimary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                activeGoal.status == WishGoalStatus.achieved
                    ? strings.tr('Ditebus ✓', 'Claimed ✓')
                    : strings.tr('Tebus!', 'Claim!'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final ctrl = ref.read(eratControllerProvider.notifier);
                if (rawMember.isParentOrGuardian) {
                  ctrl.logFocusGoalPracticeByParent(goalId: activeGoal.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.tr(
                          '+1 latihan "$focusTitle" disahkan!',
                          '+1 practice for "$focusTitle" verified!',
                        ),
                      ),
                      backgroundColor: _mochaPrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ctrl.submitFocusGoalPractice(goalId: activeGoal.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        strings.tr(
                          'Latihan "$focusTitle" dihantar untuk pengesahan Ibu Bapa!',
                          'Practice for "$focusTitle" sent to Parents for approval!',
                        ),
                      ),
                      backgroundColor: _mochaPrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _mochaPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                rawMember.isParentOrGuardian
                    ? strings.tr('+1 Sahkan', '+1 Verify')
                    : strings.tr('+ Log Latihan', '+ Log Practice'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Clean 2-Action Bar (Replaces cramped left floating rail & removes duplicate Theme button)
  Widget _buildQuickActionRow(EratAppState appState, AppStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionPill(
          icon: Icons.checklist_rounded,
          label: strings.tr('Misi', 'Quests'),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onBack?.call();
          },
        ),
        const SizedBox(width: 10),
        _buildActionPill(
          icon: Icons.card_giftcard_rounded,
          label: strings.tr('Ganjaran', 'Rewards'),
          onTap: () {
            HapticFeedback.selectionClick();
            _showSelectGoalDialog(appState, strings);
          },
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 108),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: const Color(0xFFFDE047)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. SUMMIT AWARD CARD (Animated Wobble + Real Photo Upload)
  // ===========================================================================
  Widget _buildSummitAwardCard(
    WishGoal activeGoal,
    dynamic themeConfig,
    EratAppState appState,
    AppStrings strings,
  ) {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final val = _shakeCtrl.value;
        final rotation = sin(val * pi * 8) * (1.0 - val) * 0.10;
        final scale = 1.0 + sin(val * pi) * 0.05;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(scale, scale, 1.0)
            ..rotateZ(rotation),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _showUploadPhotoSheet(strings, activeGoal);
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox.expand(
                  child: _buildAwardImage(activeGoal),
                ),
              ),
            ),

            // 3 Golden Stars Crown
            Positioned(
              top: -14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Text(
                  '★★★',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Camera Badge (Cozy Mocha, non-intrusive)
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _mochaPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAwardImage(WishGoal activeGoal) {
    if (_customUploadedImage != null && _customUploadedImage!.isNotEmpty) {
      return MediaStorageService.buildAdaptiveImage(
        _customUploadedImage,
        fit: BoxFit.cover,
        placeholder: Center(
          child: Text(
            activeGoal.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      );
    }

    if (activeGoal.customImagePath != null &&
        activeGoal.customImagePath!.isNotEmpty) {
      return MediaStorageService.buildAdaptiveImage(
        activeGoal.customImagePath,
        fit: BoxFit.cover,
        placeholder: Center(
          child: Text(
            activeGoal.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      );
    }

    return Image.asset(
      'assets/images/family_goal_cozy.jpg',
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Center(
        child: Text(activeGoal.iconEmoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }

  // ===========================================================================
  // 5. CIRCULAR CHECKPOINTS TRAIL (100% EN/BM + High-Contrast Backing Pills)
  // ===========================================================================
  Widget _buildSimplifiedAdventureTrail(
    FamilyMember activeMember,
    EratAppState appState,
    dynamic themeConfig,
    WishGoal activeGoal,
    AppStrings strings,
  ) {
    final checkpoints =
        _getCheckpointsForGoal(activeGoal, appState, activeMember, strings);

    return Column(
      children: checkpoints.map((cp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            children: [
              Align(
                alignment: cp.alignment,
                child: _buildSingleCircularNode(
                  cp: cp,
                  activeMember: activeMember,
                  themeConfig: themeConfig,
                  strings: strings,
                ),
              ),
              if (cp.stepNum > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildDottedPathConnector(themeConfig, cp.status),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<
      ({
        int stepNum,
        String title,
        _NodeStatus status,
        Alignment alignment,
      })> _getCheckpointsForGoal(
    WishGoal activeGoal,
    EratAppState appState,
    FamilyMember activeMember,
    AppStrings strings,
  ) {
    final pct = activeGoal.progress;
    final target = activeGoal.targetPoints <= 0 ? 20 : activeGoal.targetPoints;

    _NodeStatus calcStatus(double requiredPct) {
      if (pct >= requiredPct) return _NodeStatus.completed;
      if (pct >= (requiredPct - 0.2001)) return _NodeStatus.active;
      return _NodeStatus.locked;
    }

    final t1 = (target * 0.2).ceil().clamp(1, target);
    final t2 = (target * 0.4).ceil().clamp(1, target);
    final t3 = (target * 0.6).ceil().clamp(1, target);
    final t4 = (target * 0.8).ceil().clamp(1, target);
    final t5 = target;

    late final List<String> titles;
    if (activeGoal.hasFocusActivity) {
      final focus = activeGoal.focusActivity!.trim();
      titles = [
        '$focus ($t1/${t5}x)',
        '$focus ($t2/${t5}x)',
        '$focus ($t3/${t5}x)',
        '$focus ($t4/${t5}x)',
        '$focus ($t5/${t5}x) • ${strings.tr('Tebus!', 'Claim!')}',
      ];
    } else {
      // Pull child's real assigned quests first; fill remaining slots with honest Star Milestones.
      final realQuests = appState.activities
          .where(
            (a) =>
                !a.isPrivateNote &&
                activeMember.ageYears >= a.minAge &&
                activeMember.ageYears <= a.maxAge,
          )
          .map((a) => a.title(strings.isMs))
          .toList();

      final starFallbacks = [
        '${strings.tr('Langkah Pertama', 'First Spark')} • $t1 ★',
        '${strings.tr('Teruskan Usaha', 'Keep Going')} • $t2 ★',
        '${strings.tr('Separuh Jalan!', 'Halfway There!')} • $t3 ★',
        '${strings.tr('Hampir Puncak', 'Almost Summit')} • $t4 ★',
        '${strings.tr('Sasaran Dicapai!', 'Goal Reached!')} • $t5 ★',
      ];

      titles = List.generate(
        5,
        (i) => i < realQuests.length ? realQuests[i] : starFallbacks[i],
      );
    }

    return [
      (
        stepNum: 5,
        title: titles[4],
        status: calcStatus(1.0),
        alignment: Alignment.center,
      ),
      (
        stepNum: 4,
        title: titles[3],
        status: calcStatus(0.8),
        alignment: Alignment.centerRight,
      ),
      (
        stepNum: 3,
        title: titles[2],
        status: calcStatus(0.6),
        alignment: Alignment.centerLeft,
      ),
      (
        stepNum: 2,
        title: titles[1],
        status: calcStatus(0.4),
        alignment: Alignment.centerRight,
      ),
      (
        stepNum: 1,
        title: titles[0],
        status: calcStatus(0.2),
        alignment: Alignment.center,
      ),
    ];
  }

  Widget _buildSingleCircularNode({
    required dynamic cp,
    required FamilyMember activeMember,
    required dynamic themeConfig,
    required AppStrings strings,
  }) {
    final status = cp.status as _NodeStatus;

    switch (status) {
      case _NodeStatus.completed:
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showCompletedModal(cp, strings);
          },
          borderRadius: BorderRadius.circular(44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      themeConfig.nodeBgDone as Color,
                      themeConfig.nodeBorderDone as Color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: (themeConfig.nodeBorderDone as Color)
                          .withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeConfig.nodeBorderDone as Color,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  cp.title as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        );

      case _NodeStatus.active:
        final proofKey = '${_selectedGoalId}_${cp.stepNum}';
        final hasProofSent = _submittedProofByStep.containsKey(proofKey);
        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showActiveTaskModal(cp, activeMember, strings);
          },
          borderRadius: BorderRadius.circular(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final glow = _pulseCtrl.value * 0.42;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 94 + (glow * 12),
                        height: 94 + (glow * 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFDE047).withValues(alpha: glow),
                        ),
                      ),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF08A), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.65),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: -8,
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 2,
                            ),
                          ),
                          child: _buildMemberAvatar(
                            activeMember,
                            size: 26,
                            emojiSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD97706), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      cp.title as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasProofSent
                          ? strings.tr(
                              '⏳ Bukti dihantar • Tunggu Ibu Bapa',
                              '⏳ Proof sent • Awaiting Parent',
                            )
                          : strings.tr(
                              '★ Ketik untuk hantar bukti foto',
                              '★ Tap to submit photo proof',
                            ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case _NodeStatus.locked:
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            _showLockedModal(cp, strings);
          },
          borderRadius: BorderRadius.circular(38),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      themeConfig.nodeBgLocked as Color,
                      themeConfig.nodeBorderLocked as Color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.38),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  cp.title as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDottedPathConnector(dynamic themeConfig, _NodeStatus status) {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status == _NodeStatus.completed
                ? const Color(0xFF22C55E)
                : (themeConfig.pathColor as Color).withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 3,
              ),
            ],
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // 6. BOTTOM CELEBRATION PROGRESS CARD
  // ===========================================================================
  Widget _buildBottomCelebrationCard(
    dynamic themeConfig,
    WishGoal activeGoal,
    AppStrings strings,
  ) {
    final pctNum = (activeGoal.progress * 100).toInt();
    final remainingStars =
        (activeGoal.targetPoints - activeGoal.currentPoints).clamp(0, 9999);
    final goalTitle = activeGoal.title(strings.isMs);
    final basisLabel = _localizedBasisBadge(activeGoal.basis, strings);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              activeGoal.basis.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$basisLabel • $pctNum% ${strings.tr("Tercapai", "Reached")}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remainingStars > 0
                      ? (activeGoal.hasFocusActivity
                          ? strings.tr(
                              'Berlatih $remainingStars lagi kali "${activeGoal.focusActivity!}" untuk tebus "$goalTitle"!',
                              'Practice "${activeGoal.focusActivity!}" $remainingStars more times to claim "$goalTitle"!',
                            )
                          : strings.tr(
                              'Kumpul $remainingStars lagi bintang untuk tebus "$goalTitle"!',
                              'Collect $remainingStars more stars to redeem "$goalTitle"!',
                            ))
                      : strings.tr(
                          'Tahniah! Sasaran impian "$goalTitle" telah tercapai!',
                          'Awesome! "$goalTitle" is ready to redeem!',
                        ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _warmCocoa,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALS & ACTIONS (100% EN/BM + Cozy Mocha Polish)
  // ===========================================================================
  void _showThemeSelectionSheet(AppStrings strings) {
    final initialTheme = _selectedTheme;
    AdventureMapTheme pendingTheme = _selectedTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      barrierColor: const Color.fromRGBO(20, 14, 10, 0.58),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomPad = MediaQuery.of(ctx).padding.bottom;

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
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        14,
                        20,
                        bottomPad < 16 ? 34 : bottomPad + 20,
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
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.tr(
                                        'Pilih Tema Peta',
                                        'Choose Adventure Theme',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      strings.tr(
                                        'Ketik tema untuk pratonton, kemudian tekan Guna Tema.',
                                        'Tap a theme to preview, then tap Apply Theme.',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _warmCocoa,
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
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTheme = initialTheme);
                                  Navigator.pop(ctx);
                                },
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
                          ...AdventureMapTheme.values.map((th) {
                            final cfg = _getThemeConfig(th, strings);
                            final isCurrent = th == pendingTheme;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: isCurrent ? _blushSurface : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setSheetState(() => pendingTheme = th);
                                    // Live preview on the adventure map behind the scrim
                                    setState(() => _selectedTheme = th);
                                  },
                                  hoverColor: Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(minHeight: 68),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isCurrent
                                            ? _mochaPrimary
                                            : _blushBorder,
                                        width: isCurrent ? 2 : 1.1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.asset(
                                            cfg.bgAsset,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Text(
                                              cfg.fontEmoji,
                                              style:
                                                  const TextStyle(fontSize: 28),
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
                                                cfg.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: isCurrent
                                                      ? _mochaPrimary
                                                      : CozyTheme.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                cfg.subtitle,
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
                                        Icon(
                                          isCurrent
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          size: 24,
                                          color: isCurrent
                                              ? _mochaPrimary
                                              : _blushBorder,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                setState(() => _selectedTheme = pendingTheme);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: Text(
                                strings.tr('Guna Tema', 'Apply Theme'),
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

  void _showUploadPhotoSheet(AppStrings strings, WishGoal activeGoal) {
    final presets = [
      (
        asset: 'assets/images/family_goal_cozy.jpg',
        label: strings.tr('Hari Keluarga', 'Family Outing'),
      ),
      (
        asset: 'assets/images/habit_study_read.jpg',
        label: strings.tr('Buku & Seni', 'Books & Art'),
      ),
      (
        asset: 'assets/images/mode_family_cozy.jpg',
        label: strings.tr('Masa Manis', 'Sweet Treat'),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      barrierColor: const Color.fromRGBO(20, 14, 10, 0.56),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;

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
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    14,
                    22,
                    bottomPad < 16 ? 34 : bottomPad + 20,
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
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.tr(
                                    'Tukar Gambar Hadiah Puncak',
                                    'Change Peak Reward Photo',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.tr(
                                    'Muat naik foto impian atau pilih ilustrasi untuk puncak peta.',
                                    'Upload a dream photo or choose a preset artwork for your summit.',
                                  ),
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
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            tooltip: strings.tr('Tutup', 'Close'),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(ctx);
                            },
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
                      const SizedBox(height: 16),

                      // Section 1: Upload Custom (Device Photo Library & Camera)
                      Text(
                        strings.tr('MUAT NAIK FOTO', 'UPLOAD CUSTOM'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _warmCocoa,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _photoOptionTile(
                        icon: Icons.photo_library_rounded,
                        title: strings.tr(
                          'Pilih dari Galeri Foto',
                          'Choose from Photo Library',
                        ),
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final picked = await MediaStorageService.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            final uploaded =
                                await MediaStorageService.uploadWishGoalPhoto(
                              goalId: activeGoal.id,
                              imageFile: picked,
                            );
                            if (uploaded != null && mounted) {
                              setState(() => _customUploadedImage = uploaded);
                            }
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(height: 10),
                      _photoOptionTile(
                        icon: Icons.photo_camera_rounded,
                        title: strings.tr(
                          'Ambil Gambar Baharu (Kamera)',
                          'Take New Photo (Camera)',
                        ),
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final picked = await MediaStorageService.pickImage(
                            source: ImageSource.camera,
                          );
                          if (picked != null) {
                            final uploaded =
                                await MediaStorageService.uploadWishGoalPhoto(
                              goalId: activeGoal.id,
                              imageFile: picked,
                            );
                            if (uploaded != null && mounted) {
                              setState(() => _customUploadedImage = uploaded);
                            }
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Choose Preset (Curated Family Artworks)
                      Text(
                        strings.tr('PILIH ILUSTRASI', 'CHOOSE PRESET'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _warmCocoa,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: presets.map((p) {
                          final isSelected = _customUploadedImage == p.asset;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: isSelected ? _blushSurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _customUploadedImage = p.asset,
                                    );
                                    Navigator.pop(ctx);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? _mochaPrimary
                                            : _blushBorder,
                                        width: isSelected ? 1.8 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.asset(
                                            p.asset,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          p.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: CozyTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_customUploadedImage != null) ...[
                        const SizedBox(height: 12),
                        _photoOptionTile(
                          icon: Icons.delete_outline_rounded,
                          title: strings.tr(
                            'Kembali ke Ilustrasi Asal',
                            'Reset to Default Illustration',
                          ),
                          isDestructive: true,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _customUploadedImage = null);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],

                      const SizedBox(height: 14),
                      // Transparent iOS Privacy Pre-prompt Note
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: _warmCocoa,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              strings.tr(
                                'Digunakan hanya untuk foto milestone keluarga anda.',
                                'Used only to personalize your family milestone photo.',
                              ),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _warmCocoa,
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
  }

  Widget _photoOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blushBorder, width: 1.1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFFEE2E2)
                      : _blushSurface,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? const Color(0xFFB91C1C) : _mochaPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDestructive
                        ? const Color(0xFFB91C1C)
                        : CozyTheme.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDestructive ? const Color(0xFFB91C1C) : _warmCocoa,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectGoalDialog(EratAppState appState, AppStrings strings) {
    WishGoalBasis? filterBasis;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filteredGoals = filterBasis == null
                ? appState.wishGoals
                : appState.wishGoals
                    .where((g) => g.basis == filterBasis)
                    .toList();

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.72,
                    minChildSize: 0.5,
                    maxChildSize: 0.92,
                    expand: false,
                    builder: (ctx, scrollController) {
                      final bottomPad = MediaQuery.of(ctx).padding.bottom;
                      final isChildSuggester =
                          !appState.activeMember.isParentOrGuardian &&
                              appState.activeMember.ageYears < 13;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          14,
                          20,
                          bottomPad < 16 ? 34 : bottomPad + 20,
                        ),
                        child: Column(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  strings.tr(
                                    'Hadiah Impian Peta',
                                    'Milestone Dream Rewards',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: _mochaPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              strings.tr(
                                'Pilih impian untuk paparkan peta milestone mengikut tempoh sasaran.',
                                'Select a dream goal to view its milestone map by timeframe.',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: _warmCocoa,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildBasisFilterChip(
                                    label: strings.tr('Semua', 'All'),
                                    isSelected: filterBasis == null,
                                    onTap: () =>
                                        setSheetState(() => filterBasis = null),
                                  ),
                                  ...WishGoalBasis.values.map((b) {
                                    return _buildBasisFilterChip(
                                      label: _localizedBasisBadge(b, strings),
                                      isSelected: filterBasis == b,
                                      onTap: () =>
                                          setSheetState(() => filterBasis = b),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: filteredGoals.isEmpty
                                  ? Center(
                                      child: Text(
                                        strings.tr(
                                          'Tiada impian dalam kategori ini.',
                                          'No goals in this timeframe yet.',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _warmCocoa,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: scrollController,
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      itemCount: filteredGoals.length,
                                      itemBuilder: (ctx, index) {
                                        final goal = filteredGoals[index];
                                        final isSelected =
                                            goal.id == _selectedGoalId;
                                        final pct = (goal.progress * 100).toInt();
                                        final remaining = (goal.targetPoints -
                                                goal.currentPoints)
                                            .clamp(0, 999999);
                                        final canRedeem = remaining == 0;

                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _blushSurface
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isSelected
                                                  ? _mochaPrimary
                                                  : _blushBorder,
                                              width: isSelected ? 1.8 : 1,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            leading: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: _blushSurface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _blushBorder,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: goal.customImagePath !=
                                                          null &&
                                                      goal.customImagePath!
                                                          .isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        11,
                                                      ),
                                                      child: MediaStorageService
                                                          .buildAdaptiveImage(
                                                        goal.customImagePath,
                                                        width: 48,
                                                        height: 48,
                                                        fit: BoxFit.cover,
                                                        placeholder: Text(
                                                          goal.iconEmoji,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 22,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Text(
                                                      goal.iconEmoji,
                                                      style: const TextStyle(
                                                        fontSize: 22,
                                                      ),
                                                    ),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    goal.title(strings.isMs),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: CozyTheme.textDark,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFFEF3C7),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    _localizedBasisBadge(
                                                      goal.basis,
                                                      strings,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Color(0xFF78350F),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (goal.hasFocusActivity) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '🎯 ${goal.focusActivity!}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _mochaPrimary,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: goal.progress,
                                                    minHeight: 6,
                                                    backgroundColor:
                                                        _blushSurface,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                            Color>(
                                                      _mochaPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        goal.hasFocusActivity
                                                            ? '${goal.currentPoints}/${goal.targetPoints}x ($pct%)'
                                                            : '${goal.currentPoints}/${goal.targetPoints} ★ ($pct%)',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _warmCocoa,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (canRedeem)
                                                      InkWell(
                                                        onTap: () {
                                                          HapticFeedback
                                                              .mediumImpact();
                                                          ref
                                                              .read(
                                                                eratControllerProvider
                                                                    .notifier,
                                                              )
                                                              .redeemWishGoal(
                                                                goal.id,
                                                              );
                                                          Navigator.pop(ctx);
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                strings.tr(
                                                                  'Permohonan tebus "${goal.title(true)}" dihantar kepada Ibu Bapa!',
                                                                  'Redemption request for "${goal.title(false)}" sent to Parents!',
                                                                ),
                                                              ),
                                                              backgroundColor:
                                                                  _mochaPrimary,
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  14,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _mochaPrimary,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              14,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            strings.tr(
                                                              'Tebus Sekarang →',
                                                              'Redeem Now →',
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : const Color(
                                                                      0xFFFAF2E8,
                                                                    ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                10,
                                                              ),
                                                              border: Border.all(
                                                                color:
                                                                    _blushBorder,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              strings.tr(
                                                                'Perlu $remaining ★',
                                                                'Need $remaining more ★',
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    _warmCocoa,
                                                              ),
                                                            ),
                                                          ),
                                                          if (isSelected) ...[
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              strings.tr(
                                                                'Aktif ✓',
                                                                'Active ✓',
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 11.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    _mochaPrimary,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _selectedGoalId = goal.id;
                                                _customUploadedImage = null;
                                              });
                                              Navigator.pop(ctx);
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(ctx);
                                  _showCreateWishGoalWithBasisDialog(strings);
                                },
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(
                                  isChildSuggester
                                      ? strings.tr(
                                          'Cadang Ganjaran Baru',
                                          'Suggest New Reward',
                                        )
                                      : strings.tr(
                                          'Cipta Impian Baharu',
                                          'Create New Dream Goal',
                                        ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _mochaPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBasisFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _mochaPrimary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? _mochaPrimary : _blushBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : _warmCocoa,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateWishGoalWithBasisDialog(AppStrings strings) {
    final titleCtrl = TextEditingController();
    final focusCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '20');
    WishGoalBasis chosenBasis = WishGoalBasis.weekly;
    String chosenEmoji = '🎁';
    String? uploadedRewardPhoto;
    bool isUploadingPhoto = false;
    const emojis = ['🎁', '🍦', '🍕', '🚲', '🎨', '📚', '🎲', '🏖️'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final parsedTarget = int.tryParse(pointsCtrl.text.trim()) ?? 0;
            final hasFocus = focusCtrl.text.trim().isNotEmpty;
            final canSave = titleCtrl.text.trim().isNotEmpty &&
                parsedTarget > 0 &&
                !isUploadingPhoto;

            Future<void> pickRewardPhoto(ImageSource source) async {
              setDialogState(() => isUploadingPhoto = true);
              try {
                final picked =
                    await MediaStorageService.pickImage(source: source);
                if (picked != null) {
                  final uploaded =
                      await MediaStorageService.uploadWishGoalPhoto(
                    goalId: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                    imageFile: picked,
                  );
                  if (uploaded != null && uploaded.isNotEmpty) {
                    setDialogState(() => uploadedRewardPhoto = uploaded);
                  }
                }
              } finally {
                setDialogState(() => isUploadingPhoto = false);
              }
            }

            return AlertDialog(
              backgroundColor: CozyTheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                strings.tr('Cipta Hadiah Impian', 'Create Dream Reward'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17.5,
                  color: CozyTheme.textDark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.tr('Nama Hadiah:', 'Reward Name:'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: strings.tr(
                          'Cth: Pizza Party / Basikal Baru',
                          'e.g. Pizza Party / New Bicycle',
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _blushBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _blushBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _mochaPrimary,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Focus Activity (e.g. "Hafal Doa Qunut" 20x)
                    Text(
                      strings.tr(
                        'Aktiviti Fokus (Pilihan):',
                        'Focus Activity (Optional):',
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: focusCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: strings.tr(
                          'Cth: Hafal Doa Qunut / Baca Iqra\'',
                          'e.g. Memorize Doa Qunut / Read 15m',
                        ),
                        helperText: hasFocus
                            ? strings.tr(
                                'Anak perlu berlatih ${parsedTarget > 0 ? parsedTarget : 20}x & disahkan Ibu Bapa.',
                                'Child completes ${parsedTarget > 0 ? parsedTarget : 20}x verified practices to claim.',
                              )
                            : strings.tr(
                                'Kosongkan jika guna bintang umum daripada semua quests.',
                                'Leave blank to use general stars from all quests.',
                              ),
                        helperMaxLines: 2,
                        helperStyle: const TextStyle(
                          fontSize: 11,
                          color: _warmCocoa,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _blushBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _blushBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _mochaPrimary,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reward Photo Uploader (Camera / Gallery / Preview / Delete, ≥ 44 × 44 pt)
                    Text(
                      strings.tr(
                        'Gambar Hadiah (Pilihan):',
                        'Reward Photo (Optional):',
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: uploadedRewardPhoto != null
                            ? Colors.white
                            : const Color(0xFFFAF2E8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: uploadedRewardPhoto != null
                              ? _blushBorder
                              : _mochaPrimary.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _blushSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _blushBorder),
                            ),
                            alignment: Alignment.center,
                            child: uploadedRewardPhoto != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child:
                                        MediaStorageService.buildAdaptiveImage(
                                      uploadedRewardPhoto,
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 22,
                                    color: _mochaPrimary,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              uploadedRewardPhoto != null
                                  ? strings.tr(
                                      'Foto hadiah tersimpan',
                                      'Reward photo added',
                                    )
                                  : strings.tr(
                                      '+ Tambah Foto Inspirasi',
                                      '+ Add Inspiration Photo',
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: uploadedRewardPhoto != null
                                    ? CozyTheme.textDark
                                    : _mochaPrimary,
                              ),
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
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: strings.tr('Kamera', 'Camera'),
                              onPressed: () =>
                                  pickRewardPhoto(ImageSource.camera),
                              icon: const Icon(
                                Icons.photo_camera_outlined,
                                size: 20,
                                color: _mochaPrimary,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: strings.tr('Galeri', 'Gallery'),
                              onPressed: () =>
                                  pickRewardPhoto(ImageSource.gallery),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 20,
                                color: _mochaPrimary,
                              ),
                            ),
                            if (uploadedRewardPhoto != null)
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                padding: EdgeInsets.zero,
                                tooltip: strings.tr('Padam', 'Remove'),
                                onPressed: () => setDialogState(
                                  () => uploadedRewardPhoto = null,
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
                    const SizedBox(height: 12),

                    Text(
                      strings.tr('Tempoh Masa:', 'Timeframe:'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Smooth horizontal pill strip (eliminates orphaned Yearly row)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: WishGoalBasis.values.map((b) {
                          final isSel = chosenBasis == b;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () =>
                                  setDialogState(() => chosenBasis = b),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 40),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel ? _mochaPrimary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? _mochaPrimary : _blushBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _localizedBasisBadge(b, strings),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? Colors.white : _warmCocoa,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasFocus
                          ? strings.tr(
                              'Sasaran Latihan (Kali):',
                              'Target Practices (Times):',
                            )
                          : strings.tr('Sasaran Bintang:', 'Target Stars:'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: pointsCtrl,
                      onChanged: (_) => setDialogState(() {}),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: hasFocus ? 'x' : '★',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _blushBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _blushBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _mochaPrimary,
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.tr('Pilih Ikon:', 'Choose Icon:'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _warmCocoa,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Symmetrical 4×2 Icon Grid (no orphan icon on row 2)
                    Column(
                      children: [
                        for (var row = 0; row < 2; row++) ...[
                          if (row > 0) const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(4, (col) {
                              final e = emojis[row * 4 + col];
                              final isSel = chosenEmoji == e;
                              return InkWell(
                                onTap: () =>
                                    setDialogState(() => chosenEmoji = e),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 52,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSel ? _blushSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSel ? _mochaPrimary : _blushBorder,
                                      width: isSel ? 1.8 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    e,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  child: Text(
                    strings.tr('Batal', 'Cancel'),
                    style: const TextStyle(
                      color: _warmCocoa,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: canSave
                      ? () {
                          final title = titleCtrl.text.trim();
                          final focus = focusCtrl.text.trim();
                          final target =
                              int.tryParse(pointsCtrl.text.trim()) ?? 20;
                          final currentAppState =
                              ref.read(eratControllerProvider);
                          final currentMember = currentAppState.activeMember;
                          final selectedChildId = ref.read(
                            selectedChildForParentViewProvider,
                          );
                          final kids = currentAppState.members
                              .where((m) => !m.isParentOrGuardian)
                              .toList();
                          final targetMemberId = (currentMember
                                      .isParentOrGuardian &&
                                  kids.isNotEmpty)
                              ? (selectedChildId ?? kids.first.id)
                              : currentMember.id;

                          HapticFeedback.mediumImpact();
                          ref.read(eratControllerProvider.notifier).addWishGoal(
                                titleMs: title,
                                iconEmoji: chosenEmoji,
                                targetPoints: target,
                                customImagePath: uploadedRewardPhoto,
                                focusActivity: focus.isEmpty ? null : focus,
                                targetMemberId: targetMemberId,
                                basis: chosenBasis,
                              );

                          Navigator.pop(ctx);

                          final latestGoals =
                              ref.read(eratControllerProvider).wishGoals;
                          if (latestGoals.isNotEmpty) {
                            setState(() {
                              _selectedGoalId = latestGoals.first.id;
                              _customUploadedImage = uploadedRewardPhoto;
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(84, 44),
                    backgroundColor: _mochaPrimary,
                    disabledBackgroundColor: const Color(0xFFD5C3B8),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    strings.tr('Simpan', 'Save'),
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

  void _showCompletedModal(dynamic cp, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CozyTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cp.title as String,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: CozyTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.tr(
            'Hebat sekali! Tugasan ini telah disiapkan dan disahkan oleh Ibu/Ayah. Ganjaran bintang telah dimasukkan ke tabung impian anda!',
            'Awesome job! This milestone has been completed and verified by your parents. Your stars have been added to your dream goal!',
          ),
          style: const TextStyle(
            fontSize: 13.5,
            color: _warmCocoa,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _mochaPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              strings.tr('Teruskan!', 'Keep Going!'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showActiveTaskModal(
    dynamic cp,
    FamilyMember activeMember,
    AppStrings strings,
  ) {
    final name = _localizedMemberName(activeMember.name, strings);
    final proofKey = '${_selectedGoalId}_${cp.stepNum}';
    String? attachedProofPath = _submittedProofByStep[proofKey];
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pickProof(ImageSource source) async {
              setSheetState(() => isUploading = true);
              try {
                final picked =
                    await MediaStorageService.pickImage(source: source);
                if (picked != null) {
                  final uploaded =
                      await MediaStorageService.uploadActivityPhoto(
                    activityId:
                        'proof_${proofKey}_${DateTime.now().millisecondsSinceEpoch}',
                    imageFile: picked,
                  );
                  if (uploaded != null && uploaded.isNotEmpty) {
                    setSheetState(() => attachedProofPath = uploaded);
                  }
                }
              } finally {
                setSheetState(() => isUploading = false);
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
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
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
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cp.title as String,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _mochaPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _blushSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _blushBorder),
                            ),
                            child: Row(
                              children: [
                                _buildMemberAvatar(
                                  activeMember,
                                  size: 36,
                                  emojiSize: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    strings.tr(
                                      '$name sedang berada di checkpoint ini! Muat naik foto bukti untuk disahkan oleh Ibu Bapa.',
                                      '$name is on this checkpoint! Attach a photo proof for Parents to review.',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CozyTheme.textDark,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Photo Proof Preview / Picker
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _blushBorder),
                            ),
                            child: Column(
                              children: [
                                if (attachedProofPath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: MediaStorageService.buildAdaptiveImage(
                                      attachedProofPath,
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ] else ...[
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: _mochaPrimary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    strings.tr(
                                      'Ambil atau muat naik foto bukti siap',
                                      'Take or upload a completion proof photo',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _warmCocoa,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (isUploading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: _mochaPrimary,
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              pickProof(ImageSource.camera),
                                          icon: const Icon(
                                            Icons.photo_camera_rounded,
                                            size: 17,
                                          ),
                                          label: Text(
                                            strings.tr('Kamera', 'Camera'),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _mochaPrimary,
                                            side: const BorderSide(
                                              color: _blushBorder,
                                            ),
                                            minimumSize: const Size(0, 44),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              pickProof(ImageSource.gallery),
                                          icon: const Icon(
                                            Icons.photo_library_rounded,
                                            size: 17,
                                          ),
                                          label: Text(
                                            strings.tr('Galeri', 'Gallery'),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _mochaPrimary,
                                            side: const BorderSide(
                                              color: _blushBorder,
                                            ),
                                            minimumSize: const Size(0, 44),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Submit Proof CTA (Disabled until proof photo is attached)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: (attachedProofPath != null &&
                                      !isUploading)
                                  ? () {
                                      HapticFeedback.mediumImpact();
                                      setState(() {
                                        _submittedProofByStep[proofKey] =
                                            attachedProofPath!;
                                      });
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            strings.tr(
                                              'Foto bukti berjaya dihantar kepada Ibu Bapa untuk pengesahan!',
                                              'Photo proof sent to Parents for review!',
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
                                  : null,
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                strings.tr(
                                  'Hantar Bukti ke Ibu Bapa',
                                  'Submit Proof to Parents',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                disabledBackgroundColor:
                                    const Color(0xFFD5C3B8),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
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
      },
    );
  }

  void _showLockedModal(dynamic cp, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CozyTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: _mochaPrimary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cp.title as String,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: CozyTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.tr(
            'Langkah ini masih terkunci. Selesaikan checkpoint aktif terlebih dahulu untuk membuka laluan ini!',
            'This step is still locked. Complete your active checkpoint first to unlock this milestone!',
          ),
          style: const TextStyle(
            fontSize: 13.5,
            color: _warmCocoa,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _mochaPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              strings.tr('Faham', 'Got It'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

enum _NodeStatus {
  completed,
  active,
  locked,
}
