import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Unbook_screen.dart';
import '../widgets/u_space_nav_bar.dart';

class HallInfoScreen extends StatelessWidget {
  const HallInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.lemon(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

    final valueStyle = GoogleFonts.lemon(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
    );

    Widget buildInfoRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 6),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ────────────────────────────────────────────────────
              Center(
                child: Text(
                  'Hall informations',
                  style: GoogleFonts.lemon(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ── Info fields ───────────────────────────────────────────────
              buildInfoRow('Name:', 'George Mbarika hall'),
              buildInfoRow('ongoing course:', 'OOADI'),
              buildInfoRow('course lecturer:', 'Engineer Tekoh Palmer'),
              buildInfoRow('course deleguate:', 'Fotsi Fotsi Eric'),

              const SizedBox(height: 20),

              // ── Status row ───────────────────────────────────────────────
              Row(
                children: [
                  Text('status:', style: labelStyle),
                  const SizedBox(width: 20),
                  Text(
                    'BOOKED',
                    style: GoogleFonts.lemon(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFF5100),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Unbook button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UnbookScreen(),
                      ),
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
                    'Unbook hall',
                    style: GoogleFonts.lemon(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'back_btn_hall_info',
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.arrow_back,
          color: Color(0xFFFF5100),
          size: 50,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
