import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runZonedGuarded(
    () => runApp(const FitLingoApp()),
    (error, stack) => debugPrint('Error: $error\n$stack'),
  );
}

class FitLingoApp extends StatelessWidget {
  const FitLingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4),
          brightness: Brightness.dark,
          primary: const Color(0xFF06B6D4),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
