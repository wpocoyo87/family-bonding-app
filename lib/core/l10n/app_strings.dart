import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { ms, en }

final appLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);

class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  bool get isMs => lang == AppLanguage.ms;

  String tr(String ms, String en) => isMs ? ms : en;

  String get appTitle => 'ERAT';
  String get tagline => tr('Membesar Bersama Keluarga', 'Grow Together as a Family');
  String get switchProfile => tr('Tukar Profil', 'Switch Profile');
  String get bondingTab => tr('Bonding & Habit', 'Bonding & Habits');
  String get goalsTab => tr('Wish Goal', 'Wish Goals');
  String get chatTab => tr('Sembang Erat', 'Family Chat');
  String get ledgerTab => tr('Bintang & Milestone', 'Stars & Milestones');
  String get familyHubTab => tr('Keluarga & Jemputan', 'Family & Invites');

  String get noPenaltyBanner => tr(
        '🌱 Tiada penalti atau tolak mata dalam ERAT. Setiap usaha kecil diraikan — Cuba lagi esok!',
        '🌱 No penalties or point deductions in ERAT. Every small effort counts — Try again tomorrow!',
      );

  String get under13ChatNotice => tr(
        '🛡️ Notis Ketelusan (< 13 tahun): Ibu bapa boleh membaca ruang sembang ini untuk bimbingan & keselamatan. Bertukar peribadi secara automatik pada umur 13 tahun.',
        '🛡️ Transparency Notice (< 13 yrs): Parents may view this chat for guidance & safety. Automatically switches to private at age 13.',
      );

  String get teenPrivacyNotice => tr(
        '🔒 Ruang Peribadi Remaja (13+): Anda mengawal apa yang dikongsi dengan ibu bapa.',
        '🔒 Teen Personal Space (13+): You control what is shared with parents.',
      );
}

final appStringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppStrings(lang);
});

