import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';
import '../../auth/presentation/member_pin_login_screen.dart';
import 'cozy_add_member_sheet.dart';

/// Cozy Minimalist Personal Profile & Settings Tab for Private Space
class CozyPersonalProfileTab extends ConsumerWidget {
  const CozyPersonalProfileTab({super.key});

  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _dragHandle = Color(0xFFBBA396);

  static const List<String> _providedAvatars = [
    '👧',
    '👦',
    '👶',
    '👩',
    '👨',
    '🧕',
    '🧑',
    '🎓',
    '🌟',
    '🦋',
    '🦁',
    '🐼',
  ];

  static const List<String> _monthNamesEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _monthNamesMs = [
    'Jan',
    'Feb',
    'Mac',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ogo',
    'Sep',
    'Okt',
    'Nov',
    'Dis',
  ];

  String _localizedAgeBandShort(AgeBand band, bool isMs) {
    if (!isMs) {
      return switch (band) {
        AgeBand.littleExplorer => 'Little Explorer',
        AgeBand.happyHabitBuilder => 'Habit Builder',
        AgeBand.goalAchiever => 'Goal Achiever',
        AgeBand.myLifeMyGoals => 'Teen Explorer',
        AgeBand.lifelongFamilyBond => 'Family Bond',
      };
    }
    return switch (band) {
      AgeBand.littleExplorer => 'Peneroka Cilik',
      AgeBand.happyHabitBuilder => 'Pembina Tabiat',
      AgeBand.goalAchiever => 'Pencapai Matlamat',
      AgeBand.myLifeMyGoals => 'Remaja Berdikari',
      AgeBand.lifelongFamilyBond => 'Ikatan Keluarga',
    };
  }

  int _computeAgeYears(int birthMonth, int birthYear) {
    final now = DateTime.now();
    int age = now.year - birthYear;
    if (now.month < birthMonth) age--;
    return age < 1 ? 1 : age;
  }

  AgeBand _computeAgeBand(int age) {
    if (age <= 4) return AgeBand.littleExplorer;
    if (age <= 9) return AgeBand.happyHabitBuilder;
    if (age <= 12) return AgeBand.goalAchiever;
    if (age <= 17) return AgeBand.myLifeMyGoals;
    return AgeBand.lifelongFamilyBond;
  }

  List<String> _taglineSuggestions(AgeBand band, bool isMs) {
    if (isMs) {
      return switch (band) {
        AgeBand.littleExplorer => [
            'Peneroka Cilik',
            'Suka Belajar',
            'Bintang Kecil',
            'Anak Ceria',
          ],
        AgeBand.happyHabitBuilder => [
            'Pembina Tabiat',
            'Pembantu Baik',
            'Kawan Penyayang',
            'Berani Mencuba',
          ],
        AgeBand.goalAchiever => [
            'Pencapai Matlamat',
            'Pemimpi Besar',
            'Suka Membantu',
            'Sentiasa Fokus',
          ],
        AgeBand.myLifeMyGoals => [
            'Remaja Berdikari',
            'Fokus & Tenang',
            'Membesar Setiap Hari',
            'Berfikiran Positif',
          ],
        AgeBand.lifelongFamilyBond => [
            'Ikatan Keluarga',
            'Kasih Sepanjang Hayat',
            'Tenang & Bersyukur',
            'Sokongan Keluarga',
          ],
      };
    }
    return switch (band) {
      AgeBand.littleExplorer => [
          'Little Explorer',
          'Curious Dreamer',
          'Little Star',
          'Happy Helper',
        ],
      AgeBand.happyHabitBuilder => [
          'Habit Builder',
          'Kind Helper',
          'Brave Learner',
          'Cheerful Buddy',
        ],
      AgeBand.goalAchiever => [
          'Goal Achiever',
          'Dream Big',
          'Team Player',
          'Rising Star',
        ],
      AgeBand.myLifeMyGoals => [
          'Teen Explorer',
          'Calm & Focused',
          'Growing Every Day',
          'Chasing Dreams',
        ],
      AgeBand.lifelongFamilyBond => [
          'Family Bond',
          'Always Grateful',
          'Warm & Present',
          'Lifelong Learner',
        ],
    };
  }

