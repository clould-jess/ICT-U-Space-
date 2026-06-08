import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/u_space_nav_bar.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _api.getMessages();
      if (mounted) setState(() { _messages = msgs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComposeSheet() {
    final contentCtrl = TextEditingController();
    final receiverCtrl = TextEditingController();
    bool isBroadcast = false;

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
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'new ', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.black)),
                  TextSpan(text: 'message', style: GoogleFonts.lemon(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                ])),
                const SizedBox(height: 20),

                // Broadcast toggle
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_outlined, color: Color(0xFFFF5100), size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text('broadcast to all', style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black))),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: isBroadcast,
                          onChanged: (v) => setModal(() => isBroadcast = v),
                          activeThumbColor: const Color(0xFFFF5100),
                          activeTrackColor: const Color(0xFFFF5100).withValues(alpha: 0.3),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),

                // Receiver ID (hidden when broadcast)
                if (!isBroadcast) ...[
                  Text('recipient user ID (optional)', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: receiverCtrl,
                      style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Message content
                Text('message', style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'type your message...',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (contentCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await _api.sendMessage(
                          contentCtrl.text.trim(),
                          receiverId: isBroadcast ? null : (receiverCtrl.text.trim().isEmpty ? null : receiverCtrl.text.trim()),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('message sent!', style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
                            backgroundColor: const Color(0xFF00AA44),
                          ));
                          await _fetchMessages();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.lemon(fontStyle: FontStyle.italic)),
                            backgroundColor: Colors.red,
                          ));
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    label: Text('send', style: GoogleFonts.lemon(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5100),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
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
                        TextSpan(text: 'messages', style: GoogleFonts.lemon(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFFFF5100))),
                      ]),
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchMessages,
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
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mail_outline_rounded, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('no messages yet', style: GoogleFonts.lemon(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFFF5100),
                          onRefresh: _fetchMessages,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final msg = _messages[i];
                              final sender = msg['sender'] as Map<String, dynamic>?;
                              final receiver = msg['receiver'] as Map<String, dynamic>?;
                              final isMine = sender?['id'] == currentUser?.id;
                              final isBroadcast = receiver == null && !isMine;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? const Color(0xFFFF5100).withValues(alpha: 0.08)
                                      : isBroadcast
                                          ? const Color(0xFF1A1AFF).withValues(alpha: 0.06)
                                          : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: isMine
                                      ? Border.all(color: const Color(0xFFFF5100).withValues(alpha: 0.3))
                                      : isBroadcast
                                          ? Border.all(color: const Color(0xFF1A1AFF).withValues(alpha: 0.3))
                                          : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isBroadcast ? Icons.campaign_outlined : Icons.person_outline,
                                          size: 16,
                                          color: isMine ? const Color(0xFFFF5100) : Colors.black54,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isMine ? 'you → ${receiver?['name'] ?? 'broadcast'}' : '${sender?['name'] ?? 'unknown'}${isBroadcast ? ' (broadcast)' : ''}',
                                            style: GoogleFonts.lemon(fontSize: 13, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: isMine ? const Color(0xFFFF5100) : Colors.black54),
                                          ),
                                        ),
                                        Text(
                                          _timeAgo(msg['created_at'] as String?),
                                          style: GoogleFonts.lemon(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black38),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      msg['content'] as String? ?? '',
                                      style: GoogleFonts.lemon(fontSize: 15, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.black),
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
      floatingActionButton: (currentUser?.role == 'PREFECT' || currentUser?.role == 'LECTURER' || currentUser?.role == 'ADMIN')
          ? FloatingActionButton.extended(
              onPressed: _showComposeSheet,
              backgroundColor: const Color(0xFFFF5100),
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: Text('compose', style: GoogleFonts.lemon(fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Colors.white)),
            )
          : null,
      bottomNavigationBar: const USpaceNavBar(),
    );
  }
}
