import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';
import 'auth_family_screen.dart';
import 'member_pin_login_screen.dart';

class DeviceModeSelectionScreen extends ConsumerStatefulWidget {
  const DeviceModeSelectionScreen({super.key});

  @override
  ConsumerState<DeviceModeSelectionScreen> createState() =>
      _DeviceModeSelectionScreenState();
}

class _DeviceModeSelectionScreenState
    extends ConsumerState<DeviceModeSelectionScreen> {
  AppViewMode _selectedMode = AppViewMode.family;

  void _confirmSelection() {
    HapticFeedback.lightImpact();
    if (_selectedMode == AppViewMode.family) {
      ref.read(appViewModeProvider.notifier).state = AppViewMode.family;
      ref.read(isPrivateSpaceUnlockedProvider.notifier).state = false;
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const MemberPinLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final appState = ref.watch(eratControllerProvider);
    final family = appState.family;
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    final extraBottomInset =
        bottomSafeInset >= 34.0 ? 0.0 : (34.0 - bottomSafeInset);

    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            final isTablet = viewportConstraints.maxWidth >= 600.0;
            final horizontalPad = isTablet ? 32.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 860.0 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    isTablet ? 18 : 10,
                    horizontalPad,
                    extraBottomInset + (isTablet ? 18 : 10),
                  ),
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clean Minimal Top Bar (Family Photo/Logo + Family Name + Language Pill + 44x44 Overflow Menu)
              Row(
                children: [
                  MediaStorageService.buildFamilyAvatar(
                    photoPath: family.photoPath,
                    size: 42,
                    fallback: const EratBrandLogo(size: 42),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      family.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Quick Language Toggle Pill (Consistent with APP-001 & APP-002, >= 44x44 pt)
                  Semantics(
                    button: true,
                    label: strings.tr('Tukar bahasa', 'Switch language'),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(appLanguageProvider.notifier).state =
                            currentLang == AppLanguage.en
                                ? AppLanguage.ms
                                : AppLanguage.en;
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        child: Center(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: CozyTheme.pillBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: CozyTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language_rounded,
                                  size: 15,
                                  color: CozyTheme.textDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentLang == AppLanguage.en ? 'EN' : 'BM',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overflow Menu (... button with >= 44x44 pt tap target)
                  PopupMenuButton<String>(
                    tooltip: strings.tr('Pilihan lanjut', 'More options'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 180),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (val) {
                      if (val == 'lang') {
                        ref.read(appLanguageProvider.notifier).update(
                              (l) => l == AppLanguage.ms
                                  ? AppLanguage.en
                                  : AppLanguage.ms,
                            );
                      } else if (val == 'logout') {
                        ref.read(showOnboardingFlowProvider.notifier).state =
                            true;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'lang',
                        height: 46,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.language_rounded,
                              size: 18,
                              color: CozyTheme.textMedium,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.tr(
                                'Tukar Bahasa (EN/BM)',
                                'Switch Language (EN/BM)',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CozyTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        height: 46,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              strings.tr('Log Keluar', 'Sign Out'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CozyTheme.border),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: CozyTheme.textDark,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Section Header (High-Contrast Warm Cocoa Subtitle, WCAG AA/AAA)
              Center(
                child: Column(
                  children: [
                    Text(
                      strings.tr(
                        'Pilih Mod Paparan',
                        'Choose Display Mode',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.tr(
                        'Anda boleh tukar mod bila-bila masa tanpa log keluar.',
                        'You can switch modes anytime without signing out.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A463C), // Warm cocoa (8.1:1 contrast)
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Expanded Card Group: Adaptive 2-Column on iPad / Vertically Stacked on Phone
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    // Scale illustration generously with viewport while staying safe on iPhone SE
                    final artSize = isTablet
                        ? 172.0
                        : ((availableHeight - 44) * 0.34).clamp(118.0, 162.0);
                    final isCompact = !isTablet && availableHeight < 390;

                    final familyCard = _buildModeCard(
                      isTablet: isTablet,
                      isReversed: false,
                      isSelected: _selectedMode == AppViewMode.family,
                      title: strings.tr(
                        'Paparan Keluarga',
                        'Family View',
                      ),
                      description: strings.tr(
                        'Matlamat bintang & tugasan harian bersama.',
                        'Star goals & daily family quests.',
                      ),
                      microLabel: strings.tr(
                        'Ruang Kongsi',
                        'Shared Space',
                      ),
                      microIcon: Icons.groups_rounded,
                      imageAssetPath: 'assets/images/mode_family_cozy.jpg',
                      fallbackIcon: Icons.groups_rounded,
                      artSize: artSize,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () => _selectedMode = AppViewMode.family,
                        );
                      },
                    );

                    final individualCard = _buildModeCard(
                      isTablet: isTablet,
                      isReversed: true,
                      isSelected: _selectedMode == AppViewMode.private,
                      title: strings.tr(
                        'Paparan Peribadi',
                        'Individual View',
                      ),
                      description: strings.tr(
                        'Diari suara, rutin & ganjaran peribadi.',
                        'Voice diary, habits & wish rewards.',
                      ),
                      microLabel: strings.tr(
                        'Perlu PIN',
                        'PIN Required',
                      ),
                      microIcon: Icons.lock_rounded,
                      imageAssetPath: 'assets/images/mode_individual_cozy.jpg',
                      fallbackIcon: Icons.lock_rounded,
                      artSize: artSize,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () => _selectedMode = AppViewMode.private,
                        );
                      },
                    );

                    // Tablet / iPad: Side-by-Side 2-Column Card Layout
                    if (isTablet) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: familyCard),
                                const SizedBox(width: 22),
                                Expanded(child: individualCard),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final cardsColumn = Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCompact) familyCard else Expanded(child: familyCard),

                        // Signature Cozy Journal Vertical Dot Connector
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: ExcludeSemantics(
                            child: CozyTimelineConnector(
                              height: 24,
                              dotSize: 8,
                            ),
                          ),
                        ),

                        if (isCompact)
                          individualCard
                        else
                          Expanded(child: individualCard),
                      ],
                    );

                    if (isCompact) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: cardsColumn,
                      );
                    }
                    return cardsColumn;
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Native iOS Bottom Primary CTA: Continue -> (Centered maxWidth on iPad)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isTablet ? 320 : double.infinity,
                    maxWidth: isTablet ? 420 : double.infinity,
                    minHeight: 56,
                  ),
                  child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D4C41), // WCAG AAA
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        strings.tr('Teruskan', 'Continue'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
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
        ),
      ),
    );
  }

  Widget _buildModeCard({
    bool isTablet = false,
    required bool isReversed,
    required bool isSelected,
    required String title,
    required String description,
    required String microLabel,
    required IconData microIcon,
    required String imageAssetPath,
    required IconData fallbackIcon,
    required double artSize,
    required VoidCallback onTap,
  }) {
    // Clean Direct Typography with Symmetrical Micro-Label
    final textContent = Column(
      crossAxisAlignment:
          isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              microIcon,
              size: 13.5,
              color: const Color(0xFF6D4C41),
            ),
            const SizedBox(width: 5),
            Text(
              microLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6D4C41),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: isTablet ? Alignment.center : Alignment.centerLeft,
          child: Text(
            title,
            maxLines: 1,
            style: TextStyle(
              fontSize: isTablet ? 23 : 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: CozyTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          maxLines: 3,
          textAlign: isTablet ? TextAlign.center : TextAlign.start,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5A463C),
            height: 1.4,
          ),
        ),
      ],
    );

    final textColumn = Expanded(child: textContent);

    final illustration = ExcludeSemantics(
      child: Container(
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          color: CozyTheme.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CozyTheme.border, width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(109, 76, 65, 0.07),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            imageAssetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  fallbackIcon,
                  size: 46,
                  color: CozyTheme.connectorDot,
                ),
              );
            },
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFDF9) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFF6D4C41) : CozyTheme.border,
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color.fromRGBO(109, 76, 65, 0.14)
                  : const Color.fromRGBO(60, 40, 20, 0.05),
              blurRadius: isSelected ? 18 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 26 : 20,
                vertical: isTablet ? 28 : 18,
              ),
              child: Stack(
                children: [
                  Center(
                    child: isTablet
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              illustration,
                              const SizedBox(height: 20),
                              textContent,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: isReversed
                                ? [
                                    illustration,
                                    const SizedBox(width: 18),
                                    textColumn,
                                  ]
                                : [
                                    textColumn,
                                    const SizedBox(width: 18),
                                    illustration,
                                  ],
                          ),
                  ),
                  // Consistent Top-Right Radio Selection Indicator on BOTH cards
                  Positioned(
                    top: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6D4C41)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6D4C41)
                              : CozyTheme.border,
                          width: 1.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
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
}
