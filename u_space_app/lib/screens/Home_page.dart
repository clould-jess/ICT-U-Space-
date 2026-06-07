import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'hall_info_screen.dart';
import 'search_screen.dart';
import 'booking_screen.dart';
import '../widgets/u_space_nav_bar.dart';
import '../widgets/u_space_drawer.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../models/hall.dart';
import '../models/course.dart';
import '../models/reservation.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const int _sampleLimit = 3;

  bool _isActiveNow(Reservation r) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    if (r.date != today || r.status != 'BOOKED') return false;
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
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1AFF),
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
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildHallSections() {
    final hallsAsync = ref.watch(hallsProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final reservationsAsync = ref.watch(reservationsProvider);

    final sectionLabel = GoogleFonts.lemon(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );

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
    final occupiedSample = active.take(_sampleLimit).toList();
    final freeSample = halls
        .where((h) => !occupiedIds.contains(h.id))
        .take(_sampleLimit)
        .toList();

    final timeLabel = active.isNotEmpty
        ? '${active.first.startTime}-${active.first.endTime}'
        : DateFormat('HH:mm').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('occupied halls now..', style: sectionLabel),
        const SizedBox(height: 10),
        Text(
          timeLabel,
          style: GoogleFonts.lemon(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: const Color(0xFFFF5100),
          ),
        ),
        const SizedBox(height: 12),
        if (occupiedSample.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No halls occupied right now',
              style: GoogleFonts.lemon(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...occupiedSample.map((r) {
            final hall = halls.firstWhere(
              (h) => h.id == r.hallId,
              orElse: () => Hall(id: '', name: 'Unknown hall', capacity: 0, features: '', buildingBlock: ''),
            );
            Course? course;
            if (r.type == 'CLASS' && r.courseId != null) {
              try {
                course = courses.firstWhere((c) => c.id == r.courseId);
              } catch (_) {}
            }
            final subject = course?.name ?? r.eventName ?? 'Event';
            return _occupiedCard(
              subject,
              hall,
              lecturerName: course?.lecturerName,
              delegateName: course?.delegateName,
            );
          }),
        const SizedBox(height: 24),
        Text('Free halls now..', style: sectionLabel),
        const SizedBox(height: 10),
        if (freeSample.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No free halls right now',
              style: GoogleFonts.lemon(
                fontSize: 14,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...freeSample.map((h) => _freeCard(h)),
      ],
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
              // ── Top Bar ──────────────────────────────────────────────────
              Builder(builder: (context) {
                final user = ref.watch(authStateProvider).value;
                final firstName = (user?.name ?? 'there').split(' ').first;
                return Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hi ',
                              style: GoogleFonts.lemon(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: '$firstName!',
                              style: GoogleFonts.lemon(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFFFF5100),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                      icon: const Icon(Icons.search, color: Colors.black, size: 28),
                    ),
                    IconButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 20),

              _buildHallSections(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
