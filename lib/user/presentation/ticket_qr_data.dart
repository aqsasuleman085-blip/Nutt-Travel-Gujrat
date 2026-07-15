import 'package:nutt/admin_side/models/booking_model.dart';

/// Builds the exact text encoded into a ticket's QR code, and used as the
/// human-readable summary on the PDF. Includes every field shown in the
/// ticket details dialog - passenger name, phone, CNIC, seat, route,
/// date, amount, and account name/number - so scanning the code (or
/// reading the PDF) gives the full picture of that specific seat's
/// booking.
String buildTicketQrData(BookingModel booking, {required String seat}) {
  final lines = <String>[
    'NUTT TRAVEL - E-TICKET',
    'Booking ID: ${booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.id}',
    'Passenger: ${booking.userName}',
    'Phone: ${booking.phone}',
    'CNIC: ${booking.cnic}',
    'Seat: $seat',
    'Route: ${booking.busFrom} -> ${booking.busTo}',
    'Travel Date: ${booking.travelDate}',
    'Departure Time: ${booking.time}',
    'Amount: Rs ${booking.price.toStringAsFixed(0)}',
    'Payment Method: ${booking.paymentMethod}',
    if (booking.senderName.isNotEmpty) 'Account Name: ${booking.senderName}',
    if (booking.senderNumber.isNotEmpty)
      'Account Number: ${booking.senderNumber}',
    'Status: ${booking.status.toUpperCase()}',
  ];
  return lines.join('\n');
}
