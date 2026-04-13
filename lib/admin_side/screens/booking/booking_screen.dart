import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/loading_widget.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(context, 'pending'),
          _buildBookingsList(context, 'approved'),
          _buildBookingsList(context, 'rejected'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, String status) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        List bookings;
        String emptyMessage;

        switch (status) {
          case 'pending':
            bookings = bookingProvider.pendingBookings;
            emptyMessage = 'No pending bookings';
            break;
          case 'approved':
            bookings = bookingProvider.approvedBookings;
            emptyMessage = 'No approved bookings';
            break;
          case 'rejected':
            bookings = bookingProvider.rejectedBookings;
            emptyMessage = 'No rejected bookings';
            break;
          default:
            bookings = [];
            emptyMessage = 'No bookings found';
        }

        if (bookingProvider.isLoading) {
          return const LoadingWidget(message: 'Loading bookings...');
        }

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' 
                    ? Icons.pending_actions 
                    : status == 'approved' 
                      ? Icons.check_circle 
                      : Icons.cancel,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh is handled by the provider
          },
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return BookingCard(
                  booking: booking,
                  onTap: () {
                    _showBookingDetails(context, booking);
                  },
                  onApprove: status == 'pending' ? () {
                    bookingProvider.approveBooking(booking.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking approved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } : null,
                  onReject: status == 'pending' ? () {
                    bookingProvider.rejectBooking(booking.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } : null,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showBookingDetails(BuildContext context, booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details - ${booking.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User Name', booking.userName),
            _buildDetailRow('Email', booking.userEmail),
            _buildDetailRow('Route', '${booking.busFrom} → ${booking.busTo}'),
            _buildDetailRow('Price', 'Rs. ${booking.price.toStringAsFixed(0)}'),
            _buildDetailRow('Status', booking.status),
            _buildDetailRow('Booking Date', '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}'),
            _buildDetailRow('Created On', '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.darkGreen,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}