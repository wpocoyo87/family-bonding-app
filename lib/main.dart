import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/erat_providers.dart';
import 'core/theme/erat_palette.dart';
import 'features/dashboard/presentation/erat_home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseConnected = false;
  // Initialize Firebase with Erat Apps configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseConnected = true;
    debugPrint('🔥 Firebase initialized successfully for Erat Apps!');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization info: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseConnectedProvider.overrideWith((ref) => isFirebaseConnected),
      ],
      child: const EratApp(),
    ),
  );
}

class EratApp extends ConsumerWidget {
  const EratApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldTheme = ref.watch(selectedWorldThemeProvider);

    return MaterialApp(
      title: 'ERAT — Grow Together',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: worldTheme.accentColor,
          primary: worldTheme.accentColor,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodySmall: TextStyle(fontSize: 13, height: 1.4, color: EratPalette.textMuted),
          bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: EratPalette.textDark),
          bodyLarge: TextStyle(fontSize: 16.5, height: 1.45, fontWeight: FontWeight.w500, color: EratPalette.textDark),
          titleSmall: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: EratPalette.textDark),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EratPalette.textDark),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EratPalette.textDark),
          headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: EratPalette.textDark),
          headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: EratPalette.textDark),
        ),
      ),
      home: const EratHomeScreen(),
    );
  }
}
