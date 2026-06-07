import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';


class SplashScreenTwo extends StatelessWidget {
  const SplashScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // TOP ROW: bro.svg and girl_group.svg
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 30.0, top: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets_splash/bro.svg',
                      height: 140,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: SvgPicture.asset(
                        'assets_splash/girl_group.svg',
                        height: 110,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // "welcome" text
              Text(
                'welcome',
                style: GoogleFonts.lemon(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),

              // "to" text + bro2.svg (Girl studying)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets_splash/bro2.svg',
                      height: 160,
                    ),
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.12,
                      child: Text(
                        'to',
                        style: GoogleFonts.lemon(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // "University" text
              Text(
                'University',
                style: GoogleFonts.lemon(
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),

              // "Space" text
              Text(
                'Space',
                style: GoogleFonts.lemon(
                  fontSize: 85,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFF5100),
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 15),

              // Bottom SVG: pana.svg (Baseball players)
              SvgPicture.asset(
                'assets_splash/pana.svg',
                height: 150,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5100),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'next',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
