import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'models/app_state.dart';

void main() {
  runApp(const SariStoreApp());
}

class SariStoreApp extends StatelessWidget {
  const SariStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TindaHan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8572A),
          primary: const Color(0xFFE8572A),
          secondary: const Color(0xFF2D6A4F),
          surface: const Color(0xFFFFF8F5),
          background: const Color(0xFFFFF8F5),
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8572A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
