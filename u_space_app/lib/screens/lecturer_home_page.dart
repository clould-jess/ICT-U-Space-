import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/course.dart';
import '../models/reservation.dart';
import '../models/hall.dart';
import '../providers/auth_provider.dart';
import '../widgets/u_space_nav_bar.dart';
import '../widgets/u_space_drawer.dart';
import 'search_screen.dart';

class LecturerHomePage extends ConsumerStatefulWidget {
  const LecturerHomePage({super.key});

  @override
  ConsumerState<LecturerHomePage> createState() => _LecturerHomePageState();
}

class _LecturerHomePageState extends ConsumerState<LecturerHomePage> {
  final _api = ApiService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Course> _courses = [];
  List<Reservation> _reservations = [];
  List<Hall> _halls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getCourses(),
        _api.getReservations(),
        _api.getHalls(),
      ]);
      if (mounted) {
        setState(() {
          _courses = results[0] as List<Course>;
          _reservations = results[1] as List<Reservation>;
          _halls = results[2] as List<Hall>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load data');
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

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Book Hall Dialog ───────────────────────────────────────────────────────

  void _showBookingSheet(Course course) {
    if (_halls.isEmpty) {
      _showError('No halls available');
      return;
    }

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    Hall selectedHall = _halls.first;
    final bookingKeyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 40, left: 24, right: 24, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: 'book ', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                    TextSpan(text: 'hall', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                  ]),
                ),
                Text(course.name, style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 24),

                // Hall selector
                Text('hall', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Hall>(
                      value: selectedHall,
                      isExpanded: true,
                      style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                      items: _halls.map((h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.name}  (${h.capacity} seats)', style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600)),
                      )).toList(),
                      onChanged: (h) => setModal(() => selectedHall = h!),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Date
                Text('date', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5100))),
                        child: child!,
                      ),
                    );
                    if (d != null) setModal(() => selectedDate = d);
                  },
                  child: _pickerRow(Icons.calendar_today_outlined, '${selectedDate.year}-${_pad(selectedDate.month)}-${_pad(selectedDate.day)}'),
                ),

                const SizedBox(height: 12),

                // Start time
                Text('start time', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: startTime,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5100))),
                        child: child!,
                      ),
                    );
                    if (t != null) setModal(() => startTime = t);
                  },
                  child: _pickerRow(Icons.access_time_outlined, '${_pad(startTime.hour)}:${_pad(startTime.minute)}'),
                ),

                const SizedBox(height: 12),

                // End time
                Text('end time', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: endTime,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFFF5100))),
                        child: child!,
                      ),
                    );
                    if (t != null) setModal(() => endTime = t);
                  },
                  child: _pickerRow(Icons.access_time_filled_outlined, '${_pad(endTime.hour)}:${_pad(endTime.minute)}'),
                ),
                const SizedBox(height: 16),

                // Booking Key
                Text('booking key / PIN', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: bookingKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'enter your key',
                      hintStyle: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black38),
                      border: InputBorder.none,
                      suffixIcon: const Icon(Icons.key, color: Color(0xFFFF5100), size: 20),
                    ),
                    style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    'First time? It will be saved to your profile.',
                    style: GoogleFonts.lemon(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black38),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final key = bookingKeyController.text.trim();
                      if (key.isEmpty) {
                        _showError('Booking key is required');
                        return;
                      }
                      await _performBooking(course, selectedHall, selectedDate, startTime, endTime, key);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1AFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('confirm booking', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerRow(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF5100)),
          const SizedBox(width: 12),
          Text(value, style: GoogleFonts.lemon(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
        ],
      ),
    );
  }

  Future<void> _performBooking(Course course, Hall hall, DateTime date, TimeOfDay start, TimeOfDay end, String key, {bool force = false}) async {
    try {
      await _api.createReservation({
        'hall_id': hall.id,
        'course_id': course.id,
        'date': '${date.year}-${_pad(date.month)}-${_pad(date.day)}',
        'start_time': '${_pad(start.hour)}:${_pad(start.minute)}',
        'end_time': '${_pad(end.hour)}:${_pad(end.minute)}',
        'type': 'CLASS',
        'booking_key': key,
        'force_booking': force,
      });
      if (!mounted) return;
      Navigator.pop(context); // close bottom sheet
      _showSuccess('Hall booked for ${course.code}!');
      await _fetchData();
    } catch (e) {
      if (e is CapacityWarningException) {
        _showCapacityWarningDialog(e, course, hall, date, start, end, key);
      } else {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showCapacityWarningDialog(CapacityWarningException e, Course course, Hall currentHall, DateTime date, TimeOfDay start, TimeOfDay end, String key) {
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
                      final altHall = e.alternatives[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(altHall.name, style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600)),
                        subtitle: Text('Capacity: ${altHall.capacity}', style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1AFF)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _performBooking(course, altHall, date, start, end, key);
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
              _performBooking(course, currentHall, date, start, end, key, force: true);
            },
            child: Text('Book Anyway', style: GoogleFonts.lemon(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Cancel Reservation ─────────────────────────────────────────────────────

  Future<void> _cancelReservation(Reservation res) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Booking?', style: GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        content: Text(
          '${res.date}  ${res.startTime} – ${res.endTime}',
          style: GoogleFonts.lemon(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('keep', style: GoogleFonts.lemon(fontStyle: FontStyle.italic, color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('cancel it', style: GoogleFonts.lemon(fontStyle: FontStyle.italic, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteReservation(res.id);
        _showSuccess('Reservation cancelled.');
        await _fetchData();
      } catch (e) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final firstName = (user?.name ?? 'Lecturer').split(' ').first;
    final labelStyle = GoogleFonts.lemon(fontSize: 18, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const USpaceDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5100)))
            : RefreshIndicator(
                color: const Color(0xFFFF5100),
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ──────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(children: [
                                TextSpan(text: 'Hi, ', style: GoogleFonts.lemon(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                                TextSpan(text: '$firstName!', style: GoogleFonts.lemon(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                              ]),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                            icon: const Icon(Icons.search, color: Colors.black, size: 28),
                          ),
                          IconButton(
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                          ),
                        ],
                      ),

                      if (user?.matricule != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          child: Text(user!.matricule!, style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black38)),
                        ),

                      const SizedBox(height: 24),

                      // ── My Courses ───────────────────────────────────────
                      Row(
                        children: [
                          Text('my courses..', style: labelStyle),
                          const Spacer(),
                          Text('${_courses.length} course${_courses.length == 1 ? '' : 's'}', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black38)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_courses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'No courses assigned yet.\nAsk your administrator to assign courses to your account.',
                            style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      ..._courses.map((c) => _buildCourseCard(c)),

                      const SizedBox(height: 28),

                      // ── My Reservations ──────────────────────────────────
                      Row(
                        children: [
                          Text('my bookings..', style: labelStyle),
                          const Spacer(),
                          Text('${_reservations.length}', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black38)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (_reservations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'No bookings yet. Tap "book hall" on any course to reserve a room.',
                            style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      ..._reservations.map((r) => _buildReservationCard(r)),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF1A1AFF), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name, style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.white)),
                Text(course.code, style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white70)),
                Text('${course.enrolledCount} enrolled', style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white54)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showBookingSheet(course),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Color(0xFF1A1AFF), size: 16),
                  const SizedBox(width: 4),
                  Text('book hall', style: GoogleFonts.lemon(fontSize: 12, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: const Color(0xFF1A1AFF))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation res) {
    final statusColor = res.status == 'CONFIRMED' ? const Color(0xFF00AA44) : const Color(0xFFFF5100);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res.date, style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black)),
                Text('${res.startTime} – ${res.endTime}', style: GoogleFonts.lemon(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(res.status, style: GoogleFonts.lemon(fontSize: 11, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: statusColor)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _cancelReservation(res),
            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 22),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
