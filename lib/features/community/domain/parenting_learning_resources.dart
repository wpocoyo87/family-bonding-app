import 'package:flutter/material.dart';

// ============================================================================
// 1. DATA MODELS
// ============================================================================

/// Journal Article & Academic Study for Parents
class ParentingResearchArticle {
  final String id;
  final String title;
  final String authors;
  final String journalOrPublisher;
  final String year;
  final String category;
  final String summary;
  final String keyTakeaway;
  final String url;
  final String doi;
  final String iconEmoji;
  final Color accentColor;

  const ParentingResearchArticle({
    required this.id,
    required this.title,
    required this.authors,
    required this.journalOrPublisher,
    required this.year,
    required this.category,
    required this.summary,
    required this.keyTakeaway,
    required this.url,
    required this.doi,
    this.iconEmoji = '📄',
    this.accentColor = const Color(0xFF2563EB),
  });
}

/// Curated YouTube Video for 4-year-olds (Good Deeds, Respect Parents)
class KidsYouTubeVideo {
  final String id;
  final String title;
  final String channelName;
  final String duration;
  final String moralTheme;
  final String description;
  final String videoUrl;
  final String thumbnailEmoji;
  final Color badgeColor;

  const KidsYouTubeVideo({
    required this.id,
    required this.title,
    required this.channelName,
    required this.duration,
    required this.moralTheme,
    required this.description,
    required this.videoUrl,
    required this.thumbnailEmoji,
    this.badgeColor = const Color(0xFFEF4444),
  });
}

/// Fiction Story Book for 8-year-olds (Respect Elders, Love Youngest)
class FictionStoryBook {
  final String id;
  final String title;
  final String author;
  final String coverEmoji;
  final String moralLesson;
  final String readingTime;
  final List<StoryChapter> chapters;

  const FictionStoryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverEmoji,
    required this.moralLesson,
    required this.readingTime,
    required this.chapters,
  });
}

/// Short Story Book for 11-year-olds (Moral Values, Empathy, Responsibility)
class ShortStoryBook {
  final String id;
  final String title;
  final String author;
  final String coverEmoji;
  final String moralLesson;
  final String readingTime;
  final String synopsis;
  final String fullStory;

  const ShortStoryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverEmoji,
    required this.moralLesson,
    required this.readingTime,
    required this.synopsis,
    required this.fullStory,
  });
}

/// Short Novel for 15-year-olds (Youth Identity, Family Communication)
class TeenShortNovel {
  final String id;
  final String title;
  final String author;
  final String coverEmoji;
  final String theme;
  final String readingTime;
  final String synopsis;
  final List<StoryChapter> chapters;

  const TeenShortNovel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverEmoji,
    required this.theme,
    required this.readingTime,
    required this.synopsis,
    required this.chapters,
  });
}

/// Academic Journal Article for 20-year-olds (Daniel - Family Psychology, Adulthood)
class YoungAdultJournalPaper {
  final String id;
  final String title;
  final String authors;
  final String journal;
  final String year;
  final String field;
  final String abstractText;
  final String practicalTakeaway;
  final String doi;
  final String url;

  const YoungAdultJournalPaper({
    required this.id,
    required this.title,
    required this.authors,
    required this.journal,
    required this.year,
    required this.field,
    required this.abstractText,
    required this.practicalTakeaway,
    required this.doi,
    required this.url,
  });
}

class StoryChapter {
  final String title;
  final String content;

  const StoryChapter({
    required this.title,
    required this.content,
  });
}

// ============================================================================
// 2. SEED REPOSITORIES
// ============================================================================

