import 'package:flutter/material.dart';

import '../../admin_side/models/booking_model.dart';
import '../../admin_side/models/support_ticket_model.dart';
import '../services/support_ticket_service.dart';
import '../../services/booking_service.dart';
import 'my_support_tickets_screen.dart';

/// Lets the user submit a new support question to the admin, optionally
/// linked to one of their own bookings for context (e.g. "question about
/// my Gujrat → Lahore ticket"). Reused from two entry points:
///   - the chat icon on the Home screen app bar
///   - the "Ask a Question" section on the Help & Support screen
class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({Key? key}) : super(key: key);

  static const Color themeColor = Color(0xff10B981);

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _ticketService = SupportTicketService();
  final _bookingService = BookingService();

  String? _selectedBookingId; // ✅ Fixed: Changed from _selectedBooking to _selectedBookingId
  bool _isSending = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  String _bookingLabel(BookingModel b) {
    return '${b.busFrom} → ${b.busTo}  •  ${b.travelDate}  •  Seat ${b.seatNumber}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final bookings = await _bookingService.streamUserBookings().first;

      BookingModel? selectedBooking;

      if (_selectedBookingId != null) {
        try {
          selectedBooking = bookings.firstWhere(
            (b) => b.id == _selectedBookingId,
          );
        } catch (_) {
          selectedBooking = null;
        }
      }

      await _ticketService.createTicket(
        question: _questionController.text.trim(),
        bookingId: selectedBooking?.id ?? '',
        bookingSummary: selectedBooking != null
            ? _bookingLabel(selectedBooking)
            : '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your question has been sent to our support team.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MySupportTicketsScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send your question: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = AskQuestionScreen.themeColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ask a Question',
          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: themeColor),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.history, color: themeColor),
            label: const Text(
              'My Questions',
              style: TextStyle(color: themeColor),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MySupportTicketsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.question_answer, color: themeColor, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Have a question or an issue? Send it to our support "
                      "team and we'll reply here as soon as possible.",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'RELATED BOOKING (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<BookingModel>>(
              stream: _bookingService.streamUserBookings(),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];

                if (_selectedBookingId != null &&
                    !bookings.any((b) => b.id == _selectedBookingId)) {
                  _selectedBookingId = null;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedBookingId,
                      hint: const Text('None - general question'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None - general question'),
                        ),
                        ...bookings.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(
                              _bookingLabel(b),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBookingId = value; // ✅ Fixed: Using correct variable name
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'YOUR QUESTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _questionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'e.g. I made a payment but my booking still shows Pending after 6 hours, can you please check?',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter your question'
                  : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Send to Support Team',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}