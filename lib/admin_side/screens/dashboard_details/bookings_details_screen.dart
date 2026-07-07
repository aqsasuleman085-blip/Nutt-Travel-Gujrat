import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/booking_model.dart';

/// Reusable detail screen for any of the booking-based dashboard cards.
/// Pass [statusFilter] to show only bookings with that status (e.g.
/// 'approved', 'pending'), or leave it null to show every booking
/// (used for the "Total Bookings" card).
class BookingsDetailScreen extends StatelessWidget {
  final String title;
  final String? statusFilter;

  const BookingsDetailScreen({
    super.key,
    required this.title,
    this.statusFilter,
  });

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

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'bookings',
    );

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = (snapshot.data?.docs ?? [])
              .map((doc) => BookingModel.fromMap({'id': doc.id, ...doc.data()}))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final color = _statusColor(booking.status);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${booking.busFrom} → ${booking.busTo}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            booking.status.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${booking.userName} • Seat ${booking.seatNumber}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${booking.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
