import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in_screen.dart';
import 'forgot_password_screen.dart';
import 'home_page.dart';
import 'lecturer_home_page.dart';
import 'admin_home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showErrors = false;

  Future<void> _handleLogin() async {
    setState(() {
      _showErrors = true;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      final role = ref.read(authStateProvider).value?.role ?? 'STUDENT';
      _navigateByRole(role);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _navigateByRole(String role) {
    final Widget home;
    switch (role) {
      case 'ADMIN':
        home = const AdminHomePage();
        break;
      case 'LECTURER':
        home = const LecturerHomePage();
        break;
      default:
        home = const HomePage();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleBlackStyleLarge = GoogleFonts.lemon(
      fontSize: 55,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
      height: 1.1,
    );

    final titleBlackStyleSmall = GoogleFonts.lemon(
      fontSize: 45,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
      height: 1.1,
    );

    final titleOrangeStyleLarge = GoogleFonts.lemon(
      fontSize: 55,
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

    Widget buildTextField(String hint, TextEditingController controller, {bool isPassword = false}) {
      bool isError = _showErrors && controller.text.isEmpty;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError)
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
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
                controller: controller,
                obscureText: isPassword,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: hintStyle,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // "nice to"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('nice', style: titleBlackStyleLarge),
                  const SizedBox(width: 50),
                  Text('to', style: titleBlackStyleSmall),
                  const SizedBox(width: 40), // Shift entire row slightly to the left
                ],
              ),
              
              // "see you"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 40), // Shift "see" slightly to the right
                  Text('see', style: titleBlackStyleSmall),
                  const SizedBox(width: 50),
                  Text('you', style: titleOrangeStyleLarge),
                ],
              ),

              const SizedBox(height: 50),

              buildTextField('enter your email', _emailController),

              const SizedBox(height: 20),

              buildTextField('enter your password', _passwordController, isPassword: true),

              const SizedBox(height: 12),

              // Forgot password link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'forgot password?',
                  style: GoogleFonts.lemon(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF5100),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SVG Image
              SvgPicture.asset(
                'assets_login_and_sign_in/cuate.svg',
                height: 220,
              ),

              const SizedBox(height: 20),

              // Login Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3, // Slight elevation for press effect
                    ),
                    child: Text(
                      'login in',
                      style: GoogleFonts.lemon(
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Text
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
                child: Text(
                  "don't have an account? sign in",
                  style: GoogleFonts.lemon(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
