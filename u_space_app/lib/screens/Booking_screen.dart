import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'identifier_screen.dart';
import '../widgets/u_space_nav_bar.dart';
import '../models/hall.dart';
import '../models/course.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reservation_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Hall? hall;

  const BookingScreen({super.key, this.hall});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _bookingKeyController = TextEditingController();

  bool _showHallError = false;
  bool _showCourseError = false;
  bool _showMotifError = false;

  Hall? _selectedHall;
  Course? _selectedCourse;

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _adminEndTime; // only used by admin for custom duration

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _addHours(TimeOfDay t, int h) {
    final totalMin = t.hour * 60 + t.minute + h * 60;
    return TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
  }

  @override
  void initState() {
    super.initState();
    _selectedHall = widget.hall;
  }

  @override
  void dispose() {
    _motifController.dispose();
    _bookingKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime(bool isAdmin) async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked == null) return;
    setState(() {
      _startTime = picked;
      _adminEndTime = null; // reset end time when start changes
    });
  }

  Future<void> _pickEndTime() async {
    final initial = _adminEndTime ?? _addHours(_startTime, 3);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() => _adminEndTime = picked);
  }

  Future<void> _tryBook(String role, {bool force = false}) async {
    final hasCourse = _selectedCourse != null;
    final hasMotif = _motifController.text.trim().isNotEmpty;
    final hasHall = _selectedHall != null;
    final hasBookingKey = _bookingKeyController.text.trim().isNotEmpty;
    final needsKey = role != 'ADMIN';

    setState(() {
      _showHallError = !hasHall;
      _showCourseError = !hasMotif && !hasCourse;
      _showMotifError = !hasCourse && !hasMotif;
    });

    if (_showHallError || _showCourseError || _showMotifError) return;

    if (needsKey && !hasBookingKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking key / PIN is required', style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userState = ref.read(authStateProvider);
    if (userState.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    final isAdmin = role == 'ADMIN';
    final endTime = isAdmin ? (_adminEndTime ?? _addHours(_startTime, 3)) : _addHours(_startTime, 3);

    try {
      await ref.read(reservationProvider.notifier).bookHall({
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'start_time': _fmt(_startTime),
        'end_time': _fmt(endTime),
        'hall_id': _selectedHall!.id,
        'course_id': _selectedCourse?.id,
        'reserved_by': userState.value!.id,
        'type': hasMotif ? 'EVENT' : 'CLASS',
        'event_name': hasMotif ? _motifController.text.trim() : null,
        'force_booking': force,
        if (hasBookingKey) 'booking_key': _bookingKeyController.text.trim(),
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IdentifierScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is CapacityWarningException) {
        _showCapacityWarningDialog(e, role);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  void _showCapacityWarningDialog(CapacityWarningException e, String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Capacity Warning', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.message, style: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87)),
              const SizedBox(height: 16),
              if (e.alternatives.isNotEmpty) ...[
                Text('Available Alternatives:', style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: e.alternatives.length,
                    itemBuilder: (context, index) {
                      final hall = e.alternatives[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(hall.name, style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Text('Capacity: ${hall.capacity}', style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1AFF)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedHall = hall);
                          },
                          child: Text('Select', style: GoogleFonts.lemon(color: Colors.white, fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.lemon(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5100)),
            onPressed: () {
              Navigator.pop(ctx);
              _tryBook(role, force: true);
            },
            child: Text('Book Anyway', style: GoogleFonts.lemon(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.role ?? 'STUDENT';

    final hallsAsync = ref.watch(hallsProvider);
    final coursesAsync = ref.watch(coursesProvider);

    final blackTextStyle = GoogleFonts.lemon(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

    final orangeTextStyle = GoogleFonts.lemon(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: const Color(0xFFFF5100),
    );

    String roleLabel;
    switch (role) {
      case 'ADMIN': roleLabel = 'Admin'; break;
      case 'LECTURER': roleLabel = 'Lecturer'; break;
      case 'PREFECT': roleLabel = 'Delegate'; break;
      default: roleLabel = 'Student';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back Button ──────────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.undo, color: Color(0xFFFF5100), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'back',
                      style: GoogleFonts.lemon(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ── Hall Selector ─────────────────────────────────────────────
              Text('name:', style: blackTextStyle),
              const SizedBox(height: 10),

              hallsAsync.when(
                loading: () => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5100),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'loading halls...',
                        style: GoogleFonts.lemon(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (e, _) => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Text(
                    'Failed to load halls',
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ),
                data: (halls) {
                  // If a hall was pre-selected but isn't in the list, match it
                  if (_selectedHall != null && !halls.any((h) => h.id == _selectedHall!.id)) {
                    _selectedHall = null;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showHallError)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 5),
                          child: Text(
                            'Please select a hall',
                            style: GoogleFonts.lemon(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(10),
                          border: _showHallError ? Border.all(color: Colors.red, width: 2) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedHall?.id,
                            isExpanded: true,
                            hint: Text(
                              'select a hall',
                              style: GoogleFonts.lemon(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                            style: GoogleFonts.lemon(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF5100)),
                            dropdownColor: Colors.white,
                            items: halls.map((h) => DropdownMenuItem<String>(
                              value: h.id,
                              child: Text(
                                '${h.name}  (${h.capacity} seats)',
                                style: GoogleFonts.lemon(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black,
                                ),
                              ),
                            )).toList(),
                            onChanged: (id) {
                              setState(() {
                                _selectedHall = halls.firstWhere((h) => h.id == id);
                                _showHallError = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Show selected hall name in orange (like the original)
              if (_selectedHall != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(_selectedHall!.name, style: orangeTextStyle),
                ),

              const SizedBox(height: 15),

              // ── Course Selector ───────────────────────────────────────────
              coursesAsync.when(
                loading: () => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF5100),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'loading courses...',
                        style: GoogleFonts.lemon(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (e, _) => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Text(
                    'Failed to load courses',
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                    ),
                  ),
                ),
                data: (courses) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showCourseError)
                        Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 5),
                          child: Text(
                            'Please select a course or enter a motif',
                            style: GoogleFonts.lemon(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      // Course name dropdown
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(10),
                          border: _showCourseError ? Border.all(color: Colors.red, width: 2) : null,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCourse?.id,
                            isExpanded: true,
                            hint: Text(
                              'select course name',
                              style: GoogleFonts.lemon(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                            style: GoogleFonts.lemon(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF5100)),
                            dropdownColor: Colors.white,
                            items: courses.map((c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(
                                c.name,
                                style: GoogleFonts.lemon(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (id) {
                              setState(() {
                                _selectedCourse = courses.firstWhere((c) => c.id == id);
                                _showCourseError = false;
                              });
                            },
                          ),
                        ),
                      ),

                      // Course code — auto-populated, read-only
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCourse != null
                                    ? _selectedCourse!.code
                                    : 'course code (auto)',
                                style: GoogleFonts.lemon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: _selectedCourse != null
                                      ? Colors.black
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            if (_selectedCourse != null)
                              const Icon(Icons.check_circle, color: Color(0xFFFF5100), size: 20),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Or any other motif ───────────────────────────────────────
              Center(
                child: Text(
                  'Or',
                  style: GoogleFonts.lemon(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF5100),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'any other motif',
                  style: GoogleFonts.lemon(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Motif text field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showMotifError)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 5),
                      child: Text(
                        'Please select a course or enter a motif',
                        style: GoogleFonts.lemon(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(10),
                      border: _showMotifError ? Border.all(color: Colors.red, width: 2) : null,
                    ),
                    child: TextField(
                      controller: _motifController,
                      decoration: InputDecoration(
                        hintText: 'enter here',
                        hintStyle: GoogleFonts.lemon(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      style: GoogleFonts.lemon(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ── Booking Key / PIN ────────────────────────────────────────
              if (role != 'ADMIN') ...[
                Text('booking key:', style: GoogleFonts.lemon(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _bookingKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'enter your booking key / PIN',
                      hintStyle: GoogleFonts.lemon(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: const Icon(Icons.key, color: Color(0xFFFF5100), size: 22),
                    ),
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 15),
                  child: Text(
                    'First time? The key you enter will be saved to your profile.',
                    style: GoogleFonts.lemon(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // ── Time Picker ──────────────────────────────────────────────
              Text('when?', style: GoogleFonts.lemon(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Start time
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickStartTime(role == 'ADMIN'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFF1A1AFF), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Text('start', style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(_fmt(_startTime), style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // End time
                  Expanded(
                    child: GestureDetector(
                      onTap: role == 'ADMIN' ? _pickEndTime : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: role == 'ADMIN' ? const Color(0xFF1A1AFF) : const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text('end${role == 'ADMIN' ? ' (tap)' : ' (+3h)'}', style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: role == 'ADMIN' ? Colors.white70 : Colors.black45)),
                            const SizedBox(height: 4),
                            Text(
                              _fmt(role == 'ADMIN' ? (_adminEndTime ?? _addHours(_startTime, 3)) : _addHours(_startTime, 3)),
                              style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: role == 'ADMIN' ? Colors.white : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── I am? (shows only current user's role) ───────────────────
              Row(
                children: [
                  Text('I ', style: GoogleFonts.lemon(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                  Text('am?', style: GoogleFonts.lemon(fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => _tryBook(role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      roleLabel,
                      style: GoogleFonts.lemon(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
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
