import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/u_space_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getNotifications();
      if (mounted) setState(() { _notifications = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'BOOKING_CONFIRMED': return Icons.check_circle_outline_rounded;
      case 'BOOKING_REMINDER': return Icons.alarm_outlined;
      case 'HALL_AVAILABLE': return Icons.door_front_door_outlined;
      case 'BOOKING_CANCELLED': return Icons.cancel_outlined;
      case 'COURSE_ASSIGNED': return Icons.school_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'BOOKING_CONFIRMED': return const Color(0xFF00AA44);
      case 'BOOKING_REMINDER': return const Color(0xFFFF9800);
      case 'HALL_AVAILABLE': return const Color(0xFF1A1AFF);
      case 'BOOKING_CANCELLED': return Colors.red;
      case 'COURSE_ASSIGNED': return const Color(0xFFAA00AA);
      default: return const Color(0xFFFF5100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFFF5100), size: 28),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'my ', style: GoogleFonts.lemon(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                        TextSpan(text: 'notifications', style: GoogleFonts.lemon(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                      ]),
                    ),
                  ),
                  IconButton(
                    onPressed: _fetch,
                    icon: const Icon(Icons.refresh, color: Colors.black54, size: 24),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Content ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5100)))
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('no notifications', style: GoogleFonts.lemon(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFFF5100),
                          onRefresh: _fetch,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _notifications.length,
                            itemBuilder: (_, i) {
                              final n = _notifications[i];
                              final type = n['type'] as String?;
                              final color = _colorForType(type);
                              final hall = n['hall'] as Map<String, dynamic>?;
                              final course = n['course'] as Map<String, dynamic>?;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: color.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_iconForType(type), color: color, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (type != null)
                                            Text(
                                              type.replaceAll('_', ' ').toLowerCase(),
                                              style: GoogleFonts.lemon(fontSize: 11, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: color, letterSpacing: 0.5),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n['message'] as String? ?? '',
                                            style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black),
                                          ),
                                          if (hall != null || course != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (hall != null) hall['name'] as String?,
                                                if (course != null) '${course['code']}: ${course['name']}',
                                              ].whereType<String>().join('  •  '),
                                              style: GoogleFonts.lemon(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black45),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            _timeAgo(n['created_at'] as String?),
                                            style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
