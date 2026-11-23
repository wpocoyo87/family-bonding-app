import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/cozy_theme.dart';

/// Reusable Parent-Only Bottom Sheet to Create a New Child / Co-Parent / Guardian Account
void showCozyAddMemberSheet(BuildContext context, WidgetRef ref) {
  const mochaPrimary = Color(0xFF6D4C41);
  const warmCocoa = Color(0xFF5A463C);
  const blushSurface = Color(0xFFF5E4DC);
  const blushBorder = Color(0xFFE5CEC2);
  const linenSurface = Color(0xFFFAF2E8);
  const linenBorder = Color(0xFFEBDCC8);
  const dragHandle = Color(0xFFBBA396);

  const childAvatars = ['👧', '👦', '👶', '🧒', '🎓', '🌟', '🦋', '🦁', '🐼'];
  const parentAvatars = ['👨', '👩', '🧕', '🧑', '👴', '👵'];
  const monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const monthsMs = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
  ];

  final isMs = ref.read(appStringsProvider).isMs;
  final nameCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  String selectedAvatar = '👧';
  String? uploadedPhotoPath;
  bool isUploadingPhoto = false;
  final currentYear = DateTime.now().year;
  int selectedMonth = 6;
  int selectedYear = currentYear - 6;
  bool isCoParent = false;
  String parentRelation = 'dad'; // 'dad', 'mom', 'guardian', 'grandparent'
  String? errorMsg;

  final parentRelations = [
    {
      'id': 'dad',
      'en': 'Dad',
      'ms': 'Ayah',
      'emoji': '👨',
      'role': MemberRole.coparent,
    },
    {
      'id': 'mom',
      'en': 'Mom',
      'ms': 'Ibu',
      'emoji': '👩',
      'role': MemberRole.coparent,
    },
    {
      'id': 'guardian',
      'en': 'Guardian',
      'ms': 'Penjaga',
      'emoji': '🧑',
      'role': MemberRole.caregiver,
    },
    {
      'id': 'grandparent',
      'en': 'Grandparent',
      'ms': 'Datuk / Nenek',
      'emoji': '👴',
      'role': MemberRole.caregiver,
    },
  ];

  int computeAge(int m, int y) {
    final now = DateTime.now();
    int age = now.year - y;
    if (now.month < m) age--;
    return age < 1 ? 1 : age;
  }

  Map<String, dynamic> activeParentRel() => parentRelations.firstWhere(
        (r) => r['id'] == parentRelation,
        orElse: () => parentRelations.first,
      );

  String ageStageLabel(int age) {
    if (isCoParent) {
      final rel = activeParentRel();
      return isMs ? rel['ms'] as String : rel['en'] as String;
    }
    if (age <= 4) {
      return isMs ? 'Peneroka Cilik (1–4 thn)' : 'Little Explorer (1–4y)';
    }
    if (age <= 9) {
      return isMs ? 'Pembina Tabiat (5–9 thn)' : 'Habit Builder (5–9y)';
    }
    if (age <= 12) {
      return isMs ? 'Pencapai Matlamat (10–12 thn)' : 'Goal Achiever (10–12y)';
    }
    if (age <= 17) {
      return isMs ? 'Remaja Berdikari (13–17 thn)' : 'Teen Explorer (13–17y)';
    }
    return isMs ? 'Ikatan Keluarga (18+ thn)' : 'Family Bond (18+y)';
  }

  MemberRole resolveRole(int age) {
    if (isCoParent) return activeParentRel()['role'] as MemberRole;
    if (age <= 12) return MemberRole.child;
    if (age <= 17) return MemberRole.teen;
    return MemberRole.adult;
  }

  InputDecoration fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9E8D84), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blushBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: mochaPrimary, width: 1.8),
        ),
      );

  final years = List<int>.generate(85, (i) => currentYear - 1 - i);
  final months = isMs ? monthsMs : monthsEn;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final viewInsets = MediaQuery.viewInsetsOf(ctx);
          final bottomInset = MediaQuery.paddingOf(ctx).bottom;
          final age = computeAge(selectedMonth, selectedYear);
          final pinRequired = isCoParent || age >= 9;
          final avatars = isCoParent ? parentAvatars : childAvatars;

          Future<void> handlePickPhoto(ImageSource source) async {
            setModalState(() => isUploadingPhoto = true);
            try {
              final picked = await MediaStorageService.pickImage(source: source);
              if (picked == null) {
                if (ctx.mounted) setModalState(() => isUploadingPhoto = false);
                return;
              }
              final url = await MediaStorageService.uploadProfilePhoto(
                memberId: 'new_${DateTime.now().millisecondsSinceEpoch}',
                imageFile: picked,
              );
              if (ctx.mounted) {
                setModalState(() {
                  uploadedPhotoPath = url ?? picked.path;
                  isUploadingPhoto = false;
                });
              }
            } catch (_) {
              if (ctx.mounted) setModalState(() => isUploadingPhoto = false);
            }
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
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
                              color: dragHandle,
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
                                        ? 'Tambah Akaun Anak / Ahli'
                                        : 'Add Child / Family Member',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isCoParent
                                        ? (isMs
                                            ? 'Tambah pasangan, ayah, ibu atau penjaga untuk bantu mengurus keluarga.'
                                            : 'Add a dad, mom, guardian, or grandparent to co-manage family.')
                                        : (isMs
                                            ? 'Tiada e-mel diperlukan untuk anak. Umur dikesan automatik.'
                                            : 'No email needed for kids. Age & stage are auto-detected.'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: warmCocoa,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(
                                  side: BorderSide(color: blushBorder),
                                ),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => Navigator.pop(ctx),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Role Toggle: Child/Teen vs Co-Parent / Guardian
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: blushSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: blushBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      isCoParent = false;
                                      if (selectedYear < currentYear - 22) {
                                        selectedYear = currentYear - 6;
                                      }
                                      if (!childAvatars.contains(selectedAvatar)) {
                                        selectedAvatar = '👧';
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: !isCoParent
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Text(
                                      isMs ? 'Anak / Remaja' : 'Child / Teen',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: !isCoParent
                                            ? CozyTheme.textDark
                                            : warmCocoa,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      isCoParent = true;
                                      if (selectedYear > currentYear - 18) {
                                        selectedYear = currentYear - 35;
                                      }
                                      if (!parentAvatars
                                          .contains(selectedAvatar)) {
                                        selectedAvatar =
                                            activeParentRel()['emoji'] as String;
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isCoParent
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Text(
                                      isMs
                                          ? 'Ibu Bapa / Penjaga'
                                          : 'Co-Parent / Guardian',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isCoParent
                                            ? CozyTheme.textDark
                                            : warmCocoa,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Relationship Selector when Co-Parent / Guardian is active
                        if (isCoParent) ...[
                          Text(
                            isMs
                                ? 'Hubungan / Peranan Penjaga'
                                : 'Who is this Co-Parent / Guardian?',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: parentRelations.map((rel) {
                              final id = rel['id'] as String;
                              final sel = id == parentRelation;
                              return ChoiceChip(
                                label: Text(
                                  '${rel['emoji']} ${isMs ? rel['ms'] : rel['en']}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: sel
                                        ? Colors.white
                                        : CozyTheme.textDark,
                                  ),
                                ),
                                selected: sel,
                                selectedColor: mochaPrimary,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: sel ? mochaPrimary : blushBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    parentRelation = id;
                                    selectedAvatar = rel['emoji'] as String;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Name
                        Text(
                          isMs ? 'Nama Panggilan' : 'Name',
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
                          decoration: fieldDeco(
                            isCoParent
                                ? (isMs
                                    ? 'Contoh: Azman (Ayah)'
                                    : 'e.g., Mark (Dad)')
                                : (isMs ? 'Contoh: Aiman' : 'e.g., Mia'),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Profile Photo Upload (Optional)
                        Text(
                          isMs
                              ? 'Gambar Profil (Pilihan)'
                              : 'Profile Picture (Optional)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: blushBorder, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: blushSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: blushBorder),
                                ),
                                child: isUploadingPhoto
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: mochaPrimary,
                                        ),
                                      )
                                    : (uploadedPhotoPath != null
                                        ? ClipOval(
                                            child: MediaStorageService
                                                .buildAdaptiveImage(
                                              uploadedPhotoPath,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              placeholder: Text(
                                                selectedAvatar,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            selectedAvatar,
                                            style:
                                                const TextStyle(fontSize: 24),
                                          )),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  uploadedPhotoPath != null
                                      ? (isMs
                                          ? 'Gambar profil ditambah'
                                          : 'Profile photo added')
                                      : (isMs
                                          ? 'Muat naik gambar atau guna avatar'
                                          : 'Upload a photo or use avatar below'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: warmCocoa,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: isMs ? 'Kamera' : 'Camera',
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                onPressed: isUploadingPhoto
                                    ? null
                                    : () => handlePickPhoto(ImageSource.camera),
                                icon: const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 20,
                                  color: mochaPrimary,
                                ),
                              ),
                              IconButton(
                                tooltip: isMs ? 'Galeri' : 'Gallery',
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                onPressed: isUploadingPhoto
                                    ? null
                                    : () =>
                                        handlePickPhoto(ImageSource.gallery),
                                icon: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 20,
                                  color: mochaPrimary,
                                ),
                              ),
                              if (uploadedPhotoPath != null)
                                IconButton(
                                  tooltip: isMs ? 'Buang' : 'Remove',
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  onPressed: () => setModalState(
                                    () => uploadedPhotoPath = null,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: Color(0xFFB3261E),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Avatar Picker
                        Text(
                          isMs ? 'Atau Pilih Avatar' : 'Or Choose Provided Avatar',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: avatars.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, idx) {
                              final em = avatars[idx];
                              final sel =
                                  uploadedPhotoPath == null && em == selectedAvatar;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedAvatar = em;
                                    uploadedPhotoPath = null;
                                  });
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: sel ? blushSurface : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: sel ? mochaPrimary : blushBorder,
                                      width: sel ? 2 : 1.1,
                                    ),
                                  ),
                                  child: Text(
                                    em,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // DOB Month + Year
                        Text(
                          isMs
                              ? 'Tarikh Lahir (Bulan & Tahun)'
                              : 'Date of Birth (Month & Year)',
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
                                decoration: fieldDeco(isMs ? 'Bulan' : 'Month'),
                                dropdownColor: Colors.white,
                                items: List.generate(
                                  12,
                                  (i) => DropdownMenuItem<int>(
                                    value: i + 1,
                                    child: Text(
                                      months[i],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => selectedMonth = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: selectedYear,
                                decoration: fieldDeco(isMs ? 'Tahun' : 'Year'),
                                dropdownColor: Colors.white,
                                items: years
                                    .map(
                                      (y) => DropdownMenuItem<int>(
                                        value: y,
                                        child: Text(
                                          '$y',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: CozyTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setModalState(() => selectedYear = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Auto-Detected Stage Pill
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: linenSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: linenBorder),
                          ),
                          child: Text(
                            isMs
                                ? '✨ Dikesan: Umur $age thn • ${ageStageLabel(age)}'
                                : '✨ Auto-detected: Age $age • ${ageStageLabel(age)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4-Digit PIN
                        Text(
                          pinRequired
                              ? (isMs
                                  ? 'PIN 4-Digit (Wajib untuk 9+ thn / Penjaga)'
                                  : '4-Digit PIN (Required for 9+y / Co-Parent)')
                              : (isMs
                                  ? 'PIN 4-Digit (Pilihan untuk < 9 thn)'
                                  : '4-Digit PIN (Optional for under 9y)'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: CozyTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: pinCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: fieldDeco('1234').copyWith(counterText: ''),
                        ),

                        if (errorMsg != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            errorMsg!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB3261E),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isUploadingPhoto
                                ? null
                                : () {
                                    final cleanName = nameCtrl.text.trim();
                                    final cleanPin = pinCtrl.text.trim();
                                    if (cleanName.isEmpty) {
                                      setModalState(() {
                                        errorMsg = isMs
                                            ? 'Sila masukkan nama ahli.'
                                            : 'Please enter a name.';
                                      });
                                      return;
                                    }
                                    if (cleanPin.isNotEmpty &&
                                        cleanPin.length != 4) {
                                      setModalState(() {
                                        errorMsg = isMs
                                            ? 'PIN mestilah tepat 4 digit.'
                                            : 'PIN must be exactly 4 digits.';
                                      });
                                      return;
                                    }
                                    if (pinRequired && cleanPin.length != 4) {
                                      setModalState(() {
                                        errorMsg = isMs
                                            ? 'Sila tetapkan PIN 4-digit untuk profil ini.'
                                            : 'Please set a 4-digit PIN for this profile.';
                                      });
                                      return;
                                    }

                                    HapticFeedback.mediumImpact();
                                    final rel = activeParentRel();
                                    ref
                                        .read(eratControllerProvider.notifier)
                                        .addFamilyMember(
                                          name: cleanName,
                                          avatarEmoji: selectedAvatar,
                                          customPhotoPath: uploadedPhotoPath,
                                          tagline: isCoParent
                                              ? (isMs
                                                  ? rel['ms'] as String
                                                  : rel['en'] as String)
                                              : null,
                                          role: resolveRole(age),
                                          birthMonth: selectedMonth,
                                          birthYear: selectedYear,
                                          pin: cleanPin.isEmpty
                                              ? null
                                              : cleanPin,
                                        );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isMs
                                              ? 'Profil $cleanName berjaya ditambah!'
                                              : '$cleanName’s profile has been created!',
                                        ),
                                        backgroundColor: mochaPrimary,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mochaPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              isMs
                                  ? 'Cipta Akaun Ahli'
                                  : 'Create Member Profile',
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