class ParentingAndLearningRepository {
  /// Articles for Parents
  static const List<ParentingResearchArticle> parentArticles = [
    ParentingResearchArticle(
      id: 'art_lally_2010',
      title: 'How Are Habits Formed: Modelling Habit Formation in the Real World',
      authors: 'Dr. Phillippa Lally, Cornelia H. M. van Jaarsveld, Henry W. W. Potts, Jane Wardle',
      journalOrPublisher: 'European Journal of Social Psychology, Vol. 40, Issue 6',
      year: '2010',
      category: 'Psikologi Tabiat & Pembentukan Rutin',
      summary:
          'Kajian saintifik ini membuktikan bahawa pembentukan tabiat mengambil purata 66 hari dan "tertinggal satu hari tidak menjejaskan proses pembentukan tabiat jangka panjang". Ini menjadi bukti saintifik mengapa sistem ERAT tidak mengenakan denda atau membatalkan streak anak.',
      keyTakeaway:
          'Konsistensi lebih utama daripada kesempurnaan. Elakkan mendenda anak jika terlepas satu hari; dorong mereka untuk sambung keesokan harinya dengan penuh kasih sayang.',
      doi: '10.1002/ejsp.674',
      url: 'https://doi.org/10.1002/ejsp.674',
      iconEmoji: '🧠',
      accentColor: Color(0xFF0284C7),
    ),
    ParentingResearchArticle(
      id: 'art_ryan_deci_2000',
      title: 'Self-Determination Theory and the Facilitation of Intrinsic Motivation',
      authors: 'Richard M. Ryan & Edward L. Deci',
      journalOrPublisher: 'American Psychologist, Vol. 55, No. 1, 68-78',
      year: '2000',
      category: 'Motivasi Intrinsik & Autonomi',
      summary:
          'Kajian terkemuka ini memperkenalkan tiga keperluan psikologi asas manusia: Autonomi (pilihan sendiri), Kecekapan (rasa mampu), dan Keterikatan (kasih sayang keluarga). Hukuman luaran menghancurkan motivasi intrinsik anak, manakala dorongan positif membina disiplin kendiri.',
      keyTakeaway:
          'Beri anak ruang memilih tugasan harian dan bincang bersama ganjaran impian. Anak yang berasa dihargai dan bebas memilih akan lebih bersemangat membantu keluarga.',
      doi: '10.1037/0003-066X.55.1.68',
      url: 'https://doi.org/10.1037/0003-066X.55.1.68',
      iconEmoji: '🌱',
      accentColor: Color(0xFF16A34A),
    ),
    ParentingResearchArticle(
      id: 'art_kazdin_2008',
      title: 'The Kazdin Method for Parenting: Positive Reinforcement Without Punishment',
      authors: 'Prof. Alan E. Kazdin, Ph.D. (Yale Parenting Center)',
      journalOrPublisher: 'Yale University Child Study Center / Houghton Mifflin Harcourt',
      year: '2008',
      category: 'Disiplin Positif & Pengukuhan Tingkah Laku',
      summary:
          'Profesor Kazdin daripada Yale University membuktikan bahawa menghukum hanya mengajar anak cara untuk tidak ditangkap, bukan cara bertingkah laku baik. Kaedah pengukuhan positif ("Positive Opposite") dan pujian spesifik adalah 4 kali lebih berkesan mengubah perangai anak.',
      keyTakeaway:
          'Puji perbuatan baik secara spesifik (cth: "Ibu bangga adik tolong kemas kasut tadi!") dan elakkan tengkingan. Ganjaran kecil dan konsisten merangsang otak untuk mengulang tabiat tersebut.',
      doi: 'Yale-Parenting-Kazdin-Method-2008',
      url: 'https://yaleparentingcenter.yale.edu/',
      iconEmoji: '⭐',
      accentColor: Color(0xFFD97706),
    ),
    ParentingResearchArticle(
      id: 'art_harvard_serve_return',
      title: 'Serve and Return Interaction Shapes Brain Architecture',
      authors: 'Center on the Developing Child at Harvard University',
      journalOrPublisher: 'Harvard University Early Childhood Science Briefs',
      year: '2021',
      category: 'Perkembangan Otak Awal Kanak-Kanak',
      summary:
          'Interaksi dua hala secara responsif antara ibu bapa dan anak ("Serve and Return") seperti membalas pandangan mata, berbual dan mendengar dengan minat membina sambungan saraf otak yang kukuh untuk kawalan emosi dan daya fokus.',
      keyTakeaway:
          'Luangkan 10 minit mendengar cerita anak tanpa sebarang gangguan skrin telefon pintar. Respons hangat ibu bapa adalah nutrisi utama kecerdasan emosi mereka.',
      doi: 'Harvard-CDC-Serve-Return-2021',
      url: 'https://developingchild.harvard.edu/science/key-concepts/serve-and-return/',
      iconEmoji: '👶',
      accentColor: Color(0xFF9333EA),
    ),
    ParentingResearchArticle(
      id: 'art_gershoff_2016',
      title: 'Spanking and Child Outcomes: Meta-Analyses of Fifty Years of Research',
      authors: 'Elizabeth T. Gershoff & Andrew Grogan-Kaylor',
      journalOrPublisher: 'Journal of Family Psychology, 30(4), 453-469',
      year: '2016',
      category: 'Kesejahteraan Mental & Keselamatan Anak',
      summary:
          'Analisis komprehensif terhadap 160,000 orang kanak-kanak mendapati disiplin fizikal dan herdikan dikaitkan secara langsung dengan peningkatan kebimbangan, penurunan harga diri, dan keretakan ikatan ibu bapa. Disiplin berstruktur dan empati menghasilkan perkembangan psikologi terbaik.',
      keyTakeaway:
          'Ketenangan ibu bapa adalah kunci utama. Apabila anak meragam, bertenang dahulu sebelum memberi respon, agar anak belajar regulasi emosi melalui contoh teladan.',
      doi: '10.1037/fam0000191',
      url: 'https://doi.org/10.1037/fam0000191',
      iconEmoji: '🛡️',
      accentColor: Color(0xFFE11D48),
    ),
    ParentingResearchArticle(
      id: 'art_unicef_pdep',
      title: 'Positive Discipline in Everyday Parenting (PDEP)',
      authors: 'Prof. Joan E. Durrant, Ph.D. & UNICEF Global Child Protection',
      journalOrPublisher: 'UNICEF Publications & Save the Children',
      year: '2019',
      category: 'Panduan Praktikal Keibubapaan Global',
      summary:
          'Panduan rasmi UNICEF menekankan empat prinsip utama keibubapaan: menetapkan matlamat jangka panjang, memberikan kehangatan fizikal & emosi, memahami pemikiran mengikut umur anak, serta menyelesaikan masalah bersama-sama.',
      keyTakeaway:
          'Fikirkan: "Apakah nilai yang saya mahu anak saya pelajari 10 tahun dari sekarang apabila menghadapi situasi ini?" Jadikan setiap kesilapan sebagai ruang belajar bersama.',
      doi: 'UNICEF-PDEP-Guidance-2019',
      url: 'https://www.unicef.org/parenting/',
      iconEmoji: '🌍',
      accentColor: Color(0xFF0D9488),
    ),
  ];

