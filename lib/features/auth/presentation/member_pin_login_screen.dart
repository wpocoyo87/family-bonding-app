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

class MemberPinLoginScreen extends ConsumerStatefulWidget {
  final String? preselectedMemberId;

  const MemberPinLoginScreen({
    super.key,
    this.preselectedMemberId,
  });

  @override
  ConsumerState<MemberPinLoginScreen> createState() =>
      _MemberPinLoginScreenState();
}

class _MemberPinLoginScreenState extends ConsumerState<MemberPinLoginScreen> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _cardSurface = Colors.white;
  static const Color _handleAndDotStroke = Color(0xFFBBA396);

  String _enteredPin = '';
  String? _errorMessage;
  int _lastKeyPressTimestamp = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final members = ref.read(eratControllerProvider).members;
      if (widget.preselectedMemberId != null) {
        final match = members.where((m) => m.id == widget.preselectedMemberId);
        if (match.isNotEmpty) {
          _openPinPadForMember(match.first);
        }
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

  void _openPinPadForMember(FamilyMember member) {
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = '';
      _errorMessage = null;
    });
    _showPinBottomSheet(member);
  }

  bool get _isRealAccount =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  void _verifyPin(
    String pin,
    FamilyMember member,
    AppStrings strings,
    void Function(VoidCallback) updateModal,
  ) {
    final validPin = member.pin ?? '1234';
    final bool isMatch =
        _isRealAccount ? (pin == validPin) : (pin == validPin || pin == '1234');
    if (isMatch) {
      HapticFeedback.mediumImpact();
      ref.read(eratControllerProvider.notifier).switchProfile(member.id);
      ref.read(isPrivateSpaceUnlockedProvider.notifier).state = true;
      ref.read(appViewModeProvider.notifier).state = AppViewMode.private;

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close bottom sheet
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // return to main home screen
      }
    } else {
      HapticFeedback.heavyImpact();
      updateModal(() {
        _errorMessage = strings.tr(
          'PIN tidak sah. Sila cuba lagi.',
          'Incorrect PIN. Please try again.',
        );
        _enteredPin = '';
      });
    }
  }

  Widget _buildAvatar(FamilyMember member, {double size = 72, double emojiSize = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _blushSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: _blushBorder,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: member.customPhotoPath != null
          ? ClipOval(
              child: MediaStorageService.buildAdaptiveImage(
                member.customPhotoPath,
                width: size,
                height: size,
                placeholder: Text(
                  member.avatarEmoji,
                  style: TextStyle(fontSize: emojiSize),
                ),
              ),
            )
          : Text(
              member.avatarEmoji,
              style: TextStyle(fontSize: emojiSize),
            ),
    );
  }

  void _showPinBottomSheet(FamilyMember member) {
    final strings = ref.read(appStringsProvider);
    final displayName = _localizedMemberName(member.name, strings);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            void updateModal(VoidCallback fn) {
              fn();
              setModalState(() {});
            }

            final demoPin = member.pin ?? '1234';

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        14,
                        24,
                        bottomInset < 16 ? 34 : 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: _handleAndDotStroke,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildAvatar(member, size: 70, emojiSize: 34),
                          const SizedBox(height: 12),
                          Text(
                            strings.tr(
                              'Ruang Peribadi: $displayName',
                              '$displayName’s Private Space',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.tr(
                              'Masukkan PIN 4-digit untuk membuka ruang peribadi anda.',
                              'Enter your 4-digit PIN to unlock your private space.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _warmCocoa,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // PIN Dots (● ● ● ●)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (idx) {
                              final filled = idx < _enteredPin.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filled ? _mochaPrimary : Colors.white,
                                  border: Border.all(
                                    color: filled
                                        ? _mochaPrimary
                                        : _handleAndDotStroke,
                                    width: 2.2,
                                  ),
                                ),
                              );
                            }),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Demo helper button — ONLY shown in Demo Mode (never on real signed-in accounts!)
                          if (!_isRealAccount)
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                updateModal(() {
                                  _enteredPin = demoPin;
                                  _errorMessage = null;
                                });
                                Future.delayed(const Duration(milliseconds: 180), () {
                                  _verifyPin(demoPin, member, strings, updateModal);
                                });
                              },
                              hoverColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _linenSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _linenBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.key_rounded,
                                      size: 15,
                                      color: _mochaPrimary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      strings.tr(
                                        'Demo PIN: $demoPin (Ketik untuk autofill)',
                                        'Demo PIN: $demoPin (Tap to autofill)',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _mochaPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Number Keypad (1 - 9, 0, Backspace)
                          _buildKeypad(
                            onDigit: (digit) {
                              final now = DateTime.now().millisecondsSinceEpoch;
                              if (now - _lastKeyPressTimestamp < 150) return;
                              _lastKeyPressTimestamp = now;
                              HapticFeedback.selectionClick();

                              updateModal(() {
                                if (_enteredPin.length < 4) {
                                  _enteredPin += digit;
                                  _errorMessage = null;
                                }
                              });
                              if (_enteredPin.length == 4) {
                                Future.delayed(
                                  const Duration(milliseconds: 150),
                                  () {
                                    _verifyPin(
                                      _enteredPin,
                                      member,
                                      strings,
                                      updateModal,
                                    );
                                  },
                                );
                              }
                            },
                            onBackspace: () {
                              final now = DateTime.now().millisecondsSinceEpoch;
                              if (now - _lastKeyPressTimestamp < 150) return;
                              _lastKeyPressTimestamp = now;
                              HapticFeedback.selectionClick();

                              updateModal(() {
                                if (_enteredPin.isNotEmpty) {
                                  _enteredPin = _enteredPin.substring(
                                    0,
                                    _enteredPin.length - 1,
                                  );
                                  _errorMessage = null;
                                }
                              });
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
      },
    );
  }

  Widget _buildKeypad({
    required ValueChanged<String> onDigit,
    required VoidCallback onBackspace,
  }) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var col = 1; col <= 3; col++)
                _keypadButton(
                  label: '${row * 3 + col}',
                  onTap: () => onDigit('${row * 3 + col}'),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 56),
            _keypadButton(
              label: '0',
              onTap: () => onDigit('0'),
            ),
            SizedBox(
              width: 72,
              height: 56,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBackspace,
                  hoverColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: const Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      color: CozyTheme.textDark,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _keypadButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 74,
      height: 56,
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blushBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3728).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          splashColor: _mochaPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CozyTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _blushSurface,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: _mochaPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CozyTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  color: _warmCocoa,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInfoModal(BuildContext context, AppStrings strings) {
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
                    24,
                    14,
                    24,
                    bottomInset < 16 ? 34 : 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _blushBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
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
                              Icons.shield_rounded,
                              color: _mochaPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings.tr(
                                'Peraturan PIN & Privasi Profil',
                                'Profile PIN & Privacy Rules',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildInfoRow(
                        icon: Icons.lock_rounded,
                        title: strings.tr(
                          'Perlindungan PIN 4-Digit',
                          '4-Digit PIN Protection',
                        ),
                        body: strings.tr(
                          'Setiap profil dilindungi dengan PIN 4-digit untuk menjaga jurnal peribadi dan ruang refleksi setiap ahli.',
                          'Every profile is protected with a 4-digit PIN to keep personal journals and private reflections safe.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        icon: Icons.verified_user_rounded,
                        title: strings.tr(
                          'Akses Ibu Bapa vs. Ahli',
                          'Parent vs. Member Access',
                        ),
                        body: strings.tr(
                          'Profil Ibu Bapa mempunyai akses tambahan untuk mengurus sasaran keluarga, meluluskan aktiviti dan menuntut ganjaran.',
                          'Parent profiles can manage family goals, verify completed tasks, and claim family rewards.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        icon: Icons.family_restroom_rounded,
                        title: strings.tr(
                          'Hanya Keluarga Anda',
                          'Your Family Only',
                        ),
                        body: strings.tr(
                          'Hanya ahli yang berdaftar di bawah ID Keluarga ini sahaja yang akan dipaparkan di sini.',
                          'Only members registered under your Family ID appear on this screen.',
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _mochaPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            strings.tr('Faham', 'Got It'),
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
  }

  Widget _buildProfileCard(
    FamilyMember member,
    AppStrings strings,
    bool isCurrentActive,
  ) {
    final displayName = _localizedMemberName(member.name, strings);
    final subtitle = _localizedMemberSubtitle(member, strings);
    final isParent = member.isParentOrGuardian;

    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrentActive ? _mochaPrimary : _blushBorder,
          width: isCurrentActive ? 2 : 1.1,
        ),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _openPinPadForMember(member),
          hoverColor: Colors.transparent,
          splashColor: _mochaPrimary.withValues(alpha: 0.08),
          highlightColor: _mochaPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean unobstructed avatar artwork
                _buildAvatar(member, size: 78, emojiSize: 42),
                const SizedBox(height: 11),

              // Member Name (1 crisp line, never clipped awkwardly)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CozyTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Standardized 1-line Role / Stage + Age (Zero ellipsis truncation)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _warmCocoa,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Clear, legible PIN & Access badge (off the avatar artwork)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isParent ? _blushSurface : _linenSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isParent ? _blushBorder : _linenBorder,
                  ),
                ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (isParent ||
                                member.requiresPin ||
                                (member.pin ?? '').isNotEmpty)
                            ? Icons.lock_rounded
                            : Icons.verified_user_outlined,
                        size: 12,
                        color: isParent ? _mochaPrimary : _warmCocoa,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isParent
                            ? strings.tr('PIN Ibu Bapa', 'Parent PIN')
                            : ((member.requiresPin ||
                                    (member.pin ?? '').isNotEmpty)
                                ? strings.tr('Perlu PIN', 'PIN Required')
                                : strings.tr('Bimbingan Ibu Bapa', 'Parent-Guided')),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isParent ? _mochaPrimary : _warmCocoa,
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
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final family = appState.family;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Filter strictly: only members registered under this exact family ID appear (never mix demo fam_erat_01!)
    final familyMembers = appState.members
        .where((m) => m.familyId == family.id)
        .toList();

    return Scaffold(
      backgroundColor: CozyTheme.background,
      appBar: AppBar(
        backgroundColor: CozyTheme.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          strings.tr('Pilih Profil', 'Select Profile'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: CozyTheme.textDark,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: CozyTheme.textDark,
            size: 20,
          ),
          tooltip: strings.tr('Kembali', 'Back'),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(
                Icons.info_outline_rounded,
                color: _warmCocoa,
                size: 23,
              ),
              tooltip: strings.tr(
                'Peraturan PIN & Privasi',
                'PIN & Privacy Rules',
              ),
              onPressed: () => _showInfoModal(context, strings),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final horizontalPad = isTablet ? 32.0 : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 860 : double.infinity,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        2,
                        horizontalPad,
                        14,
                      ),
                      child: Text(
                        strings.tr(
                          'Pilih profil anda dan masukkan PIN 4-digit.',
                          'Choose your profile and enter your 4-digit PIN.',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _warmCocoa,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Expanded(
                      child: familyMembers.isEmpty
                          ? Center(
                              child: Text(
                                strings.tr(
                                  'Tiada ahli berdaftar untuk keluarga ini.',
                                  'No members registered for this family.',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _warmCocoa,
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPad,
                                4,
                                horizontalPad,
                                bottomInset + 34,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isTablet ? 3 : 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: isTablet ? 0.92 : 0.84,
                              ),
                              itemCount: familyMembers.length,
                              itemBuilder: (context, idx) {
                                final m = familyMembers[idx];
                                final isCurrentActive =
                                    m.id == appState.activeMemberId;
                                return _buildProfileCard(
                                  m,
                                  strings,
                                  isCurrentActive,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
