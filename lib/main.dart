import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hvqezqcocgcmjmnyzdub.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2cWV6cWNvY2djbWptbnl6ZHViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MzA5MTgsImV4cCI6MjA5MTIwNjkxOH0.ckuxciF6U2O9_lB2dth-HZagkHoVTumod4ZNi3nDbVA',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '토론 커뮤니티',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnboardingStartScreen(),
    );
  }
}