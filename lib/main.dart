import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

// 🔐 AUTH
import 'services/auth_service.dart';
import 'services/session_watcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();

  // 🔥 START SESSION WATCHER (GLOBAL)
  WidgetsBinding.instance.addObserver(
    SessionWatcher(authService),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color seedColor = const Color(0xFF2C3E50);

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: seedColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.2),
        thickness: 1,
        space: 24,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: const Color(0xFF3498DB),
        brightness: Brightness.light,
        labelStyle: GoogleFonts.inter(color: Colors.black87),
      ).copyWith(
        backgroundColor: Colors.grey[200],
        selectedColor: seedColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: Colors.white,
        iconColor: seedColor,
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData.fromDefaults(
        secondaryColor: const Color(0xFF3498DB),
        brightness: Brightness.dark,
        labelStyle: GoogleFonts.inter(color: Colors.white),
      ).copyWith(
        backgroundColor: const Color(0xFF2A2A2A),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF1E1E1E),
        iconColor: Colors.white70,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Publisher App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,

      // 🔑 IMPORTANT: GLOBAL NAVIGATOR KEY
      navigatorKey: AuthService.navigatorKey,

      // ✅ Splash decides login/home
      home: const SplashScreen(),

      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
      },

      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'SA'),
      ],
    );
  }
}
