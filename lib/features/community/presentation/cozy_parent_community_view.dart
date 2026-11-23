import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/cozy_theme.dart';

/// Parent-Only Community View:
/// Segment 0: Reddit-style Parent Discussions (connects all Parent IDs,
///            post, upvote, comment, topic filter, Report/Block/Delete UGC).
/// Segment 1: Genuine Parenting Journal Articles (research-backed reading).
class CozyParentCommunityView extends ConsumerStatefulWidget {
  const CozyParentCommunityView({super.key});

  @override
  ConsumerState<CozyParentCommunityView> createState() =>
      _CozyParentCommunityViewState();
}

class _CozyParentCommunityViewState
    extends ConsumerState<CozyParentCommunityView> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _dragHandle = Color(0xFFBBA396);

  int _activeSegment = 0; // 0 = Discussions, 1 = Articles
  String _selectedTopic = 'All';
  final Set<String> _savedArticleIds = {};

  static const List<String> _topicsEn = [
    'All',
    'Bonding',
    'Parenting',
    'Kids & Habits',
    'Adab & Ethics',
    'Ask Parents',
  ];

  static const List<Map<String, dynamic>> _parentingArticles = [
    {
      'id': 'art_aap_play',
      'authors': 'Yogman, Garner, Hutchinson, Hirsh-Pasek & Golinkoff',
      'source': 'Pediatrics (American Academy of Pediatrics)',
      'year': '2018',
      'doi': '10.1542/peds.2018-2058',
      'doiUrl': 'https://doi.org/10.1542/peds.2018-2058',
      'readMin': 4,
      'tagEn': 'Bonding & Play',
      'tagMs': 'Bonding & Bermain',
      'icon': Icons.favorite_outline_rounded,
      'titleEn': 'The Power of Play: Enhancing Child Development & Bonding',
      'titleMs': 'Kuasa Bermain Bersama: Perkembangan Anak & Bonding',
      'bulletsEn': [
        'Unstructured daily play with parents strengthens brain structure and executive function.',
        'Warm "serve-and-return" interactions buffer stress and build emotional resilience.',
      ],
      'bulletsMs': [
        'Bermain secara santai bersama ibu bapa menguatkan perkembangan otak dan fungsi eksekutif anak.',
        'Interaksi mesra dua hala membantu meredakan tekanan dan membina daya tahan emosi.',
      ],
      'bodyEn':
          'Summary of AAP Clinical Report (Yogman et al., 2018, Pediatrics):\n\nDevelopmentally appropriate play with parents is not frivolous—it directly supports brain architecture, language, social-emotional regulation, and problem-solving.\n\nWarm "serve-and-return" moments during everyday bonding lower toxic stress and strengthen parent-child trust. Even 10 minutes of distraction-free, child-led play or conversation each day acts as a protective emotional anchor.',
      'bodyMs':
          'Ringkasan Laporan Klinikal AAP (Yogman et al., 2018, Pediatrics):\n\nBermain mengikut tahap umur bersama ibu bapa bukanlah perkara remeh—ia menyokong perkembangan otak, bahasa, kawalan emosi dan penyelesaian masalah anak.\n\nInteraksi mesra dua hala semasa aktiviti harian mengurangkan tekanan dan mengukuhkan kepercayaan anak. Luangkan sekurang-kurangnya 10 minit tanpa skrin setiap hari untuk mendengar dan bermain bersama anak.',
    },
    {
      'id': 'art_tepper_chores',
      'authors': 'Tepper, Howell & Bennett',
      'source': 'Australian Occupational Therapy Journal',
      'year': '2022',
      'doi': '10.1111/1440-1630.12822',
      'doiUrl': 'https://doi.org/10.1111/1440-1630.12822',
      'readMin': 5,
      'tagEn': 'Kids & Habits',
      'tagMs': 'Tabiat & Rutin',
      'icon': Icons.psychology_outlined,
      'titleEn': 'Executive Functions & Household Chores in Children',
      'titleMs': 'Tugasan Rumah & Fungsi Eksekutif Kanak-Kanak',
      'bulletsEn': [
        'Self-care and family-care chores significantly predict stronger working memory and self-control.',
        'Age-appropriate tasks (ages 5–13) train planning, follow-through, and family teamwork.',
      ],
      'bulletsMs': [
        'Tugasan menjaga diri dan membantu keluarga berkait rapat dengan memori kerja dan kawalan diri yang lebih baik.',
        'Tugasan mengikut umur (5–13 tahun) melatih perancangan, tanggungjawab dan semangat kerjasama.',
      ],
      'bodyEn':
          'Summary of Tepper, Howell & Bennett (2022, Australian Occupational Therapy Journal):\n\nIn a study of 207 children aged 5–13, regular participation in self-care chores (such as making a simple snack or tidying personal items) and family-care chores (such as setting the table or helping prepare meals) significantly predicted stronger working memory and inhibitory control.\n\nBecause everyday chores require planning, sequencing, and remembering steps, framing them as joyful family contributions helps children build lifelong academic and life skills.',
      'bodyMs':
          'Ringkasan Kajian Tepper, Howell & Bennett (2022, Australian Occupational Therapy Journal):\n\nDalam kajian terhadap 207 kanak-kanak berumur 5–13 tahun, penglibatan konsisten dalam tugasan urus diri dan tugasan membantu keluarga terbukti meramal keupayaan memori kerja dan kawalan diri yang lebih tinggi.\n\nTugasan harian melatih anak merancang langkah dan mengurus tanggungjawab—lebih berkesan apabila disampaikan sebagai sumbangan kasih keluarga dan bukannya hukuman.',
    },
    {
      'id': 'art_ratliff_teens',
      'authors': 'Ratliff, Morris et al.',
      'source': 'Frontiers in Psychology (Open Access)',
      'year': '2023',
      'doi': '10.3389/fpsyg.2023.1193449',
      'doiUrl': 'https://doi.org/10.3389/fpsyg.2023.1193449',
      'readMin': 5,
      'tagEn': 'Adab & Communication',
      'tagMs': 'Adab & Komunikasi',
      'icon': Icons.hearing_rounded,
      'titleEn': 'Supportive Parent-Adolescent Relationships & Emotion Regulation',
      'titleMs': 'Hubungan Sokongan Ibu Bapa-Remaja & Kawalan Emosi',
      'bulletsEn': [
        'Open, validating parent-teen communication builds core emotional regulation and resilience.',
        'Calm listening before advising keeps teenagers emotionally connected and respectful.',
      ],
      'bulletsMs': [
        'Komunikasi terbuka dan empati antara ibu bapa dan remaja membina kawalan emosi dan daya tahan psikologi.',
        'Mendengar dengan tenang sebelum menasihati mengekalkan keakraban serta adab dua hala.',
      ],
      'bodyEn':
          'Summary of Ratliff, Morris et al. (2023, Frontiers in Psychology — Open Access):\n\nThis peer-reviewed study highlights how warm, supportive parent-adolescent relationships form the foundation for healthy emotion regulation and adjustment during the teen years.\n\nWhen parents validate feelings before jumping into advice and respect a teen\'s growing voice, adolescents experience lower emotional distress and remain more open to guidance.',
      'bodyMs':
          'Ringkasan Kajian Ratliff, Morris et al. (2023, Frontiers in Psychology — Akses Terbuka):\n\nKajian ini menekankan bahawa hubungan ibu bapa dan remaja yang hangat serta menyokong menjadi asas utama kepada kestabilan emosi dan penyesuaian diri remaja.\n\nApabila ibu bapa mengiktiraf perasaan remaja terlebih dahulu sebelum memberi nasihat, remaja lebih tenang, beradab, dan terbuka berkongsi cabaran mereka.',
    },
    {
      'id': 'art_rothenberg_gratitude',
      'authors': 'Rothenberg, Hussong et al.',
      'source': 'Applied Developmental Science',
      'year': '2018',
      'doi': '10.1080/10888691.2018.1441713',
      'doiUrl': 'https://doi.org/10.1080/10888691.2018.1441713',
      'readMin': 4,
      'tagEn': 'Adab & Ethics',
      'tagMs': 'Etika & Syukur',
      'icon': Icons.auto_awesome_outlined,
      'titleEn': 'Raising Grateful Children One Day at a Time',
      'titleMs': 'Membesarkan Anak Yang Bersyukur Setiap Hari',
      'bulletsEn': [
        'Daily parent-child conversations about gratitude nurture genuine prosocial behavior.',
        'Modeling appreciation authentically at home works far better than forced manners.',
      ],
      'bulletsMs': [
        'Perbualan harian ibu bapa dan anak tentang kesyukuran memupuk tingkah laku prososial yang ikhlas.',
        'Menjadi teladan syukur secara semula jadi di rumah jauh lebih berkesan berbanding paksaan.',
      ],
      'bodyEn':
          'Summary of Rothenberg, Hussong et al. (2018, Applied Developmental Science):\n\nTracking day-to-day parent socialization practices, researchers found that parents who model genuine appreciation and invite children to notice, think about, feel, and express gratitude raise children who show stronger kindness and prosocial habits.\n\nSimple daily habits—such as sharing one thing you are thankful for at dinner or thanking each other sincerely—build lasting character and adab.',
      'bodyMs':
          'Ringkasan Kajian Rothenberg, Hussong et al. (2018, Applied Developmental Science):\n\nMelalui pemerhatian amalan harian keluarga, penyelidik mendapati ibu bapa yang menunjukkan rasa syukur secara tulen serta mengajak anak menyedari dan meluahkan terima kasih berjaya memupuk sifat baik hati dan adab yang berpanjangan.\n\nAmalan ringkas seperti berkongsi satu perkara yang disyukuri setiap malam mengukuhkan peribadi mulia anak.',
    },
  ];

  String _relativeTime(DateTime dt, bool isMs) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isMs ? 'Baru sahaja' : 'Just now';
    if (diff.inMinutes < 60) {
      return isMs ? '${diff.inMinutes} min lalu' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isMs ? '${diff.inHours} jam lalu' : '${diff.inHours}h ago';
    }
    return isMs ? '${diff.inDays} hari lalu' : '${diff.inDays}d ago';
  }

  String _localizedTopic(String topic, bool isMs) {
    if (!isMs) return topic;
    return switch (topic) {
      'All' => 'Semua',
      'Bonding' => 'Bonding',
      'Parenting' => 'Keibubapaan',
      'Kids & Habits' => 'Tabiat Anak',
      'Adab & Ethics' => 'Adab & Etika',
      'Ask Parents' => 'Tanya Ibu Bapa',
      _ => topic,
    };
  }

  bool _matchesTopic(CommunityKnowledgePost post, String topic) {
    if (topic == 'All') return true;
    final tagLower = post.tag.toLowerCase();
    return switch (topic) {
      'Bonding' => tagLower.contains('bond') || tagLower.contains('kasih'),
      'Parenting' => tagLower.contains('parent') ||
          tagLower.contains('keibubapaan') ||
          tagLower.contains('bimbingan'),
      'Kids & Habits' => tagLower.contains('habit') ||
          tagLower.contains('kid') ||
          tagLower.contains('rutin') ||
          tagLower.contains('tingkah'),
      'Adab & Ethics' => tagLower.contains('adab') ||
          tagLower.contains('ethic') ||
          tagLower.contains('akhlak'),
      'Ask Parents' => tagLower.contains('ask') || tagLower.contains('tanya'),
      _ => tagLower.contains(topic.toLowerCase()),
    };
  }

  /// Create a new Reddit-style Parent Community post (supports sharing in any language)
  void _showCreatePostSheet(BuildContext context, bool isMs) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedTag = 'Bonding';
    String selectedLang = isMs ? 'ms' : 'en';
    final postTags = _topicsEn.where((t) => t != 'All').toList();
    const postLangs = [
      {'code': 'en', 'label': 'English'},
      {'code': 'ms', 'label': 'Bahasa Melayu'},
      {'code': 'zh', 'label': '中文'},
      {'code': 'ta', 'label': 'தமிழ்'},
      {'code': 'other', 'label': '🌐 Any Language'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final viewInsets = MediaQuery.viewInsetsOf(ctx);
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            final canPost = titleCtrl.text.trim().isNotEmpty &&
                contentCtrl.text.trim().isNotEmpty;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                                          ? 'Kongsi di Komuniti Ibu Bapa'
                                          : 'New Parent Community Post',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMs
                                          ? 'Kongsi dalam apa jua bahasa — BM, English, 中文 atau bahasa ibunda anda.'
                                          : 'Share in any language — English, Bahasa Melayu, or your home language.',
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

                          Text(
                            isMs ? 'Topik' : 'Topic',
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
                            children: postTags.map((tag) {
                              final sel = tag == selectedTag;
                              return ChoiceChip(
                                label: Text(
                                  _localizedTopic(tag, isMs),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: sel
                                        ? Colors.white
                                        : CozyTheme.textDark,
                                  ),
                                ),
                                selected: sel,
                                selectedColor: _mochaPrimary,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: sel ? _mochaPrimary : _blushBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => selectedTag = tag);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            isMs ? 'Bahasa Hantaran' : 'Post Language',
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
                            children: postLangs.map((lang) {
                              final code = lang['code']!;
                              final sel = code == selectedLang;
                              return ChoiceChip(
                                label: Text(
                                  lang['label']!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? Colors.white
                                        : CozyTheme.textDark,
                                  ),
                                ),
                                selected: sel,
                                selectedColor: _mochaPrimary,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: sel ? _mochaPrimary : _blushBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                onSelected: (_) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => selectedLang = code);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            isMs ? 'Tajuk Perbincangan' : 'Post Title',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleCtrl,
                            onChanged: (_) => setModalState(() {}),
                            decoration: _inputDecoration(
                              hint: isMs
                                  ? 'Contoh: Cara lembut ajar anak 5 tahun tidur awal?'
                                  : 'e.g., Gentle ways to help a 5-year-old build a bedtime routine?',
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            isMs ? 'Kandungan / Pengalaman' : 'Details / Story',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: contentCtrl,
                            maxLines: 4,
                            onChanged: (_) => setModalState(() {}),
                            decoration: _inputDecoration(
                              hint: isMs
                                  ? 'Kongsi konteks atau tips yang membantu keluarga anda...'
                                  : 'Share context, what worked for your family, or ask fellow parents...',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Community safety note (App Store UGC Guideline 1.2)
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: _linenSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _linenBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: _mochaPrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isMs
                                        ? 'Ruang ibu bapa sahaja. Kekalkan adab, hormat privasi anak, dan elakkan berkongsi maklumat peribadi sensitif.'
                                        : 'Parents-only space. Keep discussions respectful and avoid sharing sensitive personal details about children.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _warmCocoa,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: canPost
                                  ? () {
                                      HapticFeedback.mediumImpact();
                                      ref
                                          .read(eratControllerProvider.notifier)
                                          .addCommunityPost(
                                            title: titleCtrl.text.trim(),
                                            content: contentCtrl.text.trim(),
                                            tag: selectedTag,
                                            countryCode: 'MY',
                                            countryName: 'Malaysia 🇲🇾',
                                            language: selectedLang,
                                          );
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isMs
                                                ? 'Hantaran diterbitkan ke Komuniti Ibu Bapa.'
                                                : 'Published to Parent Community.',
                                          ),
                                          backgroundColor: _mochaPrimary,
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mochaPrimary,
                                disabledBackgroundColor: _blushBorder,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                isMs ? 'Terbitkan Hantaran' : 'Publish Post',
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

  /// Open Reddit-style Post & Comments thread bottom sheet
  void _showPostThreadSheet(
    BuildContext context,
    String postId,
    bool isMs,
  ) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final appState = sheetRef.watch(eratControllerProvider);
            final post = appState.communityPosts.firstWhere(
              (p) => p.id == postId,
              orElse: () => appState.communityPosts.first,
            );
            final viewInsets = MediaQuery.viewInsetsOf(ctx);
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            final isUpvoted =
                post.upvotedByIds.contains(appState.activeMember.id);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.86,
                ),
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
                      20,
                      12,
                      20,
                      bottomInset > 24 ? bottomInset + 8 : 24,
                    ),
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
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _blushSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _localizedTopic(post.tag, isMs),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _mochaPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _buildModalCloseButton(ctx),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          child: ListView(
                            children: [
                              // Author row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: _blushSurface,
                                    child: Text(
                                      post.authorAvatar,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.authorName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: CozyTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          '${post.authorRole} • ${_relativeTime(post.createdAt, isMs)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _warmCocoa,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Text(
                                post.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.content,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: _warmCocoa,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Upvote & reply count strip
                              Row(
                                children: [
                                  _buildUpvotePill(
                                    count: post.likes,
                                    active: isUpvoted,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      sheetRef
                                          .read(eratControllerProvider.notifier)
                                          .toggleLikePost(post.id);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _blushBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 16,
                                          color: _warmCocoa,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isMs
                                              ? '${post.comments.length} Komen'
                                              : '${post.comments.length} Comments',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _warmCocoa,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: _blushBorder),
                              const SizedBox(height: 10),

                              Text(
                                isMs ? 'Perbincangan Ibu Bapa' : 'Parent Replies',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (post.comments.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _blushBorder),
                                  ),
                                  child: Text(
                                    isMs
                                        ? 'Jadilah ibu bapa pertama yang berkongsi pandangan di sini.'
                                        : 'Be the first parent to share a supportive reply here.',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: _warmCocoa,
                                    ),
                                  ),
                                )
                              else
                                ...post.comments.map(
                                  (c) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _blushBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.authorAvatar,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              c.authorName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: CozyTheme.textDark,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _relativeTime(c.createdAt, isMs),
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: _warmCocoa,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          c.content,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: _warmCocoa,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Reply composer
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentCtrl,
                                decoration: _inputDecoration(
                                  hint: isMs
                                      ? 'Tulis komen yang membina...'
                                      : 'Write a supportive reply...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (commentCtrl.text.trim().isEmpty) return;
                                  HapticFeedback.lightImpact();
                                  sheetRef
                                      .read(eratControllerProvider.notifier)
                                      .addCommunityComment(
                                        postId: post.id,
                                        content: commentCtrl.text.trim(),
                                      );
                                  commentCtrl.clear();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _mochaPrimary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: const CircleBorder(),
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
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

  /// Open full genuine Parenting Journal Article reader sheet
  void _showArticleReaderSheet(
    BuildContext context,
    Map<String, dynamic> article,
    bool isMs,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.84,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                bottomInset > 34 ? bottomInset + 8 : 34,
              ),
              child: SingleChildScrollView(
                child: Column(
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
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _blushSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isMs
                                ? article['tagMs'] as String
                                : article['tagEn'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _mochaPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildModalCloseButton(ctx),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMs
                          ? article['titleMs'] as String
                          : article['titleEn'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${article['authors']} (${article['year']}) • ${article['source']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _mochaPrimary,
                        height: 1.35,
                      ),
                    ),
                    if (article['doi'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _linenSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _linenBorder),
                        ),
                        child: Text(
                          'DOI: ${article['doi']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _warmCocoa,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      isMs
                          ? article['bodyMs'] as String
                          : article['bodyEn'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _warmCocoa,
                        height: 1.6,
                      ),
                    ),
                    if (article['doiUrl'] != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final urlStr = article['doiUrl'] as String;
                            final uri = Uri.parse(urlStr);
                            bool launched = false;
                            try {
                              launched = await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                            if (!launched) {
                              await Clipboard.setData(
                                ClipboardData(text: urlStr),
                              );
                            }
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isMs
                                        ? 'Pautan DOI disalin: $urlStr'
                                        : 'DOI link copied: $urlStr',
                                  ),
                                  backgroundColor: _mochaPrimary,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 19),
                          label: Text(
                            isMs
                                ? 'Buka Artikel Jurnal Asal (DOI)'
                                : 'Open Original Paper (DOI)',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mochaPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
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
        );
      },
    );
  }

  /// UGC Moderation Menu (Report / Block / Delete — App Store Guideline 1.2)
  void _showPostOptionsSheet(
    BuildContext context,
    CommunityKnowledgePost post,
    String activeMemberId,
    bool isMs,
  ) {
    final isOwner = post.authorId == activeMemberId;
    final authorKey =
        post.authorId.isNotEmpty ? post.authorId : post.authorName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: const BoxDecoration(
                color: CozyTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                bottomInset > 34 ? bottomInset + 8 : 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: _dragHandle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isOwner)
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFB3261E),
                      ),
                      title: Text(
                        isMs ? 'Padam Hantaran Saya' : 'Delete My Post',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(eratControllerProvider.notifier)
                            .deleteCommunityPost(post.id);
                        Navigator.pop(ctx);
                      },
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(
                        Icons.flag_outlined,
                        color: _mochaPrimary,
                      ),
                      title: Text(
                        isMs ? 'Laporkan Hantaran' : 'Report Post',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      subtitle: Text(
                        isMs
                            ? 'Sembunyikan dan laporkan kandungan tidak sesuai'
                            : 'Hide this post and flag inappropriate content',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _warmCocoa,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(eratControllerProvider.notifier)
                            .reportCommunityPost(post.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isMs
                                  ? 'Terima kasih. Hantaran dilaporkan & disembunyikan.'
                                  : 'Thank you. Post reported and hidden from your feed.',
                            ),
                            backgroundColor: _mochaPrimary,
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.block_rounded,
                        color: Color(0xFFB3261E),
                      ),
                      title: Text(
                        isMs
                            ? 'Sekat ${post.authorName}'
                            : 'Block ${post.authorName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB3261E),
                        ),
                      ),
                      subtitle: Text(
                        isMs
                            ? 'Sembunyikan semua hantaran daripada pengguna ini'
                            : 'Hide all posts from this parent account',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _warmCocoa,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(eratControllerProvider.notifier)
                            .blockCommunityAuthor(authorKey);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isMs
                                  ? '${post.authorName} telah disekat.'
                                  : '${post.authorName} has been blocked.',
                            ),
                            backgroundColor: _mochaPrimary,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final activeMember = appState.activeMember;
    final isMs = ref.watch(appStringsProvider).isMs;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final visiblePosts = appState.communityPosts.where((p) {
      if (appState.reportedPostIds.contains(p.id)) return false;
      final authorKey = p.authorId.isNotEmpty ? p.authorId : p.authorName;
      if (appState.blockedAuthorIds.contains(authorKey)) return false;
      return _matchesTopic(p, _selectedTopic);
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 40),
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    isMs ? 'Komuniti Ibu Bapa' : 'Parent Community',
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
                        ? 'Ruang perbincangan ibu bapa & perkongsian artikel sahih'
                        : 'Connect with parents, share experiences & genuine parenting research',
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
            const SizedBox(height: 16),

            // Segmented Control: Discussions | Articles
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _blushSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _blushBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentBtn(
                      icon: Icons.forum_outlined,
                      label: isMs ? 'Perbincangan' : 'Discussions',
                      selected: _activeSegment == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeSegment = 0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentBtn(
                      icon: Icons.article_outlined,
                      label: isMs ? 'Artikel Jurnal' : 'Parenting Articles',
                      selected: _activeSegment == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeSegment = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_activeSegment == 0) ...[
              // Create Post CTA
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showCreatePostSheet(context, isMs);
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 22),
                  label: Text(
                    isMs
                        ? 'Tulis Hantaran / Tanya Ibu Bapa'
                        : 'Create Post / Ask Parents',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mochaPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Topic filter strip
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topicsEn.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) {
                    final topic = _topicsEn[idx];
                    final sel = topic == _selectedTopic;
                    return ChoiceChip(
                      label: Text(
                        _localizedTopic(topic, isMs),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : CozyTheme.textDark,
                        ),
                      ),
                      selected: sel,
                      selectedColor: _mochaPrimary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: sel ? _mochaPrimary : _blushBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTopic = topic);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              if (visiblePosts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _blushBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 36,
                        color: _mochaPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMs
                            ? 'Tiada hantaran untuk topik ini lagi.'
                            : 'No posts in this topic yet.',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMs
                            ? 'Mulakan perbincangan pertama bersama ibu bapa lain!'
                            : 'Start the first conversation with fellow parents!',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _warmCocoa,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...visiblePosts.map((post) {
                  final isUpvoted =
                      post.upvotedByIds.contains(activeMember.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _blushBorder, width: 1.2),
                      boxShadow: CozyTheme.cardShadow,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () =>
                          _showPostThreadSheet(context, post.id, isMs),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author + Topic + More menu
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 19,
                                  backgroundColor: _blushSurface,
                                  child: Text(
                                    post.authorAvatar,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                      Text(
                                        '${post.authorRole} • ${_relativeTime(post.createdAt, isMs)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _warmCocoa,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    onPressed: () => _showPostOptionsSheet(
                                      context,
                                      post,
                                      activeMember.id,
                                      isMs,
                                    ),
                                    icon: const Icon(
                                      Icons.more_horiz_rounded,
                                      color: _warmCocoa,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Topic + Language badges
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _linenSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _linenBorder),
                                  ),
                                  child: Text(
                                    _localizedTopic(post.tag, isMs),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: _mochaPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _blushSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    post.language == 'ms'
                                        ? 'BM'
                                        : (post.language == 'en'
                                            ? 'EN'
                                            : (post.language == 'zh'
                                                ? '中文'
                                                : (post.language == 'ta'
                                                    ? 'தமிழ்'
                                                    : '🌐'))),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _warmCocoa,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Title & Preview
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.8,
                                fontWeight: FontWeight.w500,
                                color: _warmCocoa,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Reddit-style Upvote & Comment action bar
                            Row(
                              children: [
                                _buildUpvotePill(
                                  count: post.likes,
                                  active: isUpvoted,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref
                                        .read(eratControllerProvider.notifier)
                                        .toggleLikePost(post.id);
                                  },
                                ),
                                const SizedBox(width: 10),
                                Material(
                                  color: _linenSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _showPostThreadSheet(
                                      context,
                                      post.id,
                                      isMs,
                                    ),
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(minHeight: 40),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: _linenBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 16,
                                            color: _warmCocoa,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.comments.length}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: CozyTheme.textDark,
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
                    ),
                  );
                }),
            ] else ...[
              // Segment 1: Genuine Parenting Journal Articles
              ..._parentingArticles.map((article) {
                final id = article['id'] as String;
                final isSaved = _savedArticleIds.contains(id);
                final bullets = isMs
                    ? (article['bulletsMs'] as List<String>)
                    : (article['bulletsEn'] as List<String>);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _blushBorder, width: 1.2),
                    boxShadow: CozyTheme.cardShadow,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () =>
                        _showArticleReaderSheet(context, article, isMs),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _blushSurface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  article['icon'] as IconData,
                                  size: 22,
                                  color: _mochaPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMs
                                          ? article['titleMs'] as String
                                          : article['titleEn'] as String,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: CozyTheme.textDark,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${article['source']} • ${article['year']}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _mochaPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (isSaved) {
                                        _savedArticleIds.remove(id);
                                      } else {
                                        _savedArticleIds.add(id);
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: _mochaPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < bullets.length; i++) ...[
                            if (i > 0) const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: _mochaPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bullets[i],
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: _warmCocoa,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (article['doi'] != null)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _linenSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _linenBorder),
                                    ),
                                    child: Text(
                                      'DOI: ${article['doi']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _warmCocoa,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                isMs
                                    ? 'Ringkasan & DOI ›'
                                    : 'Summary & DOI ›',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _mochaPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentBtn({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? _mochaPrimary : _warmCocoa,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? CozyTheme.textDark : _warmCocoa,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpvotePill({
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? _mochaPrimary : _blushSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? _mochaPrimary : _blushBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: active ? Colors.white : _mochaPrimary,
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : CozyTheme.textDark,
                ),
              ),
            ],
          ),
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

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9E8D84), fontSize: 13.5),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}
