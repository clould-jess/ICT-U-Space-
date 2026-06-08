import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';
import 'lecturer_home_page.dart';

/// Shown after signup as a role-confirmation screen.
/// The role is already set by the backend (detected from matricule),
/// so no selection is needed — just a friendly confirmation and navigation.
/// ADMIN is not listed because there is a single pre-configured admin account.
class TellMeMoreScreen extends ConsumerWidget {
  const TellMeMoreScreen({super.key});

  void _navigateByRole(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider).value;
    final role = user?.role ?? 'STUDENT';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.role ?? 'STUDENT';
    final matricule = user?.matricule ?? '';

    // Human-readable role label
    final String roleLabel;
    final Color roleColor;
    final String roleDescription;
    switch (role) {
      case 'LECTURER':
        roleLabel = 'Lecturer';
        roleColor = const Color(0xFF1A1AFF);
        roleDescription = 'You can book halls and manage your courses.';
        break;
      case 'PREFECT':
        roleLabel = 'Delegate';
        roleColor = const Color(0xFFFF5100);
        roleDescription = 'You can book halls on behalf of your class.';
        break;
      default:
        roleLabel = 'Student';
        roleColor = const Color(0xFF00AA44);
        roleDescription = 'You can view hall availability and your schedule.';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'tell me ',
                    style: GoogleFonts.lemon(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'more...',
                    style: GoogleFonts.lemon(
                      fontSize: 45,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFFF5100),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Detected role card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      // Role dot + label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: roleColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            roleLabel,
                            style: GoogleFonts.lemon(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (matricule.isNotEmpty)
                        Text(
                          matricule,
                          style: GoogleFonts.lemon(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        roleDescription,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lemon(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateByRole(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'continue',
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
