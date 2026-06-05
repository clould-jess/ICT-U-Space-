import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Identifier_screen.dart';
import '../widgets/u_space_nav_bar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reservation_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();

  bool _showCourseNameError = false;
  bool _showCourseCodeError = false;
  bool _showMotifError = false;

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _tryNavigate(String role) async {
    setState(() {
      _showCourseNameError = _courseNameController.text.trim().isEmpty && _motifController.text.trim().isEmpty;
      _showCourseCodeError = _courseCodeController.text.trim().isEmpty && _motifController.text.trim().isEmpty;
      _showMotifError = _motifController.text.trim().isEmpty && _courseNameController.text.trim().isEmpty;
    });

    if (!_showCourseNameError && !_showCourseCodeError || !_showMotifError) {
      final userState = ref.read(authStateProvider);
      if (userState.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
        return;
      }

      // We attempt to find the matching hall and course
      final hallsList = ref.read(hallsProvider);
      final coursesList = ref.read(coursesProvider);

      String? hallId;
      hallsList.whenData((halls) {
        try {
          hallId = halls.firstWhere((h) => h.name.contains('George Mbarika')).id;
        } catch (_) {
          if (halls.isNotEmpty) hallId = halls.first.id;
        }
      });

      String? courseId;
      coursesList.whenData((courses) {
        try {
          courseId = courses.firstWhere((c) => c.code == _courseCodeController.text.trim()).id;
        } catch (_) {
          if (courses.isNotEmpty) courseId = courses.first.id;
        }
      });

      if (hallId == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No halls available in database')));
         return;
      }

      try {
        await ref.read(reservationProvider.notifier).bookHall({
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'start_time': '11:00',
          'end_time': '14:00',
          'hall_id': hallId,
          'course_id': courseId,
          'reserved_by': userState.value!.id,
          'type': _motifController.text.isNotEmpty ? 'EVENT' : 'CLASS',
          'event_name': _motifController.text.isNotEmpty ? _motifController.text : null,
          'force_booking': false
        });

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const IdentifierScreen(),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Style definitions
    final blackTextStyle = GoogleFonts.lemon(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

    final orangeTextStyle = GoogleFonts.lemon(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
    );

    Widget buildTextField(String hint, TextEditingController controller, bool showError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showError)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                'Please fill informations',
                style: GoogleFonts.lemon(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(10),
              border: showError ? Border.all(color: Colors.red, width: 2) : null,
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.lemon(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              style: GoogleFonts.lemon(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
            ),
          ),
        ],
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
              // ── Back Button ──────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.undo,
                      color: Color(0xFFFF5100),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'back',
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

              const SizedBox(height: 30),

              // ── Name Info ────────────────────────────────────────────────
              Text('name:', style: blackTextStyle),
              const SizedBox(height: 10),
              Text('George Mbarika hall', style: orangeTextStyle),

              const SizedBox(height: 30),

              // ── Text Fields ──────────────────────────────────────────────
              buildTextField('enter course name', _courseNameController, _showCourseNameError),
              buildTextField('enter course code', _courseCodeController, _showCourseCodeError),

              const SizedBox(height: 20),

              // ── Or any other motif ───────────────────────────────────────
              Center(
                child: Text(
                  'Or',
                  style: GoogleFonts.lemon(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF5100),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'any other motif',
                  style: GoogleFonts.lemon(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              buildTextField('enter here', _motifController, _showMotifError),

              const SizedBox(height: 30),

              // ── Time Badge ───────────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0000FF), // Blue
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '11:00 - 2:00PM',
                    style: GoogleFonts.lemon(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Identity Selection ───────────────────────────────────────
              Row(
                children: [
                  Text(
                    'I ',
                    style: GoogleFonts.lemon(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'am?',
                    style: GoogleFonts.lemon(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFF5100),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _tryNavigate('LECTURER'),
                    child: Text(
                      'lecturer',
                      style: GoogleFonts.lemon(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _tryNavigate('ADMIN'),
                    child: Text(
                      'Admin',
                      style: GoogleFonts.lemon(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => _tryNavigate('PREFECT'),
                  child: Text(
                    'Delegate',
                    style: GoogleFonts.lemon(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
