import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Courses_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleBlackStyle = GoogleFonts.lemon(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
      height: 1.1,
    );

    final titleOrangeStyle = GoogleFonts.lemon(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
      height: 1.1,
    );

    Widget buildLanguageButton(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoursesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5100),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
            ),
            child: Text(
              title,
              style: GoogleFonts.lemon(
                fontSize: 35,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80, width: double.infinity),

              // Title
              Text('Choose your', style: titleBlackStyle),
              const SizedBox(height: 5),
              Text('language', style: titleOrangeStyle),

              const SizedBox(height: 50),

              // English Button
              buildLanguageButton('English'),

              const SizedBox(height: 40),

              // SVG Image
              SvgPicture.asset(
                'assets_language/bro.svg',
                height: 250,
              ),

              const SizedBox(height: 40),

              // Francais Button
              buildLanguageButton('Francais'),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