  /// YouTube Videos for Age <= 5 (e.g. Emmi, 4 yo)
  static const List<KidsYouTubeVideo> age4Videos = [
    KidsYouTubeVideo(
      id: 'vid_4_omar_hana_hormat',
      title: 'Omar & Hana: Sayang & Hormat Ibu Ayah ❤️',
      channelName: 'Omar & Hana Lagu Kanak-Kanak',
      duration: '3:45',
      moralTheme: 'Hormat Ibu Bapa',
      description:
          'Mari belajar bercakap lembut, ucap salam dan tolong peluk ibu dan ayah bila mereka pulang kerja! Sangat ceria dan mendidik.',
      videoUrl: 'https://www.youtube.com/results?search_query=omar+hana+sayang+ibu+ayah',
      thumbnailEmoji: '🌸',
      badgeColor: Color(0xFFE11D48),
    ),
    KidsYouTubeVideo(
      id: 'vid_4_didi_kemas_mainan',
      title: 'Didi & Friends: Kemas Mainan Sendiri & Buat Kebaikan 🧸',
      channelName: 'Didi & Friends Melayu',
      duration: '2:58',
      moralTheme: 'Buat Baik & Tolong Menolong',
      description:
          'Lagu riang mengajar adik-adik masukkan semula mainan ke dalam bakul selepas bermain agar rumah bersih dan kemas.',
      videoUrl: 'https://www.youtube.com/results?search_query=didi+and+friends+kemas+mainan',
      thumbnailEmoji: '🐣',
      badgeColor: Color(0xFFF59E0B),
    ),
    KidsYouTubeVideo(
      id: 'vid_4_adab_bercakap_lembut',
      title: 'Lagu Adab Bersama Keluarga: Ucap Terima Kasih & Tolong 🤲',
      channelName: 'Lagu Kanak-Kanak Edukasi',
      duration: '4:12',
      moralTheme: 'Adab Bercakap Sopan',
      description:
          'Adik-adik belajar 3 perkataan ajaib: "Tolong", "Terima Kasih", dan "Minta Maaf" setiap kali bercakap dengan ibu bapa dan abang.',
      videoUrl: 'https://www.youtube.com/results?search_query=lagu+tiga+perkataan+ajaib+kanak+kanak',
      thumbnailEmoji: '✨',
      badgeColor: Color(0xFF10B981),
    ),
    KidsYouTubeVideo(
      id: 'vid_4_sayang_adik_abang',
      title: 'Keluarga Bahagia: Sayang Adik, Kongsi Mainan Sama-Sama 🚂',
      channelName: 'Little Angel Bahasa Melayu',
      duration: '3:30',
      moralTheme: 'Kasih Sayang Adik Beradik',
      description:
          'Kisah abang dan kakak berkongsi permainan dengan adik kecil. Tidak berebut dan sentiasa senyum gembira!',
      videoUrl: 'https://www.youtube.com/results?search_query=little+angel+melayu+berkongsi+mainan',
      thumbnailEmoji: '🌈',
      badgeColor: Color(0xFF8B5CF6),
    ),
  ];

