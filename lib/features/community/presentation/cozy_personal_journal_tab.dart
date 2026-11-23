import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/voice_audio_service.dart';
import '../../../core/theme/cozy_theme.dart';
import 'cozy_inline_youtube_player.dart';
import 'cozy_parent_community_view.dart';

/// Adaptive 4th Tab:
/// - For Parents/Guardians: Reddit-style Parent Community + Parenting Journal Articles
/// - For Children / Teens / Young Adults:
///   Segment 0: My Journal (Strict per-member Voice + Writing personal diary)
///   Segment 1: Age-Appropriate Curated Content (Toddler Kid-Safe YouTube Videos
///              with Parent Gate, 5–9y Short Moral Stories, 10–12y Cerpen Pengajaran,
///              13–17y Teen Mini-Novels, 18+y Journal Articles on Bonding & Ethics)
class CozyPersonalJournalTab extends ConsumerStatefulWidget {
  const CozyPersonalJournalTab({super.key});

  @override
  ConsumerState<CozyPersonalJournalTab> createState() =>
      _CozyPersonalJournalTabState();
}

class _CozyPersonalJournalTabState
    extends ConsumerState<CozyPersonalJournalTab> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);
  static const Color _linenBorder = Color(0xFFEBDCC8);
  static const Color _dragHandle = Color(0xFFBBA396);

  final VoiceAudioService _voiceService = VoiceAudioService();
  int _activeSegment = 0; // 0 = My Journal, 1 = Age-Appropriate Stories/Videos/Articles
  String? _currentlyPlayingId;
  int _playElapsedSec = 0;
  Timer? _playTimer;
  final Set<String> _savedContentIds = {};

  static const List<Map<String, String>> _moods = [
    {'emoji': '😊', 'en': 'Happy & Grateful', 'ms': 'Gembira & Bersyukur'},
    {'emoji': '🌟', 'en': 'Proud & Energized', 'ms': 'Bangga & Bersemangat'},
    {'emoji': '💛', 'en': 'Warm & Loved', 'ms': 'Tenang & Disayangi'},
    {'emoji': '🌿', 'en': 'Calm & Reflective', 'ms': 'Tenang & Reflektif'},
    {'emoji': '🚀', 'en': 'Ready to Learn', 'ms': 'Semangat Belajar'},
  ];

  @override
  void dispose() {
    _playTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  int _parseDurationSeconds(String? raw) {
    if (raw == null || raw.isEmpty) return 20;
    final parts = raw.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 20;
      return (m * 60 + s).clamp(5, 300);
    }
    return 20;
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleVoicePlayback(JournalEntry entry) {
    HapticFeedback.lightImpact();
    if (_currentlyPlayingId == entry.id) {
      _playTimer?.cancel();
      _voiceService.stopPlayback();
      setState(() {
        _currentlyPlayingId = null;
        _playElapsedSec = 0;
      });
      return;
    }

    _playTimer?.cancel();
    final total = _parseDurationSeconds(entry.voiceDuration);
    _voiceService.play(
      entry.audioUrl,
      onComplete: () {
        if (!mounted) return;
        _playTimer?.cancel();
        setState(() {
          _currentlyPlayingId = null;
          _playElapsedSec = 0;
        });
      },
    );
    setState(() {
      _currentlyPlayingId = entry.id;
      _playElapsedSec = 0;
    });
    _playTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _playElapsedSec++;
        if (_playElapsedSec >= total) {
          timer.cancel();
          _currentlyPlayingId = null;
          _playElapsedSec = 0;
        }
      });
    });
  }

  String _dateLabel(DateTime dt, bool isMs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return isMs ? 'Hari Ini' : 'Today';
    if (diff == 1) return isMs ? 'Semalam' : 'Yesterday';
    const mEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const mMs = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
    ];
    return '${dt.day} ${(isMs ? mMs : mEn)[dt.month - 1]}';
  }

  String _contentTabLabel(AgeBand band, bool isMs) {
    return switch (band) {
      AgeBand.littleExplorer => isMs ? 'Video Adik' : 'Watch & Learn',
      AgeBand.happyHabitBuilder => isMs ? 'Cerita Pendek' : 'Short Stories',
      AgeBand.goalAchiever => isMs ? 'Cerpen Adab' : 'Moral Stories',
      AgeBand.myLifeMyGoals => isMs ? 'Cerpen Remaja' : 'Teen Reads',
      AgeBand.lifelongFamilyBond => isMs ? 'Artikel Jurnal' : 'Journal Articles',
    };
  }

  IconData _contentTabIcon(AgeBand band) {
    return switch (band) {
      AgeBand.littleExplorer => Icons.play_circle_outline_rounded,
      AgeBand.happyHabitBuilder => Icons.menu_book_rounded,
      AgeBand.goalAchiever => Icons.auto_stories_outlined,
      AgeBand.myLifeMyGoals => Icons.library_books_outlined,
      AgeBand.lifelongFamilyBond => Icons.article_outlined,
    };
  }

  List<Map<String, dynamic>> _curatedContentForAgeBand(AgeBand band) {
    return switch (band) {
      // 1–4y Toddler: Real Kid-Safe YouTube Videos with live thumbnails
      AgeBand.littleExplorer => [
          {
            'id': 'vid_please_thanks',
            'isVideo': true,
            'videoId': 'ANChOA4SyL0',
            'duration': '3:02',
            'youtubeUrl': 'https://www.youtube.com/watch?v=ANChOA4SyL0',
            'badgeEn': 'CoComelon • Good Manners',
            'badgeMs': 'CoComelon • Adab & Sopan',
            'emoji': '🎵',
            'titleEn': 'Please and Thank You Song',
            'titleMs': 'Lagu Cakap Tolong & Terima Kasih',
            'summaryEn':
                'Sing along with JJ to practice polite words that make Mom, Dad & friends smile.',
            'summaryMs':
                'Nyanyi bersama untuk melatih ucapan sopan yang menggembirakan Ibu, Ayah dan kawan.',
            'lessonEn':
                'Always say "Please" when asking and "Thank you" with a warm smile.',
            'lessonMs':
                'Sentiasa ucap "Tolong" bila meminta dan "Terima kasih" sambil senyum.',
          },
          {
            'id': 'vid_clean_up',
            'isVideo': true,
            'videoId': 'SFE0mMWbA-Y',
            'duration': '2:39',
            'youtubeUrl': 'https://www.youtube.com/watch?v=SFE0mMWbA-Y',
            'badgeEn': 'Super Simple Songs • Helping at Home',
            'badgeMs': 'Super Simple Songs • Tolong Ibu Ayah',
            'emoji': '🧸',
            'titleEn': 'Clean Up Song — Tidy Up Together!',
            'titleMs': 'Jom Kemas Mainan Bersama!',
            'summaryEn':
                'A cheerful song that turns putting toys away into a happy family habit.',
            'summaryMs':
                'Lagu ceria yang menjadikan aktiviti mengemas mainan sebagai tabiat baik harian.',
            'lessonEn':
                'Helping tidy up keeps our home cozy and shows love to our family.',
            'lessonMs':
                'Membantu mengemas membuat rumah selesa dan menunjukkan kasih pada keluarga.',
          },
          {
            'id': 'vid_omar_hana_thanks',
            'isVideo': true,
            'videoId': 'KJ9XLMh-nVU',
            'duration': '2:48',
            'youtubeUrl': 'https://www.youtube.com/watch?v=KJ9XLMh-nVU',
            'badgeEn': 'Omar & Hana • Gratitude & Adab',
            'badgeMs': 'Omar & Hana • Adab & Syukur',
            'emoji': '💛',
            'titleEn': 'Say Thank You — Omar & Hana',
            'titleMs': 'Ucap Terima Kasih — Omar & Hana',
            'summaryEn':
                'Learn how appreciating parents, siblings, and helpers builds a kind heart.',
            'summaryMs':
                'Belajar menghargai ibu bapa, adik-beradik dan orang sekeliling dengan hati yang baik.',
            'lessonEn':
                'Being grateful and appreciating others makes everyone feel loved.',
            'lessonMs':
                'Sikap bersyukur dan menghargai orang lain membina peribadi yang mulia.',
          },
          {
            'id': 'vid_kindness_kid',
            'isVideo': true,
            'videoId': 'ktOF5SRy01E',
            'duration': '2:35',
            'youtubeUrl': 'https://www.youtube.com/watch?v=ktOF5SRy01E',
            'badgeEn': 'Sesame Street • Kindness & Empathy',
            'badgeMs': 'Sesame Street • Baik Hati & Empati',
            'emoji': '🌟',
            'titleEn': 'The Kindness Kid — Helping Others',
            'titleMs': 'Anak Baik Hati — Suka Membantu',
            'summaryEn':
                'Elmo & friends show how small acts of kindness make you a real-life superhero.',
            'summaryMs':
                'Elmo dan rakan-rakan menunjukkan bagaimana perbuatan baik yang kecil amat bermakna.',
            'lessonEn':
                'Kind words and helping hands make the world brighter every day.',
            'lessonMs':
                'Kata-kata lembut dan sikap suka membantu membentuk peribadi yang hebat.',
          },
        ],

      // 5–9y Habit Builder: Illustrated Short Moral Stories (Cerita Pendek)
      AgeBand.happyHabitBuilder => [
          {
            'id': 'story_promise',
            'isVideo': false,
            'duration': '3 min',
            'badgeEn': 'Short Story • Honesty & Adab',
            'badgeMs': 'Cerita Pendek • Jujur & Adab',
            'emoji': '📖',
            'titleEn': 'The Boy Who Kept His Small Promise',
            'titleMs': 'Adik Yang Menepati Janji Kecilnya',
            'summaryEn': 'Adam promised Mom he would pack his school bag before playing. See what happened when his friends knocked early!',
            'summaryMs': 'Adam berjanji dengan Ibu untuk kemas beg sekolah sebelum bermain. Apa yang berlaku bila kawan datang awal?',
            'bodyEn':
                'Every afternoon, Adam loved riding his bicycle with his neighbor. That day, he told Mom, "I will pack my books and water bottle first."\n\nJust as he opened his bag, his friend called from outside. Adam almost ran out, then remembered his promise. He took three calm minutes to finish packing neatly.\n\nWhen Mom saw the neat bag later, she gave him the biggest hug. Adam realized keeping small promises makes people trust you.',
            'bodyMs':
                'Setiap petang, Adam suka mengayuh basikal bersama jirannya. Hari itu, dia berjanji dengan Ibu untuk mengemas beg sekolah dan botol air terlebih dahulu.\n\nBelum sempat siap, kawannya sudah memanggil di luar. Adam hampir berlari keluar, tetapi teringat janjinya. Dia mengambil masa tiga minit untuk menyusun buku dengan kemas.\n\nApabila Ibu melihat beg yang kemas, Ibu memeluknya erat. Adam belajar bahawa menepati janji kecil membina kepercayaan.',
            'lessonEn': 'A good child and student keeps promises, even small ones.',
            'lessonMs': 'Anak dan pelajar yang baik menepati janji walaupun janji kecil.',
          },
          {
            'id': 'story_teacher',
            'isVideo': false,
            'duration': '3 min',
            'badgeEn': 'Short Story • Student Ethics',
            'badgeMs': 'Cerita Pendek • Adab Pelajar',
            'emoji': '🎒',
            'titleEn': 'The Quiet Helper in Class',
            'titleMs': 'Pembantu Senyap di Dalam Kelas',
            'summaryEn': 'When a classmate dropped their colored pencils, one small act of kindness changed the whole day.',
            'summaryMs': 'Apabila pensel warna rakan terjatuh, satu tindakan kecil mengubah suasana seluruh kelas.',
            'bodyEn':
                'During art class, Maya\'s pencil box slipped and scattered across the floor. Everyone was busy drawing, and Maya felt shy.\n\nAlex quietly knelt down, helped pick up every single pencil, and smiled. "No worries, let\'s draw together!"\n\nTheir teacher noticed and reminded the class: great students aren\'t just smart—they have kind hearts and good manners.',
            'bodyMs':
                'Semasa kelas seni, kotak pensel Maya terjatuh dan bersepah di lantai. Semua orang sibuk melukis dan Maya berasa malu.\n\nAlex segera duduk membantu mengutip setiap batang pensel sambil tersenyum. "Tak apa, jom kita melukis sama-sama!"\n\nCikgu mereka tersenyum dan berpesan: pelajar hebat bukan hanya pandai, tetapi juga beradab dan baik hati.',
            'lessonEn': 'Respect teachers and help classmates without waiting to be asked.',
            'lessonMs': 'Hormati guru dan bantu rakan sekelas dengan ikhlas tanpa perlu disuruh.',
          },
        ],

      // 10–12y Goal Achiever: Moral Short Stories (Cerpen Pengajaran)
      AgeBand.goalAchiever => [
          {
            'id': 'cerpen_sibling',
            'isVideo': false,
            'duration': '5 min',
            'badgeEn': 'Moral Story • Sibling Empathy',
            'badgeMs': 'Cerpen Pengajaran • Empati Adik-Beradik',
            'emoji': '✨',
            'titleEn': 'The Broken Science Model',
            'titleMs': 'Model Sains Yang Terpatah',
            'summaryEn': 'When his younger sibling accidentally bumped his school project, Danish had to choose between anger and patience.',
            'summaryMs': 'Apabila adiknya tidak sengaja melanggar projek sains sekolah, Danish terpaksa memilih antara marah atau sabar.',
            'bodyEn':
                'Danish had spent two evenings gluing his cardboard solar system for school. When his little sister tripped and knocked Saturn off its wire, his first instinct was to shout.\n\nSeeing tears fill her eyes, Danish paused and took a deep breath—just like Dad taught him. "It\'s okay, we can fix it together," he said gently.\n\nThey taped it back with extra tape, and the next day Danish felt prouder of his patience than even his A grade.',
            'bodyMs':
                'Danish menghabiskan dua malam menyiapkan model sistem suria untuk projek sekolah. Apabila adiknya tersandung dan menyebabkan planet Zuhal tertanggal, hatinya hampir meletup marah.\n\nMelihat mata adiknya mula berkaca, Danish menarik nafas panjang seperti pesanan Ayah. "Tak apa dik, kita baiki sama-sama ya."\n\nMereka membaikinya bersama. Keesokan harinya, Danish lebih berbangga dengan kesabarannya berbanding markah A yang diperoleh.',
            'lessonEn': 'True strength as an older sibling is choosing kindness over anger.',
            'lessonMs': 'Kekuatan sebenar seorang abang atau kakak ialah memilih sabar mengatasi marah.',
          },
          {
            'id': 'cerpen_honest',
            'isVideo': false,
            'duration': '4 min',
            'badgeEn': 'Moral Story • Academic Integrity',
            'badgeMs': 'Cerpen Pengajaran • Integriti Pelajar',
            'emoji': '🧭',
            'titleEn': 'The Extra Mark on the Quiz',
            'titleMs': 'Satu Markah Tambahan Pada Ujian',
            'summaryEn': 'A teacher accidentally gave extra points. Would speaking up cost the top spot—or build something greater?',
            'summaryMs': 'Cikgu tersilap memberi markah tambahan. Adakah bersikap jujur merugikan atau membina maruah diri?',
            'bodyEn':
                'When the math quiz was returned, Sara saw "98/100"—the highest in class. Checking her paper, she noticed question 7 was marked right by mistake.\n\nHer heart beat fast. If she told the teacher, she would drop to 93. Still, she remembered her parents\' rule: "Your character matters more than any score."\n\nShe walked to the teacher\'s desk and pointed out the error. Her teacher smiled warmly: "Thank you for your honesty, Sara. That takes real courage."',
            'bodyMs':
                'Apabila kertas ujian Matematik dipulangkan, Sara mendapat 98/100—tertinggi di kelas. Namun ketika menyemak, dia perasan soalan nombor 7 sebenarnya tersalah tanda betul.\n\nHatinya berdebar. Jika dia beritahu cikgu, markahnya akan turun. Namun dia teringat pesan ibu bapanya: "Maruah dan kejujuran lebih mahal daripada sebarang markah."\n\nSara melangkah ke meja guru dan berterus-terang. Cikgunya tersenyum: "Terima kasih atas kejujuran kamu, Sara. Itu keberanian yang sebenar."',
            'lessonEn': 'Honesty in study builds self-respect that lasts a lifetime.',
            'lessonMs': 'Kejujuran dalam menuntut ilmu membina harga diri sepanjang hayat.',
          },
        ],

      // 13–17y Teen: Mini-Novels & Youth Reflections (Cerpen Remaja)
      AgeBand.myLifeMyGoals => [
          {
            'id': 'teen_dinner',
            'isVideo': false,
            'duration': '6 min',
            'badgeEn': 'Teen Mini-Novel • Family & Digital Adab',
            'badgeMs': 'Cerpen Remaja • Adab Digital & Keluarga',
            'emoji': '🌙',
            'titleEn': 'Notifications Off at 8 PM',
            'titleMs': 'Notifikasi Senyap Jam 8 Malam',
            'summaryEn': 'Hana thought her parents didn\'t understand high school stress—until one phone-free evening changed her view.',
            'summaryMs': 'Hana menyangka ibu bapanya tidak memahami tekanan sekolah—sehingga satu malam tanpa telefon mengubah segalanya.',
            'bodyEn':
                'Between exam prep and group chats, Hana\'s phone rarely left her hand. At dinner, she usually answered with one-word replies while scrolling.\n\nOne Friday, she noticed Dad quietly rubbing his tired shoulders after a double shift, still asking how her Biology test went. Something clicked.\n\nHana placed her phone face-down in her room and poured tea for both parents. That night they laughed for an hour. Being grown-up, she realized, starts with noticing the people who quietly carry us every day.',
            'bodyMs':
                'Antara persediaan peperiksaan dan mesej rakan, telefon Hana jarang lepas dari tangan. Di meja makan, dia sering menjawab sepatah-sepatah sambil menatal skrin.\n\nSatu malam Jumaat, dia perasan Ayah mengurut bahu yang letih selepas kerja panjang, namun tetap bertanya tentang ujian Biologinya. Hatinya tersentuh.\n\nHana meletakkan telefon di bilik dan menuangkan teh untuk Ibu dan Ayah. Malam itu mereka berbual dan ketawa bersama. Menjadi dewasa, sedarnya, bermula dengan menghargai insan yang sentiasa ada untuk kita.',
            'lessonEn': 'Putting your phone away during family time is modern adab and deep respect.',
            'lessonMs': 'Meletakkan telefon ketika bersama keluarga ialah adab moden dan tanda hormat yang tinggi.',
          },
          {
            'id': 'teen_balance',
            'isVideo': false,
            'duration': '5 min',
            'badgeEn': 'Teen Reflection • Emotional Maturity',
            'badgeMs': 'Refleksi Remaja • Kematangan Emosi',
            'emoji': '🌿',
            'titleEn': 'Speaking Firmly Without Being Disrespectful',
            'titleMs': 'Menyuarakan Pendapat Dengan Penuh Adab',
            'summaryEn': 'How to share your real feelings with parents and teachers calmly when you disagree.',
            'summaryMs': 'Cara berkongsi perasaan sebenar dengan ibu bapa dan guru secara tenang apabila berbeza pandangan.',
            'bodyEn':
                'Growing up means having your own opinions—and sometimes disagreeing with adults you love. The skill isn\'t staying silent, nor is it shouting.\n\nTry starting with calm ownership: "Mom, I respect your view, and I\'d love to share how I\'m feeling about my study schedule."\n\nWhen your tone stays gentle and respectful, people listen to your ideas instead of reacting to your volume.',
            'bodyMs':
                'Membesar bermakna mempunyai pandangan sendiri—dan kadangkala berbeza pendapat dengan orang dewasa. Kemahirannya bukanlah berdiam diri atau meninggikan suara.\n\nMulakan dengan nada tenang: "Ibu, saya hormati pandangan Ibu, boleh saya kongsi perasaan saya tentang jadual belajar ini?"\n\nApabila nada suara kekal lembut dan beradab, orang lain akan mendengar isi hati kita dengan lebih terbuka.',
            'lessonEn': 'Calm tone + honest words = mature communication.',
            'lessonMs': 'Nada lembut + kata jujur = komunikasi yang matang dan beradab.',
          },
        ],

      // 18+y Young Adult: Journal Articles & Life Essays
      AgeBand.lifelongFamilyBond => [
          {
            'id': 'adult_bonding',
            'isVideo': false,
            'duration': '5 min',
            'badgeEn': 'Journal Article • Lifelong Family Bond',
            'badgeMs': 'Artikel Jurnal • Ikatan Keluarga Dewasa',
            'emoji': '🎓',
            'titleEn': 'From Dependent Child to Intentional Adult Companion',
            'titleMs': 'Daripada Anak Kecil Kepada Sahabat Dewasa Buat Ibu Bapa',
            'summaryEn': 'Research on emerging adulthood shows how small, consistent gestures keep family bonds thriving after 18.',
            'summaryMs': 'Kajian fasa dewasa muda menunjukkan bagaimana tindakan kecil yang konsisten mengukuhkan kasih keluarga selepas usia 18.',
            'bodyEn':
                'Studies in Family Relations highlight a pivotal shift at age 18+: relationships with parents evolve from hierarchy into mutual care.\n\nInitiating a 10-minute check-in call, helping with errands without being asked, or mentoring younger siblings signals emotional maturity.\n\nGood ethics (adab) in young adulthood is shown not only in academic or career achievement, but in how gently we treat the people who raised us.',
            'bodyMs':
                'Kajian hubungan kekeluargaan menunjukkan peralihan penting pada usia 18 tahun ke atas: hubungan dengan ibu bapa berkembang daripada penjagaan satu hala kepada saling menyantuni.\n\nMemulakan panggilan ringkas, membantu urusan rumah tanpa disuruh, dan membimbing adik-adik mencerminkan kematangan emosi yang tinggi.\n\nAdab seorang dewasa muda bukan sekadar pada kejayaan akademik atau kerjaya, tetapi pada kelembutan kita melayan insan yang membesarkan kita.',
            'lessonEn': 'Check in intentionally—your presence means more to your family than you realize.',
            'lessonMs': 'Luangkan masa dengan sengaja—kehadiran anda amat bermakna buat keluarga.',
          },
          {
            'id': 'adult_ethics',
            'isVideo': false,
            'duration': '6 min',
            'badgeEn': 'Journal Article • Character & Leadership',
            'badgeMs': 'Artikel Jurnal • Karakter & Kepimpinan',
            'emoji': '📚',
            'titleEn': 'Everyday Integrity: How Private Habits Shape Public Character',
            'titleMs': 'Integriti Harian: Bagaimana Tabiat Peribadi Membentuk Karakter',
            'summaryEn': 'Insights from behavioral ethics on consistency, gratitude, and role-modeling for younger siblings.',
            'summaryMs': 'Dapatan etika tingkah laku tentang konsistensi, kesyukuran dan menjadi teladan buat adik-adik.',
            'bodyEn':
                'Behavioral research shows that character is rarely built in dramatic moments—it is compounded through quiet daily choices: keeping your word, managing frustration respectfully, and practicing gratitude.\n\nFor older siblings and university students, younger family members watch closely. Modeling calm discipline and warm family loyalty creates a ripple effect across the entire household.',
            'bodyMs':
                'Kajian tingkah laku membuktikan karakter jarang dibina dalam detik dramatik—ia terbentuk melalui pilihan kecil harian: menepati janji, mengurus tekanan secara beradab, dan bersyukur.\n\nSebagai abang, kakak atau mahasiswa, adik-adik memerhatikan kita sebagai contoh. Teladan disiplin yang tenang dan kasih keluarga membawa kesan positif kepada seluruh rumah.',
            'lessonEn': 'Your daily adab quietly teaches everyone around you.',
            'lessonMs': 'Adab harian anda menjadi teladan senyap buat seisi keluarga.',
          },
        ],
    };
  }

  /// Create Voice or Written Personal Journal Entry (stored per memberId in EratController)
  void _showCreateEntrySheet(
    BuildContext context,
    bool isMs, {
    required bool initialVoiceMode,
  }) {
    bool isVoiceMode = initialVoiceMode;
    bool isRecording = false;
    bool isUploadingAudio = false;
    int recordedSeconds = 0;
    String? recordedAudioUrl;
    String? activeRecFileId;
    Timer? recTimer;
    int selectedMoodIdx = 0;
    bool shareWithParents = false;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final viewInsets = MediaQuery.viewInsetsOf(ctx);
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;

            void stopTimer() {
              recTimer?.cancel();
              recTimer = null;
            }

            Future<void> toggleRecord() async {
              HapticFeedback.mediumImpact();
              if (isRecording) {
                stopTimer();
                final recId = activeRecFileId ??
                    'j_${DateTime.now().millisecondsSinceEpoch}';
                activeRecFileId = null;
                setModalState(() {
                  isRecording = false;
                  isUploadingAudio = true;
                });
                final familyId = ref.read(eratControllerProvider).family.id;
                final url = await _voiceService.stopAndUpload(
                  familyId: familyId,
                  folder: 'journal',
                  fileId: recId,
                );
                if (ctx.mounted) {
                  setModalState(() {
                    recordedAudioUrl = url;
                    isUploadingAudio = false;
                  });
                }
              } else {
                final recId = 'j_${DateTime.now().millisecondsSinceEpoch}';
                final started = await _voiceService.startRecording(recId);
                if (!started) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMs
                              ? 'Sila benarkan akses mikrofon untuk merakam diari suara.'
                              : 'Please allow microphone permission to record your voice journal.',
                        ),
                        backgroundColor: _mochaPrimary,
                      ),
                    );
                  }
                  return;
                }
                activeRecFileId = recId;
                setModalState(() {
                  isRecording = true;
                  recordedSeconds = 0;
                  recordedAudioUrl = null;
                });
                recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                  if (ctx.mounted) {
                    setModalState(() => recordedSeconds++);
                  }
                });
              }
            }

            final canSave = !isUploadingAudio &&
                (isVoiceMode
                    ? (!isRecording && recordedSeconds > 0) ||
                        titleCtrl.text.trim().isNotEmpty
                    : (titleCtrl.text.trim().isNotEmpty ||
                        contentCtrl.text.trim().isNotEmpty));

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
                            children: [
                              Expanded(
                                child: Text(
                                  isMs
                                      ? 'Catatan Diari Baharu'
                                      : 'New Journal Entry',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ),
                              _buildModalCloseButton(ctx, onClose: stopTimer),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Voice | Write Toggle
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _blushSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _blushBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSegmentBtn(
                                    icon: Icons.mic_none_rounded,
                                    label: isMs ? 'Suara' : 'Voice Note',
                                    selected: isVoiceMode,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() => isVoiceMode = true);
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _buildSegmentBtn(
                                    icon: Icons.edit_outlined,
                                    label: isMs ? 'Tulisan' : 'Write Note',
                                    selected: !isVoiceMode,
                                    onTap: () {
                                      stopTimer();
                                      HapticFeedback.selectionClick();
                                      setModalState(() {
                                        isRecording = false;
                                        isVoiceMode = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (isVoiceMode) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRecording
                                      ? _mochaPrimary
                                      : _blushBorder,
                                  width: isRecording ? 1.8 : 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: toggleRecord,
                                    child: Container(
                                      width: 66,
                                      height: 66,
                                      decoration: BoxDecoration(
                                        color: isRecording
                                            ? const Color(0xFFB3261E)
                                            : _mochaPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isRecording
                                            ? Icons.stop_rounded
                                            : Icons.mic_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isRecording
                                        ? (isMs
                                            ? 'Sedang merakam... ${_formatSeconds(recordedSeconds)}'
                                            : 'Recording... ${_formatSeconds(recordedSeconds)}')
                                        : (recordedSeconds > 0
                                            ? (isMs
                                                ? 'Rakaman siap (${_formatSeconds(recordedSeconds)}) • Ketik untuk rakam semula'
                                                : 'Recorded (${_formatSeconds(recordedSeconds)}) • Tap mic to re-record')
                                            : (isMs
                                                ? 'Ketik mikrofon untuk mula merakam suara anda'
                                                : 'Tap microphone to start recording your voice')),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          Text(
                            isMs ? 'Tajuk Catatan' : 'Title',
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
                                  ? 'Contoh: Hari yang menggembirakan di sekolah'
                                  : 'e.g., Something I felt proud of today',
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            isMs ? 'Perasaan Hari Ini' : 'How I Feel',
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
                            children: List.generate(_moods.length, (i) {
                              final m = _moods[i];
                              final sel = i == selectedMoodIdx;
                              return ChoiceChip(
                                label: Text(
                                  '${m['emoji']} ${isMs ? m['ms'] : m['en']}',
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
                                  setModalState(() => selectedMoodIdx = i);
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            isMs ? 'Refleksi / Cerita' : 'Reflection',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: CozyTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: contentCtrl,
                            maxLines: isVoiceMode ? 2 : 4,
                            onChanged: (_) => setModalState(() {}),
                            decoration: _inputDecoration(
                              hint: isMs
                                  ? 'Tulis apa yang anda syukuri atau pelajari hari ini...'
                                  : 'Write what you felt grateful for or learned today...',
                            ),
                          ),
                          const SizedBox(height: 10),

                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeTrackColor: _mochaPrimary,
                            value: shareWithParents,
                            onChanged: (v) =>
                                setModalState(() => shareWithParents = v),
                            title: Text(
                              isMs
                                  ? 'Kongsi dengan Ibu Bapa (Pilihan)'
                                  : 'Share with Parents (Optional)',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            subtitle: Text(
                              isMs
                                  ? 'Jika dimatikan, catatan ini hanya kelihatan dalam ruang peribadi anda.'
                                  : 'When off, this entry stays strictly private to your space.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _warmCocoa,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: canSave
                                  ? () {
                                      stopTimer();
                                      HapticFeedback.mediumImpact();
                                      final mood = _moods[selectedMoodIdx];
                                      ref
                                          .read(eratControllerProvider.notifier)
                                          .addJournalEntry(
                                            title: titleCtrl.text.trim().isEmpty
                                                ? (isVoiceMode
                                                    ? (isMs
                                                        ? 'Catatan Suara Hari Ini'
                                                        : 'Voice Reflection')
                                                    : (isMs
                                                        ? 'Catatan Hari Ini'
                                                        : 'Daily Reflection'))
                                                : titleCtrl.text.trim(),
                                            content: contentCtrl.text
                                                    .trim()
                                                    .isEmpty
                                                ? (isMs
                                                    ? 'Rakaman suara peribadi disimpan.'
                                                    : 'Personal voice reflection saved.')
                                                : contentCtrl.text.trim(),
                                            moodEmoji: mood['emoji']!,
                                            isVoiceEntry: isVoiceMode,
                                            voiceDuration: isVoiceMode
                                                ? _formatSeconds(
                                                    recordedSeconds > 0
                                                        ? recordedSeconds
                                                        : 12,
                                                  )
                                                : null,
                                            audioUrl: isVoiceMode
                                                ? recordedAudioUrl
                                                : null,
                                            isSharedWithParents:
                                                shareWithParents,
                                          );
                                      Navigator.pop(ctx);
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
                                isMs ? 'Simpan ke Diari Saya' : 'Save to My Journal',
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
    ).whenComplete(() => recTimer?.cancel());
  }

  /// Open full story / article reader OR In-App Kid-Safe Video Player
  void _showCuratedItemSheet(
    BuildContext context,
    Map<String, dynamic> item,
    bool isMs,
  ) {
    final isVideo = item['isVideo'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx);
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 540,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
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
                                  ? item['badgeMs'] as String
                                  : item['badgeEn'] as String,
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
                        '${item['emoji']} ${isMs ? item['titleMs'] : item['titleEn']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: CozyTheme.textDark,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (isVideo) ...[
                        // Plays directly inside ERAT — never diverts child out to YouTube app!
                        CozyInlineYoutubePlayer(
                          videoId: item['videoId'] as String,
                          fallbackEmoji: item['emoji'] as String,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isMs
                              ? item['summaryMs'] as String
                              : item['summaryEn'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _warmCocoa,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final urlStr = item['youtubeUrl'] as String;
                              final uri = Uri.parse(urlStr);
                              try {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (_) {}
                            },
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: _mochaPrimary,
                            ),
                            label: Text(
                              isMs ? 'Buka di YouTube' : 'Open in YouTube',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _mochaPrimary,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          isMs
                              ? item['bodyMs'] as String
                              : item['bodyEn'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _warmCocoa,
                            height: 1.6,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Moral / Adab Takeaway Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _linenSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _linenBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMs
                                  ? '✨ Pengajaran Adab & Etika'
                                  : '✨ Ethics & Adab Takeaway',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: _mochaPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isMs
                                  ? item['lessonMs'] as String
                                  : item['lessonEn'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CozyTheme.textDark,
                                height: 1.4,
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
    );
  }

  /// Detail sheet for reading/deleting a personal journal entry
  void _showJournalDetailSheet(
    BuildContext context,
    JournalEntry entry,
    bool isMs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                    children: [
                      Text(
                        entry.moodEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            Text(
                              '${_dateLabel(entry.createdAt, isMs)} • ${entry.isVoiceEntry ? (isMs ? 'Diari Suara' : 'Voice Note') : (isMs ? 'Diari Tulisan' : 'Written Note')}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _warmCocoa,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildModalCloseButton(ctx),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    entry.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _warmCocoa,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(eratControllerProvider.notifier)
                              .deleteJournalEntry(entry.id);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFB3261E),
                        ),
                        label: Text(
                          isMs ? 'Padam Catatan' : 'Delete Entry',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB3261E),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final activeMember = appState.activeMember;

    // Parents get the dedicated Parent Community (Reddit-style + Parenting Articles)
    if (activeMember.isParentOrGuardian) {
      return const CozyParentCommunityView();
    }

    final isMs = ref.watch(appStringsProvider).isMs;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Strictly individual per-member journal entries!
    final myEntries = appState.journalEntries
        .where((e) => e.memberId == activeMember.id)
        .toList();
    final curatedItems = _curatedContentForAgeBand(activeMember.ageBand);

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
                    isMs ? 'Diari & Ilmu Adab' : 'Journal & Growth',
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
                        ? 'Diari peribadi ${activeMember.name} & bahan sesuai umur'
                        : '${activeMember.name}\'s private diary & age-matched stories',
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

            // Segmented Control: My Journal | Age-Adaptive Content
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
                      icon: Icons.auto_stories_outlined,
                      label: isMs ? 'Diari Saya' : 'My Journal',
                      selected: _activeSegment == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeSegment = 0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentBtn(
                      icon: _contentTabIcon(activeMember.ageBand),
                      label: _contentTabLabel(activeMember.ageBand, isMs),
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
              // Voice Note + Write Note dual action row
              Row(
                children: [
                  Expanded(
                    child: _buildCreateOptionCard(
                      icon: Icons.mic_rounded,
                      title: isMs ? 'Rakam Suara' : 'Voice Note',
                      subtitle: isMs ? 'Luah secara audio' : 'Speak freely',
                      onTap: () => _showCreateEntrySheet(
                        context,
                        isMs,
                        initialVoiceMode: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCreateOptionCard(
                      icon: Icons.edit_note_rounded,
                      title: isMs ? 'Tulis Diari' : 'Write Note',
                      subtitle: isMs ? 'Catat perasaan' : 'Write thoughts',
                      onTap: () => _showCreateEntrySheet(
                        context,
                        isMs,
                        initialVoiceMode: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Individual privacy reminder
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _linenSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _linenBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: _mochaPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMs
                            ? 'Diari suara & tulisan ini ialah data individu ${activeMember.name} sahaja.'
                            : 'These voice & written entries belong privately to ${activeMember.name}.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _warmCocoa,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (myEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _blushBorder),
                  ),
                  child: Column(
                    children: [
                      const Text('📔', style: TextStyle(fontSize: 34)),
                      const SizedBox(height: 8),
                      Text(
                        isMs
                            ? 'Belum ada catatan diari lagi'
                            : 'No journal entries yet',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMs
                            ? 'Rakam suara atau tulis detik bermakna hari ini.'
                            : 'Record a voice note or write a reflection to start.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _warmCocoa,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...myEntries.map((entry) {
                  final isPlaying = _currentlyPlayingId == entry.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isPlaying ? _blushSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPlaying ? _mochaPrimary : _blushBorder,
                        width: isPlaying ? 1.5 : 1.2,
                      ),
                      boxShadow: CozyTheme.cardShadow,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          _showJournalDetailSheet(context, entry, isMs),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                  child: Text(
                                    entry.moodEmoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: CozyTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.isVoiceEntry
                                            ? '${_dateLabel(entry.createdAt, isMs)} • ${isPlaying ? '${_formatSeconds(_playElapsedSec)} / ' : ''}${entry.voiceDuration ?? '0:15'}'
                                            : '${_dateLabel(entry.createdAt, isMs)} • ${isMs ? 'Catatan Tulisan' : 'Written Note'}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _warmCocoa,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (entry.isVoiceEntry)
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Material(
                                      color: _mochaPrimary,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () =>
                                            _toggleVoicePlayback(entry),
                                        child: Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _blushSurface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isMs ? 'Baca' : 'Read',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _mochaPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              entry.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.8,
                                color: _warmCocoa,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ] else ...[
              // Segment 1: Age-Appropriate Curated Videos / Short Stories / Cerpen / Novels / Articles
              ...curatedItems.map((item) {
                final id = item['id'] as String;
                final isVideo = item['isVideo'] == true;
                final isSaved = _savedContentIds.contains(id);

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
                    onTap: () => _showCuratedItemSheet(context, item, isMs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isVideo && item['videoId'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(21),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    'https://img.youtube.com/vi/${item['videoId']}/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: _blushSurface,
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: _mochaPrimary,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, _, _) => Container(
                                      color: _blushSurface,
                                      alignment: Alignment.center,
                                      child: Text(
                                        item['emoji'] as String,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.18),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: _mochaPrimary.withValues(
                                          alpha: 0.92,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.72,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['duration'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isVideo) ...[
                                    Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _blushSurface,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        item['emoji'] as String,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMs
                                              ? item['badgeMs'] as String
                                              : item['badgeEn'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: _mochaPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          isMs
                                              ? item['titleMs'] as String
                                              : item['titleEn'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: CozyTheme.textDark,
                                            height: 1.25,
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
                                            _savedContentIds.remove(id);
                                          } else {
                                            _savedContentIds.add(id);
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
                              const SizedBox(height: 8),
                              Text(
                                isMs
                                    ? item['summaryMs'] as String
                                    : item['summaryEn'] as String,
                                style: const TextStyle(
                                  fontSize: 13.8,
                                  color: _warmCocoa,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (!isVideo)
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
                                        item['duration'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _warmCocoa,
                                        ),
                                      ),
                                    )
                                  else
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
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.ondemand_video_rounded,
                                            size: 14,
                                            color: _mochaPrimary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isMs
                                                ? 'YouTube Kanak-Kanak'
                                                : 'YouTube Kids',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _warmCocoa,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Spacer(),
                                  Text(
                                    isVideo
                                        ? (isMs
                                            ? 'Tonton Sekarang ›'
                                            : 'Watch Now ›')
                                        : (isMs ? 'Baca penuh ›' : 'Read now ›'),
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
                      ],
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

  Widget _buildCreateOptionCard({
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _mochaPrimary, width: 1.3),
            boxShadow: CozyTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _mochaPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _warmCocoa,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildModalCloseButton(BuildContext ctx, {VoidCallback? onClose}) {
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
            onClose?.call();
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
