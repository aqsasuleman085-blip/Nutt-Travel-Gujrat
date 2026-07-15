import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/support_ticket_model.dart';
import '../../providers/auth_provider.dart' as admin_auth;
import '../../../user/services/support_ticket_service.dart';

/// New admin section: an inbox of every support ticket raised by
/// passengers (via the user-side "Ask a Question" screen), most recently
/// active first. Reached via the chat-bubble icon in the admin app bar,
/// same pattern as the broadcast megaphone icon.
///
/// This is intentionally separate from the existing admin notification
/// bell (which still gets a one-line "New Support Question" alert for
/// awareness) - this screen is where the admin actually reads the full
/// question and replies.
class SupportInboxScreen extends StatelessWidget {
  const SupportInboxScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = SupportTicketService();

    return Scaffold(
      appBar: AppBar(title: const Text('Support Inbox')),
      body: StreamBuilder<List<SupportTicket>>(
        stream: service.streamAllTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No support questions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final lastMessage =
                  ticket.messages.isNotEmpty ? ticket.messages.last : null;
              final awaitingAdmin =
                  lastMessage != null && !lastMessage.isFromAdmin;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  side: BorderSide(
                    color: awaitingAdmin
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.grey.shade300,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
                    child: Text(
                      ticket.userName.isNotEmpty
                          ? ticket.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    ticket.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.bookingSummary.isNotEmpty)
                        Text(
                          ticket.bookingSummary,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      if (lastMessage != null)
                        Text(
                          lastMessage.isFromAdmin
                              ? 'You: ${lastMessage.text}'
                              : lastMessage.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                  trailing: awaitingAdmin
                      ? Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Needs Reply',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminTicketThreadScreen(ticket: ticket),
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

/// Full thread for one ticket, with a reply box for the admin. Mirrors the
/// user-side thread screen (chat-bubble layout) but with admin bubbles on
/// the right instead.
class AdminTicketThreadScreen extends StatefulWidget {
  final SupportTicket ticket;

  const AdminTicketThreadScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<AdminTicketThreadScreen> createState() =>
      _AdminTicketThreadScreenState();
}

class _AdminTicketThreadScreenState extends State<AdminTicketThreadScreen> {
  final _replyController = TextEditingController();
  final _service = SupportTicketService();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final adminAuth = Provider.of<admin_auth.AuthProvider>(context, listen: false);

    setState(() => _isSending = true);
    try {
      await _service.addAdminReply(
        ticket: widget.ticket,
        text: text,
        adminName: adminAuth.admin.name,
      );
      _replyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime dt) => DateFormat('dd MMM, hh:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: Text(widget.ticket.userName)),
      body: StreamBuilder<List<SupportTicket>>(
        stream: _service.streamAllTickets(),
        initialData: [widget.ticket],
        builder: (context, snapshot) {
          final tickets = snapshot.data ?? [widget.ticket];
          final ticket = tickets.firstWhere(
            (t) => t.id == widget.ticket.id,
            orElse: () => widget.ticket,
          );

          return Column(
            children: [
              if (ticket.userEmail.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: AppConstants.lightGreen,
                  child: Text(
                    ticket.userEmail,
                    style: const TextStyle(fontSize: 12, color: AppConstants.darkGreen),
                  ),
                ),
              if (ticket.bookingSummary.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: AppConstants.primaryColor.withOpacity(0.06),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          size: 16, color: AppConstants.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Regarding: ${ticket.bookingSummary}',
                          style: const TextStyle(
                              fontSize: 12, color: AppConstants.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final message = ticket.messages[index];
                    final isAdmin = message.isFromAdmin;

                    return Align(
                      alignment:
                          isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? AppConstants.primaryColor : Colors.white,
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
                              isAdmin ? message.senderName : ticket.userName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? Colors.white70 : AppConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: isAdmin ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: isAdmin ? Colors.white70 : Colors.grey,
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
                            hintText: 'Type your reply...',
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
                        backgroundColor: AppConstants.primaryColor,
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
                                onPressed: _sendReply,
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