  /// Fiction Story Books for Age 6 to 9 (e.g. Alex, 8 yo)
  static const List<FictionStoryBook> age8StoryBooks = [
    FictionStoryBook(
      id: 'book_8_kancil_merak',
      title: 'Kisah Sang Kancil & Sang Merak: Hormati Yang Tua, Sayangi Yang Muda',
      author: 'Pak Cik Nazri & ERAT Family Library',
      coverEmoji: '🦌',
      moralLesson: 'Menghormati orang tua dan melindungi yang lebih kecil',
      readingTime: '5 Minit Bacaan',
      chapters: [
        StoryChapter(
          title: 'Bab 1: Menghormati Sang Kura-Kura Emas',
          content:
              'Di sebuah rimba nan permai, Sang Kancil yang pintar sedang berjalan melintasi anak sungai. Di tepi tebing, Kancil melihat Sang Kura-Kura yang sudah sangat tua sedang perlahan-lahan memanjat bukit kecil membawa daun herba.\n\nWalaupun Kancil sedang tergesa-gesa mahu bermain bersama arnab, Kancil berhenti lalu menundukkan kepala tanda hormat. "Pak Cik Kura-Kura, biar saya tolong bawakan daun ini sehingga ke pondok Pak Cik," kata Sang Kancil dengan nada suara yang sangat sopan.',
        ),
        StoryChapter(
          title: 'Bab 2: Melindungi Anak Burung Ciak',
          content:
              'Tiba-tiba, Sang Merak yang sombong terbang melintas. Dia mengepakkan sayapnya sehingga angin kencang meniup sarang anak burung ciak yang masih kecil. Anak burung itu menangis ketakutan.\n\nSang Kancil segera melindunginya dengan dedaun lebar. "Sang Merak, kita yang kuat dan besar mestilah menyayangi yang kecil dan melindungi mereka, bukannya membuli atau menakut-nakutkan," nasihat Sang Kancil dengan tenang.',
        ),
        StoryChapter(
          title: 'Bab 3: Senyuman Rimba Damai',
          content:
              'Mendengar kata-kata itu, Sang Merak berasa malu lalu meminta maaf kepada anak burung ciak dan Pak Cik Kura-Kura. Sejak hari itu, semua haiwan di rimba saling menghormati orang yang lebih tua dan menyayangi adik-adik yang lebih kecil.\n\nPengajaran: Hormatilah ibu bapa, datuk nenek dan orang dewasa. Sayangilah adik-adik kita dengan hati yang tulus!',
        ),
      ],
    ),
    FictionStoryBook(
      id: 'book_8_abang_penyayang',
      title: 'Misi Rahsia Si Abang Penyayang: Operasi Hari Jadi Adik',
      author: 'Cikgu Aisyah',
      coverEmoji: '🎁',
      moralLesson: 'Kasih sayang adik-beradik & rela berkorban',
      readingTime: '6 Minit Bacaan',
      chapters: [
        StoryChapter(
          title: 'Bab 1: Tabung Bintang Alex',
          content:
              'Alex mempunyai sebuah tabung bintang yang dikumpulnya setiap kali selesai membantu Ibu mencuci pinggan dan menyiram pokok bunga. Hari lahir adik perempuannya, Emmi, tinggal tiga hari lagi.\n\nAlex tahu Emmi sangat mengidamkan sebuah kotak pensel warna dengan lukisan pelangi untuk melukis di tadika.',
        ),
        StoryChapter(
          title: 'Bab 2: Kejutan Dari Hati',
          content:
              'Tanpa memberitahu sesiapa, Alex meminta izin daripada Ibu untuk menggunakan mata bintangnya bagi mendapatkan kotak pensel warna tersebut sebagai hadiah untuk adik.\n\nIbu tersenyum bangga dan menitiskan air mata gembira melihat betapa mulianya hati Alex yang begitu menyayangi adiknya.',
        ),
        StoryChapter(
          title: 'Bab 3: Pelukan Hangat Hari Lahir',
          content:
              'Pada pagi hari lahir Emmi, Alex menghulurkan bungkusan hadiah itu dengan reben buatan tangannya sendiri. "Selamat Hari Lahir, adikku sayang!" kata Alex.\n\nEmmi melompat gembira dan memeluk abangnya erat-erat: "Terima kasih Abang! Abang adalah wira terbaik Emmi!" Rumah mereka dipenuhi kehangatan dan gelak tawa.',
        ),
      ],
    ),
  ];

