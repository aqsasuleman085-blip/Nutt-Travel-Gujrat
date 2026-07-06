import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

/// Refund reason options shown in the dropdown.
const List<String> kRefundReasons = [
  'Emergency',
  'Change of Plan',
  'Booked by Mistake',
  'Wrong Date Selected',
  'Personal Reason',
  'Other',
];

/// A bottom-sheet form the user fills out when requesting a refund.
///
/// - Route & Passenger Name are read-only, auto-filled from the booking.
/// - Account Name & Account Number are auto-filled from the booking's
///   JazzCash sender details (senderName / senderNumber) but remain
///   editable, in case the refund should go to a different account.
/// - Refund Reason is a required dropdown; selecting "Other" reveals an
///   extra text field for the user to specify their own reason.
/// - A Terms & Conditions checkbox must be ticked before the user can submit.
///
/// On submit, [onSubmit] is called with (accountName, accountNumber, reason)
/// and the sheet closes. The caller (tickets_screen.dart) is responsible for
/// actually sending the refund request to Firebase.
class RefundRequestForm extends StatefulWidget {
  final BookingModel booking;
  final Color themeColor;
  final Future<void> Function(
    String accountName,
    String accountNumber,
    String reason,
  )
  onSubmit;

  const RefundRequestForm({
    super.key,
    required this.booking,
    required this.themeColor,
    required this.onSubmit,
  });

  @override
  State<RefundRequestForm> createState() => _RefundRequestFormState();
}

class _RefundRequestFormState extends State<RefundRequestForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _accountNameController;
  late final TextEditingController _accountNumberController;
  final TextEditingController _otherReasonController = TextEditingController();

  String? _selectedReason;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill account name/number from the booking's JazzCash sender
    // details (entered by the user at booking time), but keep them editable
    // in case the refund needs to go to a different account.
    _accountNameController = TextEditingController(
      text: widget.booking.senderName,
    );
    _accountNumberController = TextEditingController(
      text: widget.booking.senderNumber,
    );
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  String get _route => '${widget.booking.busFrom} → ${widget.booking.busTo}';

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Build the final reason string: if "Other" is picked, use the
    // free-text reason the user typed instead of the literal word "Other".
    final String finalReason = _selectedReason == 'Other'
        ? _otherReasonController.text.trim()
        : (_selectedReason ?? '');

    setState(() => _isSubmitting = true);

    // Close the sheet first, then let the parent screen handle the actual
    // Firebase call (it already shows its own snackbar + loading state on
    // the ticket card).
    Navigator.of(context).pop();

    await widget.onSubmit(
      _accountNameController.text.trim(),
      _accountNumberController.text.trim(),
      finalReason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                Text(
                  'Refund Request Form',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seat ${booking.seatNumber} • Rs ${booking.price.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                _sectionLabel('JOURNEY & PASSENGER (from your booking)'),
                const SizedBox(height: 8),
                _readOnlyField(label: 'Route', value: _route),
                const SizedBox(height: 12),
                _readOnlyField(
                  label: 'Passenger Name',
                  value: booking.userName,
                ),

                const SizedBox(height: 20),
                _sectionLabel('REFUND ACCOUNT DETAILS'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountNameController,
                  decoration: _inputDecoration('Account Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Account name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Account Number'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Account number is required'
                      : null,
                ),

                const SizedBox(height: 20),
                _sectionLabel('REFUND REASON'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: _inputDecoration('Select a reason'),
                  items: kRefundReasons
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a refund reason' : null,
                ),

                // Extra text field shown only when "Other" is selected.
                if (_selectedReason == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherReasonController,
                    maxLines: 2,
                    decoration: _inputDecoration('Please specify your reason'),
                    validator: (value) {
                      if (_selectedReason == 'Other' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please specify your reason';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),
                _sectionLabel('TERMS & CONDITIONS'),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() => _agreedToTerms = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: widget.themeColor,
                  title: const Text(
                    'I agree to the terms and conditions.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Refund Request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.grey,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
    );
  }
}
