import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Hall_info_screen.dart';
import 'Search_screen.dart';
import 'Booking_screen.dart';
import '../widgets/u_space_nav_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Style definitions
    final bodyBlackStyle = GoogleFonts.lemon(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

    final sectionLabelStyle = GoogleFonts.lemon(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

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
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1AFF), // blue
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

    Widget buildFreeCard({
      required String status,
      required String hall,
    }) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingScreen(),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9), // grey
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: GoogleFonts.lemon(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hall,
                style: GoogleFonts.lemon(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
            ],
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
              // ── Top Bar ──────────────────────────────────────────────────
              Row(
                children: [
                  // "Hi Garett!"
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hi ',
                            style: GoogleFonts.lemon(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: 'Garett!',
                            style: GoogleFonts.lemon(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFFF5100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Search icon
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  // Burger menu
                  IconButton(
                    onPressed: () {
                      // TODO: open menu
                    },
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Occupied halls ───────────────────────────────────────────
              Text('occupied halls now..', style: sectionLabelStyle),

              const SizedBox(height: 10),

              // Time
              Text(
                '11:00-14:00',
                style: GoogleFonts.lemon(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFF5100),
                ),
              ),

              const SizedBox(height: 12),

              // Occupied cards
              buildOccupiedCard(
                subject: 'Introduction to IOT and Embedded..',
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

              const SizedBox(height: 24),

              // ── Free halls ───────────────────────────────────────────────
              Text('Free halls now..', style: sectionLabelStyle),

              const SizedBox(height: 10),

              buildFreeCard(
                status: '*****',
                hall: 'George Mbarika hall',
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'back_btn_home',
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