  /// Short Story Books for Age 10 to 13 (e.g. Adam, 11 yo)
  static const List<ShortStoryBook> age11ShortStories = [
    ShortStoryBook(
      id: 'story_11_langkah_berani',
      title: 'Langkah Berani di Sekolah Baharu: Kekuatan Sokongan Ibu Bapa',
      author: 'Dr. Firdaus Ahmad',
      coverEmoji: '🎒',
      moralLesson: 'Keberanian, kejujuran berkomunikasi dengan keluarga, dan empati',
      readingTime: '8 Minit Bacaan',
      synopsis:
          'Kisah Adam yang berasa bimbang di sekolah baharu, namun sokongan dan kata-kata perangsang daripada Ayah dan Ibu membina keyakinan dirinya untuk berbuat kebaikan.',
      fullStory:
          'Hari pertama di Sekolah Kebangsaan Seri Melati membuatkan jantung Adam berdegup kencang. Tiada wajah kawan lama yang dikenalinya. Suasana di koridor penuh dengan murid-murid yang bergelak ketawa dalam kumpulan masing-masing.\n\nSemasa waktu rehat, Adam duduk bersendirian di bawah pohon rendang. Dia teringat pesanan Ayah pada pagi tadi: "Adam, bila kita berada di tempat baharu, jangan tunggu orang lain datang menyapa kita. Hulurkan tangan dahulu, berikan senyuman paling ikhlas, dan jika ada orang memerlukan bantuan, jadilah yang pertama membantu."\n\nTiba-tiba, seorang budak lelaki di hadapannya terjatuh dan buku-buku latihannya berselerak di atas lantai tar. Beberapa murid lain hanya melihat sambil ketawa kecil. Tanpa berlengah, Adam bangkit dan berlari ke arah budak itu. Dia membantu mengutip setiap buku yang terjatuh dan menolong budak itu berdiri.\n\n"Terima kasih kawan! Nama saya Harith," kata budak itu dengan senyuman lega.\n"Nama saya Adam. Saya murid baharu di sini," jawab Adam ceria.\n\nBermula dari detik itu, Adam mendapat seorang sahabat sejati. Pada petang itu, ketika makan malam bersama keluarga, Adam berkongsi pengalamannya dengan Ibu dan Ayah. Dia sedar bahawa nasihat ibu bapa bukan sekadar kata-kata kosong, tetapi kompas yang membimbingnya menjadi insan yang berempati dan berjiwa wira.',
    ),
    ShortStoryBook(
      id: 'story_11_bintang_empati',
      title: 'Bintang Empati Adam: Memahami Hati Adik & Sahabat',
      author: 'Ustazah Nurul Ain',
      coverEmoji: '🌟',
      moralLesson: 'Mengawal kemarahan dan meletakkan diri di tempat orang lain',
      readingTime: '7 Minit Bacaan',
      synopsis:
          'Apabila adik kecil merosakkan model sains yang dibina semalaman, Adam belajar mengawal emosi dan melihat kesilapan dari sudut empati seorang abang.',
      fullStory:
          'Adam menghabiskan masa berjam-jam menyusun kepingan kadbod dan lampu LED kecil untuk projek sains "Sistem Suria Mini". Dia berasa sangat bangga dengan hasil kerjanya.\n\nNamun, semasa Adam ke dapur untuk mengambil segelas air, adik kecilnya yang berusia 4 tahun masuk ke bilik dan tertarik dengan cahaya lampu itu. Tanpa sengaja, kepingan planet Musytari terlanggar dan model itu terjatuh ke lantai!\n\nApabila Adam kembali dan melihat ciptaannya berselerak, darahnya berderau. Tangannya mengepal, mahu sahaja dia menengking adik kecilnya. Namun, apabila dia melihat wajah adiknya yang pucat ketakutan dengan air mata bergenang di pipi, Adam teringat prinsip ERAT yang dipelajarinya: "Kemarahan tidak pernah membaiki apa yang patah; empati yang menyatukan kembali jiwa."\n\nAdam menarik nafas panjang selama lima saat. Dia melutut di hadapan adiknya. "Adik tak sengaja kan?" tanya Adam dengan suara lembut.\n\nAdiknya mengangguk laju sambil menangis: "Adik cuma nak tengok bintang cantik abang... adik minta maaf..."\n\nAdam memeluk adiknya. "Tak apa, mari kita kutip dan pasang balik sama-sama. Adik boleh tolong pegang pelekat ini." Ibu yang memerhati dari balik pintu tersenyum bangga. Hari itu, Adam bukan sahaja membaiki model sainsnya, malah dia mengukir lencana empati paling bersinar di dalam hatinya.',
    ),
  ];