  /// Bottom sheet: Upload custom profile photo OR choose a provided avatar
  void _showAvatarPhotoSheet(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) {
    final isMs = ref.read(appStringsProvider).isMs;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            final hasCustomPhoto = member.customPhotoPath != null &&
                member.customPhotoPath!.trim().isNotEmpty;

            Future<void> handlePick(ImageSource source) async {
              setModalState(() => isUploading = true);
              try {
                final picked = await MediaStorageService.pickImage(
                  source: source,
                );
                if (picked == null) {
                  if (ctx.mounted) setModalState(() => isUploading = false);
                  return;
                }
                final uploaded = await MediaStorageService.uploadProfilePhoto(
                  memberId: member.id,
                  imageFile: picked,
                );
                if (uploaded != null && uploaded.isNotEmpty) {
                  ref.read(eratControllerProvider.notifier).updateMemberProfile(
                        memberId: member.id,
                        customPhotoPath: uploaded,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMs
                              ? 'Gambar profil berjaya dikemas kini.'
                              : 'Profile photo updated.',
                        ),
                        backgroundColor: _mochaPrimary,
                      ),
                    );
                  }
                } else if (ctx.mounted) {
                  setModalState(() => isUploading = false);
                }
              } catch (_) {
                if (ctx.mounted) setModalState(() => isUploading = false);
              }
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    bottomInset > 34 ? bottomInset + 8 : 36,
                  ),
                  child: SingleChildScrollView(
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

                        // Header with 44x44 close button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMs
                                        ? 'Tukar Gambar Profil'
                                        : 'Change Profile Picture',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: CozyTheme.textDark,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isMs
                                        ? 'Muat naik gambar sendiri atau pilih avatar yang disediakan.'
                                        : 'Upload your own photo or pick a provided avatar.',
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
                            const SizedBox(width: 8),
                            _buildModalCloseButton(ctx),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 1: Upload Custom Photo
                        Text(
                          isMs ? 'MUAT NAIK GAMBAR' : 'UPLOAD PHOTO',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _warmCocoa,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (isUploading)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _blushBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: _mochaPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isMs
                                      ? 'Menyimpan gambar profil...'
                                      : 'Saving profile photo...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          _buildActionOptionTile(
                            icon: Icons.photo_library_outlined,
                            label: isMs
                                ? 'Pilih dari Galeri Foto'
                                : 'Choose from Photo Library',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              handlePick(ImageSource.gallery);
                            },
                          ),
                          const SizedBox(height: 10),
                          _buildActionOptionTile(
                            icon: Icons.photo_camera_outlined,
                            label: isMs
                                ? 'Ambil Gambar Baharu (Kamera)'
                                : 'Take a New Photo (Camera)',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              handlePick(ImageSource.camera);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isMs
                                ? 'Hanya digunakan untuk memaparkan profil anda dalam ruang keluarga.'
                                : 'Used only to personalize your profile inside your family space.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _warmCocoa,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Section 2: Provided Avatars
                        Text(
                          isMs ? 'PILIH AVATAR DISEDIAKAN' : 'CHOOSE PROVIDED AVATAR',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: _warmCocoa,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 10),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _providedAvatars.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.15,
                          ),
                          itemBuilder: (_, idx) {
                            final emoji = _providedAvatars[idx];
                            final isSelected =
                                !hasCustomPhoto && member.avatarEmoji == emoji;
                            return Material(
                              color: isSelected ? _blushSurface : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(eratControllerProvider.notifier)
                                      .updateMemberProfile(
                                        memberId: member.id,
                                        avatarEmoji: emoji,
                                        clearCustomPhoto: true,
                                      );
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? _mochaPrimary
                                          : _blushBorder,
                                      width: isSelected ? 2 : 1.1,
                                    ),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 28),
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
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom sheet: Edit Name, Date of Birth (auto-detects Age & Age Band), and Short Quote / Tagline
  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) {
    final isMs = ref.read(appStringsProvider).isMs;
    final nameCtrl = TextEditingController(text: member.name);
    final taglineCtrl = TextEditingController(text: member.tagline ?? '');
    int selectedMonth = member.birthMonth.clamp(1, 12);
    final currentYear = DateTime.now().year;
    int selectedYear = member.birthYear.clamp(currentYear - 90, currentYear - 1);

    final years = List<int>.generate(90, (i) => currentYear - 1 - i);
    final months = isMs ? _monthNamesMs : _monthNamesEn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final viewInsets = MediaQuery.viewInsetsOf(ctx);
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            final detectedAge = _computeAgeYears(selectedMonth, selectedYear);
            final detectedBand = _computeAgeBand(detectedAge);
            final suggestions = _taglineSuggestions(detectedBand, isMs);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CozyTheme.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      bottomInset > 34 ? bottomInset + 8 : 34,
                    ),
                    child: SingleChildScrollView(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMs
                                          ? 'Kemas Kini Profil & Tarikh Lahir'
                                          : 'Edit Profile & Date of Birth',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMs
                                          ? 'Umur & kumpulan umur dikesan secara automatik daripada tarikh lahir.'
                                          : 'Age and stage are automatically detected from date of birth.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _warmCocoa,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildModalCloseButton(ctx),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Name input
                          Text(
                            isMs ? 'Nama Paparan' : 'Display Name',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              hint: isMs ? 'Nama ahli' : 'Member name',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // DOB Month & Year pickers
                          Text(
                            isMs ? 'Tarikh Lahir (Bulan & Tahun)' : 'Date of Birth (Month & Year)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedMonth,
                                  decoration: _inputDecoration(
                                    hint: isMs ? 'Bulan' : 'Month',
                                  ),
                                  dropdownColor: Colors.white,
                                  items: List.generate(12, (i) {
                                    return DropdownMenuItem<int>(
                                      value: i + 1,
                                      child: Text(
                                        months[i],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => selectedMonth = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedYear,
                                  decoration: _inputDecoration(
                                    hint: isMs ? 'Tahun' : 'Year',
                                  ),
                                  dropdownColor: Colors.white,
                                  items: years.map((y) {
                                    return DropdownMenuItem<int>(
                                      value: y,
                                      child: Text(
                                        '$y',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => selectedYear = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Live Auto-Detected Age & Stage Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _linenSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _linenBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: _mochaPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isMs
                                        ? 'Dikesan: Umur $detectedAge thn • ${_localizedAgeBandShort(detectedBand, true)}'
                                        : 'Detected: Age $detectedAge • ${_localizedAgeBandShort(detectedBand, false)}',
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
                          const SizedBox(height: 16),

                          // Personal Short Quote / Tagline
                          Text(
                            isMs
                                ? 'Gelaran / Kata Pendek (Tagline)'
                                : 'Personal Tagline / Short Quote',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: taglineCtrl,
                            maxLength: 32,
                            decoration: _inputDecoration(
                              hint: _localizedAgeBandShort(detectedBand, isMs),
                            ).copyWith(counterText: ''),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: suggestions.map((s) {
                              return ActionChip(
                                label: Text(
                                  s,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: _blushBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => taglineCtrl.text = s);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                final cleanName = nameCtrl.text.trim();
                                final cleanTagline = taglineCtrl.text.trim();
                                if (cleanName.isEmpty) return;

                                HapticFeedback.mediumImpact();
                                ref
                                    .read(eratControllerProvider.notifier)
                                    .updateMemberProfile(
                                      memberId: member.id,
                                      name: cleanName,
                                      birthMonth: selectedMonth,
                                      birthYear: selectedYear,
                                      tagline: cleanTagline.isEmpty
                                          ? null
                                          : cleanTagline,
                                      clearTagline: cleanTagline.isEmpty,
                                    );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isMs
                                          ? 'Profil & tarikh lahir disimpan.'
                                          : 'Profile & date of birth saved.',
                                    ),
                                    backgroundColor: _mochaPrimary,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                isMs ? 'Simpan Perubahan' : 'Save Changes',
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

  /// Bottom sheet: Set or Change 4-Digit PIN
  void _showPinSettingsSheet(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) {
    final isMs = ref.read(appStringsProvider).isMs;
    final hasExistingPin = (member.pin ?? '').isNotEmpty;
    final currentPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();
    bool obscurePins = true;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final viewInsets = MediaQuery.viewInsetsOf(ctx);
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CozyTheme.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12,
                      22,
                      bottomInset > 34 ? bottomInset + 8 : 34,
                    ),
                    child: SingleChildScrollView(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasExistingPin
                                          ? (isMs
                                              ? 'Tukar PIN 4-Digit'
                                              : 'Change 4-Digit PIN')
                                          : (isMs
                                              ? 'Tetapkan PIN 4-Digit'
                                              : 'Set 4-Digit PIN'),
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMs
                                          ? 'PIN melindungi ruang peribadi, diari dan tetapan profil anda.'
                                          : 'Your PIN protects your private space, journal, and profile settings.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _warmCocoa,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildModalCloseButton(ctx),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (hasExistingPin) ...[
                            Text(
                              isMs ? 'PIN Semasa' : 'Current PIN',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: currentPinCtrl,
                              keyboardType: TextInputType.number,
                              obscureText: obscurePins,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _inputDecoration(
                                hint: '••••',
                              ).copyWith(counterText: ''),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Text(
                            isMs ? 'PIN Baharu (4 digit)' : 'New PIN (4 digits)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: newPinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: obscurePins,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration(
                              hint: '••••',
                            ).copyWith(
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePins
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _warmCocoa,
                                  size: 20,
                                ),
                                onPressed: () => setModalState(
                                  () => obscurePins = !obscurePins,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            isMs ? 'Sahkan PIN Baharu' : 'Confirm New PIN',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: confirmPinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: obscurePins,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration(
                              hint: '••••',
                            ).copyWith(counterText: ''),
                          ),

                          if (errorMsg != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              errorMsg!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB3261E),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                final current = currentPinCtrl.text.trim();
                                final next = newPinCtrl.text.trim();
                                final confirm = confirmPinCtrl.text.trim();

                                if (hasExistingPin && current != member.pin) {
                                  setModalState(() {
                                    errorMsg = isMs
                                        ? 'PIN semasa tidak sepadan.'
                                        : 'Current PIN does not match.';
                                  });
                                  return;
                                }
                                if (next.length != 4) {
                                  setModalState(() {
                                    errorMsg = isMs
                                        ? 'Sila masukkan tepat 4 digit nombor.'
                                        : 'Please enter exactly 4 digits.';
                                  });
                                  return;
                                }
                                if (next != confirm) {
                                  setModalState(() {
                                    errorMsg = isMs
                                        ? 'Pengesahan PIN tidak sepadan.'
                                        : 'New PIN and confirmation do not match.';
                                  });
                                  return;
                                }

                                HapticFeedback.mediumImpact();
                                ref
                                    .read(eratControllerProvider.notifier)
                                    .updateMemberPin(
                                      memberId: member.id,
                                      newPin: next,
                                    );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isMs
                                          ? 'PIN 4-digit berjaya disimpan.'
                                          : '4-digit PIN saved.',
                                    ),
                                    backgroundColor: _mochaPrimary,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                isMs ? 'Simpan PIN' : 'Save PIN',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          // Allow removing PIN only for young children (< 9y and not parent)
                          if (hasExistingPin && !member.requiresPin) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(eratControllerProvider.notifier)
                                      .updateMemberPin(
                                        memberId: member.id,
                                        newPin: null,
                                      );
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isMs
                                            ? 'PIN dibuang. Mod bimbingan ibu bapa diaktifkan.'
                                            : 'PIN removed. Parent-guided access enabled.',
                                      ),
                                      backgroundColor: _mochaPrimary,
                                    ),
                                  );
                                },
                                child: Text(
                                  isMs
                                      ? 'Buang PIN (Guna Mod Bimbingan Ibu Bapa)'
                                      : 'Remove PIN (Use Parent-Guided Access)',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _warmCocoa,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(eratControllerProvider);
    final activeMember = appState.activeMember;
    final isParent = activeMember.isParentOrGuardian;
    final strings = ref.watch(appStringsProvider);
    final isMs = strings.isMs;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final hasPin = (activeMember.pin ?? '').isNotEmpty;
    final badgeCount = activeMember.milestones.length;
    final months = isMs ? _monthNamesMs : _monthNamesEn;
    final dobLabel =
        '${months[(activeMember.birthMonth - 1).clamp(0, 11)]} ${activeMember.birthYear}';

    final displayTagline = (activeMember.tagline != null &&
            activeMember.tagline!.trim().isNotEmpty)
        ? activeMember.tagline!.trim()
        : (isParent
            ? (isMs ? 'Ibu Bapa • Pentadbir' : 'Parent • Admin')
            : _localizedAgeBandShort(activeMember.ageBand, isMs));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            bottomInset + 40,
          ),
          children: [
            // Screen Title & Subtitle
            Center(
              child: Column(
                children: [
                  Text(
                    isMs ? 'Profil & Tetapan' : 'Profile & Settings',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMs
                        ? 'Maklumat akaun peribadi & kawalan keluarga'
                        : 'Personal account details & family controls',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: _warmCocoa,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hero Profile Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _blushBorder, width: 1.2),
                boxShadow: CozyTheme.cardShadow,
              ),
              child: Column(
                children: [
                  // Tappable Avatar with Camera Badge (>= 44x44 target)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showAvatarPhotoSheet(context, ref, activeMember);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _blushSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: _blushBorder, width: 2.2),
                          ),
                          child: (activeMember.customPhotoPath != null &&
                                  activeMember.customPhotoPath!
                                      .trim()
                                      .isNotEmpty)
                              ? ClipOval(
                                  child: MediaStorageService.buildAdaptiveImage(
                                    activeMember.customPhotoPath,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: Text(
                                      activeMember.avatarEmoji,
                                      style: const TextStyle(fontSize: 38),
                                    ),
                                  ),
                                )
                              : Text(
                                  activeMember.avatarEmoji,
                                  style: const TextStyle(fontSize: 38),
                                ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _mochaPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    activeMember.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: CozyTheme.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Personal Tagline / Short Quote + Auto-Detected Age Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _linenSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _linenBorder),
                    ),
                    child: Text(
                      isParent
                          ? displayTagline
                          : (isMs
                              ? '$displayTagline • ${activeMember.ageYears} thn'
                              : '$displayTagline • ${activeMember.ageYears}y'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _warmCocoa,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stars & Badges Stats Row
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatPill(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFD9822B),
                        backgroundColor: _blushSurface,
                        borderColor: _blushBorder,
                        label: isMs
                            ? '${activeMember.stars} Bintang'
                            : '${activeMember.stars} Stars',
                      ),
                      _buildStatPill(
                        icon: Icons.emoji_events_rounded,
                        iconColor: _mochaPrimary,
                        backgroundColor: _linenSurface,
                        borderColor: _linenBorder,
                        label: isMs
                            ? '$badgeCount Lencana'
                            : '$badgeCount Badges',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: Account, DOB & Tagline (Interactive)
            _buildInteractiveCard(
              icon: Icons.person_outline_rounded,
              title: isMs ? 'Maklumat Diri & Tarikh Lahir' : 'Profile & Date of Birth',
              subtitle: isMs
                  ? 'Lahir $dobLabel • Umur ${activeMember.ageYears} thn'
                  : 'Born $dobLabel • Age ${activeMember.ageYears}',
              onTap: () {
                HapticFeedback.lightImpact();
                _showEditProfileSheet(context, ref, activeMember);
              },
            ),
            const SizedBox(height: 12),

            // Parent-Only Card: Add Child / Guardian / Co-Parent
            if (isParent) ...[
              _buildInteractiveCard(
                icon: Icons.person_add_alt_1_rounded,
                title: isMs
                    ? 'Tambah Anak / Penjaga / Ibu Bapa'
                    : 'Add Child / Guardian / Co-Parent',
                subtitle: isMs
                    ? '${appState.members.length} ahli keluarga'
                    : '${appState.members.length} family members',
                onTap: () {
                  HapticFeedback.lightImpact();
                  showCozyAddMemberSheet(context, ref);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Card 2: App Language Switcher (EN / BM)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blushBorder, width: 1.2),
                boxShadow: CozyTheme.cardShadow,
              ),
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
                    child: const Icon(
                      Icons.translate_rounded,
                      size: 21,
                      color: _mochaPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMs ? 'Bahasa Aplikasi' : 'App Language',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMs ? 'Bahasa Melayu' : 'English',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _warmCocoa,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _blushSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _blushBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangChip(
                          label: 'EN',
                          selected: !isMs,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(appLanguageProvider.notifier).state =
                                AppLanguage.en;
                          },
                        ),
                        _buildLangChip(
                          label: 'BM',
                          selected: isMs,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(appLanguageProvider.notifier).state =
                                AppLanguage.ms;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card 3: Security & 4-Digit PIN (Interactive)
            _buildInteractiveCard(
              icon: Icons.verified_user_outlined,
              title: isMs ? 'Keselamatan & PIN' : 'Security & PIN',
              subtitle: hasPin
                  ? (isMs
                      ? 'PIN 4-digit aktif • Ketik untuk tukar'
                      : '4-digit PIN active • Tap to change')
                  : (isMs
                      ? 'Belum ditetapkan • Ketik untuk tetapkan PIN'
                      : 'Not set yet • Tap to set a 4-digit PIN'),
              onTap: () {
                HapticFeedback.lightImpact();
                _showPinSettingsSheet(context, ref, activeMember);
              },
            ),
            const SizedBox(height: 22),

            // Action Buttons Row (Switch Member vs Lock Space — both 50pt tall >= 44pt)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const MemberPinLoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: CozyTheme.textDark,
                        side: const BorderSide(
                          color: _mochaPrimary,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            size: 19,
                            color: _mochaPrimary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isMs ? 'Tukar Ahli' : 'Switch Member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
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
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(isPrivateSpaceUnlockedProvider.notifier).state =
                            false;
                        ref.read(appViewModeProvider.notifier).state =
                            AppViewMode.selection;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mochaPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 17),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isMs ? 'Kunci Ruang' : 'Lock Space',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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
          ],
        ),
      ),
    );
  }

  Widget _buildModalCloseButton(BuildContext ctx) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: _blushBorder),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(ctx);
          },
          child: const Icon(
            Icons.close_rounded,
            size: 20,
            color: CozyTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActionOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _blushBorder, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _blushSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: _mochaPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: CozyTheme.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: _mochaPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9E8D84),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _blushBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _mochaPrimary, width: 1.8),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: CozyTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _blushBorder, width: 1.2),
            boxShadow: CozyTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _blushSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _blushBorder),
                ),
                child: Icon(icon, size: 22, color: _mochaPrimary),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _mochaPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: _mochaPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _mochaPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 38),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : _warmCocoa,
            ),
          ),
        ),
      ),
    );
  }
}
