import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env load failed: $e');
  }
  await Supabase.initialize(
    url: 'https://hvqezqcocgcmjmnyzdub.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2cWV6cWNvY2djbWptbnl6ZHViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MzA5MTgsImV4cCI6MjA5MTIwNjkxOH0.ckuxciF6U2O9_lB2dth-HZagkHoVTumod4ZNi3nDbVA',
  );
  final client = Supabase.instance.client;
  if (client.auth.currentUser == null) {
    try {
      await client.auth.signInAnonymously();
    } catch (e) {
      debugPrint('signInAnonymously failed: $e');
    }
  }
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
      home: const HomeScreen(),
    );
  }
}