import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'hall_info_screen.dart';
import 'booking_screen.dart';
import '../widgets/u_space_nav_bar.dart';
import '../widgets/u_space_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../models/hall.dart';
import '../models/course.dart';
import '../models/reservation.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _freeOnly = false;
  String _query = '';
  static const int _sampleLimit = 3;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isActiveNow(Reservation r) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    // Prisma returns ISO strings like 2026-06-08T00:00:00.000Z, so we check if it starts with today
    if (!r.date.startsWith(today) || r.status != 'BOOKED') return false;
    final startParts = r.startTime.split(':');
    final endParts = r.endTime.split(':');
    if (startParts.length < 2 || endParts.length < 2) return false;
    final currentMin = now.hour * 60 + now.minute;
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return currentMin >= startMin && currentMin <= endMin;
  }

  Widget _occupiedCard(String subject, Hall hall, {String? lecturerName, String? delegateName}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HallInfoScreen(
          hall: hall,
          courseName: subject,
          lecturerName: lecturerName,
          delegateName: delegateName,
        )),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0000FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: GoogleFonts.lemon(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hall.name,
              style: GoogleFonts.lemon(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _freeCard(Hall hall) {
    final role = ref.read(authStateProvider).value?.role ?? 'STUDENT';
    final canBook = role != 'STUDENT';
    return GestureDetector(
      onTap: () {
        if (!canBook) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Only class delegates can book halls'),
          ));
          return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(hall: hall)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'available',
                    style: GoogleFonts.lemon(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hall.name,
                    style: GoogleFonts.lemon(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (!canBook)
              const Icon(Icons.lock_outline_rounded, color: Colors.black26, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final hallsAsync = ref.watch(hallsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final reservationsAsync = ref.watch(reservationsProvider);

    if (reservationsAsync.isLoading ||
        hallsAsync.isLoading ||
        coursesAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFFF5100)),
        ),
      );
    }

    if (reservationsAsync.hasError ||
        hallsAsync.hasError ||
        coursesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Could not load hall data',
          style: GoogleFonts.lemon(
            fontSize: 14,
            color: Colors.red,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final reservations = reservationsAsync.value!;
    final halls = hallsAsync.value!;
    final courses = coursesAsync.value!;

    final active = reservations.where(_isActiveNow).toList();
    final occupiedIds = active.map((r) => r.hallId).toSet();

    final cards = <Widget>[];

    if (!_freeOnly) {
      final occupiedFiltered = active.where((r) {
        if (_query.isEmpty) return true;
        final hall = halls.firstWhere(
          (h) => h.id == r.hallId,
          orElse: () =>
              Hall(id: '', name: '', capacity: 0, features: '', buildingBlock: ''),
        );
        final subject = r.type == 'CLASS' && r.courseId != null
            ? courses
                .firstWhere(
                  (c) => c.id == r.courseId,
                  orElse: () => Course(
                    id: '',
                    code: '',
                    name: '',
                    enrolledCount: 0,
                    lecturerId: '',
                  ),
                )
                .name
            : r.eventName ?? '';
        return hall.name.toLowerCase().contains(_query) ||
            subject.toLowerCase().contains(_query);
      }).take(_sampleLimit);

      for (final r in occupiedFiltered) {
        final hall = halls.firstWhere(
          (h) => h.id == r.hallId,
          orElse: () => Hall(
            id: '',
            name: 'Unknown hall',
            capacity: 0,
            features: '',
            buildingBlock: '',
          ),
        );
        final subject = r.type == 'CLASS' && r.courseId != null
            ? courses
                .firstWhere(
                  (c) => c.id == r.courseId,
                  orElse: () => Course(
                    id: '',
                    code: '',
                    name: 'Unknown course',
                    enrolledCount: 0,
                    lecturerId: '',
                  ),
                )
                .name
            : r.eventName ?? 'Event';
        Course? course;
        if (r.type == 'CLASS' && r.courseId != null) {
          try { course = courses.firstWhere((c) => c.id == r.courseId); } catch (_) {}
        }
        cards.add(_occupiedCard(
          subject, hall,
          lecturerName: course?.lecturerName,
          delegateName: course?.delegateName,
        ));
      }
    }

    final freeFiltered = halls.where((h) {
      if (occupiedIds.contains(h.id)) return false;
      if (_query.isEmpty) return true;
      return h.name.toLowerCase().contains(_query);
    }).take(_sampleLimit);

    for (final h in freeFiltered) {
      cards.add(_freeCard(h));
    }

    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No results found',
          style: GoogleFonts.lemon(
            fontSize: 14,
            color: Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const USpaceDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Bar ───────────────────────────────────────────────
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'search halls or courses..',
                          border: InputBorder.none,
                          hintStyle: GoogleFonts.lemon(
                            fontSize: 16,
                            color: Colors.black45,
                          ),
                        ),
                        style: GoogleFonts.lemon(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.search,
                      color: Color(0xFFFF5100),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Icon(Icons.menu, color: Colors.black, size: 28),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Free Halls Tab ───────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _freeOnly = !_freeOnly),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: _freeOnly ? const Color(0xFF1A1AFF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _freeOnly
                          ? const Color(0xFF1A1AFF)
                          : Colors.black38,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'free halls',
                    style: GoogleFonts.lemon(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _freeOnly ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Results ──────────────────────────────────────────────────
              _buildResults(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
