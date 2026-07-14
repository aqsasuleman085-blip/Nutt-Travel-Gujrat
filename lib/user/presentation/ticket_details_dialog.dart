import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

import '../../services/booking_service.dart';
import 'add_extra_seats_dialog.dart';
import 'edit_passenger_dialog.dart';

/// Read-only ticket details dialog. The edit icon (shown only when status
/// == 'pending') opens EditPassengerDialog; the seat icon opens
/// AddExtraSeatsDialog. Both are separate, fully self-contained dialogs
/// (see edit_passenger_dialog.dart / add_extra_seats_dialog.dart) styled
/// with the shared StyledFormDialog shell so they look consistent with
/// each other.
class TicketDetailsDialog extends StatefulWidget {
  final BookingModel booking;

  const TicketDetailsDialog({super.key, required this.booking});

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  final BookingService _bookingService = BookingService();

  // Whether the ROOT booking of this reservation (this booking itself if
  // it has no linkedBookingId, or whatever it's linked to otherwise) is
  // still 'pending'. "Add More Seats" is only allowed while the root is
  // pending - once the admin approves or rejects the root, the whole
  // reservation (root + every addon) is locked, even if a specific addon
  // booking's own status still happens to say 'pending'.
  bool _rootIsPending = false;

  // Whether the root has ALREADY used its one and only "Add More Seats"
  // chance. Once true, it stays true forever for this reservation - the
  // option is permanently gone, even if that addon later gets
  // rejected/refunded.
  bool _rootHasUsedAddSeats = false;

  bool _loadingRootStatus = true;

  BookingModel get booking => widget.booking;

  @override
  void initState() {
    super.initState();
    _loadRootStatus();
  }

  Future<void> _loadRootStatus() async {
    if (booking.linkedBookingId.isEmpty) {
      // This booking IS the root.
      setState(() {
        _rootIsPending = booking.status == 'pending';
        _rootHasUsedAddSeats = booking.hasUsedAddSeats;
        _loadingRootStatus = false;
      });
      return;
    }

    try {
      final root = await _bookingService.getBookingById(
        booking.linkedBookingId,
      );
      if (mounted) {
        setState(() {
          _rootIsPending = root?.status == 'pending';
          _rootHasUsedAddSeats = root?.hasUsedAddSeats ?? true;
          _loadingRootStatus = false;
        });
      }
    } catch (e) {
      // If we can't confirm the root is still pending, default to NOT
      // allowing seat additions - safer to block than to accidentally
      // allow adding seats onto an already-decided reservation.
      if (mounted) {
        setState(() {
          _rootIsPending = false;
          _rootHasUsedAddSeats = true;
          _loadingRootStatus = false;
        });
      }
    }
  }

  bool get _canEdit => booking.status == 'pending';

  // Adding more seats requires ALL of: this specific booking still being
  // pending, the reservation's root booking still being pending (see
  // _loadRootStatus above), the root NOT having already used its one
  // add-seats chance, and this booking not itself being an addon (kept
  // one level deep).
  bool get _canAddSeats =>
      !_loadingRootStatus &&
      _rootIsPending &&
      !_rootHasUsedAddSeats &&
      booking.status == 'pending' &&
      booking.linkedBookingId.isEmpty;

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
            if (!_loadingRootStatus &&
                booking.linkedBookingId.isEmpty &&
                booking.status == 'pending' &&
                _rootHasUsedAddSeats) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have already used your one chance to add more '
                        'seats to this booking. Any further seats need a '
                        'new booking.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
