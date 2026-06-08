import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _showError = true);

    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ApiService().forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'something went wrong. try again.',
            style: GoogleFonts.lemon(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          backgroundColor: const Color(0xFFFF5100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleBlackStyleLarge = GoogleFonts.lemon(
      fontSize: 50,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
      height: 1.1,
    );

    final titleOrangeStyleLarge = GoogleFonts.lemon(
      fontSize: 50,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
      height: 1.1,
    );

    final hintStyle = GoogleFonts.lemon(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.grey.shade600,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      // ── Back Arrow ────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        heroTag: 'back_btn_forgot',
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.arrow_back,
          color: Color(0xFFFF5100),
          size: 50,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // ── Title ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('forgot', style: titleBlackStyleLarge),
                  const SizedBox(width: 40),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 40),
                  Text('your', style: GoogleFonts.lemon(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                    height: 1.1,
                  )),
                  const SizedBox(width: 20),
                  Text('pass?', style: titleOrangeStyleLarge),
                ],
              ),

              const SizedBox(height: 16),

              // ── Subtitle ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'enter your email and we\'ll send you a reset link.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lemon(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.black45,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Success State ─────────────────────────────────────────────
              if (_emailSent) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFFFF5100),
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'check your inbox!',
                          style: GoogleFonts.lemon(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'a reset link was sent to\n${_emailController.text.trim()}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lemon(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Back to login
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'back to login',
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFF5100),
                    ),
                  ),
                ),
              ]

              // ── Input State ───────────────────────────────────────────────
              else ...[
                // Email field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showError && _emailController.text.trim().isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, bottom: 6.0),
                          child: Text(
                            'fill all the fields please',
                            style: GoogleFonts.lemon(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) {
                            if (_showError) setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'enter your email',
                            hintStyle: hintStyle,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                          ),
                          style: GoogleFonts.lemon(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Send button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5100),
                        disabledBackgroundColor:
                            const Color(0xFFFF5100).withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'send reset link',
                              style: GoogleFonts.lemon(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Back to login
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'back to login',
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
