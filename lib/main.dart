import 'package:flutter/material.dart';
import 'screens/title_screen.dart';

void main() => runApp(const StarshipTrooperzApp());

class StarshipTrooperzApp extends StatelessWidget {
  const StarshipTrooperzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STARSHIP TROOPERZ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF88),
          secondary: Color(0xFF00AAFF),
          surface: Color(0xFF040814),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const TitleScreen(),
    );
  }
}
