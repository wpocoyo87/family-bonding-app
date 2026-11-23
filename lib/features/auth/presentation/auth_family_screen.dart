import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../../core/theme/erat_palette.dart';

/// Controls whether the user is viewing the onboarding/login flow or main dashboard
final showOnboardingFlowProvider = StateProvider<bool>((ref) => true);

class AuthFamilyScreen extends ConsumerStatefulWidget {
  const AuthFamilyScreen({super.key});

  @override
  ConsumerState<AuthFamilyScreen> createState() => _AuthFamilyScreenState();
}

class _AuthFamilyScreenState extends ConsumerState<AuthFamilyScreen>
    with SingleTickerProviderStateMixin {
  // 0 = Splash/Welcome, 1 = Sign In / Sign Up, 2 = Create/Join Family + Theme Setup, 3 = Choose Experience
  int _step = 0;
  int _onboardingSlide = 0;
  final _pageController = PageController();

  bool _isPlayingVoiceSample = false;
  Timer? _voiceSampleTimer;
  final AudioPlayer _sampleVoicePlayer = AudioPlayer();
  StreamSubscription<void>? _sampleVoiceCompleteSub;
  late final AnimationController _waveformCtrl;

  bool _isLogin = true;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isJoinFamily = false;
  bool _isAuthLoading = false;
  bool _isStatusError = false;

  final _authScrollCtrl = ScrollController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _submitButtonKey = GlobalKey();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _familyNameCtrl = TextEditingController(text: 'Happy Family');
  final _inviteCodeCtrl = TextEditingController();
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _waveformCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _emailFocusNode.addListener(_onAuthFieldFocusChanged);
    _passwordFocusNode.addListener(_onAuthFieldFocusChanged);
    _confirmPasswordFocusNode.addListener(_onAuthFieldFocusChanged);
  }

  void _onAuthFieldFocusChanged() {
    final shouldLift = _passwordFocusNode.hasFocus ||
        _confirmPasswordFocusNode.hasFocus ||
        (!_isLogin && _emailFocusNode.hasFocus);
    if (shouldLift) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        final ctx = _submitButtonKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _voiceSampleTimer?.cancel();
    _sampleVoiceCompleteSub?.cancel();
    _sampleVoicePlayer.dispose();
    _waveformCtrl.dispose();
    _pageController.dispose();
    _authScrollCtrl.dispose();
    _emailFocusNode.removeListener(_onAuthFieldFocusChanged);
    _passwordFocusNode.removeListener(_onAuthFieldFocusChanged);
    _confirmPasswordFocusNode.removeListener(_onAuthFieldFocusChanged);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _familyNameCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  void _stopVoiceSample() {
    _voiceSampleTimer?.cancel();
    _voiceSampleTimer = null;
    _sampleVoiceCompleteSub?.cancel();
    _sampleVoiceCompleteSub = null;
    _sampleVoicePlayer.stop();
    if (_isPlayingVoiceSample) {
      _waveformCtrl.stop();
      setState(() => _isPlayingVoiceSample = false);
    }
  }

  Future<void> _toggleVoiceSample() async {
    HapticFeedback.lightImpact();
    if (_isPlayingVoiceSample) {
      _stopVoiceSample();
      return;
    }
    _voiceSampleTimer?.cancel();
    await _sampleVoiceCompleteSub?.cancel();
    setState(() => _isPlayingVoiceSample = true);
    _waveformCtrl.repeat(reverse: true);
    _sampleVoiceCompleteSub = _sampleVoicePlayer.onPlayerComplete.listen((_) {
      if (mounted) _stopVoiceSample();
    });
    try {
      await _sampleVoicePlayer.play(
        AssetSource('audio/love_you_mom_dad.m4a'),
      );
    } catch (_) {
      // Fallback visual timer if audio playback fails on web/headless
    }
    _voiceSampleTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlayingVoiceSample) {
        _stopVoiceSample();
      }
    });
  }

  Future<void> _finishOnboarding() async {
    final controller = ref.read(eratControllerProvider.notifier);
    if (_isJoinFamily && _inviteCodeCtrl.text.trim().isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await controller.joinFamilyByInviteCode(
          uid: user.uid,
          email: user.email ?? _emailCtrl.text.trim(),
          displayName: user.displayName ?? _nameCtrl.text.trim(),
          inviteCode: _inviteCodeCtrl.text.trim(),
        );
      }
    } else if (!_isJoinFamily && _familyNameCtrl.text.trim().isNotEmpty) {
      controller.updateFamilyName(_familyNameCtrl.text.trim());
    }
    if (!mounted) return;
    // Land on Display Mode Selection (Family View vs Individual View) first
    ref.read(appViewModeProvider.notifier).state = AppViewMode.selection;
    ref.read(isPrivateSpaceUnlockedProvider.notifier).state = false;
    ref.read(showOnboardingFlowProvider.notifier).state = false;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _mapAuthError(FirebaseAuthException e, AppStrings strings) {
    switch (e.code) {
      case 'invalid-email':
        return strings.tr(
          'Format emel tidak sah. Sila semak semula.',
          'Invalid email format. Please check and try again.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return strings.tr(
          'Emel atau kata laluan tidak tepat. Sila cuba lagi.',
          'Incorrect email or password. Please try again.',
        );
      case 'email-already-in-use':
        return strings.tr(
          'Emel ini telah didaftarkan. Sila log masuk.',
          'This email is already registered. Please sign in.',
        );
      case 'weak-password':
        return strings.tr(
          'Kata laluan terlalu lemah. Gunakan sekurang-kurangnya 6 aksara.',
          'Password is too weak. Use at least 6 characters.',
        );
      case 'network-request-failed':
        return strings.tr(
          'Tiada sambungan internet. Sila semak rangkaian anda.',
          'Network error. Please check your internet connection.',
        );
      default:
        return e.message ??
            strings.tr(
              'Pengesahan gagal. Sila cuba sebentar lagi.',
              'Authentication failed. Please try again.',
            );
    }
  }

  Future<void> _handleForgotPassword(AppStrings strings) async {
    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Sila masukkan emel yang sah terlebih dahulu untuk set semula kata laluan.',
          'Please enter a valid email address first to reset your password.',
        );
      });
      return;
    }

    final isFirebaseReady = ref.read(firebaseConnectedProvider);
    if (isFirebaseReady) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _isStatusError = true;
          _statusMsg = _mapAuthError(e, strings);
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isStatusError = false;
      _statusMsg = strings.tr(
        'Pautan tetapan semula kata laluan telah dihantar ke $email.',
        'A password reset link has been sent to $email.',
      );
    });
  }

  Future<void> _handleSignInOrSignUp(AppStrings strings) async {
    if (_isAuthLoading) return;

    final isFirebaseReady = ref.read(firebaseConnectedProvider);
    final name = _nameCtrl.text.trim();
    final familyName = _familyNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    // Clear inline validation before calling Firebase
    if (!_isLogin && name.isEmpty) {
      setState(() {
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Sila masukkan nama anda.',
          'Please enter your name.',
        );
      });
      return;
    }
    if (!_isLogin && familyName.isEmpty) {
      setState(() {
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Sila masukkan nama keluarga anda.',
          'Please enter your family name.',
        );
      });
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Sila masukkan alamat emel yang sah (contoh: ibu@family.com).',
          'Please enter a valid email address (e.g. mom@family.com).',
        );
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Kata laluan mestilah sekurang-kurangnya 6 aksara.',
          'Password must be at least 6 characters.',
        );
      });
      return;
    }
    if (!_isLogin && password != confirmPassword) {
      setState(() {
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Pengesahan kata laluan tidak sepadan.',
          'Passwords do not match.',
        );
      });
      return;
    }

    setState(() {
      _isAuthLoading = true;
      _statusMsg = null;
      _isStatusError = false;
    });

    try {
      final controller = ref.read(eratControllerProvider.notifier);

      if (isFirebaseReady) {
        if (_isLogin) {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = cred.user?.uid;
          if (uid != null) {
            final hasExistingFamily =
                await controller.loadUserAndFamilyFromFirestore(
              uid: uid,
              email: email,
              fallbackDisplayName: cred.user?.displayName,
            );
            if (!mounted) return;
            setState(() => _isAuthLoading = false);
            if (hasExistingFamily) {
              _finishOnboarding();
              return;
            }
          }
        } else {
          final cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
          await cred.user?.updateDisplayName(name);
          final uid = cred.user?.uid;
          if (uid != null) {
            await controller.registerUserAndFamily(
              uid: uid,
              email: email,
              displayName: name,
              familyName: familyName,
            );
          }
        }
      } else {
        // Offline / local fallback still creates & stores user + family state cleanly
        if (!_isLogin) {
          await controller.registerUserAndFamily(
            uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            displayName: name,
            familyName: familyName,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _isAuthLoading = false;
        _step = 2;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthLoading = false;
        _isStatusError = true;
        _statusMsg = _mapAuthError(e, strings);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthLoading = false;
        _isStatusError = true;
        _statusMsg = strings.tr(
          'Gagal menyimpan data ke Firebase. Sila cuba lagi.',
          'Could not save data to Firebase. Please try again.',
        );
      });
    }
  }

  void _showGoogleDemoBottomSheet(BuildContext context, AppStrings strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomSafeInset = MediaQuery.viewPaddingOf(ctx).bottom;
        final extraBottom =
            bottomSafeInset >= 34.0 ? 12.0 : (34.0 - bottomSafeInset);

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: CozyTheme.border, width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(30, 22, 18, 0.18),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 22, extraBottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tactile Top Drag Handle Pill
                  Center(
                    child: ExcludeSemantics(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: CozyTheme.connectorDot.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sheet Header: ERAT Logo + Title + Explicit 44x44 Close Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const EratBrandLogo(size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.tr(
                                'Cuba Mod Demo',
                                'Try Demo Mode',
                              ),
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.tr(
                                'Teroka tanpa daftar akaun',
                                'Explore without signing up',
                              ),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: CozyTheme.textMedium,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        tooltip: strings.tr('Tutup', 'Close'),
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: CozyTheme.pillBackground,
                            shape: BoxShape.circle,
                            border: Border.all(color: CozyTheme.border),
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
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: CozyTheme.border),
                  const SizedBox(height: 16),

                  // Quick Demo Access Mode Card -> Opens Display Mode Selection first
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        await ref
                            .read(eratControllerProvider.notifier)
                            .enterDemoMode();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.tr(
                                'Mod Demo Pantas diaktifkan! Pilih mod paparan anda.',
                                'Quick Demo Mode activated! Choose your display mode.',
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: CozyTheme.textDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        _finishOnboarding();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF6D4C41),
                            width: 1.4,
                          ),
                          boxShadow: CozyTheme.cardShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6D4C41),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.bolt_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.tr(
                                      'Mula Demo Pantas',
                                      'Start Quick Demo',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    strings.tr(
                                      'Paparan Keluarga & Peribadi',
                                      'Family & Individual view',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF5A463C),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: Color(0xFF6D4C41),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      strings.tr(
                        'Data contoh sahaja • Tiada akaun dicipta',
                        'Sample data only • No account created',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5A463C),
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

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: CozyTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600.0;
            final double maxContentWidth = !isTablet
                ? double.infinity
                : switch (_step) {
                    0 => 620.0, // Onboarding Carousel (Balanced iPad width)
                    1 => 500.0, // Sign In / Sign Up Form (Optimal readable form width)
                    _ => 560.0, // Family Setup Steps
                  };

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: switch (_step) {
                    0 => _buildSplashWelcomeStep(strings),
                    1 => _buildSignInStep(strings),
                    2 => _buildCreateOrJoinFamilyStep(strings),
                    _ => _buildChooseExperienceStep(strings),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEratLogo({double size = 64}) {
    return EratBrandLogo(size: size);
  }

  Widget _buildLanguageTogglePill(AppStrings strings) {
    final currentLang = ref.watch(appLanguageProvider);
    return Semantics(
      button: true,
      label: strings.tr('Tukar bahasa', 'Switch language'),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(appLanguageProvider.notifier).state =
              currentLang == AppLanguage.en ? AppLanguage.ms : AppLanguage.en;
        },
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: CozyTheme.pillBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: CozyTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 15,
                    color: CozyTheme.textMedium,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    currentLang == AppLanguage.en ? 'EN' : 'BM',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: CozyTheme.textDark,
                      letterSpacing: 0.4,
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

  Widget _buildVoiceSamplePill(AppStrings strings) {
    const barBaseHeights = [6.0, 12.0, 16.0, 10.0, 14.0, 8.0, 13.0, 7.0];
    return Semantics(
      button: true,
      label: _isPlayingVoiceSample
          ? strings.tr(
              'Sedang memainkan contoh nota suara',
              'Playing sample voice note',
            )
          : strings.tr(
              'Mainkan contoh nota suara 2 saat',
              'Play 2-second sample voice note',
            ),
      child: InkWell(
        onTap: _toggleVoiceSample,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _isPlayingVoiceSample
                ? CozyTheme.pillBackgroundCompleted
                : CozyTheme.pillBackgroundWarm,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPlayingVoiceSample
                  ? CozyTheme.borderCompleted
                  : CozyTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isPlayingVoiceSample
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_fill_rounded,
                size: 20,
                color: const Color(0xFF6D4C41),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _waveformCtrl,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(barBaseHeights.length, (i) {
                      final phase = (_waveformCtrl.value + (i * 0.14)) % 1.0;
                      final wave = _isPlayingVoiceSample
                          ? (0.45 + 0.55 * (1.0 - (2.0 * phase - 1.0).abs()))
                          : 0.65;
                      return Container(
                        width: 2.5,
                        height: barBaseHeights[i] * wave,
                        margin: const EdgeInsets.symmetric(horizontal: 1.4),
                        decoration: BoxDecoration(
                          color: _isPlayingVoiceSample
                              ? const Color(0xFF6D4C41)
                              : CozyTheme.connectorDot,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isPlayingVoiceSample
                      ? strings.tr(
                          '"Sayang Ibu & Ayah!" 0:02',
                          '"Love you Mom & Dad!" 0:02',
                        )
                      : strings.tr(
                          'Dengar contoh nota (0:02)',
                          'Play sample note (0:02)',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CozyTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 0: START ONBOARDING PAGE (APP-001 — COZY MINIMALIST APP STORE UI)
  // =========================================================================
  Widget _buildSplashWelcomeStep(AppStrings strings) {
    // 4 dedicated, distinct onboarding slides strictly synced with 4 pagination dots
    final slides = [
      (
        icon: Icons.home_rounded,
        tag: strings.tr('Ikatan Harian', 'Daily Family Bonding'),
        title: strings.tr(
          'Momen Bermakna Bersama',
          'Meaningful Moments Together',
        ),
        subtitle: strings.tr(
          'Aktiviti 10 minit tanpa gajet setiap hari untuk eratkan kasih sayang.',
          '10-minute gadget-free moments every day to deepen family love.',
        ),
        image: 'assets/images/mode_family_cozy.jpg',
        hasVoiceSample: false,
      ),
      (
        icon: Icons.mic_rounded,
        tag: strings.tr('Diari Suara', 'Voice Journal'),
        title: strings.tr(
          'Sembang & Nota Suara Selamat',
          'Safe Chat & Voice Notes',
        ),
        subtitle: strings.tr(
          'Ruang hangat untuk anak meluahkan perasaan dan kenangan harian.',
          'A warm sanctuary for kids to share feelings with one-tap voice notes.',
        ),
        image: 'assets/images/carousel_chat_cozy.jpg',
        hasVoiceSample: true,
      ),
      (
        icon: Icons.star_rounded,
        tag: strings.tr('Tabiat & Bintang', 'Family Habits & Star Goals'),
        title: strings.tr(
          'Tabiat Positif & Impian Bersama',
          'Wholesome Habits & Star Goals',
        ),
        subtitle: strings.tr(
          'Bina rutin harian tanpa tekanan dan kumpul bintang untuk ganjaran keluarga.',
          'Build stress-free daily routines and pool stars toward shared family dreams.',
        ),
        image: 'assets/images/family_task_cozy.jpg',
        hasVoiceSample: false,
      ),
      (
        icon: Icons.spa_rounded,
        tag: strings.tr('Adaptasi Umur', 'Adaptive by Age'),
        title: strings.tr(
          'Sesuai Untuk Setiap Peringkat',
          'Tailored for Every Stage',
        ),
        subtitle: strings.tr(
          'Paparan berevolusi automatik dari anak kecil hingga remaja & ibu bapa.',
          'Evolves automatically from toddlers to growing teens and parents.',
        ),
        image: 'assets/images/carousel_age_cozy.jpg',
        hasVoiceSample: false,
      ),
    ];

    final currentSlide = _onboardingSlide.clamp(0, slides.length - 1);
    final isLastSlide = currentSlide == slides.length - 1;
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    // SafeArea already applies bottomSafeInset (34 pt on iPhone 13-16);
    // top up if smaller so total clearance below Sign In is always >= 34 pt.
    final extraBottomInset =
        bottomSafeInset >= 34.0 ? 0.0 : (34.0 - bottomSafeInset);

    return PopScope(
      // Prevent iOS edge-swipe back navigation from clashing with horizontal carousel swipes
      canPop: false,
      child: Padding(
        key: const ValueKey('step_welcome_cozy_carousel'),
        padding: EdgeInsets.fromLTRB(22, 6, 22, extraBottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Bar: Skip Affordance (left, >= 44x44 pt hit area) + Language Switcher Pill (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isLastSlide)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _stopVoiceSample();
                        setState(() => _step = 1);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        tapTargetSize: MaterialTapTargetSize.padded,
                        foregroundColor: CozyTheme.textMuted,
                      ),
                      child: Text(
                        strings.tr('Langkau', 'Skip'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CozyTheme.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 44, height: 44),
                _buildLanguageTogglePill(strings),
              ],
            ),

            // Official ERAT Brand Logo (Cozy Mocha & Honey-Gold Theme)
            _buildEratLogo(size: 58),
            const SizedBox(height: 4),
            Text(
              strings.tr(
                'membesar bersama, disayangi selamanya',
                'grow together, cherish forever',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CozyTheme.textMuted,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 12),

            // Onboarding Carousel Card (Momentum-based snapping + Expanded for Dynamic Type)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                pageSnapping: true,
                physics: const PageScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                onPageChanged: (i) {
                  HapticFeedback.lightImpact();
                  _stopVoiceSample();
                  setState(() => _onboardingSlide = i);
                },
                itemBuilder: (ctx, index) {
                  final slide = slides[index];
                  final voiceOverSummary = strings.tr(
                    '${slide.tag}. ${slide.title}. ${slide.subtitle} Halaman ${index + 1} daripada ${slides.length}.',
                    '${slide.tag}. ${slide.title}. ${slide.subtitle} Page ${index + 1} of ${slides.length}.',
                  );

                  return GestureDetector(
                    key: ValueKey('onboarding_slide_$index'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _stopVoiceSample();
                      if (index < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        setState(() => _step = 1);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: CozyTheme.border,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(60, 40, 20, 0.05),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Purely Decorative Illustration: proportional scaleAspectFit for iPhone SE & Dynamic Type
                          Expanded(
                            child: ExcludeSemantics(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  width: double.infinity,
                                  color: CozyTheme.background,
                                  child: Image.asset(
                                    slide.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Grouped VoiceOver Card Copy (Tag + Title + Subtitle + Page X of Y)
                          Semantics(
                            container: true,
                            excludeSemantics: true,
                            label: voiceOverSummary,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Consistent Fixed-Height Top Tag Pill (28 pt across all 4 slides)
                                Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CozyTheme.pillBackground,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: CozyTheme.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        slide.icon,
                                        size: 14,
                                        color: CozyTheme.badgeCompleted,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          slide.tag,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: CozyTheme.textMedium,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Short, Punchy Title (Scales with Dynamic Type)
                                Text(
                                  slide.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                    color: CozyTheme.textDark,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Tight Value Statement (Scales with Dynamic Type)
                                Text(
                                  slide.subtitle,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: CozyTheme.textMedium,
                                    height: 1.38,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Interactive Audio Waveform Preview on Voice Journal slide
                          if (slide.hasVoiceSample) ...[
                            const SizedBox(height: 10),
                            _buildVoiceSamplePill(strings),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Tappable Pagination Indicators (4 Steps — Strictly Synced with slides.length)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == currentSlide;
                return Semantics(
                  button: true,
                  selected: active,
                  label: strings.tr(
                    'Pergi ke halaman ${i + 1} daripada ${slides.length}',
                    'Go to page ${i + 1} of ${slides.length}',
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _stopVoiceSample();
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 12,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF6D4C41)
                              : CozyTheme.connectorLine,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Primary CTA: "Continue" on Slides 1-3, "Get Started" on Final Slide (Slide 4)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: 56,
              ),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _stopVoiceSample();
                  if (!isLastSlide) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    setState(() => _step = 1);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6D4C41), // WCAG AAA (7.25:1)
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Row(
                    key: ValueKey('cta_last_$isLastSlide'),
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isLastSlide
                              ? strings.tr('Mulakan', 'Get Started')
                              : strings.tr('Teruskan', 'Continue'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Secondary CTA (Minimum 48x48 pt tap area, >= 34 pt bottom safe area inset)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _stopVoiceSample();
                setState(() {
                  _isLogin = true;
                  _step = 1;
                });
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: CozyTheme.textMuted,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: strings.tr(
                        'Sudah ada akaun? ',
                        'Already have an account? ',
                      ),
                    ),
                    TextSpan(
                      text: strings.tr('Log Masuk ', 'Sign In '),
                      style: const TextStyle(
                        color: CozyTheme.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 16,
                        color: CozyTheme.badgeCompleted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // STEP 1: SIGN IN / SIGN UP (APP-002 — FIREBASE AUTH + FIRESTORE + HIG POLISH)
  // =========================================================================
  Widget _buildAuthTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    EdgeInsets scrollPadding = const EdgeInsets.only(bottom: 120),
    Widget? suffixIcon,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CozyTheme.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(60, 40, 20, 0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        obscureText: obscureText,
        scrollPadding: scrollPadding,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 15,
          color: CozyTheme.textDark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8C7A70),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              prefixIcon,
              color: CozyTheme.connectorDot,
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInStep(AppStrings strings) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    final extraBottomInset =
        bottomSafeInset >= 34.0 ? 0.0 : (34.0 - bottomSafeInset);

    void switchAuthMode(bool toLogin) {
      if (_isLogin == toLogin) return;
      HapticFeedback.selectionClick();
      setState(() {
        _isLogin = toLogin;
        _statusMsg = null;
        _isStatusError = false;
      });
    }

    return LayoutBuilder(
      key: const ValueKey('step_signin_cozy'),
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _authScrollCtrl,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            keyboardInset + extraBottomInset + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight -
                      keyboardInset -
                      extraBottomInset -
                      24)
                  .clamp(0.0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Back Button (only when a previous step/route exists) + Language Switcher Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_step > 0 || Navigator.of(context).canPop())
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (_step > 0) {
                            setState(() => _step = 0);
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        constraints:
                            const BoxConstraints(minWidth: 44, minHeight: 44),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: CozyTheme.textDark,
                        ),
                      )
                    else
                      const SizedBox(width: 44, height: 44),
                    _buildLanguageTogglePill(strings),
                  ],
                ),

                // Main Centered Auth Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ERAT Brand Logo + Smoothly Animated Title Header
                      Center(
                        child: Column(
                          children: [
                            _buildEratLogo(size: 72),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) {
                                final offsetAnim = Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offsetAnim,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey('auth_header_$_isLogin'),
                                children: [
                                  Text(
                                    _isLogin
                                        ? strings.tr(
                                            'Selamat Kembali',
                                            'Welcome Back',
                                          )
                                        : strings.tr(
                                            'Daftar Akaun Baru',
                                            'Create Family Account',
                                          ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      color: CozyTheme.textDark,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isLogin
                                        ? strings.tr(
                                            'Langkah kecil untuk keluarga bahagia',
                                            'Small steps toward a happier family',
                                          )
                                        : strings.tr(
                                            'Simpan profil dan ruang keluarga anda dengan selamat',
                                            'Save your profile and family space securely in the cloud',
                                          ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: CozyTheme.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // High-Contrast Segmented Pill Toggle (Unmistakable Active State, >= 44pt height)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CozyTheme.pillBackground,
                          borderRadius: BorderRadius.circular(26),
                          border:
                              Border.all(color: CozyTheme.border, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                button: true,
                                selected: _isLogin,
                                child: InkWell(
                                  onTap: () => switchAuthMode(true),
                                  borderRadius: BorderRadius.circular(22),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    constraints:
                                        const BoxConstraints(minHeight: 44),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _isLogin
                                          ? const Color(0xFF6D4C41)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: _isLogin
                                          ? const [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                  60,
                                                  40,
                                                  20,
                                                  0.14,
                                                ),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      strings.tr('Log Masuk', 'Sign In'),
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: _isLogin
                                            ? Colors.white
                                            : CozyTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Semantics(
                                button: true,
                                selected: !_isLogin,
                                child: InkWell(
                                  onTap: () => switchAuthMode(false),
                                  borderRadius: BorderRadius.circular(22),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    constraints:
                                        const BoxConstraints(minHeight: 44),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: !_isLogin
                                          ? const Color(0xFF6D4C41)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: !_isLogin
                                          ? const [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                  60,
                                                  40,
                                                  20,
                                                  0.14,
                                                ),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      strings.tr('Daftar', 'Sign Up'),
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: !_isLogin
                                            ? Colors.white
                                            : CozyTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign-Up Exclusive Fields (Name + Family Name) with smooth fade + slide + size transition
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, -0.06),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: !_isLogin
                              ? Column(
                                  key: const ValueKey('signup_top_fields'),
                                  children: [
                                    _buildAuthTextField(
                                      controller: _nameCtrl,
                                      hintText: strings.tr(
                                        'Nama Anda (contoh: Sarah)',
                                        'Your Name (e.g. Sarah)',
                                      ),
                                      prefixIcon: Icons.person_outline_rounded,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAuthTextField(
                                      controller: _familyNameCtrl,
                                      hintText: strings.tr(
                                        'Nama Keluarga (contoh: Keluarga Ahmad)',
                                        'Family Name (e.g. Ahmad Family)',
                                      ),
                                      prefixIcon: Icons.home_outlined,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('signup_top_empty'),
                                ),
                        ),
                      ),

                      // Email Input (Consistent lowercase placeholder matching real email validation)
                      _buildAuthTextField(
                        controller: _emailCtrl,
                        focusNode: _emailFocusNode,
                        hintText: strings.tr(
                          'Emel (contoh: ibu@family.com)',
                          'Email (e.g. mom@family.com)',
                        ),
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      // Password Input (Generous padding + 44x44 eye toggle + keyboard lift)
                      _buildAuthTextField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocusNode,
                        hintText: _isLogin
                            ? strings.tr('Kata Laluan', 'Password')
                            : strings.tr(
                                'Kata Laluan (min. 6 aksara)',
                                'Password (min. 6 characters)',
                              ),
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        scrollPadding: const EdgeInsets.only(bottom: 160),
                        textInputAction: _isLogin
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: _isLogin
                            ? (_) => _handleSignInOrSignUp(strings)
                            : null,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          tooltip: _obscurePassword
                              ? strings.tr(
                                  'Tunjuk kata laluan',
                                  'Show password',
                                )
                              : strings.tr(
                                  'Sembunyi kata laluan',
                                  'Hide password',
                                ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: CozyTheme.textMedium,
                            size: 20,
                          ),
                        ),
                      ),

                      // Confirm Password (Sign Up only) with smooth fade + slide + size transition
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, -0.06),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: !_isLogin
                              ? Padding(
                                  key: const ValueKey('signup_confirm_field'),
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _buildAuthTextField(
                                    controller: _confirmPasswordCtrl,
                                    focusNode: _confirmPasswordFocusNode,
                                    hintText: strings.tr(
                                      'Sahkan Kata Laluan',
                                      'Confirm Password',
                                    ),
                                    prefixIcon: Icons.verified_user_outlined,
                                    obscureText: _obscureConfirmPassword,
                                    scrollPadding:
                                        const EdgeInsets.only(bottom: 180),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) =>
                                        _handleSignInOrSignUp(strings),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: CozyTheme.textMedium,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('signup_confirm_empty'),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Remember Me + Forgot Password (High contrast, >= 44x44 pt Apple HIG hit areas)
                      if (_isLogin)
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(
                                  () => _rememberMe = !_rememberMe,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor:
                                                const Color(0xFF6D4C41),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            onChanged: (v) => setState(
                                              () => _rememberMe = v ?? true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          strings.tr(
                                            'Ingat saya',
                                            'Remember me',
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
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _handleForgotPassword(strings),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              child: Text(
                                strings.tr(
                                  'Lupa kata laluan?',
                                  'Forgot password?',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6D4C41),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (_statusMsg != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _isStatusError
                                ? const Color(0xFFFEF2F2)
                                : CozyTheme.pillBackgroundWarm,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isStatusError
                                  ? const Color(0xFFFCA5A5)
                                  : CozyTheme.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _isStatusError
                                    ? Icons.error_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 18,
                                color: _isStatusError
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF6D4C41),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMsg!,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: _isStatusError
                                        ? const Color(0xFF991B1B)
                                        : CozyTheme.textDark,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Main Submit Button (WCAG AAA contrast + loading spinner + keyboard ensureVisible key)
                      ConstrainedBox(
                        key: _submitButtonKey,
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 54,
                        ),
                        child: ElevatedButton(
                          onPressed: _isAuthLoading
                              ? null
                              : () => _handleSignInOrSignUp(strings),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D4C41),
                            disabledBackgroundColor:
                                const Color(0xFF6D4C41).withValues(alpha: 0.65),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          child: _isAuthLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Row(
                                    key: ValueKey('auth_cta_$_isLogin'),
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin
                                            ? strings.tr('Log Masuk', 'Sign In')
                                            : strings.tr(
                                                'Daftar Akaun',
                                                'Create Account',
                                              ),
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      // Symmetrical Divider (18px above & 18px below)
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: CozyTheme.border, thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              strings.tr('atau', 'or'),
                              style: const TextStyle(
                                color: CozyTheme.textMedium,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: CozyTheme.border, thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Demo Account Button (Reliable no-login-wall access for App Store reviewers)
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 50,
                        ),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: CozyTheme.border,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showGoogleDemoBottomSheet(context, strings);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 20,
                                color: CozyTheme.badgeCompleted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                strings.tr(
                                  'Cuba Mod Demo Pantas',
                                  'Try Quick Demo Mode',
                                ),
                                style: const TextStyle(
                                  color: CozyTheme.textDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Anchored Bottom Prompt + Trust Footer
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => switchAuthMode(!_isLogin),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: CozyTheme.textMedium,
                              height: 1.3,
                            ),
                            children: [
                              TextSpan(
                                text: _isLogin
                                    ? strings.tr(
                                        'Belum ada akaun keluarga? ',
                                        'Don\'t have a family account? ',
                                      )
                                    : strings.tr(
                                        'Sudah ada akaun keluarga? ',
                                        'Already have a family account? ',
                                      ),
                              ),
                              TextSpan(
                                text: _isLogin
                                    ? strings.tr(
                                        'Daftar Sekarang',
                                        'Sign Up Now',
                                      )
                                    : strings.tr('Log Masuk', 'Sign In'),
                                style: const TextStyle(
                                  color: Color(0xFF6D4C41),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: CozyTheme.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            strings.tr(
                              'Peribadi & selamat untuk seisi keluarga',
                              'Private & secure for your whole family',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: CozyTheme.textMuted,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  // =========================================================================
  // STEP 2: SETUP FAMILY (COZY MINIMALIST STYLE)
  // =========================================================================
  Widget _buildCreateOrJoinFamilyStep(AppStrings strings) {
    final selectedTheme = ref.watch(selectedWorldThemeProvider);

    return SingleChildScrollView(
      key: const ValueKey('step_create_family_cozy'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => setState(() => _step = 1),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: CozyTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Column(
              children: [
                Text(
                  'Ruang Keluarga Anda 🏡',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: CozyTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cipta ruang santai atau sertai dengan kod jemputan',
                  style: TextStyle(
                    fontSize: 13,
                    color: CozyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Custom Segmented Pill Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: CozyTheme.pillBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CozyTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isJoinFamily = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isJoinFamily ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: !_isJoinFamily ? CozyTheme.softShadow : null,
                      ),
                      child: Text(
                        'Cipta Keluarga',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: !_isJoinFamily
                              ? CozyTheme.textDark
                              : CozyTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isJoinFamily = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isJoinFamily ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isJoinFamily ? CozyTheme.softShadow : null,
                      ),
                      child: Text(
                        'Guna Kod Jemputan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _isJoinFamily
                              ? CozyTheme.textDark
                              : CozyTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Soft Border Input Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CozyTheme.border, width: 1.2),
              boxShadow: CozyTheme.cardShadow,
            ),
            child: TextField(
              controller: _isJoinFamily ? _inviteCodeCtrl : _familyNameCtrl,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: CozyTheme.textDark,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: _isJoinFamily
                    ? 'Masukkan Kod Jemputan (cth: ERAT-48H)'
                    : 'Nama Keluarga (cth: Happy Family)',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFA59286),
                ),
                prefixIcon: Icon(
                  _isJoinFamily ? Icons.qr_code_rounded : Icons.home_rounded,
                  color: CozyTheme.connectorDot,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Theme Selection
          const Text(
            'Pilih Suasana Warna Tema 🎨',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: CozyTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sesuaikan tema visual yang disukai keluarga anda',
            style: TextStyle(
              fontSize: 12,
              color: CozyTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: EratWorldTheme.values.map((theme) {
              final isSelected = theme == selectedTheme;
              return GestureDetector(
                onTap: () {
                  ref.read(selectedWorldThemeProvider.notifier).state = theme;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? CozyTheme.pillBackground : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? CozyTheme.connectorDot
                          : CozyTheme.border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: CozyTheme.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Text(theme.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          theme.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? CozyTheme.textDark
                                : CozyTheme.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.connectorDot,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Seterusnya ➔',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 3: CHOOSE PROFILE EXPERIENCE (COZY MINIMALIST STYLE)
  // =========================================================================
  Widget _buildChooseExperienceStep(AppStrings strings) {
    final appState = ref.watch(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);

    return SingleChildScrollView(
      key: const ValueKey('step_choose_experience_cozy'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => setState(() => _step = 2),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: CozyTheme.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Column(
              children: [
                Text(
                  'Pilih Profil Ahli 🌸',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: CozyTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Setiap paparan disesuaikan mengikut peringkat umur',
                  style: TextStyle(
                    fontSize: 13,
                    color: CozyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: appState.members.map((m) {
              final selected = m.id == appState.activeMemberId;
              final roleSubtitle = m.isParentOrGuardian
                  ? 'Ibu Bapa'
                  : 'Umur ${m.ageYears} • ${m.ageBand.shortTitle}';

              return GestureDetector(
                onTap: () => controller.switchProfile(m.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? CozyTheme.pillBackground : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? CozyTheme.connectorDot
                          : CozyTheme.border,
                      width: selected ? 2.0 : 1.0,
                    ),
                    boxShadow: CozyTheme.cardShadow,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : CozyTheme.pillBackgroundWarm,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          m.avatarEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? CozyTheme.textDark
                              : CozyTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        roleSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CozyTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 26),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _finishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: CozyTheme.connectorDot,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Masuk Dashboard Utama ➔',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
