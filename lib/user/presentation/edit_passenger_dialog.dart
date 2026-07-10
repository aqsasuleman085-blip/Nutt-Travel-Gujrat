import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

import '../../services/booking_service.dart';
import 'styled_form_dialog.dart';
import 'user_themed_text_field.dart';

/// Standalone dialog for editing a PENDING booking's passenger info
/// (name, phone, CNIC). The booked seat itself is never editable here -
/// see AddExtraSeatsDialog for adding more seats instead.
class EditPassengerDialog extends StatefulWidget {
  final BookingModel booking;

  const EditPassengerDialog({super.key, required this.booking});

  @override
  State<EditPassengerDialog> createState() => _EditPassengerDialogState();
}

class _EditPassengerDialogState extends State<EditPassengerDialog> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.booking.userName);
    _phoneController = TextEditingController(text: widget.booking.phone);
    _cnicController = TextEditingController(text: widget.booking.cnic);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _bookingService.updateBookingDetails(
        bookingId: widget.booking.id,
        passengerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        cnic: _cnicController.text.trim(),
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
    return StyledFormDialog(
      headerIcon: Icons.edit,
      title: 'Edit Passenger Info',
      subtitle: 'Seat ${widget.booking.seatNumber} • '
          '${widget.booking.busFrom} → ${widget.booking.busTo}',
      primaryLabel: 'Save Changes',
      isBusy: _isSaving,
      onCancelPressed: () => Navigator.pop(context),
      onPrimaryPressed: _save,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserThemedTextField(
              label: 'Passenger Name',
              controller: _nameController,
              inputFormatters: [NameOnlyInputFormatter()],
              validator: (v) =>
                  validateNameOnly(v, fieldLabel: 'Passenger name'),
            ),
            UserThemedTextField(
              label: 'Phone Number (11 digits)',
              controller: _phoneController,
              keyboardType: TextInputType.number,
              validator: validatePakistaniPhone,
            ),
            UserThemedTextField(
              label: 'CNIC (13 digits)',
              controller: _cnicController,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length != 13) {
                  return 'Must be exactly 13 digits';
                }
                return null;
              },
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your booked seat (${widget.booking.seatNumber}) '
                      'cannot be changed here. To book more seats, use '
                      '"Add More Seats" instead.',
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
