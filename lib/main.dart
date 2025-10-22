import 'package:flutter/material.dart';
import 'widgets/custom_bottom_navigation_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF081944);
    const Color lightNavy = Color(0xFF0D2357);
    return MaterialApp(
      title: 'Doctor Dream',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: lightNavy,
          selectedItemColor: Colors.white,
          unselectedItemColor: Color(0xFF9AA5C4),
          type: BottomNavigationBarType.fixed,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E8CF2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CustomBottomNavigationBar(),
      debugShowCheckedModeBanner: false,
    );
  }
}
