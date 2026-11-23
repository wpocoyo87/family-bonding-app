import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';

class FamilyStarGoalScreen extends ConsumerStatefulWidget {
  const FamilyStarGoalScreen({super.key});

  @override
  ConsumerState<FamilyStarGoalScreen> createState() =>
      _FamilyStarGoalScreenState();
}

class _FamilyStarGoalScreenState extends ConsumerState<FamilyStarGoalScreen> {
  FamilyGoalStatus _selectedGoalTab = FamilyGoalStatus.active;

  /// Exact localized role label for parents, co-parents & caregivers.
  static String _localizedGuardianRole(
    FamilyMember member,
    AppStrings strings,
  ) {
    return switch (member.role) {
      MemberRole.owner => strings.tr('Ibu Bapa', 'Parent'),
      MemberRole.coparent => strings.tr('Co-Parent', 'Co-Parent'),
      MemberRole.caregiver => strings.tr('Penjaga', 'Caregiver'),
      _ => strings.tr('Ibu Bapa', 'Parent'),
    };
  }

  /// Concise, 100% localized 1-line role/stage + age label that never truncates on mobile cards.
  static String _localizedMemberSubtitle(
    FamilyMember member,
    AppStrings strings,
  ) {
    if (member.isParentOrGuardian) {
      return _localizedGuardianRole(member, strings);
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

  static String _localizedBadgeCount(int count, AppStrings strings) {
    if (strings.isMs) return '$count Lencana';
    return '$count ${count == 1 ? 'Badge' : 'Badges'}';
  }

  /// Parent PIN gate so only Parents/Guardians can create or modify Family Star Goals
  void _requireParentPin({
    required BuildContext context,
    required List<FamilyMember> guardians,
    required AppStrings strings,
    required String actionLabel,
    required VoidCallback onAuthorized,
  }) {
    final pinCtrl = TextEditingController();
    final validPins = guardians
        .map((g) => (g.pin != null && g.pin!.isNotEmpty) ? g.pin! : '1234')
        .toSet();
    if (validPins.isEmpty) validPins.add('1234');
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
                      strings.tr('Pengesahan Ibu Bapa', 'Parent PIN Required'),
                      style: const TextStyle(
                        fontSize: 17,
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
                      'Hanya ibu bapa/penjaga boleh $actionLabel. Masukkan PIN 4-digit ibu bapa:',
                      'Only parents/caregivers can $actionLabel. Enter 4-digit Parent PIN:',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A463C),
                      height: 1.4,
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
                    if (!validPins.contains(pinCtrl.text.trim())) {
                      HapticFeedback.heavyImpact();
                      setDialogState(() {
                        errorMsg = strings.tr(
                          'PIN Ibu Bapa tidak sah.',
                          'Incorrect Parent PIN.',
                        );
                      });
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    Navigator.of(dialogCtx).pop();
                    onAuthorized();
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
                    strings.tr('Teruskan', 'Continue'),
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

  /// Parent PIN confirmation before marking a reached Family Goal as Claimed
  void _showClaimRewardPinDialog({
    required BuildContext context,
    required FamilyRewardGoal goal,
    required List<FamilyMember> guardians,
    required AppStrings strings,
  }) {
    final pinCtrl = TextEditingController();
    final goalTitle = strings.isMs ? goal.titleMs : goal.titleEn;
    final validPins = guardians
        .map((g) => (g.pin != null && g.pin!.isNotEmpty) ? g.pin! : '1234')
        .toSet();
    if (validPins.isEmpty) validPins.add('1234');
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
                    Icons.card_giftcard_rounded,
                    size: 22,
                    color: Color(0xFF6D4C41),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strings.tr('Tebus Ganjaran Keluarga', 'Claim Family Reward'),
                      style: const TextStyle(
                        fontSize: 17,
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
                      'Masukkan PIN Ibu Bapa untuk sahkan tebusan "$goalTitle". Bintang akan dimulakan semula untuk matlamat seterusnya.',
                      'Enter Parent PIN to claim "$goalTitle". Stars will reset for the next family goal.',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A463C),
                      height: 1.4,
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
                    if (!validPins.contains(pinCtrl.text.trim())) {
                      HapticFeedback.heavyImpact();
                      setDialogState(() {
                        errorMsg = strings.tr(
                          'PIN Ibu Bapa tidak sah.',
                          'Incorrect Parent PIN.',
                        );
                      });
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    ref
                        .read(eratControllerProvider.notifier)
                        .claimFamilyRewardGoal(goal.id);
                    Navigator.of(dialogCtx).pop();
                    setState(() => _selectedGoalTab = FamilyGoalStatus.claimed);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF6D4C41),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        content: Text(
                          strings.tr(
                            'Tahniah! "$goalTitle" telah ditebus bersama!',
                            'Yay! "$goalTitle" has been claimed together!',
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    strings.tr('Tebus ✓', 'Claim ✓'),
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

  /// Create New Shared Family Goal Modal (Title + Target Stars + Capture/Upload Reward Photo)
  void _showCreateFamilyGoalModal(BuildContext context, AppStrings strings) {
    final titleCtrl = TextEditingController();
    int selectedTargetStars = 50;
    String? uploadedPhotoPath;
    bool isUploadingPhoto = false;
    const starOptions = [30, 50, 100, 150, 200];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickRewardPhoto(ImageSource source) async {
              final picked = await MediaStorageService.pickImage(
                source: source,
              );
              if (picked == null) return;
              setModalState(() => isUploadingPhoto = true);
              final uploaded = await MediaStorageService.uploadFamilyGoalPhoto(
                goalId: 'fgoal_${DateTime.now().millisecondsSinceEpoch}',
                imageFile: picked,
              );
              if (!modalCtx.mounted) return;
              setModalState(() {
                isUploadingPhoto = false;
                if (uploaded != null) {
                  uploadedPhotoPath = uploaded;
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
                                    'Matlamat Keluarga Baharu',
                                    'New Family Goal',
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
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Reward Title
                          TextField(
                            controller: titleCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: strings.tr(
                                'Ganjaran Sekeluarga',
                                'Shared Family Reward',
                              ),
                              hintText: strings.tr(
                                'cth: Berkelah di Pantai Hujung Minggu',
                                'e.g. Weekend Beach Picnic',
                              ),
                              filled: true,
                              fillColor: Colors.white,
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

                          // Target Stars
                          Text(
                            strings.tr('Sasaran Bintang', 'Target Stars'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: starOptions.map((s) {
                              final isSel = selectedTargetStars == s;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(
                                        () => selectedTargetStars = s,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF6D4C41)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSel
                                              ? const Color(0xFF6D4C41)
                                              : CozyTheme.border,
                                        ),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '★ $s',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: isSel
                                                ? Colors.white
                                                : CozyTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Reward Photo (Capture / Upload / Delete)
                          Text(
                            strings.tr(
                              'Foto Ganjaran (Pilihan)',
                              'Reward Photo (Optional)',
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
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5E4DC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE5CEC2),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: uploadedPhotoPath != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              child: MediaStorageService
                                                  .buildAdaptiveImage(
                                                uploadedPhotoPath,
                                                width: 52,
                                                height: 52,
                                                fit: BoxFit.cover,
                                                placeholder: const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFF6D4C41),
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.card_giftcard_rounded,
                                              size: 24,
                                              color: Color(0xFF6D4C41),
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
                                            : () => pickRewardPhoto(
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
                                            : () => pickRewardPhoto(
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
                                      if (uploadedPhotoPath != null)
                                        OutlinedButton.icon(
                                          onPressed: isUploadingPhoto
                                              ? null
                                              : () => setModalState(
                                                    () => uploadedPhotoPath =
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
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isUploadingPhoto
                                  ? null
                                  : () {
                                      final title = titleCtrl.text.trim();
                                      if (title.isEmpty) return;
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(eratControllerProvider.notifier)
                                          .addFamilyRewardGoal(
                                            title: title,
                                            targetStars: selectedTargetStars,
                                            imagePath: uploadedPhotoPath,
                                            makeActive: true,
                                          );
                                      Navigator.of(modalCtx).pop();
                                      setState(
                                        () => _selectedGoalTab =
                                            FamilyGoalStatus.active,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D4C41),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: Text(
                                strings.tr(
                                  'Simpan Matlamat',
                                  'Save Family Goal',
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

  void _showMemberMilestoneModal({
    required BuildContext context,
    required FamilyMember member,
    required AppStrings strings,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color.fromRGBO(30, 22, 18, 0.52),
      builder: (modalCtx) {
        final milestones = member.milestones;
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
                    const SizedBox(height: 16),

                    // Clear Member Milestones Header
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E4DC),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5CEC2),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: member.customPhotoPath != null
                              ? ClipOval(
                                  child: MediaStorageService.buildAdaptiveImage(
                                    member.customPhotoPath,
                                    width: 56,
                                    height: 56,
                                    placeholder: Text(
                                      member.avatarEmoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                )
                              : Text(
                                  member.avatarEmoji,
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
                                  'Pencapaian ${member.name}',
                                  '${member.name}’s Milestones',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _localizedMemberSubtitle(member, strings),
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
                          onPressed: () => Navigator.pop(modalCtx),
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
                    const SizedBox(height: 18),

                    // Stats Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E4DC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5CEC2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCol(
                            icon: Icons.local_fire_department_rounded,
                            label: strings.tr('Rantaian', 'Streak'),
                            value:
                                '${member.streakDays} ${strings.tr('Hari', member.streakDays == 1 ? 'Day' : 'Days')}',
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: const Color(0xFFE5CEC2),
                          ),
                          _buildStatCol(
                            icon: Icons.star_rounded,
                            label: strings.tr('Bintang', 'Stars'),
                            value: '${member.stars}',
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: const Color(0xFFE5CEC2),
                          ),
                          _buildStatCol(
                            icon: Icons.workspace_premium_rounded,
                            label: strings.tr('Lencana', 'Badges'),
                            value: '${milestones.length}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Milestone Section Title
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 20,
                          color: Color(0xFF6D4C41),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.tr(
                            'Pencapaian & Lencana',
                            'Milestones & Badges',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: CozyTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (milestones.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2E8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEBDCC8)),
                        ),
                        child: Text(
                          strings.tr(
                            'Teruskan aktiviti harian untuk membuka lencana pertama anda.',
                            'Keep up daily activities to unlock your first badge.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5A463C),
                          ),
                        ),
                      )
                    else
                      ...milestones.map((badgeName) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5CEC2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5E4DC),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getBadgeEmoji(badgeName),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _localizedBadgeName(badgeName, strings),
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getBadgeDesc(badgeName, strings),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5A463C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                size: 20,
                                color: Color(0xFF6D4C41),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6D4C41),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          strings.tr('Tutup', 'Close'),
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
        );
      },
    );
  }

  static Widget _buildStatCol({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6D4C41)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: CozyTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5A463C),
          ),
        ),
      ],
    );
  }

  static String _getBadgeEmoji(String badge) {
    if (badge.contains('10 Good Habits')) return '🌟';
    if (badge.contains('Streak')) return '🔥';
    if (badge.contains('Team Spirit')) return '🤝';
    if (badge.contains('Family Goal')) return '🎯';
    return '🌱';
  }

  static String _localizedBadgeName(String badge, AppStrings strings) {
    if (!strings.isMs) return badge;
    if (badge.contains('10 Good Habits')) return '10 Tabiat Baik';
    if (badge.contains('7-Day Streak')) return 'Rantaian 7 Hari';
    if (badge.contains('Team Spirit')) return 'Semangat Berpasukan';
    if (badge.contains('Family Goal')) return 'Matlamat Keluarga';
    if (badge.contains('First Week')) return 'Minggu Pertama';
    return badge;
  }

  static String _getBadgeDesc(String badge, AppStrings strings) {
    if (badge.contains('10 Good Habits')) {
      return strings.tr(
        'Melengkapkan 10 tabiat positif',
        'Completed 10 good habits',
      );
    }
    if (badge.contains('Streak')) {
      return strings.tr(
        'Konsisten 7 hari berturut-turut',
        'Consistent for 7 days in a row',
      );
    }
    if (badge.contains('Team Spirit')) {
      return strings.tr(
        'Sumbangan aktif dalam cabaran keluarga',
        'Active family team player',
      );
    }
    if (badge.contains('Family Goal')) {
      return strings.tr(
        'Mencapai sasaran impian keluarga',
        'Achieved family dream milestone',
      );
    }
    return strings.tr('Langkah permulaan bersama ERAT', 'First steps together');
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final members = appState.members;
    final guardians = members.where((m) => m.isParentOrGuardian).toList();
    final starContributors =
        members.where((m) => !m.isParentOrGuardian).toList();
    final allGoals = appState.familyGoals;

    final activeGoals =
        allGoals.where((g) => g.status == FamilyGoalStatus.active).toList();
    final readyGoals = allGoals
        .where((g) => g.status == FamilyGoalStatus.readyToClaim)
        .toList();
    final claimedGoals =
        allGoals.where((g) => g.status == FamilyGoalStatus.claimed).toList();

    final visibleGoals = switch (_selectedGoalTab) {
      FamilyGoalStatus.active => activeGoals,
      FamilyGoalStatus.readyToClaim => readyGoals,
      FamilyGoalStatus.claimed => claimedGoals,
    };

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
        title: Text(
          strings.tr('Matlamat Bintang Keluarga', 'Family Star Goal'),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: CozyTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF6D4C41),
              size: 25,
            ),
            tooltip: strings.tr('Tambah Matlamat', 'New Family Goal'),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () {
              HapticFeedback.lightImpact();
              _requireParentPin(
                context: context,
                guardians: guardians,
                strings: strings,
                actionLabel: strings.tr(
                  'mengemas kini matlamat bintang keluarga',
                  'update family star goals',
                ),
                onAuthorized: () => _showCreateFamilyGoalModal(context, strings),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600.0;
            final crossAxisCount = isTablet ? 3 : 2;
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
                    extraBottomInset + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shared Family Goals Lifecycle Tabs: Active | Ready (N) | Claimed (N)
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
                              child: _buildGoalTab(
                                label:
                                    '${strings.tr('Aktif', 'Active')} (${activeGoals.length})',
                                isSelected:
                                    _selectedGoalTab == FamilyGoalStatus.active,
                                onTap: () => setState(
                                  () => _selectedGoalTab =
                                      FamilyGoalStatus.active,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildGoalTab(
                                label:
                                    '${strings.tr('Sedia', 'Ready')} (${readyGoals.length})',
                                isSelected: _selectedGoalTab ==
                                    FamilyGoalStatus.readyToClaim,
                                onTap: () => setState(
                                  () => _selectedGoalTab =
                                      FamilyGoalStatus.readyToClaim,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildGoalTab(
                                label:
                                    '${strings.tr('Ditebus', 'Claimed')} (${claimedGoals.length})',
                                isSelected: _selectedGoalTab ==
                                    FamilyGoalStatus.claimed,
                                onTap: () => setState(
                                  () => _selectedGoalTab =
                                      FamilyGoalStatus.claimed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Family Goals List for Selected Lifecycle Tab
                      if (visibleGoals.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF2E8),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEBDCC8)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                strings.tr(
                                  'Tiada matlamat dalam bahagian ini.',
                                  'No family goals in this tab yet.',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5A463C),
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => _requireParentPin(
                                  context: context,
                                  guardians: guardians,
                                  strings: strings,
                                  actionLabel: strings.tr(
                                    'mengemas kini matlamat bintang keluarga',
                                    'update family star goals',
                                  ),
                                  onAuthorized: () =>
                                      _showCreateFamilyGoalModal(
                                    context,
                                    strings,
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 17),
                                label: Text(
                                  strings.tr(
                                    'Tambah Matlamat Baharu',
                                    'New Family Goal',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6D4C41),
                                  side: const BorderSide(
                                    color: Color(0xFF6D4C41),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  minimumSize: const Size(140, 44),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...visibleGoals.map(
                          (goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFamilyGoalCard(
                              goal: goal,
                              guardians: guardians,
                              strings: strings,
                            ),
                          ),
                        ),

                      const SizedBox(height: 14),

                      // Section 1: Parents & Caregivers (Passive Role Pills)
                      if (guardians.isNotEmpty) ...[
                        Text(
                          strings.tr(
                            'Ibu Bapa & Penjaga',
                            'Parents & Caregivers',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: guardians.map((g) {
                            final roleLabel =
                                _localizedGuardianRole(g, strings);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF2E8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFEBDCC8),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5E4DC),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: g.customPhotoPath != null
                                        ? ClipOval(
                                            child: MediaStorageService
                                                .buildAdaptiveImage(
                                              g.customPhotoPath,
                                              width: 34,
                                              height: 34,
                                              placeholder: Text(
                                                g.avatarEmoji,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            g.avatarEmoji,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        g.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        g.stars > 0
                                            ? '$roleLabel • ★ ${g.stars} ${strings.tr('disumbang', 'contributed')}'
                                            : roleLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF5A463C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // Section 2: Star Contributors
                      Text(
                        strings.tr('Pengumpul Bintang', 'Star Contributors'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.tr(
                          'Ketik mana-mana kad ahli untuk lihat pencapaian & lencana.',
                          'Tap any member card to view milestones & badges.',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5A463C),
                        ),
                      ),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: isTablet ? 1.08 : 0.96,
                        ),
                        itemCount: starContributors.length,
                        itemBuilder: (context, idx) {
                          final m = starContributors[idx];
                          final subtitle = _localizedMemberSubtitle(m, strings);
                          final badgeLabel = _localizedBadgeCount(
                            m.milestones.length,
                            strings,
                          );

                          return Semantics(
                            button: true,
                            label:
                                '${m.name}, $subtitle, ${m.stars} stars, $badgeLabel',
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFDF9),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE5CEC2),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(110, 70, 38, 0.05),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  hoverColor: Colors.transparent,
                                  splashColor: const Color(0x146D4C41),
                                  highlightColor: const Color(0x0D6D4C41),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showMemberMilestoneModal(
                                      context: context,
                                      member: m,
                                      strings: strings,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    child: Stack(
                                      children: [
                                        const Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: Color(0xFFB59B8E),
                                          ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF5E4DC),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE5CEC2,
                                                    ),
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: m.customPhotoPath != null
                                                    ? ClipOval(
                                                        child: MediaStorageService
                                                            .buildAdaptiveImage(
                                                          m.customPhotoPath,
                                                          width: 56,
                                                          height: 56,
                                                          placeholder: Text(
                                                            m.avatarEmoji,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 28,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Text(
                                                        m.avatarEmoji,
                                                        style: const TextStyle(
                                                          fontSize: 28,
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                m.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: CozyTheme.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  subtitle,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF5A463C),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF5E4DC),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.star_rounded,
                                                        size: 14,
                                                        color:
                                                            Color(0xFF6D4C41),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '${m.stars}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: CozyTheme
                                                              .textDark,
                                                        ),
                                                      ),
                                                      const Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 5,
                                                        ),
                                                        child: Text(
                                                          '•',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Color(
                                                              0xFF8C685C,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        badgeLabel,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFF5A463C),
                                                        ),
                                                      ),
                                                    ],
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
                              ),
                            ),
                          );
                        },
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

  Widget _buildGoalTab({
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
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D4C41) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF5A463C),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyGoalCard({
    required FamilyRewardGoal goal,
    required List<FamilyMember> guardians,
    required AppStrings strings,
  }) {
    final title = strings.isMs ? goal.titleMs : goal.titleEn;
    final remaining = (goal.targetStars - goal.currentStars).clamp(0, 999);
    final isReady = goal.status == FamilyGoalStatus.readyToClaim;
    final isClaimed = goal.status == FamilyGoalStatus.claimed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isClaimed ? const Color(0xFFF2ECE6) : const Color(0xFFF5E4DC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isClaimed ? const Color(0xFFDED4CB) : const Color(0xFFE5CEC2),
          width: 1.3,
        ),
        boxShadow: isClaimed
            ? const []
            : const [
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Reward Image Thumbnail (Uploaded / Asset / Default Icon)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5CEC2)),
                ),
                alignment: Alignment.center,
                child: goal.imagePath != null && goal.imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: MediaStorageService.buildAdaptiveImage(
                          goal.imagePath,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: const Icon(
                            Icons.star_rounded,
                            size: 26,
                            color: Color(0xFF6D4C41),
                          ),
                        ),
                      )
                    : Icon(
                        isClaimed
                            ? Icons.verified_rounded
                            : Icons.card_giftcard_rounded,
                        size: 26,
                        color: const Color(0xFF6D4C41),
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
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: isClaimed
                            ? const Color(0xFF7B6960)
                            : CozyTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isClaimed
                          ? strings.tr(
                              'Ganjaran keluarga telah ditebus',
                              'Shared family reward claimed',
                            )
                          : isReady
                              ? strings.tr(
                                  'Sasaran tercapai! Sedia ditebus bersama.',
                                  'Goal reached! Ready to claim together.',
                                )
                              : strings.tr(
                                  'Lagi $remaining bintang untuk ditebus',
                                  '$remaining more stars to unlock',
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5CEC2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFF6D4C41),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${goal.currentStars}/${goal.targetStars}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: goal.progress),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, animatedVal, _) {
                return LinearProgressIndicator(
                  value: animatedVal,
                  minHeight: 9,
                  backgroundColor: const Color(0xB3FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isClaimed
                        ? const Color(0xFF8C7B72)
                        : const Color(0xFF6D4C41),
                  ),
                );
              },
            ),
          ),
          if (isReady) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showClaimRewardPinDialog(
                    context: context,
                    goal: goal,
                    guardians: guardians,
                    strings: strings,
                  );
                },
                icon: const Icon(Icons.card_giftcard_rounded, size: 17),
                label: Text(
                  strings.tr('Tebus Ganjaran (PIN)', 'Claim Reward (PIN)'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D4C41),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ] else if (isClaimed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: Color(0xFF6D4C41),
                ),
                const SizedBox(width: 5),
                Text(
                  strings.tr('Sudah Ditebus', 'Claimed'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6D4C41),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
