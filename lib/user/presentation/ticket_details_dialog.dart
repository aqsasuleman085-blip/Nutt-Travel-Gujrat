import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

import 'add_extra_seats_dialog.dart';
import 'edit_passenger_dialog.dart';

/// Read-only ticket details dialog. The edit icon (shown only when status
/// == 'pending') opens EditPassengerDialog; the seat icon opens
/// AddExtraSeatsDialog. Both are separate, fully self-contained dialogs
/// (see edit_passenger_dialog.dart / add_extra_seats_dialog.dart) styled
/// with the shared StyledFormDialog shell so they look consistent with
/// each other.
class TicketDetailsDialog extends StatelessWidget {
  final BookingModel booking;

  const TicketDetailsDialog({super.key, required this.booking});

  bool get _canEdit => booking.status == 'pending';

  // Adding more seats is allowed regardless of this booking's status - it's
  // a NEW booking, not a change to this one. Only blocked if this booking
  // is itself an addon (to keep the link one level deep).
  bool get _canAddSeats => booking.linkedBookingId.isEmpty;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateFromTimestamp(int timestamp) {
    return _formatDate(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('Ticket Details - ${booking.seatNumber}')),
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit passenger info',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => EditPassengerDialog(booking: booking),
                );
              },
            ),
          if (_canAddSeats)
            IconButton(
              icon: const Icon(Icons.event_seat, size: 20),
              tooltip: 'Add more seats',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddExtraSeatsDialog(booking: booking),
                );
              },
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            _detailRow('Gender', booking.gender.isEmpty ? 'N/A' : booking.gender),
            const Divider(),

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

            const Text(
              'PAYMENT INFORMATION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _detailRow('Ticket Price', 'Rs ${booking.price.toStringAsFixed(0)}'),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
