import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Hall_info_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildOccupiedCard({
      required String subject,
      required String hall,
    }) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HallInfoScreen(),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0000FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: GoogleFonts.lemon(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hall,
                style: GoogleFonts.lemon(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildFreeTab(String label) {
      return GestureDetector(
        onTap: () {
          // No action for now
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black38, width: 1.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.lemon(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Bar ───────────────────────────────────────────────
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                          hintStyle: GoogleFonts.lemon(
                            fontSize: 16,
                            color: Colors.black45,
                          ),
                        ),
                        style: GoogleFonts.lemon(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.search,
                      color: Color(0xFFFF5100),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.menu,
                      color: Colors.black,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Free Halls Tab ───────────────────────────────────────────
              buildFreeTab('free halls'),

              const SizedBox(height: 24),

              // ── Occupied Cards ───────────────────────────────────────────
              buildOccupiedCard(
                subject: 'introduction to IOT and Embedded..',
                hall: 'Chumbow hall',
              ),
              buildOccupiedCard(
                subject: 'Java Programming 2 Group 2',
                hall: 'Pondi hall',
              ),
              buildOccupiedCard(
                subject: 'CCNA 2',
                hall: 'IT hall',
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
