import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Login_screen.dart';
import 'Tell_me_more_screen.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showErrors = false;

  Future<void> _handleSignIn() async {
    setState(() {
      _showErrors = true;
    });

    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).signup(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        'STUDENT', // Defaulting to STUDENT for now
      );
      
      if (!mounted) return;
      // Navigate to Home Page on success
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matriculeController.dispose();
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
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
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
                  const SizedBox(width: 40),
                ],
              ),
              
              // "meet you"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 40),
                  Text('meet', style: titleBlackStyleSmall),
                  const SizedBox(width: 50),
                  Text('you', style: titleOrangeStyleLarge),
                ],
              ),

              const SizedBox(height: 30),

              buildTextField('enter your name', _nameController),
              buildTextField('enter matricule no', _matriculeController),
              buildTextField('enter your email', _emailController),
              buildTextField('enter your password', _passwordController, isPassword: true),

              const SizedBox(height: 40),

              // Sign in Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3, // Slight elevation for press effect
                    ),
                    child: Text(
                      'sign in',
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
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: Text(
                  "have an account? login in",
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
      floatingActionButton: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TellMeMoreScreen()),
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
