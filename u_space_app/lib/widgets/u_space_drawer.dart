import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class USpaceDrawer extends ConsumerWidget {
  const USpaceDrawer({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authStateProvider.notifier).logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFFF5100),
    Color labelColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 18),
            Text(
              label,
              style: GoogleFonts.lemon(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'LECTURER': return const Color(0xFF1A1AFF);
      case 'ADMIN': return const Color(0xFFFF5100);
      case 'PREFECT': return const Color(0xFFAA00AA);
      default: return const Color(0xFF00AA44);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.black54, size: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'U ', style: GoogleFonts.lemon(fontSize: 42, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF0011FF))),
                        TextSpan(text: '-', style: GoogleFonts.lemon(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.red)),
                        TextSpan(text: 'Space', style: GoogleFonts.lemon(fontSize: 42, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'manage your space.',
                    style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black38),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: _roleColor(user.role), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                                Text(user.role.toLowerCase(), style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black45)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Container(height: 2, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(5))),
            ),

            // ── Menu Items ────────────────────────────────────────────────────
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_outlined,
              label: 'settings',
              onTap: () => Navigator.of(context).pushNamed('/settings'),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.message_outlined,
              label: 'messages',
              onTap: () => Navigator.of(context).pushNamed('/messages'),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.notifications_outlined,
              label: 'notifications',
              onTap: () => Navigator.of(context).pushNamed('/notifications'),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person_outline,
              label: 'profile',
              onTap: () => Navigator.of(context).pushNamed('/profile'),
            ),

            // Student / Prefect — timetable
            if (user?.role == 'STUDENT' || user?.role == 'PREFECT')
              _buildDrawerItem(
                context: context,
                icon: Icons.calendar_month_outlined,
                label: 'my timetable',
                onTap: () => Navigator.of(context).pushNamed('/timetable'),
              ),

            // Lecturer — course management
            if (user?.role == 'LECTURER')
              _buildDrawerItem(
                context: context,
                icon: Icons.school_outlined,
                label: 'my courses',
                onTap: () => Navigator.of(context).pushNamed('/my-courses'),
              ),

            const Spacer(),

            // ── Logout ────────────────────────────────────────────────────────
            _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              label: 'log out',
              onTap: () => _logout(context, ref),
              iconColor: Colors.black54,
              labelColor: Colors.black54,
            ),

            // ── Footer ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Text('v1.0.0', style: GoogleFonts.lemon(fontSize: 12, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black26)),
            ),
          ],
        ),
      ),
    );
  }
}
