import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRefund;

  /// When this booking has one or more linked "extra seats" bookings in
  /// the same status/tab, these carry the combined display values so the
  /// card can show "Seats 7, 9, 10" and the combined total instead of just
  /// this one booking's own seat/amount. If there are no linked addons,
  /// these simply match the booking's own seatNumber/totalAmount.
  final String? combinedSeatLabel;
  final double? combinedTotalAmount;
  final int extraSeatsCount;

  const BookingCard({
    Key? key,
    required this.booking,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.onRefund,
    this.combinedSeatLabel,
    this.combinedTotalAmount,
    this.extraSeatsCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displaySeats = combinedSeatLabel ?? booking.seatNumber;
    final displayAmount = combinedTotalAmount ?? booking.totalAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Seat: $displaySeats')),
                  if (extraSeatsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+$extraSeatsCount seat${extraSeatsCount == 1 ? '' : 's'} added',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                ],
              ),
              Text('Route: ${booking.busFrom} → ${booking.busTo}'),
              Text('Date: ${booking.travelDate}'),
              Text('Amount: Rs ${displayAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onApprove != null) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onReject != null) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onRefund != null) ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onRefund,
                      child: const Text('Refund'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onTap,
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'refund_pending':
        return Colors.orange;
      case 'refunded':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (booking.status) {
      case 'pending':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'refund_pending':
        return 'REFUND PENDING';
      case 'refunded':
        return 'REFUNDED';
      case 'rejected':
        return 'REJECTED';
      default:
        return booking.status.toUpperCase();
    }
  }
}
