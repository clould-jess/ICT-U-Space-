import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '1success_screen.dart';
import '../widgets/u_space_nav_bar.dart';

class UnbookScreen extends StatefulWidget {
  const UnbookScreen({super.key});

  @override
  State<UnbookScreen> createState() => _UnbookScreenState();
}

class _UnbookScreenState extends State<UnbookScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
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
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'back',
                      style: GoogleFonts.lemon(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // ── Title Texts ──────────────────────────────────────────────
              Text(
                'Enter',
                style: GoogleFonts.lemon(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFFF5100),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: const Alignment(0.3, 0.0), // slightly to the right of center
                child: Text(
                  'your',
                  style: GoogleFonts.lemon(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'unique',
                style: GoogleFonts.lemon(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'identifier',
                  style: GoogleFonts.lemon(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF5100),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Error Message ─────────────────────────────────────────────
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 8),
                  child: Text(
                    'please enter your unique key',
                    style: GoogleFonts.lemon(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ),

              // ── Text Field ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(15),
                  border: _showError ? Border.all(color: Colors.red, width: 2) : null,
                ),
                child: TextField(
                  controller: _keyController,
                  decoration: InputDecoration(
                    hintText: 'enter your key',
                    hintStyle: GoogleFonts.lemon(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                  style: GoogleFonts.lemon(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Done Button ──────────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_keyController.text.trim().length != 8) {
                        setState(() {
                          _showError = true;
                        });
                      } else {
                        setState(() {
                          _showError = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SuccessScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5, // Increased elevation for push effect
                      splashFactory: InkRipple.splashFactory,
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.lemon(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
