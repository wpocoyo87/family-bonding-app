import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';
import '../domain/parenting_learning_resources.dart';

class ParentCommunityTab extends ConsumerStatefulWidget {
  const ParentCommunityTab({super.key});

  @override
  ConsumerState<ParentCommunityTab> createState() => _ParentCommunityTabState();
}

class _ParentCommunityTabState extends ConsumerState<ParentCommunityTab> {
  // Parent View State (0 = Forum Ibu Bapa, 1 = Kajian & Jurnal, 2 = Jurnal Anak)
  int _parentSubTab = 0;
  String _parentCountryFilter = 'ALL'; // 'ALL', 'MY', 'GLOBAL'
  String _selectedCategory = 'All';
  String _selectedResearchCategory = 'Semua';

  // Child View State (0 = My Journal / Diari Saya, 1 = Kids Wisdom / Sudut Ilmu Teladan)
  int _childSubTab = 0;
  String _childCountryFilter = 'MY'; // 'MY' (Default local), 'GLOBAL', 'ALL'
  String? _playingVoiceJournalId;

  final Set<String> _likedPostIds = {'post_my_1'};

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final controller = ref.read(eratControllerProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    final activeMember = appState.activeMember;
    final isParent = activeMember.isParentOrGuardian;
    final worldTheme = ref.watch(selectedWorldThemeProvider);

    // ==========================================================
    // 1. IF ACTIVE MEMBER IS A CHILD: SHOW "DIARI & ILMU TELADAN"
    // (Children do NOT see parent adult discussions; they see their
    //  own personal/voice journal and curated behaviour tips from parents)
    // ==========================================================
    if (!isParent) {
      return _buildChildJournalAndWisdom(
        context,
        activeMember,
        appState,
        controller,
        worldTheme,
        strings,
      );
    }

    // ==========================================================
    // 2. IF ACTIVE MEMBER IS A PARENT: SHOW "PARENT COMMUNITY & SHARED JOURNALS"
    // ==========================================================
    return _buildParentCommunityView(
      context,
      activeMember,
      appState,
      controller,
      worldTheme,
      strings,
    );
  }

