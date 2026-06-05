import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Language_screen.dart';

class TellMeMoreScreen extends StatelessWidget {
  const TellMeMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleBlackStyle = GoogleFonts.lemon(
      fontSize: 45,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

    final titleOrangeStyle = GoogleFonts.lemon(
      fontSize: 45,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
    );

    Widget buildRoleButton(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35.0, vertical: 15.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
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
              const SizedBox(height: 120),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('tell me ', style: titleBlackStyle),
                  Text('more...', style: titleOrangeStyle),
                ],
              ),

              const SizedBox(height: 50),

              buildRoleButton('Lecturer'),
              buildRoleButton('Admin.S'),
              buildRoleButton('Delegate'),
              buildRoleButton('Student'),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
