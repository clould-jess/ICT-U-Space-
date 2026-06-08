import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/u_space_nav_bar.dart';
import 'login_screen.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;

  // Locally editable fields (supplemental data not in DB)
  String _age = '';
  String _selectedAvatar = 'assets_language/glasses.svg';

  final List<String> _avatarOptions = [
    'assets_language/glasses.svg',
    'assets_language/bro.svg',
    'assets_language/pana graduate.svg',
    'assets_language/cuate working.svg',
    'assets_splash/group_of_students.svg',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _age = prefs.getString('profile_age') ?? '';
      _selectedAvatar = prefs.getString('profile_avatar') ?? 'assets_language/glasses.svg';
      _isLoading = false;
    });
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_age', _age);
    await prefs.setString('profile_avatar', _selectedAvatar);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'profile updated!',
            style: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          backgroundColor: const Color(0xFFFF5100),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _roleDisplayLabel(String role) {
    switch (role) {
      case 'LECTURER':
        return 'Lecturer';
      case 'ADMIN':
        return 'Administrator';
      case 'PREFECT':
        return 'Delegate / Prefect';
      default:
        return 'Student';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'LECTURER':
        return const Color(0xFF1A1AFF);
      case 'ADMIN':
        return const Color(0xFFFF5100);
      case 'PREFECT':
        return const Color(0xFFAA00AA);
      default:
        return const Color(0xFF00AA44);
    }
  }

  void _showEditDialog(User? user) {
    final ageController = TextEditingController(text: _age);
    String tempAvatar = _selectedAvatar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'edit ',
                          style: GoogleFonts.lemon(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'profile',
                          style: GoogleFonts.lemon(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFFF5100),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Avatar selection
                    Text(
                      'choose avatar:',
                      style: GoogleFonts.lemon(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _avatarOptions.length,
                        itemBuilder: (context, index) {
                          final path = _avatarOptions[index];
                          final isSelected = tempAvatar == path;
                          return GestureDetector(
                            onTap: () => setModalState(() => tempAvatar = path),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFF5100)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFFE0E0E0),
                                radius: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: SvgPicture.asset(path),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Age field (only supplemental data editable here)
                    _buildInputField('age', ageController,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 8),

                    // Read-only info note
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 20),
                      child: Text(
                        'Name, matricule, email and role are managed by your account.',
                        style: GoogleFonts.lemon(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.black38,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _age = ageController.text.trim();
                            _selectedAvatar = tempAvatar;
                          });
                          _saveLocalData();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5100),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'save changes',
                          style: GoogleFonts.lemon(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lemon(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF0F0F0) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: GoogleFonts.lemon(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: readOnly ? Colors.black45 : Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF5100), size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lemon(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.lemon(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: valueColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final User? user = authState.value;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5100)),
          ),
        ),
      );
    }

    final role = user?.role ?? 'STUDENT';
    final roleLabel = _roleDisplayLabel(role);
    final roleColor = _roleColor(role);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'your ',
                          style: GoogleFonts.lemon(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: 'profile',
                          style: GoogleFonts.lemon(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFFF5100),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.black87, size: 26),
                    tooltip: 'Log out',
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ── Avatar ──
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5100), Color(0xFF0011FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5100).withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: SvgPicture.asset(
                            _selectedAvatar,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEditDialog(user),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5100),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Role badge under avatar
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor, width: 1.5),
                  ),
                  child: Text(
                    roleLabel,
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: roleColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ── Info Cards ──
              _buildInfoCard(
                'full name',
                user?.name ?? 'not logged in',
                Icons.person,
              ),
              if (_age.isNotEmpty)
                _buildInfoCard('age', '$_age years old', Icons.cake),
              _buildInfoCard(
                'matricule no.',
                user?.matricule ?? '—',
                Icons.assignment_ind,
                valueColor: roleColor,
              ),
              _buildInfoCard(
                'email address',
                user?.email ?? 'not logged in',
                Icons.email,
              ),
              _buildInfoCard(
                'role',
                roleLabel,
                Icons.school,
                valueColor: roleColor,
              ),
              if (user?.academicLevel != null)
                _buildInfoCard(
                  'academic level',
                  user!.academicLevel!,
                  Icons.grade,
                ),
              if (user?.semester != null)
                _buildInfoCard(
                  'semester',
                  user!.semester!,
                  Icons.calendar_today,
                ),

              const SizedBox(height: 20),

              // ── Edit button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDialog(user),
                  icon: const Icon(Icons.edit_note, size: 28, color: Colors.white),
                  label: Text(
                    'edit details',
                    style: GoogleFonts.lemon(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5100),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
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