  // =========================================================================
  // CHILD VIEW: PERSONAL JOURNAL + KIDS KNOWLEDGE CORNER (BEHAVIOUR & STORIES)
  // =========================================================================
  Widget _buildChildJournalAndWisdom(
    BuildContext context,
    FamilyMember activeMember,
    EratAppState appState,
    EratController controller,
    EratWorldTheme worldTheme,
    AppStrings strings,
  ) {
    final myJournalEntries = appState.journalEntries
        .where((j) => j.memberId == activeMember.id)
        .toList();

    return Column(
      children: [
        // Top Header
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  _childSubTab == 0
                      ? 'Diari Saya 📖✨'
                      : 'Sudut Ilmu Teladan 💡',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: EratPalette.textDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: _childSubTab == 0 ? 'Catat Diari Baru' : 'Info',
                onPressed: () {
                  if (_childSubTab == 0) {
                    _showAddJournalSheet(context, activeMember, controller);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🌟 Tips & ilmu ini dikongsi oleh ibu bapa untuk membimbing adik-adik!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: Icon(
                  _childSubTab == 0 ? Icons.edit_note_rounded : Icons.info_outline_rounded,
                  size: 26,
                  color: EratPalette.textDark,
                ),
              ),
            ],
          ),
        ),

        // Segmented Switcher for Kids: Diari Saya vs Sudut Ilmu
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: EratPalette.lavenderBorder),
            ),
            child: Row(
              children: [
                _buildSegmentItem(
                  label: '📖 Diari Saya (${myJournalEntries.length})',
                  isSelected: _childSubTab == 0,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _childSubTab = 0),
                ),
                _buildSegmentItem(
                  label: '💡 Tips & Ilmu Teladan',
                  isSelected: _childSubTab == 1,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _childSubTab = 1),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _childSubTab == 0
              ? _buildChildJournalList(
                  context,
                  activeMember,
                  myJournalEntries,
                  controller,
                  worldTheme,
                )
              : _buildChildKnowledgeList(
                  context,
                  activeMember,
                  appState,
                  controller,
                  worldTheme,
                ),
        ),
      ],
    );
  }

  /// SUB-VIEW 1 (CHILD): PERSONAL & VOICE JOURNAL LIST
  Widget _buildChildChildGreetingCard(
    FamilyMember activeMember,
    EratWorldTheme worldTheme,
    EratController controller,
  ) {
    final isYoungKid = activeMember.ageYears <= 6;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            worldTheme.softTint,
            const Color(0xFFFDF4FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: EratPalette.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/mascot_companion.jpg',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buku Harian ${activeMember.name} 🌟',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: EratPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isYoungKid
                          ? 'Belum pandai menaip? Tekan mikrofon untuk bercakap ke dalam diari!'
                          : 'Catat perasaan, detik bangga, atau luahan hati kamu hari ini.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Audio Voice Journal (Giant for young kids) + Written Journal
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.mic_rounded, size: 20),
                  label: const Text(
                    'Rakam Suara 🎙️',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  onPressed: () => _showVoiceJournalSheet(context, activeMember, controller),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: worldTheme.accentColor,
                    side: BorderSide(color: worldTheme.accentColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text(
                    'Tulis Catatan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  onPressed: () => _showAddJournalSheet(context, activeMember, controller),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildJournalList(
    BuildContext context,
    FamilyMember activeMember,
    List<JournalEntry> entries,
    EratController controller,
    EratWorldTheme worldTheme,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _buildChildChildGreetingCard(activeMember, worldTheme, controller),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catatan Diari Kamu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: EratPalette.textDark,
              ),
            ),
            Text(
              '${entries.length} Catatan',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: EratPalette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EratPalette.lavenderBorder),
            ),
            child: const Center(
              child: Text(
                'Belum ada catatan lagi. Tekan "Rakam Suara 🎙️" untuk luahkan hari kamu!',
                textAlign: TextAlign.center,
                style: TextStyle(color: EratPalette.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          ...entries.map((entry) {
            final isPlaying = _playingVoiceJournalId == entry.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Mood Emoji + Date + Privacy Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(entry.moodEmoji, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: entry.isSharedWithParents
                              ? const Color(0xFFFCE7F3)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.isSharedWithParents ? '💖 Dikongsi' : '🔒 Hanya Saya',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: entry.isSharedWithParents
                                    ? const Color(0xFFDB2777)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Voice Player (If Voice Journal)
                  if (entry.isVoiceEntry) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_playingVoiceJournalId == entry.id) {
                                  _playingVoiceJournalId = null;
                                } else {
                                  _playingVoiceJournalId = entry.id;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [4, 12, 18, 10, 22, 14, 8, 20, 16, 10, 14].map((h) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 3,
                                  height: isPlaying ? (h * 1.1).clamp(4.0, 22.0) : h.toDouble(),
                                  decoration: BoxDecoration(
                                    color: isPlaying ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Text(
                            entry.voiceDuration ?? '0:05',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Content text
                  Text(
                    entry.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  /// SUB-VIEW 2 (CHILD): KIDS KNOWLEDGE CORNER (BEHAVIOUR, CALMING & KINDNESS POSTS)
  Widget _buildChildKnowledgeList(
    BuildContext context,
    FamilyMember activeMember,
    EratAppState appState,
    EratController controller,
    EratWorldTheme worldTheme,
  ) {
    final childAge = activeMember.ageYears;

    // Filter posts that are marked for kids and match country filter
    final kidsPosts = appState.communityPosts.where((p) {
      if (!p.isSharedForKids) return false;
      if (_childCountryFilter == 'MY') return p.countryCode == 'MY';
      if (_childCountryFilter == 'GLOBAL') return p.isInternational || p.countryCode == 'GLOBAL';
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        // Minimalist Header Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'Sudut Ilmu & Teladan',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: worldTheme.softTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activeMember.name} • $childAge Thn',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: worldTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ====================================================================
        // AGE-ADAPTIVE SECTION:
        // - Age <= 5: YouTube Videos (Good deeds, respect parents)
        // - Age 6..9: Fiction Story Books (Respect elders, love youngest)
        // - Age 10..13: Short Story Books (Moral values, empathy)
        // - Age 14..17: Short Novels (Teen identity, family bonding)
        // - Age >= 18: Journal Articles & Insights (Daniel, 20yo)
        // ====================================================================
        if (childAge <= 5)
          _buildAge4VideoSection(context, worldTheme)
        else if (childAge <= 9)
          _buildAge8StoryBookSection(context, worldTheme)
        else if (childAge <= 13)
          _buildAge11ShortStorySection(context, worldTheme)
        else if (childAge <= 17)
          _buildAge15NovelSection(context, worldTheme)
        else
          _buildAge20JournalSection(context, worldTheme),

        const SizedBox(height: 20),

        // Section Title: Nasihat Ibu Bapa (Minimalist)
        Row(
          children: [
            const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            const Text(
              'Petua Ibu Bapa',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${kidsPosts.length} petua',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Country & Language Filter Chips (Local MY vs International)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill(
                'MY',
                '🇲🇾 Malaysia (Tempatan)',
                _childCountryFilter == 'MY',
                () => setState(() => _childCountryFilter = 'MY'),
                worldTheme,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'GLOBAL',
                '🌍 Antarabangsa (Global)',
                _childCountryFilter == 'GLOBAL',
                () => setState(() => _childCountryFilter = 'GLOBAL'),
                worldTheme,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'ALL',
                '🌐 Semua Tips (${appState.communityPosts.where((p) => p.isSharedForKids).length})',
                _childCountryFilter == 'ALL',
                () => setState(() => _childCountryFilter = 'ALL'),
                worldTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Knowledge Posts Feed
        ...kidsPosts.map((post) {
          final isLiked = _likedPostIds.contains(post.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: EratPalette.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author & Country Flag
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: worldTheme.softTint,
                      child: Text(post.authorAvatar, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: EratPalette.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post.countryName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            post.authorRole,
                            style: const TextStyle(fontSize: 11, color: EratPalette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post.tag,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Post Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: EratPalette.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // Post Body
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Kid Like Button (Encouragement)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            _likedPostIds.remove(post.id);
                          } else {
                            _likedPostIds.add(post.id);
                            controller.toggleLikePost(post.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isLiked ? const Color(0xFFFCE7F3) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              size: 16,
                              color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${post.likes + (isLiked ? 1 : 0)} Suka',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Disahkan oleh Ibu Bapa',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // PARENT VIEW: COMMUNITY FORUM + SHARED KIDS JOURNALS
  // =========================================================================
  Widget _buildParentCommunityView(
    BuildContext context,
    FamilyMember activeMember,
    EratAppState appState,
    EratController controller,
    EratWorldTheme worldTheme,
    AppStrings strings,
  ) {
    final sharedKidsEntries = appState.journalEntries
        .where((j) => j.isSharedWithParents)
        .toList();

    return Column(
      children: [
        // Parent Header
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        strings.tr('Parent Community', 'Parent Community'),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: EratPalette.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: EratPalette.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ibu Bapa Sah',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Perkongsian bimbingan tingkah laku & panduan keluarga',
                    style: TextStyle(fontSize: 11.5, color: EratPalette.textMuted),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: worldTheme.softTint,
                child: IconButton(
                  tooltip: 'Kongsi Petua Baru',
                  icon: Icon(Icons.edit_note_rounded, color: worldTheme.accentColor, size: 20),
                  onPressed: () => _showCreateParentPostSheet(context, controller),
                ),
              ),
            ],
          ),
        ),

        // Segment Switcher: Forum vs Kajian Jurnal vs Shared Kids Journals
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: EratPalette.lavenderBorder),
            ),
            child: Row(
              children: [
                _buildSegmentItem(
                  label: '👨‍👩‍👧‍👦 Forum',
                  isSelected: _parentSubTab == 0,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _parentSubTab = 0),
                ),
                _buildSegmentItem(
                  label: '📚 Kajian Jurnal',
                  isSelected: _parentSubTab == 1,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _parentSubTab = 1),
                ),
                _buildSegmentItem(
                  label: '📖 Jurnal Anak (${sharedKidsEntries.length})',
                  isSelected: _parentSubTab == 2,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _parentSubTab = 2),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _parentSubTab == 0
              ? _buildParentForumFeed(context, appState, controller, worldTheme)
              : _parentSubTab == 1
                  ? _buildParentResearchArticlesView(context, worldTheme)
                  : _buildSharedKidsJournalsForParents(context, sharedKidsEntries, worldTheme),
        ),
      ],
    );
  }

  /// Parent Forum Feed with Country Filter (Local MY vs International)
  Widget _buildParentForumFeed(
    BuildContext context,
    EratAppState appState,
    EratController controller,
    EratWorldTheme worldTheme,
  ) {
    final filteredPosts = appState.communityPosts.where((p) {
      if (_parentCountryFilter == 'MY' && p.countryCode != 'MY') return false;
      if (_parentCountryFilter == 'GLOBAL' && (!p.isInternational && p.countryCode != 'GLOBAL')) return false;
      if (_selectedCategory != 'All' && p.tag != _selectedCategory) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
      children: [
        // Daily Parenting Insight Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEDE9FE), Color(0xFFEAF4FF)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EratPalette.lavenderBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: EratPalette.softShadow,
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFF6C5CE7), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Petua Harian Ibu Bapa 💡',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: EratPalette.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '"Bina hubungan sebelum pembetulan. Beri pengiktirafan emosi sebelum menyuruh anak kemas."',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: EratPalette.textDark,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Country Filter Pills (Local vs International)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill(
                'ALL',
                '🌐 Semua (${appState.communityPosts.length})',
                _parentCountryFilter == 'ALL',
                () => setState(() => _parentCountryFilter = 'ALL'),
                worldTheme,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'MY',
                '🇲🇾 Malaysia (Tempatan)',
                _parentCountryFilter == 'MY',
                () => setState(() => _parentCountryFilter = 'MY'),
                worldTheme,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                'GLOBAL',
                '🌍 Antarabangsa',
                _parentCountryFilter == 'GLOBAL',
                () => setState(() => _parentCountryFilter = 'GLOBAL'),
                worldTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Topic Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'All',
              'Bimbingan Tingkah Laku',
              'Kawalan Emosi',
              'Ketenangan Tidur',
              'Healthy Habits',
            ].map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: worldTheme.accentColor,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : EratPalette.textDark,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Discussion Posts Feed
        ...filteredPosts.map((post) {
          final isLiked = _likedPostIds.contains(post.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: EratPalette.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: EratPalette.softLavender,
                      child: Text(post.authorAvatar, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: EratPalette.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.countryName,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          Text(
                            post.authorRole,
                            style: const TextStyle(fontSize: 11, color: EratPalette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (post.isSharedForKids)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🌟 Sudut Ilmu',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: EratPalette.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Likes & Replies
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            _likedPostIds.remove(post.id);
                          } else {
                            _likedPostIds.add(post.id);
                            controller.toggleLikePost(post.id);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                            size: 18,
                            color: isLiked ? const Color(0xFFEF4444) : EratPalette.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes + (isLiked ? 1 : 0)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isLiked ? const Color(0xFFEF4444) : EratPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 17, color: EratPalette.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${post.replies} respons',
                          style: const TextStyle(fontSize: 12.5, color: EratPalette.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Shared Kids Journals View for Parents (Sarah Mom)
  Widget _buildSharedKidsJournalsForParents(
    BuildContext context,
    List<JournalEntry> sharedEntries,
    EratWorldTheme worldTheme,
  ) {
    if (sharedEntries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Anak-anak belum berkongsi catatan diari lagi.\nBila mereka pilih "Kongsi dengan Ibu Bapa", ia akan muncul di sini!',
            textAlign: TextAlign.center,
            style: TextStyle(color: EratPalette.textMuted, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF4FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF5D0FE)),
          ),
          child: const Row(
            children: [
              Text('💖', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Catatan diari ini dikongsi oleh anak-anak dengan rela hati untuk ibu bapa raikan usaha mereka.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF86198F)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        ...sharedEntries.map((entry) {
          final isPlaying = _playingVoiceJournalId == entry.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: EratPalette.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(entry.moodEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          entry.memberName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: EratPalette.textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: EratPalette.textDark,
                  ),
                ),
                const SizedBox(height: 6),

                if (entry.isVoiceEntry) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _playingVoiceJournalId =
                                  _playingVoiceJournalId == entry.id ? null : entry.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '🎙️ Rakam Suara Anak',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          entry.voiceDuration ?? '0:05',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                Text(
                  entry.content,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.35),
                ),
                const SizedBox(height: 10),

                // Mom Action: Leave Hug / Encouragement
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDB2777),
                      backgroundColor: const Color(0xFFFDF2F8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.favorite_rounded, size: 16),
                    label: const Text(
                      'Beri Kata Semangat 💖',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFDB2777),
                          content: Text('Pelukan kasih sayang dihantar ke ${entry.memberName}! 💖'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // MODALS & BOTTOM SHEETS
  // =========================================================================

  /// Audio Voice Journal Sheet (Designed for kids 4-6y like Emmi)
  void _showVoiceJournalSheet(
    BuildContext context,
    FamilyMember activeMember,
    EratController controller,
  ) {
    bool isRecording = false;
    String selectedMood = '🌟';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rakam Suara Diari ${activeMember.name} 🎙️',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih perasaan kamu dan tekan mikrofon untuk bercakap:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // Mood Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['🌟', '😊', '🚀', '😴', '😢'].map((m) {
                      final isSel = selectedMood == m;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedMood = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? const Color(0xFFF59E0B) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(m, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Giant Mic Button for Kids
                  GestureDetector(
                    onTapDown: (_) {
                      setSheetState(() => isRecording = true);
                    },
                    onTapUp: (_) {
                      setSheetState(() => isRecording = false);
                      controller.addJournalEntry(
                        title: 'Suara Diari: ${activeMember.name} ($selectedMood)',
                        content: 'Adik bercakap tentang hari ini dengan gembira dan berkongsi detik indah!',
                        moodEmoji: selectedMood,
                        isVoiceEntry: true,
                        voiceDuration: '0:07',
                        isSharedWithParents: true,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('🎙️ Suara diari ${activeMember.name} telah disimpan! ✨'),
                        ),
                      );
                    },
                    onTapCancel: () {
                      setSheetState(() => isRecording = false);
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: isRecording
                            ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                            : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isRecording ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                                .withValues(alpha: 0.35),
                            blurRadius: isRecording ? 20 : 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isRecording ? Icons.fiber_manual_record_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isRecording
                        ? '🔴 SEDANG MERAKAM SUARA... (LEPASKAN)'
                        : 'Tekan & tahan untuk bercakap!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isRecording ? const Color(0xFFDC2626) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Written Journal Sheet
  void _showAddJournalSheet(
    BuildContext context,
    FamilyMember activeMember,
    EratController controller,
  ) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedMood = '😊';
    bool shareWithParents = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Diari Baru 📖',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Mood Selector
                  const Text(
                    'Bagaimana perasaan kamu hari ini?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['😊', '🌟', '🚀', '😴', '😢'].map((m) {
                      final isSel = selectedMood == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedMood = m),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? const Color(0xFFF59E0B) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(m, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tajuk (cth: Kemaskan katil sendiri)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: contentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis apa yang kamu rasa atau buat hari ini...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sharing toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Kongsi dengan Ibu & Ayah',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Ibu & Ayah boleh membaca dan memberi pelukan kata semangat',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: shareWithParents,
                    onChanged: (v) => setSheetState(() => shareWithParents = v),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EratPalette.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        if (contentCtrl.text.trim().isEmpty) return;
                        controller.addJournalEntry(
                          title: titleCtrl.text.trim().isEmpty
                              ? 'Catatan Hari Ini'
                              : titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          moodEmoji: selectedMood,
                          isSharedWithParents: shareWithParents,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✨ Catatan diari kamu berjaya disimpan!')),
                        );
                      },
                      child: const Text('Simpan Diari ✨', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Parent Create Post Sheet with Country Selection & "Share to Kids Corner" Switch
  void _showCreateParentPostSheet(BuildContext context, EratController controller) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedTag = 'Bimbingan Tingkah Laku';
    String selectedCountry = 'MY';
    bool shareToKids = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kongsi Petua Bimbingan Ibu Bapa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Country Selector Row
                  Row(
                    children: [
                      const Text(
                        'Negara:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('🇲🇾 Malaysia'),
                        selected: selectedCountry == 'MY',
                        onSelected: (_) => setSheetState(() => selectedCountry = 'MY'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('🌍 Antarabangsa'),
                        selected: selectedCountry == 'GLOBAL',
                        onSelected: (_) => setSheetState(() => selectedCountry = 'GLOBAL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tajuk (cth: Cara tenang hadapi anak merajuk)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: bodyCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Kongsikan panduan, pengalaman, atau tips yang berjaya...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Switch: Share to Kids Knowledge Corner
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Kongsi ke Sudut Ilmu Kanak-Kanak 🌟',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Boleh dibaca oleh anak-anak sebagai tips tingkah laku & ketenangan diri',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    value: shareToKids,
                    onChanged: (v) => setSheetState(() => shareToKids = v),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EratPalette.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        controller.addCommunityPost(
                          title: titleCtrl.text.trim(),
                          content: bodyCtrl.text.trim(),
                          tag: selectedTag,
                          countryCode: selectedCountry,
                          countryName: selectedCountry == 'MY' ? 'Malaysia 🇲🇾' : 'International 🌍',
                          language: selectedCountry == 'MY' ? 'ms' : 'en',
                          isSharedForKids: shareToKids,
                          isInternational: selectedCountry == 'GLOBAL',
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✨ Petua berjaya dikongsi ke Komuniti & Sudut Ilmu!'),
                          ),
                        );
                      },
                      child: const Text('Terbitkan Petua', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // HELPER WIDGETS
  // =========================================================================
  Widget _buildSegmentItem({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : EratPalette.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    String key,
    String label,
    bool isSelected,
    VoidCallback onTap,
    EratWorldTheme worldTheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? worldTheme.accentColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? worldTheme.accentColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. AGE 4: YOUTUBE VIDEOS (MINIMALIST)
  // ===========================================================================
  Widget _buildAge4VideoSection(BuildContext context, EratWorldTheme worldTheme) {
    final videos = ParentingAndLearningRepository.age4Videos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎬', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text(
              'Video Teladan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Umur 4 Thn',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...videos.map((vid) {
          return InkWell(
            onTap: () => _showYouTubeVideoDialog(context, vid),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(vid.thumbnailEmoji, style: const TextStyle(fontSize: 22)),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vid.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(vid.duration, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                vid.moralTheme,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: vid.badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 2. AGE 8: FICTION STORY BOOKS (MINIMALIST)
  // ===========================================================================
  Widget _buildAge8StoryBookSection(BuildContext context, EratWorldTheme worldTheme) {
    final books = ParentingAndLearningRepository.age8StoryBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📚', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text(
              'Buku Cerita Fiksyen',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Umur 8 Thn',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...books.map((b) {
          return InkWell(
            onTap: () => _showFictionStoryDialog(context, b),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(b.coverEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${b.readingTime} • ${b.chapters.length} Bab • ${b.author}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 3. AGE 11: SHORT STORY BOOKS (MINIMALIST)
  // ===========================================================================
  Widget _buildAge11ShortStorySection(BuildContext context, EratWorldTheme worldTheme) {
    final stories = ParentingAndLearningRepository.age11ShortStories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📖', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text(
              'Cerita Pendek Inspirasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Umur 11 Thn',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...stories.map((st) {
          return InkWell(
            onTap: () => _showShortStoryDialog(context, st),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(st.coverEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${st.readingTime} • ${st.author}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 4. AGE 15: TEEN NOVELS (MINIMALIST)
  // ===========================================================================
  Widget _buildAge15NovelSection(BuildContext context, EratWorldTheme worldTheme) {
    final novels = ParentingAndLearningRepository.age15Novels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📕', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text(
              'Novel Remaja',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Umur 15 Thn',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...novels.map((nov) {
          return InkWell(
            onTap: () => _showTeenNovelDialog(context, nov),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(nov.coverEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nov.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${nov.chapters.length} Bab • ${nov.readingTime} • ${nov.author}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 5. AGE 20: JOURNAL PAPERS (MINIMALIST)
  // ===========================================================================
  Widget _buildAge20JournalSection(BuildContext context, EratWorldTheme worldTheme) {
    final papers = ParentingAndLearningRepository.age20JournalPapers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Text(
              'Jurnal Psikologi Dewasa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Umur 20 Thn',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...papers.map((p) {
          return InkWell(
            onTap: () => _showYoungAdultPaperDialog(context, p),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('📑', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${p.authors} (${p.year}) • ${p.journal}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // 6. PARENT RESEARCH ARTICLES VIEW (MINIMALIST)
  // ===========================================================================
  Widget _buildParentResearchArticlesView(
    BuildContext context,
    EratWorldTheme worldTheme,
  ) {
    final allArticles = ParentingAndLearningRepository.parentArticles;
    final filtered = _selectedResearchCategory == 'Semua'
        ? allArticles
        : allArticles.where((a) => a.category.contains(_selectedResearchCategory)).toList();

    final categories = [
      'Semua',
      'Psikologi Tabiat',
      'Motivasi Intrinsik',
      'Disiplin Positif',
      'Perkembangan Otak',
      'Kesejahteraan Mental',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        // Minimalist Header Bar
        Row(
          children: [
            const Text('🔬', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text(
              'Kajian & Jurnal Keibubapaan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: EratPalette.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${filtered.length} Kajian',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSel = _selectedResearchCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedResearchCategory = cat),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? worldTheme.accentColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? worldTheme.accentColor : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Sleek Minimalist Article Cards
        ...filtered.map((art) {
          return InkWell(
            onTap: () => _showParentArticleDialog(context, art),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: EratPalette.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(art.iconEmoji, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: art.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          art.category,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: art.accentColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        art.year,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    art.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: EratPalette.textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),

                  Text(
                    '${art.authors} • ${art.journalOrPublisher}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 13, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          art.keyTakeaway,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
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

  // ===========================================================================
  // 7. MODAL DIALOGS FOR RICH MEDIA & READERS
  // ===========================================================================

  void _showYouTubeVideoDialog(BuildContext context, KidsYouTubeVideo video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                video.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Simulation
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(video.thumbnailEmoji, style: const TextStyle(fontSize: 44)),
                      const SizedBox(height: 6),
                      Text(
                        video.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: Text(
                      '▶ Sedang memainkan (${video.duration})',
                      style: const TextStyle(fontSize: 10.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pelajaran: ${video.moralTheme} bersama ${video.channelName}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              video.description,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
            ),
            const SizedBox(height: 14),

            // Video link info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      video.videoUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF2563EB)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: video.videoUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pautan YouTube disalin!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Syabas! Adik telah menonton video teladan dan membina akhlak baik!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Tanda Telah Tonton ✓'),
          ),
        ],
      ),
    );
  }

  void _showFictionStoryDialog(BuildContext context, FictionStoryBook book) {
    showDialog(
      context: context,
      builder: (ctx) {
        int activeChapter = 0;

        return StatefulBuilder(
          builder: (ctx, setStoryState) {
            final chap = book.chapters[activeChapter];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(book.coverEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Oleh: ${book.author} • Bab ${activeChapter + 1} daripada ${book.chapters.length}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          chap.title,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        chap.content,
                        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (activeChapter > 0)
                  TextButton(
                    onPressed: () => setStoryState(() => activeChapter--),
                    child: const Text('◀ Bab Sebelum'),
                  ),
                if (activeChapter < book.chapters.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setStoryState(() => activeChapter++),
                    child: const Text('Bab Seterusnya ▶'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🌟 Tahniah! Kamu telah tamat membaca buku cerita teladan!'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Tamat Bacaan ✓'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShortStoryDialog(BuildContext context, ShortStoryBook story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(story.coverEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Karya: ${story.author} • ${story.readingTime}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nilai Moral: ${story.moralLesson}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  story.fullStory,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🌟 Bagus sekali! Teruskan memupuk empati dan nilai murni dalam keluarga!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Selesai Membaca ✓'),
          ),
        ],
      ),
    );
  }

  void _showTeenNovelDialog(BuildContext context, TeenShortNovel novel) {
    showDialog(
      context: context,
      builder: (ctx) {
        int activeChapter = 0;

        return StatefulBuilder(
          builder: (ctx, setNovelState) {
            final chap = novel.chapters[activeChapter];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(novel.coverEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          novel.title,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Oleh: ${novel.author} • Bab ${activeChapter + 1} / ${novel.chapters.length}',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Text(
                          chap.title,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF5B21B6)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        chap.content,
                        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (activeChapter > 0)
                  TextButton(
                    onPressed: () => setNovelState(() => activeChapter--),
                    child: const Text('◀ Bab Sebelum'),
                  ),
                if (activeChapter < novel.chapters.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setNovelState(() => activeChapter++),
                    child: const Text('Bab Seterusnya ▶'),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✨ Hebat! Selesai membaca novel inspirasi ikatan keluarga!'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Tamat Membaca ✓'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showYoungAdultPaperDialog(BuildContext context, YoungAdultJournalPaper paper) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${paper.authors} (${paper.year})',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Bidang: ${paper.field}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF0369A1)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jurnal: ${paper.journal}',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Abstrak Penyelidikan Ilmiah:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  paper.abstractText,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Nasihat Praktikal Untuk Kehidupan Dewasa Muda:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paper.practicalTakeaway,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF14532D), height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          paper.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF2563EB)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: paper.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pautan DOI jurnal disalin!'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${paper.title}. ${paper.authors} (${paper.year}). ${paper.journal}. DOI: ${paper.doi}'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Sitasi APA kertas kajian disalin ke papan klip!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_all_rounded, size: 16),
            label: const Text('Salin Sitasi APA'),
          ),
        ],
      ),
    );
  }

  void _showParentArticleDialog(BuildContext context, ParentingResearchArticle article) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: article.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(article.iconEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${article.authors} (${article.year})',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: article.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Kategori: ${article.category}',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: article.accentColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sumber: ${article.journalOrPublisher}',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dapatan Utama Kajian:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  article.summary,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Bimbingan Untuk Ibu Bapa ERAT:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.keyTakeaway,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF14532D), height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          article.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF2563EB)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: article.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pautan artikel disalin!'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: article.accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${article.authors} (${article.year}). ${article.title}. ${article.journalOrPublisher}. DOI: ${article.doi}'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Sitasi APA rujukan ilmiah disalin ke papan klip!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_all_rounded, size: 16),
            label: const Text('Salin Sitasi APA'),
          ),
        ],
      ),
    );
  }
}
