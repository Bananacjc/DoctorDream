import 'package:flutter/material.dart';
import 'constants/color_constant.dart';
import 'widgets/custom_bottom_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';

import './data/local/local_database.dart';

void main() async{
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize the database
  await LocalDatabase.instance.database;

  // Run the app
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
          seedColor: const Color(0xFF03174C),
          primary: const Color(0xFF03174C),
          onPrimary: const Color(0xFFFFFFFF),
          primaryContainer: const Color(0xFF8286F1),
          onPrimaryContainer: const Color(0xFFFFFFFF),
          secondary: const Color(0xFFFAF8FF),
          onSecondary: const Color(0xFF000000),
          secondaryContainer: const Color(0xFFD9D9D9),
          onSecondaryContainer: const Color(0xFF03174C),
          error: const Color(0xFFB14066),
          onError: const Color(0xFFFFFFFF),
          brightness: Brightness.dark,
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.robotoFlex(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onPrimary
          ),
          headlineLarge: GoogleFonts.robotoFlex(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Theme.of(context).colorScheme.onPrimary
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: ColorConstant.primary.withAlpha(100),
          selectionHandleColor: ColorConstant.primary,
          cursorColor: ColorConstant.primary,
        ),
        useMaterial3: true,
      ),
      home: const CustomBottomNavigationBar(),
      debugShowCheckedModeBanner: false,
    );
  }
}
