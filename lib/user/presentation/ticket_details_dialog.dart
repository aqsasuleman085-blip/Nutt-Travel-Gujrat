import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';
import '../../services/booking_service.dart';

/// The ticket details dialog, now with an Edit mode for PENDING bookings.
///
/// While viewing, this looks exactly like the original read-only details
/// dialog. Tapping the edit icon (only shown when status == 'pending')
/// switches the Passenger Information section into editable fields for
/// name/phone/CNIC, plus a dropdown to change the seat to any currently
/// available seat on the same bus/date. Everything else (journey, payment,
/// status) stays read-only, since those aren't details the user owns.
class TicketDetailsDialog extends StatefulWidget {
  final BookingModel booking;

  const TicketDetailsDialog({super.key, required this.booking});

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  final BookingService _bookingService = BookingService();

  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  String? _selectedSeat;

  List<String> _availableSeats = [];
  bool _loadingSeats = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.booking.userName);
    _phoneController = TextEditingController(text: widget.booking.phone);
    _cnicController = TextEditingController(text: widget.booking.cnic);
    _selectedSeat = widget.booking.seatNumber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.booking.status == 'pending';

  String _dateKey(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.replaceAll('/', '-');
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  Future<void> _enterEditMode() async {
    setState(() {
      _isEditing = true;
      _loadingSeats = true;
    });

    try {
      final booking = widget.booking;

      // Fetch total seat count for this bus.
      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(booking.busId)
          .get();
      final totalSeats = (busDoc.data()?['totalSeats'] as num?)?.toInt() ?? 0;

      // Fetch currently booked/locked seats for this bus/date.
      final dateKey = _dateKey(booking.travelDate);
      final snap = await FirebaseDatabase.instance
          .ref('seat_data/${booking.busId}/$dateKey')
          .get();

      final Set<String> takenSeats = {};
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final booked = data['booked'];
        if (booked is Map) {
          takenSeats.addAll(booked.keys.map((k) => k.toString()));
        }
        final locks = data['locks'];
        final now = DateTime.now().millisecondsSinceEpoch;
        if (locks is Map) {
          locks.forEach((key, value) {
            if (value is Map) {
              final expiresAt = (value['expiresAt'] as num?)?.toInt() ?? 0;
              if (expiresAt > now) {
                takenSeats.add(key.toString());
              }
            }
          });
        }
      }

      // The booking's own current seat is always available to "change back
      // to", even though it's technically marked booked by this booking.
      takenSeats.remove(booking.seatNumber);

      final seats = List.generate(totalSeats, (i) => (i + 1).toString())
          .where((s) => !takenSeats.contains(s))
          .toList();

      if (mounted) {
        setState(() {
          _availableSeats = seats;
          _loadingSeats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSeats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load available seats: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _cnicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _bookingService.updateBookingDetails(
        bookingId: widget.booking.id,
        passengerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        cnic: _cnicController.text.trim(),
        newSeatNumber: _selectedSeat,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text('Ticket Details - ${booking.seatNumber}'),
          ),
          if (_canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit booking',
              onPressed: _enterEditMode,
            ),
        ],
      ),
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

            if (!_isEditing) ...[
              _detailRow('Passenger Name', booking.userName),
              _detailRow('Email', booking.userEmail),
              _detailRow('Phone', booking.phone),
              _detailRow('CNIC', booking.cnic),
              _detailRow(
                'Gender',
                booking.gender.isEmpty ? 'N/A' : booking.gender,
              ),
            ] else ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Passenger Name'),
              ),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (11 digits)'),
              ),
              TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CNIC (13 digits)'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Seat Number',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              _loadingSeats
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _availableSeats.contains(_selectedSeat)
                          ? _selectedSeat
                          : booking.seatNumber,
                      isExpanded: true,
                      items: [
                        // Always include the current seat as an option,
                        // even though it's "taken" by this same booking.
                        if (!_availableSeats.contains(booking.seatNumber))
                          DropdownMenuItem(
                            value: booking.seatNumber,
                            child: Text('Seat ${booking.seatNumber} (current)'),
                          ),
                        ..._availableSeats.map(
                          (seat) => DropdownMenuItem(
                            value: seat,
                            child: Text('Seat $seat'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSeat = value);
                      },
                    ),
            ],
            const Divider(),

            // Bus & Journey Details (always read-only)
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
            if (!_isEditing) _detailRow('Seat Number', booking.seatNumber),
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
      actions: _isEditing
          ? [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
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
}
