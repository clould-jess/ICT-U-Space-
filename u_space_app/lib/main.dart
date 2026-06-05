import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/Splash_screen_two.dart';
import 'screens/Home_page.dart';
import 'screens/Search_screen.dart';


void main() {
  runApp(const ProviderScope(child: USpaceApp()));
}

class USpaceApp extends StatelessWidget {
  const USpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SplashScreenTwo()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets_splash/group_of_students.svg',
              height: 180,
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: GoogleFonts.lemon(
                  fontSize: 75,
                  fontWeight: FontWeight.bold,
                ),
                children: const [
                  TextSpan(
                    text: 'U ',
                    style: TextStyle(
                      color: Color(0xFF0011FF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(
                    text: '-',
                    style: TextStyle(
                      color: Color(0xFFFF0000),
                    ),
                  ),
                  TextSpan(
                    text: 'Space',
                    style: TextStyle(
                      color: Color(0xFFFF5100),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
