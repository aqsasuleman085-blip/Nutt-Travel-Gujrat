import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../admin_side/models/support_ticket_model.dart';
import '../services/support_ticket_service.dart';
import 'ask_question_screen.dart';

const Color _themeColor = Color(0xff10B981);

/// Lists every support ticket the current user has opened, most recently
/// active first, with a preview of the latest message and a "Replied"
/// badge once admin has responded at least once.
class MySupportTicketsScreen extends StatelessWidget {
  const MySupportTicketsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = SupportTicketService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Questions',
          style: TextStyle(fontWeight: FontWeight.bold, color: _themeColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _themeColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _themeColor,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text('Ask a Question', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AskQuestionScreen()),
          );
        },
      ),
      body: StreamBuilder<List<SupportTicket>>(
        stream: service.streamMyTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _themeColor),
            );
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.question_answer_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      "You haven't asked any questions yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final lastMessage = ticket.messages.isNotEmpty
                  ? ticket.messages.last
                  : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: _themeColor.withOpacity(0.12),
                    child: Icon(
                      ticket.hasReply
                          ? Icons.mark_email_read
                          : Icons.hourglass_top,
                      color: _themeColor,
                    ),
                  ),
                  title: Text(
                    ticket.messages.isNotEmpty
                        ? ticket.messages.first.text
                        : '(no message)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.bookingSummary.isNotEmpty)
                          Text(
                            ticket.bookingSummary,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (lastMessage != null)
                          Text(
                            lastMessage.isFromAdmin
                                ? 'Support: ${lastMessage.text}'
                                : 'You: ${lastMessage.text}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: !ticket.hasReply
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketThreadScreen(ticket: ticket),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shows the full message thread for one ticket and lets the user send a
/// follow-up if the admin's reply wasn't enough.
/// Shows the full message thread for one ticket and lets the user send a
/// follow-up if the admin's reply wasn't enough. Streams live from
/// Firestore (same pattern as the admin thread screen) so a new admin
/// reply appears immediately without leaving and reopening the screen.
///
/// Opened from a row in "My Questions", where the tapped [ticket] is
/// already in hand.
class TicketThreadScreen extends StatefulWidget {
  final SupportTicket ticket;

  const TicketThreadScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends State<TicketThreadScreen> {
  final _replyController = TextEditingController();
  final _service = SupportTicketService();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendFollowUp() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _service.addUserFollowUp(ticketId: widget.ticket.id, text: text);
      _replyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow-up sent.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime dt) {
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Support Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, color: _themeColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _themeColor),
      ),
      body: StreamBuilder<List<SupportTicket>>(
        stream: _service.streamMyTickets(),
        initialData: [widget.ticket],
        builder: (context, snapshot) {
          // Surface stream errors instead of an unexplained blank screen
          // (e.g. a missing Firestore index) - falls back to the ticket
          // we already have so the user can still read/reply.
          if (snapshot.hasError) {
            debugPrint('streamMyTickets error: ${snapshot.error}');
          }

          final tickets = snapshot.data ?? [widget.ticket];
          SupportTicket currentTicket = widget.ticket;
          for (final t in tickets) {
            if (t.id == widget.ticket.id) {
              currentTicket = t;
              break;
            }
          }

          return Column(
            children: [
              if (currentTicket.bookingSummary.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: _themeColor.withOpacity(0.08),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, size: 16, color: _themeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Regarding: ${currentTicket.bookingSummary}',
                          style: const TextStyle(fontSize: 12, color: _themeColor),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentTicket.messages.length,
                  itemBuilder: (context, index) {
                    final message = currentTicket.messages[index];
                    final isAdmin = message.isFromAdmin;

                    return Align(
                      alignment:
                          isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.white : _themeColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin ? message.senderName : 'You',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? _themeColor : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: isAdmin ? Colors.black87 : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isAdmin ? Colors.grey : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: 'Type a follow-up message...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: _themeColor,
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.white, size: 18),
                                onPressed: _sendFollowUp,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
