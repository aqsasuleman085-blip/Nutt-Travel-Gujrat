import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';
import '../../services/booking_service.dart';
import 'refund_request_form.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final Color themeColor = const Color(0xff10B981);
  final BookingService _bookingService = BookingService();

  // Track which booking is being processed
  String? _processingBookingId;

  /// Check if refund is allowed based on ALL business rules
  bool _canRequestRefund(BookingModel booking) {
    try {
      // NEVER show refund button for these statuses
      final nonRefundableStatuses = [
        'refunded',
        'refund_pending',
        'rejected',
        'cancelled',
        'completed',
        'expired',
      ];

      if (nonRefundableStatuses.contains(booking.status)) {
        return false;
      }

      // Only allow refund for 'approved' or 'pending' bookings
      if (booking.status != 'approved' && booking.status != 'pending') {
        return false;
      }

      final now = DateTime.now();

      // Parse travel date and time
      if (booking.travelDate.isEmpty) return false;

      final date = DateTime.parse(booking.travelDate);
      DateTime? ticketTime;

      if (booking.time.isNotEmpty) {
        final parts = booking.time.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        ticketTime = DateTime(date.year, date.month, date.day, hour, minute);
      } else {
        ticketTime = date;
      }

      if (ticketTime == null) return false;

      final diff = ticketTime.difference(now);

      // Ticket already started
      if (diff.isNegative) return false;

      // Must have at least 12 hours remaining
      return diff > const Duration(hours: 12);
    } catch (e) {
      return false;
    }
  }

  /// Opens the full Refund Request Form (bottom sheet) instead of the old
  /// one-tap confirmation dialog. The form collects route/passenger details
  /// (read-only, auto-filled from the booking), account details (auto-filled
  /// but editable), a refund reason dropdown, and a terms & conditions
  /// checkbox. On submit it calls _processRefund with all the extra details.
  Future<void> _openRefundRequestForm(BookingModel booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RefundRequestForm(
        booking: booking,
        themeColor: themeColor,
        onSubmit: (accountName, accountNumber, reason) =>
            _processRefund(
              booking,
              refundAccountName: accountName,
              refundAccountNumber: accountNumber,
              refundReason: reason,
            ),
      ),
    );
  }

  /// Process refund - Always sets status to refund_pending.
  /// Now also carries passenger name + account details + refund reason,
  /// all collected from the Refund Request Form.
  Future<void> _processRefund(
    BookingModel booking, {
    required String refundAccountName,
    required String refundAccountNumber,
    required String refundReason,
  }) async {
    // Set processing state for this booking
    setState(() {
      _processingBookingId = booking.id;
    });

    try {
      // Call the unified refund method - always goes to refund_pending
      await _bookingService.processRefund(
        bookingId: booking.id,
        userId: booking.userId,
        amount: booking.price,
        seatNumber: booking.seatNumber,
        route: '${booking.busFrom} → ${booking.busTo}',
        paymentMethod: booking.paymentMethod,
        passengerName: booking.userName,
        refundAccountName: refundAccountName,
        refundAccountNumber: refundAccountNumber,
        refundReason: refundReason,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⏳ Refund request submitted. Waiting for admin approval.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process refund: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Clear processing state
      if (mounted) {
        setState(() {
          _processingBookingId = null;
        });
      }
    }
  }

  /// Shows a confirmation dialog before soft-deleting a ticket from this
  /// user's "My Tickets" list. The underlying booking record is kept in
  /// Firestore (for admin/history), only hidden from this user's view.
  Future<void> _confirmDeleteTicket(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Ticket'),
        content: Text(
          'Are you sure you want to remove ticket ${booking.seatNumber} '
          '(${booking.busFrom} → ${booking.busTo}) from your list?\n\n'
          'This will only remove it from your view. Your booking record '
          'is kept for our records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteTicket(booking);
    }
  }

  Future<void> _deleteTicket(BookingModel booking) async {
    setState(() {
      _processingBookingId = booking.id;
    });

    try {
      await _bookingService.hideBookingForUser(booking.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket removed from your list.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingBookingId = null;
        });
      }
    }
  }

  void _showDetailsDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ticket Details - ${booking.seatNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Passenger Information
              const Text(
                'PASSENGER INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _detailRow('Passenger Name', booking.userName),
              _detailRow('Email', booking.userEmail),
              _detailRow('Phone', booking.phone),
              _detailRow('CNIC', booking.cnic),
              _detailRow(
                'Gender',
                booking.gender.isEmpty ? 'N/A' : booking.gender,
              ),
              const Divider(),

              // Bus & Journey Details
              const Text(
                'JOURNEY DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _detailRow('Route', '${booking.busFrom} → ${booking.busTo}'),
              _detailRow('Seat Number', booking.seatNumber),
              _detailRow(
                'Travel Date',
                booking.travelDate.isNotEmpty
                    ? booking.travelDate
                    : _formatDate(booking.bookingDate),
              ),
              _detailRow(
                'Departure Time',
                booking.time.isNotEmpty ? booking.time : 'N/A',
              ),
              _detailRow('Booking Date', _formatDate(booking.bookingDate)),
              const Divider(),

              // Payment Information
              const Text(
                'PAYMENT INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _detailRow(
                'Ticket Price',
                'Rs ${booking.price.toStringAsFixed(0)}',
              ),
              _detailRow(
                'Total Amount',
                'Rs ${booking.totalAmount.toStringAsFixed(0)}',
              ),
              _detailRow(
                'Paid Amount',
                'Rs ${booking.paidAmount.toStringAsFixed(0)}',
              ),
              _detailRow('Payment Method', booking.paymentMethod),
              if (booking.senderName.isNotEmpty)
                _detailRow('Sender Name', booking.senderName),
              if (booking.senderNumber.isNotEmpty)
                _detailRow('Sender Number', booking.senderNumber),
              if (booking.paymentReference.isNotEmpty)
                _detailRow('Transaction Ref', booking.paymentReference),
              const Divider(),

              // Status Information
              const Text(
                'STATUS INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              _detailRow(
                'Current Status',
                booking.status == 'refunded'
                    ? 'REFUNDED'
                    : booking.status == 'refund_pending'
                    ? 'REFUND PENDING'
                    : booking.status.toUpperCase(),
              ),

              // Refund Details (if applicable)
              if (booking.status == 'refund_pending' ||
                  booking.status == 'refunded') ...[
                const SizedBox(height: 8),
                const Text(
                  'REFUND DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (booking.refundAmount.isNotEmpty)
                  _detailRow('Refund Amount', 'Rs ${booking.refundAmount}'),
                if (booking.refundAccountName.isNotEmpty)
                  _detailRow('Refund Account', booking.refundAccountName),
                if (booking.refundReason.isNotEmpty)
                  _detailRow('Refund Reason', booking.refundReason),
                if (booking.refundRequestedAt != null)
                  _detailRow(
                    'Requested Date',
                    _formatDateFromTimestamp(booking.refundRequestedAt!),
                  ),
                if (booking.refundApprovedAt != null)
                  _detailRow(
                    'Approved Date',
                    _formatDateFromTimestamp(booking.refundApprovedAt!),
                  ),
              ],

              // Rejection Details (if applicable)
              if (booking.status == 'rejected' &&
                  booking.rejectionReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'REJECTION DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _detailRow('Rejection Reason', booking.rejectionReason),
                if (booking.rejectedAt != null)
                  _detailRow('Rejected Date', _formatDate(booking.rejectedAt!)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return _formatDate(date);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  /// Build ticket card
  Widget buildTicketCard(BookingModel booking) {
    final isRefunded = booking.status == 'refunded';
    final isRefundPending = booking.status == 'refund_pending';
    final isRejected = booking.status == 'rejected';
    final isCancelled = booking.status == 'cancelled';
    final isCompleted = booking.status == 'completed';
    final isExpired = booking.status == 'expired';
    final isProcessing = _processingBookingId == booking.id;

    // Determine if we should show refund button
    final showRefundButton = _canRequestRefund(booking) && !isProcessing;

    // Determine if this is a terminal/ended state (no actions available)
    final isTerminalState =
        isRefunded ||
        isRefundPending ||
        isRejected ||
        isCancelled ||
        isCompleted ||
        isExpired;

    final statusColor = isRefunded
        ? Colors.blue
        : isRefundPending
        ? Colors.orange
        : isRejected
        ? Colors.red
        : isCancelled
        ? Colors.grey
        : isCompleted
        ? Colors.green
        : isExpired
        ? Colors.grey
        : booking.status == 'approved'
        ? Colors.green
        : booking.status == 'pending'
        ? Colors.orange
        : Colors.grey;

    final statusText = isRefunded
        ? 'REFUNDED'
        : isRefundPending
        ? 'REFUND PENDING'
        : isRejected
        ? 'REJECTED'
        : isCancelled
        ? 'CANCELLED'
        : isCompleted
        ? 'COMPLETED'
        : isExpired
        ? 'EXPIRED'
        : booking.status.toUpperCase();

    final displayDate = booking.travelDate.isNotEmpty
        ? booking.travelDate
        : _formatDate(booking.bookingDate).split(' ')[0];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: themeColor.withOpacity(0.3)),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: () => _showDetailsDialog(context, booking),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket ${booking.id.substring(0, 6)}...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      // Delete icon: soft-deletes the ticket from this
                      // user's list only (booking record is kept in
                      // Firestore for admin/history purposes).
                      InkWell(
                        onTap: () => _confirmDeleteTicket(booking),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${booking.busFrom} → ${booking.busTo}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date: $displayDate",
                    style: const TextStyle(fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Seat: ${booking.seatNumber}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    "Rs ${booking.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Show refund reason preview if available
              if (booking.refundReason.isNotEmpty &&
                  (isRefundPending || isRefunded)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRefundPending
                            ? Icons.pending_actions
                            : Icons.check_circle,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Refund Reason: ${booking.refundReason}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Show rejection reason preview if applicable
              if (booking.rejectionReason.isNotEmpty && isRejected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejection Reason: ${booking.rejectionReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              /// Show appropriate badge or buttons based on status
              if (isTerminalState) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRefunded
                            ? Icons.abc_rounded
                            : isRefundPending
                            ? Icons.pending
                            : isRejected
                            ? Icons.cancel
                            : Icons.info_outline,
                        size: 18,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (booking.status == 'approved' ||
                  booking.status == 'pending') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showRefundButton)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _openRefundRequestForm(booking),
                        child: const Text("Request Refund"),
                      ),
                    if (showRefundButton) const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () => _showDetailsDialog(context, booking),
                      child: const Text("View Details"),
                    ),
                  ],
                ),
              ] else ...[
                // Fallback: Show only view button for any other status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () => _showDetailsDialog(context, booking),
                      child: const Text("View Details"),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget getCurrentScreen() {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.streamUserBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allBookings = snapshot.data ?? [];

        if (allBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.airplane_ticket_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No tickets found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book your first ticket to see it here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            itemCount: allBookings.length,
            itemBuilder: (context, index) =>
                buildTicketCard(allBookings[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Tickets",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
      ),
      body: getCurrentScreen(),
    );
  }
}
