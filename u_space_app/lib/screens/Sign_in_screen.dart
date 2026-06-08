import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'home_page.dart';
import 'lecturer_home_page.dart';
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
  String _detectedRole = ''; // '' | 'STUDENT' | 'LECTURER' | 'INVALID'

  @override
  void initState() {
    super.initState();
    _matriculeController.addListener(_onMatriculeChanged);
  }

  void _onMatriculeChanged() {
    final raw = _matriculeController.text.trim().toUpperCase();
    String role;
    if (raw.isEmpty) {
      role = '';
    } else if (raw.startsWith('ICTULEC')) {
      role = 'LECTURER';
    } else if (raw.startsWith('ICTU')) {
      role = 'STUDENT';
    } else {
      role = 'INVALID';
    }
    if (role != _detectedRole) {
      setState(() => _detectedRole = role);
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

  Future<void> _handleSignIn() async {
    setState(() => _showErrors = true);

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _matriculeController.text.trim().isEmpty) {
      return;
    }

    if (_detectedRole == 'INVALID' || _detectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid matricule. Must start with ICTU (student) or ICTULEC (lecturer).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_emailController.text.toLowerCase().endsWith('@ictuniversity.edu.cm')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration is restricted to @ictuniversity.edu.cm emails only.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).signup(
        _nameController.text.trim(),
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
        _matriculeController.text.trim(),
      );

      if (!mounted) return;
      final user = ref.read(authStateProvider).value;
      _navigateByRole(user?.role ?? _detectedRole);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateByRole(String role) {
    if (role == 'LECTURER') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LecturerHomePage()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    }
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    final hasError = _showErrors && controller.text.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                'fill all the fields please',
                style: GoogleFonts.lemon(
                  fontSize: 13,
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
              border: hasError ? Border.all(color: Colors.red, width: 1.5) : null,
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              textCapitalization: capitalization,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.lemon(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              style: GoogleFonts.lemon(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatriculeField() {
    final hasError = _showErrors && _matriculeController.text.isEmpty;

    // Role badge colour
    Color badgeColor;
    String badgeLabel;
    switch (_detectedRole) {
      case 'LECTURER':
        badgeColor = const Color(0xFF1A1AFF);
        badgeLabel = 'Lecturer detected';
        break;
      case 'STUDENT':
        badgeColor = const Color(0xFF00AA44);
        badgeLabel = 'Student detected';
        break;
      case 'INVALID':
        badgeColor = Colors.red;
        badgeLabel = 'Invalid matricule';
        break;
      default:
        badgeColor = Colors.transparent;
        badgeLabel = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                'fill all the fields please',
                style: GoogleFonts.lemon(
                  fontSize: 13,
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
              border: hasError
                  ? Border.all(color: Colors.red, width: 1.5)
                  : _detectedRole == 'INVALID'
                      ? Border.all(color: Colors.red, width: 1.5)
                      : null,
            ),
            child: TextField(
              controller: _matriculeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'enter matricule no.',
                hintStyle: GoogleFonts.lemon(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              style: GoogleFonts.lemon(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          // Dynamic role badge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _detectedRole.isNotEmpty
                ? Padding(
                    key: ValueKey(_detectedRole),
                    padding: const EdgeInsets.only(top: 8, left: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          badgeLabel,
                          style: GoogleFonts.lemon(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // Title: "nice to / meet you"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'nice',
                    style: GoogleFonts.lemon(
                      fontSize: 55,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 50),
                  Text(
                    'to',
                    style: GoogleFonts.lemon(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    'meet',
                    style: GoogleFonts.lemon(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 50),
                  Text(
                    'you',
                    style: GoogleFonts.lemon(
                      fontSize: 55,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFF5100),
                      height: 1.1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildTextField('enter your name', _nameController),
              _buildMatriculeField(),
              _buildTextField('enter your email', _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField('enter your password', _passwordController,
                  isPassword: true),

              const SizedBox(height: 40),

              // Sign in button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
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

              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text(
                  'have an account? login',
                  style: GoogleFonts.lemon(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
