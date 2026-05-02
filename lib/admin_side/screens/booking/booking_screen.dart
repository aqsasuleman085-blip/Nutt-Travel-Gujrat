import 'package:flutter/material.dart';
import 'package:nutt/admin_side/core/constants/app_constants.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/widgets/booking_card.dart';
import 'package:nutt/admin_side/widgets/loading_widget.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _processingId;

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

  Future<void> _handleAction({
    required Future<void> Function() action,
    required String bookingId,
    required String successMessage,
  }) async {
    try {
      setState(() => _processingId = bookingId);

      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingId = null);
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required Color confirmColor,
    required String confirmText,
  }) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: const Color.fromARGB(255, 255, 255, 255),
          unselectedLabelColor: Colors.white54,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const LoadingWidget(message: 'Loading...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(provider.pendingBookings, 'pending'),
                _buildList(provider.approvedBookings, 'approved'),
                _buildList(provider.rejectedBookings, 'rejected'),
              ],
            ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, String status) {
    if (bookings.isEmpty) {
      return Center(child: Text('No $status bookings'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final isProcessing = _processingId == booking.id;

        return Stack(
          children: [
            BookingCard(
              booking: booking,
              onTap: () => _showDetails(booking),
              onApprove: status == 'pending'
                  ? () async {
                      final confirmed = await _showConfirmDialog(
                        title: 'Approve Booking',
                        message:
                            'Approve booking for ${booking.userName} (Seat ${booking.seatNumber})?',
                        confirmColor: Colors.green,
                        confirmText: 'Approve',
                      );
                      if (!confirmed) return;

                      await _handleAction(
                        bookingId: booking.id,
                        action: () => context
                            .read<BookingProvider>()
                            .approveBooking(booking.id),
                        successMessage: 'Booking Approved ✓',
                      );
                    }
                  : null,
              onReject: status == 'pending'
                  ? () async {
                      final confirmed = await _showConfirmDialog(
                        title: 'Reject Booking',
                        message:
                            'Reject booking for ${booking.userName} (Seat ${booking.seatNumber})?',
                        confirmColor: Colors.red,
                        confirmText: 'Reject',
                      );
                      if (!confirmed) return;

                      await _handleAction(
                        bookingId: booking.id,
                        action: () => context
                            .read<BookingProvider>()
                            .rejectBooking(booking.id),
                        successMessage: 'Booking Rejected ✗',
                      );
                    }
                  : null,
            ),

            if (isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDetails(BookingModel booking) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Booking - ${booking.userName}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row("Name", booking.userName),
              _row("Phone", booking.phone),
              _row("CNIC", booking.cnic),
              _row("Seat", booking.seatNumber),
              _row("Route", "${booking.busFrom} → ${booking.busTo}"),
              _row("Date", booking.travelDate),
              _row("Amount", "Rs ${booking.totalAmount}"),
              _row("Status", booking.status),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              "$k:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
