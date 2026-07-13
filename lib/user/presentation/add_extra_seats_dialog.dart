import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

import '../../services/booking_service.dart';
import 'seat_grid_picker.dart';
import 'styled_form_dialog.dart';
import 'user_themed_text_field.dart';

/// Standalone dialog for adding extra seats on top of an existing booking.
/// Creates a NEW linked booking (via BookingService.addExtraSeats) - the
/// original booking is never modified.
class AddExtraSeatsDialog extends StatefulWidget {
  final BookingModel booking;

  const AddExtraSeatsDialog({super.key, required this.booking});

  @override
  State<AddExtraSeatsDialog> createState() => _AddExtraSeatsDialogState();
}

class _AddExtraSeatsDialogState extends State<AddExtraSeatsDialog> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _isSaving = false;

  int _extraSeatCount = 1;
  List<String?> _extraSeatSelections = [null];
  List<String> _availableSeats = [];
  double _busTicketPrice = 0;
  List<BookingModel> _relatedBookings = [];

  final _senderNameController = TextEditingController();
  final _senderNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderNumberController.dispose();
    super.dispose();
  }

  String _dateKey(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.replaceAll('/', '-');
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    final booking = widget.booking;
    try {
      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(booking.busId)
          .get();
      final totalSeats = (busDoc.data()?['totalSeats'] as num?)?.toInt() ?? 0;
      final ticketPrice =
          (busDoc.data()?['ticketPrice'] as num?)?.toDouble() ?? booking.price;

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
              if (expiresAt > now) takenSeats.add(key.toString());
            }
          });
        }
        // Seats other users have booked but are still awaiting admin
        // approval also count as taken - otherwise two people could pick
        // the same seat during the approval window.
        final pending = data['pending'];
        if (pending is Map) {
          takenSeats.addAll(pending.keys.map((k) => k.toString()));
        }
      }

      final related = await _bookingService.getRelatedBookings(booking);

      // Exclude every seat this SAME reservation already has - the root
      // booking's own seat plus every addon's seat(s) - so the user can't
      // accidentally pick a seat they've already booked for themselves.
      for (final b in related) {
        for (final s in b.seatNumber.split(',')) {
          takenSeats.add(s.trim());
        }
      }

      final seats = List.generate(totalSeats, (i) => (i + 1).toString())
          .where((s) => !takenSeats.contains(s))
          .toList();

      if (mounted) {
        setState(() {
          _availableSeats = seats;
          _busTicketPrice = ticketPrice;
          _relatedBookings = related;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load seats: $e')),
        );
      }
    }
  }

  void _setSeatCount(int count) {
    setState(() {
      _extraSeatCount = count;
      _extraSeatSelections = List.generate(
        count,
        (i) => i < _extraSeatSelections.length ? _extraSeatSelections[i] : null,
      );
    });
  }

  double get _total => _busTicketPrice * _extraSeatCount;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        if (status.contains('refund')) return Colors.blueGrey;
        return Colors.grey;
    }
  }

  Future<void> _confirm() async {
    final selections =
        _extraSeatSelections.whereType<String>().toSet().toList();

    if (selections.length != _extraSeatCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a seat for each slot.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _bookingService.addExtraSeats(
        originalBooking: widget.booking,
        extraSeats: selections,
        senderName: _senderNameController.text.trim(),
        senderNumber: _senderNumberController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selections.length} extra seat(s) requested. '
              'Waiting for admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add seats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return StyledFormDialog(
      headerIcon: Icons.event_seat,
      title: 'Add More Seats',
      subtitle: '${booking.busFrom} → ${booking.busTo} • ${booking.travelDate}',
      primaryLabel: 'Confirm & Request Seats',
      isBusy: _isSaving,
      onCancelPressed: () => Navigator.pop(context),
      onPrimaryPressed:
          (_loading || _availableSeats.isEmpty) ? null : _confirm,
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          : _availableSeats.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No other seats are currently available on this bus/date.',
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This creates a new booking request for admin approval. '
                  'Your original seat (${booking.seatNumber}) is not affected.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                if (_relatedBookings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'YOUR SEATS ON THIS BOOKING',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: SeatGridPicker.themeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: SeatGridPicker.themeColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: List.generate(_relatedBookings.length, (i) {
                        final b = _relatedBookings[i];
                        final isOriginal = b.linkedBookingId.isEmpty;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: i == _relatedBookings.length - 1
                                ? null
                                : Border(
                                    bottom:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOriginal
                                    ? Icons.star
                                    : Icons.add_circle_outline,
                                size: 15,
                                color: SeatGridPicker.themeColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isOriginal
                                      ? 'Original booking - Seat ${b.seatNumber}'
                                      : 'Added seat(s) - ${b.seatNumber}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(b.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  b.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(b.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Text(
                  'How many extra seats?',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: List.generate(4, (i) => i + 1)
                      .where((n) => n <= _availableSeats.length)
                      .map((n) {
                    final selected = n == _extraSeatCount;
                    return ChoiceChip(
                      label: Text('$n seat${n == 1 ? '' : 's'}'),
                      selected: selected,
                      onSelected: (_) => _setSeatCount(n),
                      selectedColor: SeatGridPicker.themeColor,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? SeatGridPicker.themeColor
                            : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),

                for (var i = 0; i < _extraSeatCount; i++) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Seat ${i + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  SeatGridPicker(
                    availableSeats: _availableSeats,
                    selectedByOtherSlots: _extraSeatSelections
                        .whereType<String>()
                        .toSet(),
                    currentSlotValue: _extraSeatSelections[i],
                    onSeatTap: (seat) {
                      setState(() => _extraSeatSelections[i] = seat);
                    },
                  ),
                ],

                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 4),
                const Text(
                  'JAZZCASH PAYMENT DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserThemedTextField(
                        label: 'Sender Name',
                        controller: _senderNameController,
                        inputFormatters: [NameOnlyInputFormatter()],
                        validator: (v) =>
                            validateNameOnly(v, fieldLabel: 'Sender name'),
                      ),
                      UserThemedTextField(
                        label: 'Sender Number (11 digits)',
                        controller: _senderNumberController,
                        keyboardType: TextInputType.number,
                        validator: validatePakistaniPhone,
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price per seat: Rs ${_busTicketPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '$_extraSeatCount seat${_extraSeatCount == 1 ? '' : 's'} '
                        '× Rs ${_busTicketPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: Rs ${_total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
