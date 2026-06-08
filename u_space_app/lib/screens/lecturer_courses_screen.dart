import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../services/api_service.dart';
import '../widgets/u_space_nav_bar.dart';

class LecturerCoursesScreen extends ConsumerStatefulWidget {
  const LecturerCoursesScreen({super.key});

  @override
  ConsumerState<LecturerCoursesScreen> createState() => _LecturerCoursesScreenState();
}

class _LecturerCoursesScreenState extends ConsumerState<LecturerCoursesScreen> {
  final _api = ApiService();
  bool _isBusy = false;

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
      backgroundColor: error ? Colors.red : const Color(0xFF00AA44),
    ));
  }

  Future<void> _claim(String courseId) async {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;
    setState(() => _isBusy = true);
    try {
      await _api.claimCourse(courseId, userId);
      ref.invalidate(coursesProvider);
      if (mounted) _snack('Course claimed!');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _unclaim(String courseId) async {
    setState(() => _isBusy = true);
    try {
      await _api.unclaimCourse(courseId);
      ref.invalidate(coursesProvider);
      if (mounted) _snack('Course released.');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showPrefectPicker(String courseId, String courseName) async {
    setState(() => _isBusy = true);
    Map<String, dynamic>? detail;
    try {
      detail = await _api.getCourseDetail(courseId);
    } catch (e) {
      if (mounted) _snack('Could not load students: $e', error: true);
      setState(() => _isBusy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isBusy = false);

    final students = (detail['students'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (students.isEmpty) {
      _snack('No enrolled students for this course yet.', error: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'pick ', style: GoogleFonts.lemon(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                TextSpan(text: 'delegate', style: GoogleFonts.lemon(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
              ])),
              Text(courseName, style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black45)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    final isPrefect = (detail!['delegate_id'] == s['id']);
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        setState(() => _isBusy = true);
                        try {
                          await _api.assignCoursePersonnel(courseId, delegateId: s['id'] as String);
                          ref.invalidate(coursesProvider);
                          if (mounted) _snack('${s['name']} set as delegate!');
                        } catch (e) {
                          if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
                        } finally {
                          if (mounted) setState(() => _isBusy = false);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isPrefect ? const Color(0xFFAA00AA).withValues(alpha: 0.08) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(12),
                          border: isPrefect ? Border.all(color: const Color(0xFFAA00AA), width: 1.5) : null,
                        ),
                        child: Row(
                          children: [
                            Icon(isPrefect ? Icons.star_rounded : Icons.person_outline, color: isPrefect ? const Color(0xFFAA00AA) : Colors.black38, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'] as String? ?? '', style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                                  if (s['matricule'] != null)
                                    Text(s['matricule'] as String, style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38)),
                                ],
                              ),
                            ),
                            if (isPrefect)
                              Text('current delegate', style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFFAA00AA))),
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final myId = user?.id ?? '';
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFFF5100), size: 28),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'my ', style: GoogleFonts.lemon(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                        TextSpan(text: 'courses', style: GoogleFonts.lemon(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Claim the courses you teach. Two lecturers cannot share a course.',
                style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black38),
              ),
            ),

            if (_isBusy)
              const LinearProgressIndicator(color: Color(0xFFFF5100), backgroundColor: Colors.transparent),

            Expanded(
              child: coursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5100))),
                error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.lemon(color: Colors.red, fontStyle: FontStyle.italic))),
                data: (courses) {
                  final mine = courses.where((c) => c.lecturerId == myId).toList();
                  final available = courses.where((c) => c.lecturerId == null).toList();
                  final taken = courses.where((c) => c.lecturerId != null && c.lecturerId != myId).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    children: [
                      if (mine.isNotEmpty) ...[
                        _sectionLabel('your courses (${mine.length})'),
                        ...mine.map((c) => _courseCard(
                          c.code, c.name,
                          subtitle: c.delegateName != null ? 'delegate: ${c.delegateName}' : 'no delegate yet',
                          subtitleColor: c.delegateName != null ? const Color(0xFFAA00AA) : Colors.black38,
                          borderColor: const Color(0xFFFF5100),
                          actions: [
                            _actionBtn('assign delegate', Icons.star_outline_rounded, const Color(0xFFAA00AA), () => _showPrefectPicker(c.id, c.name)),
                            _actionBtn('release', Icons.remove_circle_outline, Colors.red, () => _unclaim(c.id)),
                          ],
                        )),
                      ],

                      if (available.isNotEmpty) ...[
                        _sectionLabel('available to claim (${available.length})'),
                        ...available.map((c) => _courseCard(
                          c.code, c.name,
                          subtitle: '${c.enrolledCount} students enrolled',
                          actions: [
                            _actionBtn('claim', Icons.add_circle_outline_rounded, const Color(0xFF1A1AFF), () => _claim(c.id)),
                          ],
                        )),
                      ],

                      if (taken.isNotEmpty) ...[
                        _sectionLabel('already assigned (${taken.length})'),
                        ...taken.map((c) => _courseCard(
                          c.code, c.name,
                          subtitle: 'lecturer: ${c.lecturerName ?? 'unknown'}',
                          subtitleColor: Colors.black38,
                          dimmed: true,
                          actions: [],
                        )),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
    child: Text(text.toUpperCase(), style: GoogleFonts.lemon(fontSize: 11, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black38, letterSpacing: 1.4)),
  );

  Widget _courseCard(String code, String name, {
    String? subtitle, Color subtitleColor = Colors.black45,
    Color borderColor = Colors.transparent, bool dimmed = false,
    required List<Widget> actions,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dimmed ? const Color(0xFFF5F5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dimmed ? Colors.black12 : borderColor.withValues(alpha: borderColor == Colors.transparent ? 0 : 0.4), width: 1.5),
        boxShadow: dimmed ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: dimmed ? Colors.black45 : Colors.black)),
                Text(code, style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38)),
              ],
            )),
            if (subtitle != null)
              Text(subtitle, style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: subtitleColor)),
          ]),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: actions.map((a) => Padding(padding: const EdgeInsets.only(right: 8), child: a)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isBusy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.lemon(fontSize: 12, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: color)),
        ]),
      ),
    );
  }
}
