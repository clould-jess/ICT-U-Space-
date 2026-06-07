import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/u_space_nav_bar.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// Departments are now fetched dynamically from the API.


class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _api = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, String> _majorsMap = {};

  // Academic profile
  String _selectedMajor = '';
  int _selectedLevel = 0;    // 1-4, 0 = not set
  int _selectedSemester = 0; // 1-2, 0 = not set

  // Course enrollment
  List<Map<String, dynamic>> _allCourses = [];
  Set<String> _enrolledIds = {};

  // Notification toggles (persisted to SharedPreferences)
  bool _notifBookingConfirmed = true;
  bool _notifBookingReminder = true;
  bool _notifHallAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNotifPrefs();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifBookingConfirmed = prefs.getBool('notif_booking_confirmed') ?? true;
        _notifBookingReminder = prefs.getBool('notif_booking_reminder') ?? true;
        _notifHallAvailable = prefs.getBool('notif_hall_available') ?? false;
      });
    }
  }

  Future<void> _saveNotifPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getUserSettings();
      final user = data['user'] as Map<String, dynamic>?;
      final allCourses = data['allCourses'] as List<dynamic>? ?? [];
      final enrolled = user?['enrolledIn'] as List<dynamic>? ?? [];
      final departments = await _api.getDepartments();

      final levelStr = (user?['academic_level'] ?? '') as String;
      final semStr = (user?['semester'] ?? '') as String;
      setState(() {
        _majorsMap = departments;
        _selectedMajor = (user?['major'] ?? '') as String;
        _selectedLevel = int.tryParse(levelStr) ?? 0;
        _selectedSemester = int.tryParse(semStr) ?? 0;
        _allCourses = allCourses.cast<Map<String, dynamic>>();
        _enrolledIds = enrolled
            .map<String>((c) => (c as Map<String, dynamic>)['id'] as String)
            .toSet();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _api.updateUserSettings(
        academicLevel: _selectedLevel > 0 ? _selectedLevel.toString() : null,
        semester: _selectedSemester > 0 ? _selectedSemester.toString() : null,
        major: _selectedMajor.isNotEmpty ? _selectedMajor : null,
        courseIds: _enrolledIds.toList(),
      );
      if (mounted) {
        ref.read(authStateProvider.notifier).refreshProfile();
        _showSnack('settings saved!', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
      backgroundColor: color,
    ));
  }

  // ── Change Password ──────────────────────────────────────────────────────

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
            left: 24, right: 24, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'change ', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                  TextSpan(text: 'password', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                ])),
                const SizedBox(height: 20),
                _sheetField('current password', currentCtrl, obscure: true),
                const SizedBox(height: 12),
                _sheetField('new password', newCtrl, obscure: true),
                const SizedBox(height: 12),
                _sheetField('confirm new password', confirmCtrl, obscure: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('passwords do not match', style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                      if (newCtrl.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('password must be at least 6 characters', style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                      setModal(() => isSaving = true);
                      try {
                        await _api.changePassword(currentCtrl.text.trim(), newCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) _showSnack('password changed!', Colors.green);
                      } catch (e) {
                        if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
                      } finally {
                        if (ctx.mounted) setModal(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text('save', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Change Email ──────────────────────────────────────────────────────────

  void _showChangeEmailSheet() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
            left: 24, right: 24, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'change ', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                  TextSpan(text: 'email', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                ])),
                const SizedBox(height: 20),
                _sheetField('new email address', emailCtrl),
                const SizedBox(height: 12),
                _sheetField('confirm with password', passCtrl, obscure: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (emailCtrl.text.trim().isEmpty) {
                        _showSnack('please enter new email', Colors.red);
                        return;
                      }
                      setModal(() => isSaving = true);
                      try {
                        final newEmail = await _api.changeEmail(emailCtrl.text.trim(), passCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          _showSnack('email changed to $newEmail!', Colors.green);
                          ref.read(authStateProvider.notifier).refreshProfile();
                        }
                      } catch (e) {
                        if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
                      } finally {
                        if (ctx.mounted) setModal(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text('save', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete Account ────────────────────────────────────────────────────────

  void _showDeleteAccountDialog() {
    final passCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
            left: 24, right: 24, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'delete ', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.red)),
                TextSpan(text: 'account', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
              ])),
              const SizedBox(height: 8),
              Text(
                'This action is permanent and cannot be undone.',
                style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _sheetField('enter your password to confirm', passCtrl, obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setModal(() => isSaving = true);
                    try {
                      await _api.deleteAccount(passCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        await ref.read(authStateProvider.notifier).logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
                    } finally {
                      if (ctx.mounted) setModal(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('delete permanently', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared field widget ───────────────────────────────────────────────────

  Widget _sheetField(String hint, TextEditingController ctrl, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black38),
        ),
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lemon(fontSize: 11, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black38, letterSpacing: 1.6),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    Color? labelColor,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF5100), size: 26),
            const SizedBox(width: 18),
            Expanded(child: Text(label, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: labelColor ?? Colors.black))),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({required IconData icon, required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF5100), size: 26),
          const SizedBox(width: 18),
          Expanded(child: Text(label, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black))),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFFFF5100),
              activeTrackColor: const Color(0xFFFF5100).withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.role ?? 'STUDENT';
    final isAdmin = role == 'ADMIN';
    final isStudent = role == 'STUDENT' || role == 'PREFECT';
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'back_btn_settings',
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.arrow_back, color: Color(0xFFFF5100), size: 50),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5100)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('your ', style: GoogleFonts.lemon(fontSize: 38, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black, height: 1.1)),
                        Text('settings', style: GoogleFonts.lemon(fontSize: 38, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100), height: 1.1)),
                      ],
                    ),
                    Text('manage your preferences below', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black38)),

                    // ── ACADEMIC PROFILE (student/prefect only) ────────────
                    if (isStudent) ...[
                      _sectionHeader('academic profile'),

                      // Major dropdown
                      Text('department / major', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMajor.isNotEmpty ? _selectedMajor : null,
                            isExpanded: true,
                            hint: Text('select department', style: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black38)),
                            style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                            items: _majorsMap.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text('${e.key} — ${e.value}', style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                            )).toList(),
                            onChanged: (v) => setState(() {
                              _selectedMajor = v ?? '';
                              _enrolledIds.clear();
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Level picker
                      Text('year / level', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(4, (i) {
                          final lvl = i + 1;
                          final selected = _selectedLevel == lvl;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedLevel = lvl;
                                _enrolledIds.clear();
                              }),
                              child: Container(
                                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFFF5100) : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Text('L$lvl', style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: selected ? Colors.white : Colors.black54))),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      // Semester picker
                      Text('semester', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Row(
                        children: [1, 2].map((s) {
                          final selected = _selectedSemester == s;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedSemester = s),
                              child: Container(
                                margin: EdgeInsets.only(right: s == 1 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF1A1AFF) : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Text('Semester $s', style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: selected ? Colors.white : Colors.black54))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                    ],

                    // ── MY COURSES (free selection — no filter) ────────────
                    if (isStudent) ...[
                      _sectionHeader('my courses'),
                      Text('select every course you study this semester:', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                      const SizedBox(height: 10),
                      if (_allCourses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                          child: Text('No courses loaded in the system yet.', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                        )
                      else
                        ..._allCourses.map((c) {
                          final id = c['id'] as String;
                          final isEnrolled = _enrolledIds.contains(id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isEnrolled) { _enrolledIds.remove(id); } else { _enrolledIds.add(id); }
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isEnrolled ? const Color(0xFF1A1AFF).withValues(alpha: 0.08) : const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(12),
                                border: isEnrolled ? Border.all(color: const Color(0xFF1A1AFF), width: 1.5) : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(isEnrolled ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isEnrolled ? const Color(0xFF1A1AFF) : Colors.black38, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c['name'] as String? ?? '', style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                                      Text(c['code'] as String? ?? '', style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                                    ],
                                  )),
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1AFF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text('save course selection', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                        ),
                      ),
                    ],

                    // ── NOTIFICATIONS ──────────────────────────────────────
                    _sectionHeader('notifications'),
                    _toggleTile(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'booking confirmed',
                      value: _notifBookingConfirmed,
                      onChanged: (v) {
                        setState(() => _notifBookingConfirmed = v);
                        _saveNotifPref('notif_booking_confirmed', v);
                      },
                    ),
                    _toggleTile(
                      icon: Icons.alarm_outlined,
                      label: 'booking reminder',
                      value: _notifBookingReminder,
                      onChanged: (v) {
                        setState(() => _notifBookingReminder = v);
                        _saveNotifPref('notif_booking_reminder', v);
                      },
                    ),
                    _toggleTile(
                      icon: Icons.door_front_door_outlined,
                      label: 'hall now available',
                      value: _notifHallAvailable,
                      onChanged: (v) {
                        setState(() => _notifHallAvailable = v);
                        _saveNotifPref('notif_hall_available', v);
                      },
                    ),

                    // ── THEME ──────────────────────────────────────────────
                    _sectionHeader('theme'),
                    Row(
                      children: AppTheme.values.map((theme) {
                        final isSelected = currentTheme == theme;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => ref.read(themeProvider.notifier).setTheme(theme),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8, bottom: 10),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF5100) : const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected ? null : Border.all(color: Colors.black12),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                      color: theme.bgColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black26, width: 1.5),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    theme.label,
                                    style: GoogleFonts.lemon(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // ── ACCOUNT ────────────────────────────────────────────
                    _sectionHeader('account'),
                    _settingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'change password',
                      onTap: _showChangePasswordSheet,
                    ),
                    _settingsTile(
                      icon: Icons.email_outlined,
                      label: 'change email',
                      onTap: _showChangeEmailSheet,
                    ),
                    if (!isAdmin)
                      _settingsTile(
                        icon: Icons.person_remove_outlined,
                        label: 'delete account',
                        labelColor: Colors.red.shade600,
                        trailing: Icon(Icons.chevron_right_rounded, color: Colors.red.shade300, size: 22),
                        onTap: _showDeleteAccountDialog,
                      ),

                    // ── ABOUT ──────────────────────────────────────────────
                    _sectionHeader('about'),
                    _settingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'app version',
                      trailing: Text('v1.0.0', style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black38)),
                    ),
                    _settingsTile(icon: Icons.description_outlined, label: 'terms of use'),
                    _settingsTile(icon: Icons.privacy_tip_outlined, label: 'privacy policy'),
                    _settingsTile(icon: Icons.bug_report_outlined, label: 'report a bug'),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