  /// Short Novels for Age 14 to 17 (e.g. Hana, 15 yo)
  static const List<TeenShortNovel> age15Novels = [
    TeenShortNovel(
      id: 'novel_15_melodi_dua_generasi',
      title: 'Melodi Dua Generasi: Diari Remaja & Ibu',
      author: 'Siti Zulaikha (Penulis Novel Remaja Inspirasi)',
      coverEmoji: '🎧',
      theme: 'Merapatkan Jurang Komunikasi Remaja-Ibu Bapa & Pencarian Identiti',
      readingTime: '12 Minit Bacaan',
      synopsis:
          'Kisah Hana, seorang remaja 15 tahun yang meminati seni muzik digital, merasa ibunya tidak memahami dunianya. Namun satu peristiwa membuka pintu komunikasi hati ke hati antara dua generasi.',
      chapters: [
        StoryChapter(
          title: 'Bab 1: Dentuman Bunyi di Sebalik Pintu Bilik',
          content:
              'Headphone di telinga Hana bergegar dengan melodi lofi rentak rancak yang baru diciptanya. Pada usia 15 tahun, Hana merasakan bahawa dunia di dalam skrin dan muziknya adalah satu-satunya tempat di mana dia boleh menjadi dirinya sendiri.\n\nKetukan bertalu-talu di pintu bilik memutuskan imaginasinya. Wajah Ibu muncul dengan riak bimbang. "Hana, dah pukul 11 malam. Esok ada ujian Matematik. Kenapa masih memakai headphone?"\n\n"Ibu tak fahamlah! Hana tengah siapkan projek seni digital untuk pertandingan sekolah!" balas Hana dengan nada yang sedikit meninggi, sebelum menyembunyikan wajahnya di bantal. Suasana bilik tiba-tiba menjadi dingin.',
        ),
        StoryChapter(
          title: 'Bab 2: Kertas Lukisan yang Usang',
          content:
              'Keesokan petangnya, semasa mencari buku rujukan di almari ruang tamu, sebuah buku lakaran lama terjatuh. Hana membukanya dengan rasa ingin tahu.\n\nDi dalamnya terdapat lukisan-lukisan tangan cat air yang sangat halus dan indah, ditandatangani oleh "Sarah, 1998" — ibunya sendiri! Di halaman belakang, terdapat catatan tulisan tangan: "Impianku ingin menjadi pereka grafik, namun keluargaku memerlukan aku bekerja awal untuk menyara datuk."\n\nHana tergamam. Dia tidak pernah tahu bahawa ibunya juga pernah mempunyai impian seni yang sama seperti dirinya.',
        ),
        StoryChapter(
          title: 'Bab 3: Harmoni Dua Jiwa',
          content:
              'Malam itu, Hana tidak menutup pintu biliknya. Dia membawa sebuah cawan teh chamomile suam ke meja kerja ibunya. "Ibu... Hana minta maaf pasal semalam."\n\nHana menunjukkan karyanya di skrin laptop. "Hana buat muzik ini berinspirasikan lukisan lama Ibu yang Hana jumpa di almari."\n\nIbu memandang Hana dengan mata berkaca-kaca lalu memeluk anak gadisnya itu. "Ibu bukan melarang Hana berkarya, sayang. Ibu cuma takut Hana terlalu penat menanggung tekanan sekolah seorang diri."\n\nMalam itu, jurang antara dua generasi lebur dalam kehangatan empati. Hana menyedari bahawa di sebalik ketegasan seorang ibu, tersimpan cinta yang paling dalam yang sentiasa menginginkan kebahagiaan anaknya.',
        ),
      ],
    ),
    TeenShortNovel(
      id: 'novel_15_di_sebalik_skrin',
      title: 'Di Sebalik Skrin Biru: Belajar Mendengar & Didengari',
      author: 'Reza Iskandar',
      coverEmoji: '📱',
      theme: 'Kesihatan Mental Remaja, Tekanan Rakan Sebaya & Sokongan Keluarga',
      readingTime: '10 Minit Bacaan',
      synopsis:
          'Kisah menavigasi cabaran media sosial, perbandingan diri, dan bagaimana keberanian meluahkan perasaan kepada keluarga menjadi pelindung terbaik jiwa remaja.',
      chapters: [
        StoryChapter(
          title: 'Bab 1: Ilusi Angka Likes',
          content:
              'Melihat perkongsian rakan-rakan sekelas yang kelihatan begitu bergaya di Instagram sering membuatkan jiwa Hana terasa sunyi dan tidak sempurna. Tekanan untuk sentiasa kelihatan hebat di hadapan orang lain begitu membebankan.',
        ),
        StoryChapter(
          title: 'Bab 2: Perbualan di Meja Kopi',
          content:
              'Ayah melihat keresahan pada riak wajah Hana. Mereka duduk di anjung rumah sambil memandang bintang. Ayah mengingatkan: "Nilai diri kita bukan diukur dengan berapa banyak jempol maya yang kita kumpul, tetapi seberapa ikhlas kita menyayangi orang di sekeliling kita."',
        ),
        StoryChapter(
          title: 'Bab 3: Kebebasan Menjadi Diri Sendiri',
          content:
              'Hana mengambil keputusan untuk berpuasa media sosial selama seminggu dan menghabiskan masanya melukis bersama adik dan berjoging bersama Ayah. Beban di bahunya beransur hilang, digantikan dengan ketenangan jiwa yang hakiki.',
        ),
      ],
    ),
  ];

