import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/theme/erat_palette.dart';
import '../../auth/presentation/auth_family_screen.dart';

class FamilyHubTab extends ConsumerStatefulWidget {
  const FamilyHubTab({super.key});

  @override
  ConsumerState<FamilyHubTab> createState() => _FamilyHubTabState();
}

class _FamilyHubTabState extends ConsumerState<FamilyHubTab> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final lang = ref.watch(appLanguageProvider);
    final activeMember = appState.activeMember;
    final worldTheme = ref.watch(selectedWorldThemeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      children: [
        // Top Header (Matching Mockup Screen 8: "Settings")
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                ref.read(appLanguageProvider.notifier).state =
                    lang == AppLanguage.ms ? AppLanguage.en : AppLanguage.ms;
              },
              child: Text(
                lang == AppLanguage.ms ? 'BM 🇲🇾' : 'EN 🌐',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: EratPalette.primaryPurple,
                ),
              ),
            ),
            Text(
              strings.tr('Settings', 'Settings'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: EratPalette.textDark,
              ),
            ),
            IconButton(
              onPressed: () => _showThemePickerModal(context, strings),
              icon: const Icon(
                Icons.settings_outlined,
                color: EratPalette.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // CARD 1: Active Member Profile Card with Custom Photo Support
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: EratPalette.softShadow,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showChangeProfilePhotoDialog(context, strings, activeMember),
                child: Stack(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: EratPalette.softLavender,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: EratPalette.lavenderBorder,
                          width: 2,
                        ),
                      ),
                      child: activeMember.customPhotoPath != null
                          ? ClipOval(
                              child: MediaStorageService.buildAdaptiveImage(
                                activeMember.customPhotoPath,
                                width: 62,
                                height: 62,
                                placeholder: Text(
                                  activeMember.avatarEmoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            )
                          : Text(
                              activeMember.avatarEmoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: EratPalette.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeMember.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: EratPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age ${activeMember.ageYears} • ${activeMember.ageBand.label(strings.isMs).split(" (").first}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: EratPalette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showChangeProfilePhotoDialog(context, strings, activeMember),
                      child: const Text(
                        '📷 Change Photo',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: EratPalette.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showSwitchMemberSheet(context, strings),
                child: Text(
                  strings.tr('Switch >', 'Switch >'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: EratPalette.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // CARD 2: Settings Menu Items Card (Matching Mockup Screen 8)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconColor: EratPalette.primaryPurple,
                title: strings.tr('Privacy Settings', 'Privacy Settings'),
                subtitle: strings.tr(
                  'Control what to share (${activeMember.privacyLevel.name})',
                  'Control what to share (${activeMember.privacyLevel.name})',
                ),
                onTap: () => _showPrivacyModal(context, strings),
              ),
              const Divider(height: 1, indent: 68, endIndent: 16),
              _SettingsTile(
                icon: Icons.groups_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconColor: EratPalette.primaryPurple,
                title: strings.tr('Family Members', 'Family Members'),
                subtitle: strings.tr(
                  'Manage your family (${appState.members.length}) & 48h Invite Code',
                  'Manage your family (${appState.members.length}) & 48h Invite Code',
                ),
                onTap: () => _showFamilyMembersModal(context, strings),
              ),
              const Divider(height: 1, indent: 68, endIndent: 16),
              _SettingsTile(
                icon: Icons.auto_awesome_rounded,
                iconBg: const Color(0xFFFFF7EB),
                iconColor: const Color(0xFFF59E0B),
                title: strings.tr('Appearance', 'Appearance'),
                subtitle: strings.tr('Choose your theme', 'Choose your theme'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${worldTheme.emoji} ${worldTheme.title}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: EratPalette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: EratPalette.textMuted,
                    ),
                  ],
                ),
                onTap: () => _showThemePickerModal(context, strings),
              ),
              const Divider(height: 1, indent: 68, endIndent: 16),
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                iconBg: const Color(0xFFFFF0F6),
                iconColor: const Color(0xFFEC4899),
                title: strings.tr('Notifications', 'Notifications'),
                subtitle: strings.tr('Stay updated', 'Stay updated'),
                trailing: Switch(
                  value: _notificationsEnabled,
                  activeTrackColor: EratPalette.primaryPurple,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
              ),
              const Divider(height: 1, indent: 68, endIndent: 16),
              _SettingsTile(
                icon: Icons.logout_rounded,
                iconBg: const Color(0xFFFFF0F0),
                iconColor: const Color(0xFFEF4444),
                title: strings.tr('Log Out', 'Log Out'),
                subtitle: strings.tr(
                  'Kembali ke halaman Log Masuk',
                  'Return to Login & Welcome screen',
                ),
                onTap: () {
                  ref.read(showOnboardingFlowProvider.notifier).state = true;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSwitchMemberSheet(BuildContext context, AppStrings strings) {
    final appState = ref.read(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr(
                    'Pilih Profil & Pengalaman Umur',
                    'Select Profile & Age Experience',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: EratPalette.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: appState.members.length,
                    itemBuilder: (ctx, i) {
                      final m = appState.members[i];
                      final selected = m.id == appState.activeMemberId;
                      return ListTile(
                        leading: Text(
                          m.avatarEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        title: Text(
                          '${m.name} (${m.ageYears}y)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(m.ageBand.label(strings.isMs)),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: EratPalette.primaryPurple,
                              )
                            : null,
                        onTap: () {
                          controller.switchProfile(m.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemePickerModal(BuildContext context, AppStrings strings) {
    final current = ref.read(selectedWorldThemeProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr('Choose Your Theme (6 Worlds)', 'Choose Your Theme (6 Worlds)'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: EratPalette.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: EratWorldTheme.values.map((t) {
                    final selected = t == current;
                    return ChoiceChip(
                      avatar: Text(t.emoji),
                      label: Text(
                        t.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : EratPalette.textDark,
                        ),
                      ),
                      selected: selected,
                      selectedColor: t.accentColor,
                      onSelected: (_) {
                        ref.read(selectedWorldThemeProvider.notifier).state = t;
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyModal(BuildContext context, AppStrings strings) {
    final appState = ref.read(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);
    final member = appState.activeMember;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.tr('Privacy Settings', 'Privacy Settings'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...PrivacyLevel.values.map((lvl) {
                  final selected = lvl == member.privacyLevel;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: EratPalette.primaryPurple,
                    ),
                    title: Text(
                      lvl.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      controller.updateMemberPrivacy(member.id, lvl);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeProfilePhotoDialog(
    BuildContext context,
    AppStrings strings,
    FamilyMember member,
  ) {
    final photoPresets = [
      (path: 'assets/images/family_hero.jpg', label: '👩🏻‍💼 Mom / Family'),
      (path: 'assets/images/habit_study_read.jpg', label: '👦🏻 Boy / Study'),
      (path: 'assets/images/challenge_kindness.jpg', label: '👧🏻 Girl / Kindness'),
      (path: 'assets/images/challenge_clean_room.jpg', label: '🧸 Explorer / Play'),
      (path: 'assets/images/mascot_companion.jpg', label: '🧚 Mascot Lumi'),
      (path: 'assets/images/app_logo_icon.jpg', label: '🌟 ERAT Purple'),
    ];

    String? selectedPhoto = member.customPhotoPath;
    bool isUploading = false;
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                strings.tr('Tukar Gambar Profil', 'Change Profile Photo'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Avatar Preview
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: EratPalette.softLavender,
                        shape: BoxShape.circle,
                        border: Border.all(color: EratPalette.primaryPurple, width: 2.5),
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: MediaStorageService.buildAdaptiveImage(
                          selectedPhoto,
                          width: 84,
                          height: 84,
                          placeholder: Text(
                            member.avatarEmoji,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Camera & Gallery Upload Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: Text(strings.tr('Kamera', 'Camera')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              foregroundColor: EratPalette.primaryPurple,
                              side: const BorderSide(color: EratPalette.lavenderBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final xfile = await MediaStorageService.pickImage(
                                        source: ImageSource.camera);
                                    if (xfile != null) {
                                      setDialogState(() => isUploading = true);
                                      final uploaded =
                                          await MediaStorageService.uploadProfilePhoto(
                                        memberId: member.id,
                                        imageFile: xfile,
                                      );
                                      setDialogState(() {
                                        if (uploaded != null) selectedPhoto = uploaded;
                                        isUploading = false;
                                      });
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_library_rounded, size: 16),
                            label: Text(strings.tr('Galeri', 'Gallery')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              foregroundColor: EratPalette.primaryPurple,
                              side: const BorderSide(color: EratPalette.lavenderBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final xfile = await MediaStorageService.pickImage(
                                        source: ImageSource.gallery);
                                    if (xfile != null) {
                                      setDialogState(() => isUploading = true);
                                      final uploaded =
                                          await MediaStorageService.uploadProfilePhoto(
                                        memberId: member.id,
                                        imageFile: xfile,
                                      );
                                      setDialogState(() {
                                        if (uploaded != null) selectedPhoto = uploaded;
                                        isUploading = false;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text(
                            'Memuat naik ke storan...',
                            style: TextStyle(
                              fontSize: 12,
                              color: EratPalette.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    const Text(
                      'Atau Pilih Foto Preset:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: EratPalette.textDark),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: photoPresets.map((p) {
                        final isSel = selectedPhoto == p.path;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedPhoto = p.path),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel ? EratPalette.primaryPurple : Colors.grey.shade300,
                                width: isSel ? 2.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    p.path,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  p.label.split(' ').first,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Custom Link or Reset to Emoji button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: ctx,
                                builder: (uCtx) => AlertDialog(
                                  title: const Text('Link Gambar Sendiri (URL)'),
                                  content: TextField(
                                    controller: urlCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'https://...',
                                      labelText: 'URL Gambar',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(uCtx),
                                      child: const Text('Batal'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        if (urlCtrl.text.trim().isNotEmpty) {
                                          setDialogState(() {
                                            selectedPhoto = urlCtrl.text.trim();
                                          });
                                        }
                                        Navigator.pop(uCtx);
                                      },
                                      child: const Text('Gunakan'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.link_rounded, size: 16),
                            label: const Text('Custom URL', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => setDialogState(() => selectedPhoto = null),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Guna Emoji', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(strings.tr('Batal', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedPhoto != null) {
                      ref
                          .read(eratControllerProvider.notifier)
                          .updateMemberPhoto(member.id, selectedPhoto!);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✨ Profile photo updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(strings.tr('Simpan', 'Save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFamilyMembersModal(BuildContext context, AppStrings strings) {
    final appState = ref.read(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);
    final nameCtrl = TextEditingController();
    final yearCtrl =
        TextEditingController(text: '${DateTime.now().year - 8}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${appState.family.name} • Invite: ${appState.family.inviteCode}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EratPalette.primaryPurple,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: strings.tr(
                    'Tambah Nama Ahli Baru',
                    'Add New Member Name',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yearCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.tr('Tahun Lahir', 'Birth Year'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              EratPrimaryPillButton(
                label: strings.tr('Tambah Ahli Keluarga', 'Add Family Member'),
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final yr = int.tryParse(yearCtrl.text) ?? 2018;
                  controller.addFamilyMember(
                    name: nameCtrl.text.trim(),
                    avatarEmoji: '🌟',
                    role: MemberRole.child,
                    birthMonth: 6,
                    birthYear: yr,
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: EratPalette.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: EratPalette.textMuted,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: EratPalette.textMuted,
          ),
    );
  }
}
