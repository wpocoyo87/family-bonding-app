import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';

class WishGoalsTab extends ConsumerWidget {
  const WishGoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    final isMs = strings.isMs;
    final activeMember = appState.activeMember;
    final family = appState.family;

    final familyProgress =
        (family.familyGoalCurrentStars / family.familyGoalTargetStars)
            .clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Shared Family Goal Card (FR-32: No sibling ranking, collective progress!)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                activeMember.ageBand.primaryColor,
                activeMember.ageBand.primaryColor.withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tr(
                            'Matlamat Bersama Keluarga (Tiada Ranking)',
                            'Shared Family Goal (No Sibling Ranking)',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isMs
                              ? family.familyGoalTitleMs
                              : family.familyGoalTitleEn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: familyProgress,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.tr(
                  '⭐ ${family.familyGoalCurrentStars} / ${family.familyGoalTargetStars} Bintang Keluarga terkumpul bersama!',
                  '⭐ ${family.familyGoalCurrentStars} / ${family.familyGoalTargetStars} Family Stars collected together!',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Header + Add Wish Goal Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.tr('Wish Goal Bergambar', 'Visual Wish Goals'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    strings.tr(
                      'Anak cadangkan impian, Ibu/Ayah luluskan & capai bersama.',
                      'Children propose dreams, Parents approve & achieve together.',
                    ),
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showAddWishGoalDialog(context, ref, strings),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(strings.tr('Impian Baru', 'New Wish')),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Wish Goals Cards
        ...appState.wishGoals.map((goal) {
          final isPending = goal.status == WishGoalStatus.pendingApproval;
          final isAchieved = goal.status == WishGoalStatus.achieved;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isPending
                    ? Colors.orange.shade300
                    : isAchieved
                        ? Colors.green.shade400
                        : Colors.grey.shade300,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: goal.customImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: MediaStorageService.buildAdaptiveImage(
                                  goal.customImagePath,
                                  width: 56,
                                  height: 56,
                                  placeholder: Text(
                                    goal.iconEmoji,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                              )
                            : Text(
                                goal.iconEmoji,
                                style: const TextStyle(fontSize: 30),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  goal.memberName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: activeMember.ageBand.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    goal.basis.badge,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.orange.shade100
                                        : isAchieved
                                            ? Colors.green.shade100
                                            : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPending
                                        ? strings.tr(
                                            '⏳ Menunggu Kelulusan Parent',
                                            '⏳ Pending Parent Approval',
                                          )
                                        : isAchieved
                                            ? strings.tr('🎉 Tercapai!', '🎉 Achieved!')
                                            : strings.tr(
                                                '✅ Diluluskan (${goal.approvedByName ?? "Parent"})',
                                                '✅ Approved (${goal.approvedByName ?? "Parent"})',
                                              ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal.title(isMs),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAchieved
                            ? Colors.green
                            : activeMember.ageBand.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${goal.currentPoints} / ${goal.targetPoints} pts (${(goal.progress * 100).round()}%)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPending && activeMember.isParentOrGuardian)
                        FilledButton.tonalIcon(
                          onPressed: () {
                            controller.approveWishGoal(goal.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  strings.tr(
                                    '✅ Wish Goal "${goal.title(isMs)}" telah diluluskan!',
                                    '✅ Wish Goal "${goal.title(isMs)}" approved!',
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                          label: Text(
                            strings.tr('Luluskan Impian', 'Approve Wish'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAddWishGoalDialog(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) {
    final titleCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '150');
    WishGoalBasis selectedBasis = WishGoalBasis.weekly;
    String selectedEmoji = '🎁';
    String? selectedPhotoPath;
    bool isUploading = false;
    const emojis = ['🎁', '🍦', '🎨', '🚲', '🏕️', '📚', '⚽', '🍕'];

    final photoPresets = [
      (path: 'assets/images/challenge_clean_room.jpg', label: '🧸 Toy / LEGO', emoji: '🧸'),
      (path: 'assets/images/habit_study_read.jpg', label: '📚 Books / Study', emoji: '📚'),
      (path: 'assets/images/challenge_kindness.jpg', label: '🚲 Bicycle / Outdoor', emoji: '🚲'),
      (path: 'assets/images/family_hero.jpg', label: '🏡 Family Picnic', emoji: '🏡'),
      (path: 'assets/images/icon_good_deeds.jpg', label: '🍕 Pizza Party', emoji: '🍕'),
      (path: 'assets/images/mascot_companion.jpg', label: '🧚 Mascot / Art', emoji: '🎨'),
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                strings.tr('Tambah Wish Goal Bergambar', 'Add Visual Wish Goal'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Picture Preview Box
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD8B4FE), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: MediaStorageService.buildAdaptiveImage(
                            selectedPhotoPath,
                            width: 80,
                            height: 80,
                            placeholder: Text(
                              selectedEmoji,
                              style: const TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Choice: Pick Photo / Picture
                    const Text(
                      'Pilih Gambar / Foto Sendiri:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: photoPresets.map((p) {
                          final isSelected = selectedPhotoPath == p.path;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedPhotoPath = p.path;
                                  selectedEmoji = p.emoji;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF9333EA) : Colors.grey.shade300,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        p.path,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.label.split(' ').first,
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Or Pick Emoji
                    const Text(
                      'Atau Pilih Emoji:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: emojis.map((e) {
                        final isSelected = e == selectedEmoji && selectedPhotoPath == null;
                        return ChoiceChip(
                          label: Text(e, style: const TextStyle(fontSize: 18)),
                          selected: isSelected,
                          onSelected: (_) => setDialogState(() {
                            selectedEmoji = e;
                            selectedPhotoPath = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Camera & Gallery Upload for Wish Goal Photo
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: const Text('Kamera Hadiah'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF9333EA),
                              side: const BorderSide(color: Color(0xFFE9D5FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final xfile = await MediaStorageService.pickImage(
                                        source: ImageSource.camera);
                                    if (xfile != null) {
                                      setDialogState(() => isUploading = true);
                                      final uploaded =
                                          await MediaStorageService.uploadWishGoalPhoto(
                                        goalId: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                                        imageFile: xfile,
                                      );
                                      setDialogState(() {
                                        if (uploaded != null) selectedPhotoPath = uploaded;
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
                            label: const Text('Galeri Hadiah'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF9333EA),
                              side: const BorderSide(color: Color(0xFFE9D5FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final xfile = await MediaStorageService.pickImage(
                                        source: ImageSource.gallery);
                                    if (xfile != null) {
                                      setDialogState(() => isUploading = true);
                                      final uploaded =
                                          await MediaStorageService.uploadWishGoalPhoto(
                                        goalId: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                                        imageFile: xfile,
                                      );
                                      setDialogState(() {
                                        if (uploaded != null) selectedPhotoPath = uploaded;
                                        isUploading = false;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text(
                            'Memuat naik gambar hadiah...',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF9333EA), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: strings.tr(
                          'Apakah impian / aktiviti keluarga anda?',
                          'What is your wish or family activity?',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Basis / Timeframe Selector
                    const Text(
                      'Tempoh Masa Impian (Basis):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: WishGoalBasis.values.map((b) {
                        final isSel = selectedBasis == b;
                        return ChoiceChip(
                          label: Text(b.badge, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          onSelected: (_) => setDialogState(() => selectedBasis = b),
                          selectedColor: const Color(0xFFFEF3C7),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSel ? const Color(0xFF92400E) : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.tr('Sasaran Mata (Points)', 'Target Points'),
                        border: const OutlineInputBorder(),
                      ),
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
                    if (titleCtrl.text.trim().isEmpty) return;
                    final target = int.tryParse(pointsCtrl.text) ?? 150;
                    ref.read(eratControllerProvider.notifier).addWishGoal(
                          titleMs: titleCtrl.text.trim(),
                          iconEmoji: selectedEmoji,
                          targetPoints: target,
                          customImagePath: selectedPhotoPath,
                          basis: selectedBasis,
                        );
                    Navigator.pop(ctx);
                  },
                  child: Text(strings.tr('Hantar Impian', 'Submit Wish')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