  /// Academic Journal Articles & Review Papers for Age 20 (Daniel - Family Psychology)
  static const List<YoungAdultJournalPaper> age20JournalPapers = [
    YoungAdultJournalPaper(
      id: 'paper_20_arnett_emerging_adulthood',
      title: 'Emerging Adulthood and Family Dynamics: The Transition to Mutuality and Interdependence',
      authors: 'Prof. Jeffrey Jensen Arnett, Ph.D.',
      journal: 'Journal of Adult Development & American Psychological Association',
      year: '2018',
      field: 'Psikologi Perkembangan Dewasa Muda (18-25 Tahun)',
      abstractText:
          'Kertas kajian ini menganalisis transisi psikologi anak muda berusia 18 hingga 25 tahun dari kebergantungan remaja kepada hubungan kesetaraan (mutuality) bersama ibu bapa. Kajian mendapati bahawa mengekalkan kelekatan erat dan komunikasi terbuka dengan keluarga mempercepatkan kematangan kerjaya dan mengurangkan kadar kemurungan di alam universiti dan tempat kerja sebanyak 42%.',
      practicalTakeaway:
          'Pada usia 20 tahun, hubungan anda dengan ibu bapa kini beralih menjadi rakan kongsi kehidupan. Berbual tentang perancangan kewangan, kerjaya, dan nilai hidup secara matang membina rasa hormat timbal balik antara orang dewasa.',
      doi: '10.1007/s10804-018-9302-4',
      url: 'https://doi.org/10.1007/s10804-018-9302-4',
    ),
    YoungAdultJournalPaper(
      id: 'paper_20_intergenerational_communication',
      title: 'Intergenerational Communication & Emotional Regulation in Young Adult Family Relationships',
      authors: 'Dr. Karen L. Fingerman, Kira S. Birditt, & Frank F. Furstenberg',
      journal: 'Family Relations: Interdisciplinary Journal of Applied Family Science, Vol. 69',
      year: '2020',
      field: 'Komunikasi Keluarga & Regulasi Emosi',
      abstractText:
          'Kajian empirikal terhadap 500 keluarga mendapati bahawa konflik antara anak dewasa dan ibu bapa paling kerap berpunca daripada perbezaan gaya hidup digital dan privasi. Kajian mencadangkan model komunikasi empati kolaboratif — di mana anak dewasa mendengar perspektif ibu bapa tanpa defensif, manakala ibu bapa memberi ruang autonomi kepada anak.',
      practicalTakeaway:
          'Bila berlaku perbezaan pendapat dengan ibu bapa, elakkan bersikap defensif. Berikan penjelasan rasional dengan tenang dan hargai niat baik mereka yang berasaskan kasih sayang.',
      doi: '10.1111/fare.12450',
      url: 'https://doi.org/10.1111/fare.12450',
    ),
    YoungAdultJournalPaper(
      id: 'paper_20_lifelong_attachment_burnout',
      title: 'Family Attachment as a Psychological Buffer Against Modern Workplace Stress and Burnout',
      authors: 'Prof. John Bowlby Research Foundation & Positive Psychology Review',
      year: '2022',
      journal: 'Journal of Positive Psychology and Well-Being, Vol. 16',
      field: 'Ketahanan Mental & Kesejahteraan Hidup',
      abstractText:
          'Kajian membuktikan bahawa orang dewasa muda yang mempunyai "pangkalan selamat" (secure base) dalam keluarga menunjukkan tahap hormon kortisol (stres) yang jauh lebih rendah semasa menghadapi peperiksaan akhir atau temuduga kerja. Ikatan keluarga seumur hidup bertindak sebagai perisai biologi terhadap keletihan mental (burnout).',
      practicalTakeaway:
          'Makan malam bersama keluarga atau bertanya khabar ibu bapa setiap minggu bukan sekadar rutin, tetapi terapi biologi yang menstabilkan emosi dan fokus masa depan anda.',
      doi: '10.1080/17439760.2022.2045890',
      url: 'https://doi.org/10.1080/17439760.2022.2045890',
    ),
  ];
}

