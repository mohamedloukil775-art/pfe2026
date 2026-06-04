import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/storage/token_storage.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/auth/auth_gateway.dart';
import 'features/player/player_home_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  }
  runApp(const PadelChampionshipApp());
}

class PadelChampionshipApp extends StatelessWidget {
  const PadelChampionshipApp({super.key});

  ThemeData _buildTheme() {
    // Padel color palette — lime green primary, dark navy background
    const lime = Color(0xFFC8F000);
    const darkBg = Color(0xFF080C14);
    const cardBg = Color(0xFF0F1621);
    const bluePadel = Color(0xFF00A8FF);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: lime,
      brightness: Brightness.dark,
      primary: lime,
      secondary: bluePadel,
      surface: cardBg,
      onPrimary: const Color(0xFF080C14),
      onSecondary: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1520),
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0D1520),
        indicatorColor: lime.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? lime : Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? lime : Colors.white38,
            size: 24,
          ),
        ),
        height: 68,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lime.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111C2E),
        hintStyle: const TextStyle(color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIconColor: Colors.white38,
        suffixIconColor: Colors.white38,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lime, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lime,
          foregroundColor: const Color(0xFF080C14),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lime,
          side: const BorderSide(color: lime, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF111C2E),
        selectedColor: lime.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: lime.withValues(alpha: 0.25)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Championnat Padel',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: SplashScreen(nextScreen: const _AppEntryPoint()),
    );
  }
}

class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: TokenStorage.getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userInfo = snapshot.data;
        final userId = int.tryParse(userInfo?['userId'] ?? '');
        final userRole = userInfo?['userRole']?.toLowerCase();

        if (userId != null && userRole != null) {
          if (userRole == 'admin') {
            return const AdminHomeScreen();
          }
          return PlayerHomeScreen(userId: userId);
        }

        return const AuthGateway();
      },
    );
  }
}
