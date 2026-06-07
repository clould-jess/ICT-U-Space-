import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import '../widgets/u_space_nav_bar.dart';

class SecondSuccessScreen extends StatelessWidget {
  const SecondSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ── "Hall is now" ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Hall  ',
                      style: GoogleFonts.lemon(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'is  ',
                      style: GoogleFonts.lemon(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'now',
                      style: GoogleFonts.lemon(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── "book" ───────────────────────────────────────────────────
                Text(
                  'book',
                  style: GoogleFonts.lemon(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF0000FF),
                  ),
                ),

                const SizedBox(height: 30),

                // ── Image ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SvgPicture.asset(
                    'assets_language/cuate working.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                // ── "click here to go back home" ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'click here',
                          style: GoogleFonts.lemon(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFFF5100),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFFF5100),
                            decorationThickness: 2,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                                (route) => false,
                              );
                            },
                        ),
                        TextSpan(
                          text: ' to go back  home',
                          style: GoogleFonts.lemon(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
