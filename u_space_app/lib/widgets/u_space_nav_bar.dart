import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class USpaceNavBar extends StatelessWidget {
  const USpaceNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_filled,
            label: 'Home',
            // Pop back to the root instead of pushing /home — preserves the
            // correct home for each role (AdminHomePage, LecturerHomePage, etc.)
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          _NavItem(
            icon: Icons.search,
            label: 'Search',
            onTap: () => Navigator.of(context).pushNamed('/search'),
          ),
          _NavItem(
            icon: Icons.message_outlined,
            label: 'Messages',
            onTap: () => Navigator.of(context).pushNamed('/messages'),
          ),
          _NavItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFF5100), size: 28),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lemon(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
