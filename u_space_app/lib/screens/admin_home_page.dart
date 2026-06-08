import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/hall.dart';
import '../models/course.dart';
import '../providers/auth_provider.dart';
import '../widgets/u_space_drawer.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<User> _users = [];
  List<Hall> _halls = [];
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getUsers(),
        _api.getHalls(),
        _api.getCourses(),
      ]);
      if (mounted) {
        setState(() {
          _users = results[0] as List<User>;
          _halls = results[1] as List<Hall>;
          _courses = results[2] as List<Course>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load data: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
      backgroundColor: const Color(0xFF00AA44),
    ));
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'LECTURER': return const Color(0xFF1A1AFF);
      case 'ADMIN': return const Color(0xFFFF5100);
      case 'PREFECT': return const Color(0xFFAA00AA);
      default: return const Color(0xFF00AA44);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          ),
        ),
      ],
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
  );

  Widget _sheetTitle(String plain, String colored) => RichText(
    text: TextSpan(children: [
      TextSpan(text: '$plain ', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
      TextSpan(text: colored, style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
    ]),
  );

  // ── Users ──────────────────────────────────────────────────────────────────

  void _showChangeRoleSheet(User user) {
    String selectedRole = user.role;
    const roles = ['STUDENT', 'PREFECT', 'LECTURER'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'change role: ', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                TextSpan(text: user.name, style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
              ])),
              const SizedBox(height: 20),
              ...roles.map((role) {
                final color = _roleColor(role);
                return GestureDetector(
                  onTap: () => setModal(() => selectedRole = role),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: selectedRole == role ? color.withValues(alpha: 0.12) : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(12),
                      border: selectedRole == role ? Border.all(color: color, width: 2) : null,
                    ),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(role, style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                        const Spacer(),
                        if (selectedRole == role) Icon(Icons.check_circle, color: color),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRole == user.role
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await _api.updateUserRole(user.id, selectedRole);
                            _showSuccess('${user.name} is now $selectedRole');
                            await _fetchData();
                          } catch (e) {
                            _showError(e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5100),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text('save', style: GoogleFonts.lemon(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Halls ──────────────────────────────────────────────────────────────────

  void _showCreateHallSheet() {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final featuresCtrl = TextEditingController();
    final blockCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 40, left: 24, right: 24, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              _sheetTitle('create', 'hall'),
              const SizedBox(height: 20),
              _field('hall name', nameCtrl),
              const SizedBox(height: 12),
              _field('capacity (seats)', capacityCtrl, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field('features (e.g. projector, AC)', featuresCtrl),
              const SizedBox(height: 12),
              _field('building block (e.g. Block A)', blockCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || capacityCtrl.text.trim().isEmpty) {
                      _showError('Name and capacity are required');
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await _api.createHall(
                        name: nameCtrl.text.trim(),
                        capacity: int.tryParse(capacityCtrl.text.trim()) ?? 0,
                        features: featuresCtrl.text.trim(),
                        buildingBlock: blockCtrl.text.trim(),
                      );
                      _showSuccess('Hall created!');
                      await _fetchData();
                    } catch (e) {
                      _showError(e.toString().replaceFirst('Exception: ', ''));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1AFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('create hall', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateCapacityDialog(Hall hall) {
    final ctrl = TextEditingController(text: hall.capacity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Capacity', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hall.name, style: GoogleFonts.lemon(fontSize: 16, fontStyle: FontStyle.italic, color: const Color(0xFF1A1AFF))),
            const SizedBox(height: 16),
            _field('new capacity', ctrl, keyboard: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel', style: GoogleFonts.lemon(fontStyle: FontStyle.italic, color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.updateHallCapacity(hall.id, int.tryParse(ctrl.text.trim()) ?? hall.capacity);
                _showSuccess('Capacity updated!');
                await _fetchData();
              } catch (e) {
                _showError(e.toString().replaceFirst('Exception: ', ''));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1AFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('save', style: GoogleFonts.lemon(fontStyle: FontStyle.italic, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Courses ────────────────────────────────────────────────────────────────

  void _showCreateCourseSheet() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 40, left: 24, right: 24, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              _sheetTitle('create', 'course'),
              const SizedBox(height: 8),
              Text(
                'Enrollment count auto-updates when students choose courses in their settings.',
                style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38),
              ),
              const SizedBox(height: 16),
              _field('course code (e.g. CS101)', codeCtrl),
              const SizedBox(height: 12),
              _field('course name', nameCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                      _showError('Code and name are required');
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await _api.createCourse(
                        code: codeCtrl.text.trim().toUpperCase(),
                        name: nameCtrl.text.trim(),
                        enrolledCount: 0,
                      );
                      _showSuccess('Course created!');
                      await _fetchData();
                    } catch (e) {
                      _showError(e.toString().replaceFirst('Exception: ', ''));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5100),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('create course', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseOptions(Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            Text(course.name, style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
            Text('${course.code}  •  ${course.enrolledCount} students', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
            const SizedBox(height: 20),
            _optionTile(Icons.person_add_outlined, 'assign lecturer', const Color(0xFF1A1AFF), () {
              Navigator.pop(ctx);
              _showAssignPersonnelSheet(course, isLecturer: true);
            }),
            _optionTile(Icons.group_add_outlined, 'assign delegate', const Color(0xFFAA00AA), () {
              Navigator.pop(ctx);
              _showAssignPersonnelSheet(course, isLecturer: false);
            }),
            _optionTile(Icons.delete_outline_rounded, 'delete course', Colors.red, () async {
              Navigator.pop(ctx);
              final confirm = await _confirmDelete(course.name);
              if (confirm == true) {
                try {
                  await _api.deleteCourse(course.id);
                  _showSuccess('Course deleted.');
                  await _fetchData();
                } catch (e) {
                  _showError(e.toString().replaceFirst('Exception: ', ''));
                }
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: color)),
          ],
        ),
      ),
    );
  }

  void _showAssignPersonnelSheet(Course course, {required bool isLecturer}) {
    final eligible = isLecturer
        ? _users.where((u) => u.role == 'LECTURER').toList()
        : _users.where((u) => u.role == 'STUDENT' || u.role == 'PREFECT').toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        expand: false,
        builder: (ctx, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'assign ', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                TextSpan(text: isLecturer ? 'lecturer' : 'delegate', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
              ])),
              Text(course.name, style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
              const SizedBox(height: 16),
              if (eligible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isLecturer
                        ? 'No lecturers registered yet.\nAsk a lecturer to sign up first.'
                        : 'No students/prefects found.',
                    style: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: eligible.length,
                  itemBuilder: (ctx, i) {
                    final u = eligible[i];
                    final isCurrent = isLecturer ? u.id == course.lecturerId : u.id == course.delegateId;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await _api.assignCoursePersonnel(
                            course.id,
                            lecturerId: isLecturer ? u.id : null,
                            delegateId: !isLecturer ? u.id : null,
                          );
                          _showSuccess('${u.name} assigned!');
                          await _fetchData();
                        } catch (e) {
                          _showError(e.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFFF5100).withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrent ? Border.all(color: const Color(0xFFFF5100), width: 1.5) : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                                  Text(u.matricule ?? u.email, style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                                ],
                              ),
                            ),
                            if (isCurrent) const Icon(Icons.check_circle, color: Color(0xFFFF5100), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String name) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete?', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      content: Text(
        'This will permanently delete "$name" along with its timetable entries and reservations.',
        style: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('cancel', style: GoogleFonts.lemon(fontStyle: FontStyle.italic, color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('delete', style: GoogleFonts.lemon(fontStyle: FontStyle.italic, color: Colors.white)),
        ),
      ],
    ),
  );

  // ── Tabs ───────────────────────────────────────────────────────────────────

  Widget _userCard(User u) {
    final color = _roleColor(u.role);
    final courses = u.role == 'LECTURER'
        ? u.coursesTaught
        : u.role == 'PREFECT'
            ? u.coursesDelegated
            : u.enrolledIn;
    return GestureDetector(
      onTap: u.role == 'ADMIN' ? null : () => _showChangeRoleSheet(u),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                      Text(u.email, style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                      if (u.matricule != null)
                        Text(u.matricule!, style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(u.role, style: GoogleFonts.lemon(fontSize: 10, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: color)),
                ),
                if (u.role != 'ADMIN') ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 16, color: Colors.black38),
                ],
              ],
            ),
            if (courses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: courses.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c.code, style: GoogleFonts.lemon(fontSize: 10, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: color)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleSection(String title, List<User> users, Color color) {
    if (users.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 4, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text('$title (${users.length})', style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color)),
          ]),
        ),
        ...users.map(_userCard),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) return Center(child: Text('No users found', style: GoogleFonts.lemon(color: Colors.grey)));
    final admins     = _users.where((u) => u.role == 'ADMIN').toList();
    final lecturers  = _users.where((u) => u.role == 'LECTURER').toList();
    final prefects   = _users.where((u) => u.role == 'PREFECT').toList();
    final students   = _users.where((u) => u.role == 'STUDENT').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roleSection('Admins',    admins,    const Color(0xFFFF5100)),
          _roleSection('Lecturers', lecturers, const Color(0xFF1A1AFF)),
          _roleSection('Prefects',  prefects,  const Color(0xFFAA00AA)),
          _roleSection('Students',  students,  const Color(0xFF00AA44)),
        ],
      ),
    );
  }

  Widget _buildHallsTab() {
    if (_halls.isEmpty) return Center(child: Text('No halls found', style: GoogleFonts.lemon(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _halls.length,
      itemBuilder: (_, i) {
        final h = _halls[i];
        return GestureDetector(
          onTap: () => _showUpdateCapacityDialog(h),
          onLongPress: () async {
            final confirm = await _confirmDelete(h.name);
            if (confirm == true) {
              try {
                await _api.deleteHall(h.id);
                _showSuccess('Hall deleted.');
                await _fetchData();
              } catch (e) {
                _showError(e.toString().replaceFirst('Exception: ', ''));
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1A1AFF), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.white)),
                      Text('${h.capacity} seats  •  ${h.buildingBlock}', style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70)),
                      if (h.features.isNotEmpty)
                        Text(h.features, style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white54)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.edit, color: Colors.white70, size: 18),
                    const SizedBox(height: 4),
                    Text('hold to delete', style: GoogleFonts.lemon(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesTab() {
    if (_courses.isEmpty) return Center(child: Text('No courses found', style: GoogleFonts.lemon(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _courses.length,
      itemBuilder: (_, i) {
        final c = _courses[i];
        return GestureDetector(
          onTap: () => _showCourseOptions(c),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5100).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF5100).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                      Text(c.code, style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        c.lecturerName != null ? '${c.lecturerName}' : 'no lecturer assigned',
                        style: GoogleFonts.lemon(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: c.lecturerName != null ? const Color(0xFF1A1AFF) : Colors.grey,
                        ),
                      ),
                      Text('${c.enrolledCount} students', style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.black38, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final adminUser = ref.watch(authStateProvider).value;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const USpaceDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(text: 'Admin ', style: GoogleFonts.lemon(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                            TextSpan(text: 'Dashboard', style: GoogleFonts.lemon(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                          ]),
                        ),
                        if (adminUser != null)
                          Text('Hi, ${adminUser.name}', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black38)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh, color: Colors.black54, size: 24),
                  ),
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                  ),
                ],
              ),
            ),

            // Stats bar
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _statChip('${_users.length}', 'users', const Color(0xFF00AA44)),
                    const SizedBox(width: 8),
                    _statChip('${_halls.length}', 'halls', const Color(0xFF1A1AFF)),
                    const SizedBox(width: 8),
                    _statChip('${_courses.length}', 'courses', const Color(0xFFFF5100)),
                  ],
                ),
              ),

            // ── Tab bar ───────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF5100),
              unselectedLabelColor: Colors.black38,
              indicatorColor: const Color(0xFFFF5100),
              labelStyle: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
              unselectedLabelStyle: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic),
              tabs: const [Tab(text: 'Users'), Tab(text: 'Halls'), Tab(text: 'Courses')],
            ),

            // ── Tab content ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5100)))
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildUsersTab(), _buildHallsTab(), _buildCoursesTab()],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          if (_tabController.index == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _tabController.index == 1 ? _showCreateHallSheet : _showCreateCourseSheet,
            backgroundColor: const Color(0xFFFF5100),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              _tabController.index == 1 ? 'add hall' : 'add course',
              style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color)),
            Text(label, style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: color)),
          ],
        ),
      ),
    );
  }
}
