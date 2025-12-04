import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nashwaluthfiya_124230016_pam_a/menu/login_page.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/hive_service.dart';
import 'package:nashwaluthfiya_124230016_pam_a/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  await HiveService.initHive();
  await NotificationService.initialize();  
  await NotificationService.checkAndNotify();
  
  runApp(const StokMateApp());
}

class StokMateApp extends StatelessWidget {
  const StokMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StokMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26A69A),
          primary: const Color(0xFF26A69A),
          secondary: const Color(0xFF4DB6AC),
          tertiary: const Color(0xFF80CBC4),
          surface: const Color(0xFFF5FFFE),
          background: const Color(0xFFE0F7F4),
          error: const Color(0xFFFF6B6B),      
        ),
        scaffoldBackgroundColor: const Color(0xFFE0F7F4),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFF5FFFE),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF26A69A),
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF26A69A),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5FFFE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF26A69A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF80CBC4).withOpacity(0.3),
          labelStyle: const TextStyle(color: Color(0xFF00695C)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Color(0xFF004D40)),
          bodyMedium: TextStyle(color: Color(0xFF00796B)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}