import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/u_space_nav_bar.dart';
import '../services/api_service.dart';

const _kDayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

class StudentTimetableScreen extends ConsumerStatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  ConsumerState<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends ConsumerState<StudentTimetableScreen> {
  final _api = ApiService();
  bool _isLoading = true;
  List<_Slot> _allSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTimetable();
      final slots = data.map((e) {
        final course = e['course'] as Map<String, dynamic>?;
        final hall = e['hall'] as Map<String, dynamic>?;
        return _Slot(
          courseCode: course?['code'] ?? 'Unknown',
          courseName: course?['name'] ?? 'Unknown Course',
          start: e['start_time'] ?? '',
          end: e['end_time'] ?? '',
          hall: hall?['name'] ?? 'Unknown Hall',
          day: e['day_of_week'] ?? 'Monday',
        );
      }).toList();
      if (mounted) setState(() { _allSlots = slots; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build day → list of slots
    final Map<String, List<_Slot>> schedule = {};
    for (final slot in _allSlots) {
      schedule.putIfAbsent(slot.day, () => []);
      schedule[slot.day]!.add(slot);
    }

    // Sort slots within each day by start time
    for (final day in schedule.keys) {
      schedule[day]!.sort((a, b) => a.start.compareTo(b.start));
    }

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
                        TextSpan(text: 'timetable', style: GoogleFonts.lemon(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5100)),
                ),
              )
            else if (_allSlots.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 60, color: Colors.black12),
                        const SizedBox(height: 16),
                        Text(
                          'No timetable entries found.\nEnsure you have selected your courses in Settings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lemon(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  children: _kDayOrder
                      .where((day) => schedule.containsKey(day))
                      .map((day) {
                    final slots = schedule[day]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          day.toUpperCase(),
                          style: GoogleFonts.lemon(fontSize: 11, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black38, letterSpacing: 1.6),
                        ),
                        const SizedBox(height: 8),
                        ...slots.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1AFF).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1A1AFF).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5100),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.courseName,
                                      style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.courseCode,
                                      style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${s.start} – ${s.end}',
                                    style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.hall,
                                    style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black45),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}

class _Slot {
  final String courseCode;
  final String courseName;
  final String start;
  final String end;
  final String hall;
  final String day;
  const _Slot({required this.courseCode, required this.courseName, required this.start, required this.end, required this.hall, required this.day});
}
