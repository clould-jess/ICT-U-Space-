import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'selection_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final TextEditingController _majorController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  bool _showMajorError = false;
  bool _showLevelError = false;
  bool _showFillError = false;

  static const List<String> _validMajors = [
    'Software Engineering',
    'Computer Science',
    'Information Security Network',
    'Cybersecurity',
  ];

  void _validateMajor(String value) {
    final isValid = _validMajors.any(
      (major) => major.toLowerCase() == value.trim().toLowerCase(),
    );
    setState(() {
      _showMajorError = value.trim().isNotEmpty && !isValid;
    });
  }

  void _validateLevel(String value) {
    final validLevels = ['1', '2', '3', '4'];
    final isValid = validLevels.contains(value.trim());
    setState(() {
      _showLevelError = value.trim().isNotEmpty && !isValid;
    });
  }

  void _tryNavigate(BuildContext context) {
    final majorValue = _majorController.text.trim();
    final levelValue = _levelController.text.trim();
    final validLevels = ['1', '2', '3', '4'];
    final isMajorValid = _validMajors.any(
      (m) => m.toLowerCase() == majorValue.toLowerCase(),
    );
    final isLevelValid = validLevels.contains(levelValue);

    if (majorValue.isEmpty || levelValue.isEmpty || !isMajorValid || !isLevelValid) {
      setState(() {
        _showFillError = true;
        if (majorValue.isNotEmpty) _showMajorError = !isMajorValid;
        if (levelValue.isNotEmpty) _showLevelError = !isLevelValid;
      });
      return;
    }

    setState(() => _showFillError = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  }

  @override
  void dispose() {
    _majorController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleBlackStyle = GoogleFonts.lemon(
      fontSize: 35,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
      height: 1.2,
    );

    final titleOrangeStyle = GoogleFonts.lemon(
      fontSize: 35,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
      height: 1.2,
    );

    Widget buildMajorTextField() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showMajorError)
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 6.0),
                child: Text(
                  'enter correct major',
                  style: GoogleFonts.lemon(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(15),
                border: _showMajorError
                    ? Border.all(color: Colors.red, width: 1.5)
                    : null,
              ),
              child: TextField(
                controller: _majorController,
                onChanged: _validateMajor,
                decoration: InputDecoration(
                  hintText: 'Computer Science',
                  hintStyle: GoogleFonts.lemon(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
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
          ],
        ),
      );
    }

    Widget buildLevelTextField() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showLevelError)
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 6.0),
                child: Text(
                  'enter correct level',
                  style: GoogleFonts.lemon(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(15),
                border: _showLevelError
                    ? Border.all(color: Colors.red, width: 1.5)
                    : null,
              ),
              child: TextField(
                controller: _levelController,
                onChanged: _validateLevel,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'level 2',
                  hintStyle: GoogleFonts.lemon(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
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
              const SizedBox(height: 60, width: double.infinity),

              // "Enter your major"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Enter your ', style: titleBlackStyle),
                  Text('major', style: titleOrangeStyle),
                ],
              ),

              const SizedBox(height: 40),

              // Major text field with validation
              buildMajorTextField(),

              const SizedBox(height: 50),

              // "What level are you?"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('What ', style: titleBlackStyle),
                  Text('level ', style: titleOrangeStyle),
                  Text('are', style: titleBlackStyle),
                ],
              ),
              const SizedBox(height: 5),
              Text('you?', style: titleBlackStyle),

              const SizedBox(height: 40),

              // Level text field with validation
              buildLevelTextField(),

              const SizedBox(height: 40),

              // Graduate image
              SvgPicture.asset(
                'assets_language/pana graduate.svg',
                height: 250,
              ),

              const SizedBox(height: 20),

              // Global fill error
              if (_showFillError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Text(
                    'please fill all informations',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lemon(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'back_btn_courses',
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
            FloatingActionButton(
              heroTag: 'forward_btn_courses',
              onPressed: () => _tryNavigate(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.arrow_forward,
                color: Color(0xFFFF5100),
                size: 50,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
