import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';

import '../../services/booking_service.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  int selectedIndex = 0; // 0 = Upcoming, 1 = Past

  final Color themeColor = const Color(0xff10B981); // Emerald Green
  final BookingService _bookingService = BookingService();

  /// Returns true if the travel date is today or in the future.
  /// Uses travelDate (string "YYYY-MM-DD") if available, otherwise bookingDate.
  bool _isUpcoming(BookingModel booking) {
    try {
      final today = DateTime.now();
      // Prefer travelDate (string like "2026-04-28")
      if (booking.travelDate.isNotEmpty) {
        final travelDate = DateTime.parse(booking.travelDate);
        return travelDate.isAfter(today.subtract(const Duration(days: 1)));
      }
      // Fallback to bookingDate (DateTime)
      return booking.bookingDate.isAfter(
        today.subtract(const Duration(days: 1)),
      );
    } catch (e) {
      return false;
    }
  }

  /// Shows full booking details in a dialog
  void _showDetailsDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Ticket Details - ${booking.seatNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Passenger', booking.userName),
              _detailRow('Email', booking.userEmail),
              const Divider(),
              _detailRow('Route', '${booking.busFrom} → ${booking.busTo}'),
              _detailRow('Seat', booking.seatNumber),
              _detailRow(
                'Travel Date',
                booking.travelDate.isNotEmpty
                    ? booking.travelDate
                    : _formatDate(booking.bookingDate),
              ),
              _detailRow('Booking Date', _formatDate(booking.bookingDate)),
              const Divider(),
              _detailRow('Price', 'Rs ${booking.price.toStringAsFixed(0)}'),
              _detailRow('Payment Method', booking.paymentMethod),
              _detailRow(
                'Transaction Ref',
                booking.paymentReference.isNotEmpty
                    ? booking.paymentReference
                    : 'N/A',
              ),
              const Divider(),
              _detailRow('Booking ID', booking.id),
              _detailRow('Status', booking.status.toUpperCase()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget buildTicketCard(BookingModel booking) {
    final statusColor = booking.status == 'approved'
        ? Colors.green
        : booking.status == 'rejected'
        ? Colors.red
        : Colors.orange;

    // Display travel date if available, otherwise fallback to booking date
    final displayDate = booking.travelDate.isNotEmpty
        ? booking.travelDate
        : _formatDate(booking.bookingDate);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: themeColor.withOpacity(0.3)),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket ${booking.id.substring(0, 6)}...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${booking.busFrom} → ${booking.busTo}',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date: $displayDate",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
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
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Rs ${booking.price.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showDetailsDialog(context, booking),
                  child: const Text("View"),
                ),
              ],
            ),
          ],
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
                const SizedBox(height: 8),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 12),
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
          return const Center(
            child: Text(
              'No tickets available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Filter based on selected tab (Upcoming / Past)
        final filteredBookings = selectedIndex == 0
            ? allBookings.where(_isUpcoming).toList()
            : allBookings.where((b) => !_isUpcoming(b)).toList();

        // if (filteredBookings.isEmpty) {
        //   return Center(
        //     child: Text(
        //       selectedIndex == 0 ? 'No upcoming tickets' : 'No past tickets',
        //       style: const TextStyle(color: Colors.grey),
        //     ),
        //   );
        // }

        return ListView.builder(
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            return buildTicketCard(filteredBookings[index]);
          },
        );
      },
    );
  }

  Widget buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(children: [buildButton("Upcoming", 0)]),
    );
  }

  Widget buildButton(String text, int index) {
    bool isSelected = selectedIndex == index;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        // child: ElevatedButton(
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: isSelected ? themeColor : Colors.grey.shade300,
        //     foregroundColor: isSelected ? Colors.white : Colors.black,
        //   ),
        //   onPressed: () {
        //     setState(() {
        //       selectedIndex = index;
        //     });
        //   },
        //   child: Text(text),
        // ),
      ),
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
          "Tickets Detail",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: Column(
        children: [
          buildTopButtons(),
          Expanded(child: getCurrentScreen()),
        ],
      ),
    );
  }
}
