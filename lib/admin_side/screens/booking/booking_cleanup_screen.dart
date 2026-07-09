import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';

/// Manual cleanup screen: lists bookings that are safe to delete because
/// their travel date has already passed AND they're either 'approved'
/// (trip already happened), or 'rejected'/'refunded' (never used the
/// seat). The admin reviews the list and deletes individually or in bulk -
/// nothing is ever auto-deleted in the background.
class BookingCleanupScreen extends StatefulWidget {
  const BookingCleanupScreen({super.key});

  @override
  State<BookingCleanupScreen> createState() => _BookingCleanupScreenState();
}

class _BookingCleanupScreenState extends State<BookingCleanupScreen> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'refunded':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    BookingProvider provider,
  ) async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Bookings'),
        content: Text(
          'Permanently delete ${_selectedIds.length} expired booking'
          '${_selectedIds.length == 1 ? '' : 's'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await provider.deleteBookings(_selectedIds.toList());
      if (mounted) {
        setState(() {
          _selectedIds.clear();
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected bookings deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _confirmSingleDelete(
    BuildContext context,
    BookingProvider provider,
    BookingModel booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Booking'),
        content: Text(
          'Permanently delete the booking for ${booking.userName} '
          '(Seat ${booking.seatNumber})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.deleteBooking(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final expired = provider.expiredBookings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Clean Up Expired (${expired.length})'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (expired.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == expired.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds
                      ..clear()
                      ..addAll(expired.map((b) => b.id));
                  }
                });
              },
              child: Text(
                _selectedIds.length == expired.length
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: expired.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cleaning_services, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing to clean up',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expired approved/rejected/refunded bookings\nwill appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: expired.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final booking = expired[index];
                final isSelected = _selectedIds.contains(booking.id);
                final color = _statusColor(booking.status);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(booking.id);
                            } else {
                              _selectedIds.remove(booking.id);
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${booking.userName} • Seat ${booking.seatNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
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
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${booking.busFrom} → ${booking.busTo} • ${booking.travelDate}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () =>
                            _confirmSingleDelete(context, provider, booking),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: (_selectedIds.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting
                        ? null
                        : () => _confirmBulkDelete(context, provider),
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete),
                    label: Text('Delete ${_selectedIds.length} Selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
