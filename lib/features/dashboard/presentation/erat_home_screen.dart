import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../../core/theme/erat_palette.dart';
import '../../auth/presentation/auth_family_screen.dart';
import '../../auth/presentation/device_mode_selection_screen.dart';
import '../../auth/presentation/member_pin_login_screen.dart';
import '../../chat/presentation/cozy_personal_chat_tab.dart';
import '../../community/presentation/cozy_personal_journal_tab.dart';
import '../../family/presentation/cozy_personal_profile_tab.dart';
import '../../family/presentation/family_public_screen.dart';
import '../../rewards/presentation/cozy_personal_quests_tab.dart';
import 'cozy_personal_home_tab.dart';

class EratHomeScreen extends ConsumerStatefulWidget {
  const EratHomeScreen({super.key});

  @override
  ConsumerState<EratHomeScreen> createState() => _EratHomeScreenState();
}

class _EratHomeScreenState extends ConsumerState<EratHomeScreen> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _restorePersistedFirebaseSession();
  }

  /// Keep real signed-in accounts logged in on this device across app restarts
  Future<void> _restorePersistedFirebaseSession() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final loaded = await ref
          .read(eratControllerProvider.notifier)
          .loadUserAndFamilyFromFirestore(
            uid: user.uid,
            email: user.email ?? '',
            fallbackDisplayName: user.displayName,
          );
      if (!mounted) return;
      if (loaded) {
        ref.read(showOnboardingFlowProvider.notifier).state = false;
      }
    });
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

  String _localizedMemberSubtitle(FamilyMember member, AppStrings strings) {
    final customTag = member.tagline?.trim();
    if (customTag != null && customTag.isNotEmpty) {
      if (member.isParentOrGuardian) return customTag;
      return '$customTag • ${member.ageYears}${strings.isMs ? ' thn' : 'y'}';
    }

    if (member.isParentOrGuardian) {
      switch (member.role) {
        case MemberRole.owner:
          return strings.tr('Ibu Bapa', 'Parent');
        case MemberRole.coparent:
          return strings.tr('Ibu Bapa', 'Co-Parent');
        case MemberRole.caregiver:
          return strings.tr('Penjaga', 'Caregiver');
        case MemberRole.adult:
        case MemberRole.teen:
        case MemberRole.child:
          break;
      }
    }

    final age = member.ageYears;
    switch (member.ageBand) {
      case AgeBand.littleExplorer:
        return strings.tr('Peneroka Kecil • $age thn', 'Little Explorer • ${age}y');
      case AgeBand.happyHabitBuilder:
        return strings.tr('Pembina Tabiat • $age thn', 'Habit Builder • ${age}y');
      case AgeBand.goalAchiever:
        return strings.tr('Pencapai Matlamat • $age thn', 'Goal Achiever • ${age}y');
      case AgeBand.myLifeMyGoals:
        return strings.tr('Matlamat Remaja • $age thn', 'Teen Goals • ${age}y');
      case AgeBand.lifelongFamilyBond:
        return strings.tr('Ikatan Keluarga • $age thn', 'Family Bond • ${age}y');
    }
  }

  void _showSpaceSwitchSheet(BuildContext context, AppStrings strings) {
    HapticFeedback.selectionClick();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
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
                    bottomInset < 16 ? 34 : 22,
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
                        strings.tr('Tukar Paparan', 'Switch View'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.tr(
                          'Kunci ruang peribadi anda atau tukar ke profil ahli lain.',
                          'Lock your private space or switch to another family profile.',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _warmCocoa,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _spaceActionTile(
                        icon: Icons.switch_account_rounded,
                        title: strings.tr('Tukar Profil Ahli', 'Switch Member Profile'),
                        subtitle: strings.tr(
                          'Buka skrin pilih profil & PIN',
                          'Open profile picker & PIN login',
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MemberPinLoginScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _spaceActionTile(
                        icon: Icons.family_restroom_rounded,
                        title: strings.tr('Papan Keluarga', 'Family Board'),
                        subtitle: strings.tr(
                          'Kunci ruang peribadi & kembali ke paparan keluarga',
                          'Lock private space & return to Family View',
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(isPrivateSpaceUnlockedProvider.notifier).state =
                              false;
                          ref.read(appViewModeProvider.notifier).state =
                              AppViewMode.family;
                        },
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

  Widget _spaceActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _blushBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _blushSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: _mochaPrimary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _warmCocoa,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mochaPrimary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showOnboarding = ref.watch(showOnboardingFlowProvider);
    final isPrivateUnlocked = ref.watch(isPrivateSpaceUnlockedProvider);
    final appViewMode = ref.watch(appViewModeProvider);
    final worldTheme = ref.watch(selectedWorldThemeProvider);
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final activeMember = appState.activeMember;

    if (showOnboarding) {
      return const AuthFamilyScreen();
    }

    // 1. Device View Selection Screen: 2 Cards (Family View vs Individual View)
    if (appViewMode == AppViewMode.selection) {
      return const DeviceModeSelectionScreen();
    }

    // 2. Family View: Shared communal board (no private 5 buttons)
    if (appViewMode == AppViewMode.family || !isPrivateUnlocked) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: worldTheme.backgroundGradient,
        ),
        child: const FamilyPublicScreen(),
      );
    }

    final displayName = _localizedMemberName(activeMember.name, strings);
    final subtitle = _localizedMemberSubtitle(activeMember, strings);

    // Private Space: 5 Exclusive Navigation Tabs
    final tabs = [
      CozyPersonalHomeTab(
        onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
      ),
      const CozyPersonalQuestsTab(),
      const CozyPersonalChatTab(),
      const CozyPersonalJournalTab(),
      const CozyPersonalProfileTab(),
    ];

    return Scaffold(
      backgroundColor: CozyTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          decoration: const BoxDecoration(
            color: CozyTheme.background,
            border: Border(
              bottom: BorderSide(color: _blushBorder, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _blushSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _blushBorder, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: activeMember.customPhotoPath != null
                        ? ClipOval(
                            child: MediaStorageService.buildAdaptiveImage(
                              activeMember.customPhotoPath,
                              width: 40,
                              height: 40,
                              placeholder: Text(
                                activeMember.avatarEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          )
                        : Text(
                            activeMember.avatarEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _warmCocoa,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tappable Private Space pill (≥ 44 pt hit target)
                  Material(
                    color: _blushSurface,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: () => _showSpaceSwitchSheet(context, strings),
                      hoverColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 44,
                          minWidth: 44,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _blushBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                size: 13,
                                color: _mochaPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                strings.tr('Peribadi', 'Private'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _mochaPrimary,
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
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: tabs[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: _blushBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3728).withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: _blushSurface,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? _mochaPrimary : const Color(0xFF9E8D84),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 23,
                color: selected ? _mochaPrimary : const Color(0xFF9E8D84),
              );
            }),
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) {
              HapticFeedback.selectionClick();
              setState(() => _selectedIndex = idx);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: strings.tr('Utama', 'Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.check_circle_outline_rounded),
                selectedIcon: const Icon(Icons.check_circle_rounded),
                label: strings.tr('Misi', 'Quests'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: const Icon(Icons.chat_bubble_rounded),
                label: strings.tr('Sembang', 'Chat'),
              ),
              NavigationDestination(
                icon: Icon(
                  activeMember.isParentOrGuardian
                      ? Icons.forum_outlined
                      : Icons.auto_stories_outlined,
                ),
                selectedIcon: Icon(
                  activeMember.isParentOrGuardian
                      ? Icons.forum_rounded
                      : Icons.auto_stories_rounded,
                ),
                label: activeMember.isParentOrGuardian
                    ? strings.tr('Komuniti', 'Community')
                    : strings.tr('Diari', 'Journal'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: strings.tr('Profil', 'Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
