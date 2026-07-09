import 'package:flutter/material.dart';
import 'package:nutt/admin_side/core/constants/app_constants.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/widgets/booking_card.dart';
import 'package:nutt/admin_side/widgets/loading_widget.dart';
import 'package:nutt/services/notification_service.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import 'booking_cleanup_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _processingId;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Applies the search query (name/CNIC/phone) and date-range filter
  /// (based on travel date) on top of a status-filtered booking list.
  List<BookingModel> _applyFilters(List<BookingModel> bookings) {
    var result = bookings;

    if (_searchQuery.isNotEmpty) {
      result = result.where((b) {
        final name = b.userName.toLowerCase();
        final cnic = b.cnic.toLowerCase();
        final phone = b.phone.toLowerCase();
        return name.contains(_searchQuery) ||
            cnic.contains(_searchQuery) ||
            phone.contains(_searchQuery);
      }).toList();
    }

    if (_dateRange != null) {
      result = result.where((b) {
        final travelDate = DateTime.tryParse(b.travelDate);
        if (travelDate == null) return false;
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
        );
        return !travelDate.isBefore(start) && !travelDate.isAfter(end);
      }).toList();
    }

    return result;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<Map<String, String>?> _showRejectDialog(BookingModel booking) async {
    final refundAmountController = TextEditingController(
      text: booking.totalAmount.toStringAsFixed(0),
    );
    final refundAccountController = TextEditingController();
    final reasonController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: refundAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refundAccountController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Account Name',
                    hintText: 'JazzCash / Easypaisa / Bank Account',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reason For Rejection',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (refundAmountController.text.trim().isEmpty ||
                    refundAccountController.text.trim().isEmpty ||
                    reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'refundAmount': refundAmountController.text.trim(),
                  'refundAccountName': refundAccountController.text.trim(),
                  'rejectionReason': reasonController.text.trim(),
                });
              },
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>?> _showRefundDialog(BookingModel booking) async {
    final refundAmountController = TextEditingController(
      text: booking.totalAmount.toStringAsFixed(0),
    );
    final refundAccountController = TextEditingController();
    final reasonController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Process Refund'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Booking: ${booking.userName} - Seat ${booking.seatNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refundAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refundAccountController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Account Name',
                    hintText: 'JazzCash / Easypaisa / Bank Account',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason (Optional)',
                    hintText: 'Enter reason for refund',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (refundAmountController.text.trim().isEmpty ||
                    refundAccountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Refund Amount and Account Name are required',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'refundAmount': refundAmountController.text.trim(),
                  'refundAccountName': refundAccountController.text.trim(),
                  'refundReason': reasonController.text.trim(),
                });
              },
              child: const Text(
                'Confirm Refund',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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
        actions: [
          IconButton(
            icon: Badge(
              label: Text(provider.expiredBookings.length.toString()),
              isLabelVisible: provider.expiredBookings.isNotEmpty,
              child: const Icon(Icons.cleaning_services_outlined),
            ),
            tooltip: 'Clean Up Expired Bookings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BookingCleanupScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: const Color.fromARGB(255, 255, 255, 255),
          unselectedLabelColor: Colors.white54,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Refund Pending'),
            Tab(text: 'Refunded'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget(message: 'Loading...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        _applyFilters(provider.pendingBookings),
                        'pending',
                      ),
                      _buildList(
                        _applyFilters(provider.approvedBookings),
                        'approved',
                      ),
                      _buildList(
                        _applyFilters(provider.refundPendingBookings),
                        'refund_pending',
                      ),
                      _buildList(
                        _applyFilters(provider.refundedBookings),
                        'refunded',
                      ),
                      _buildList(
                        _applyFilters(provider.rejectedBookings),
                        'rejected',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name, CNIC, or phone',
                        hintStyle: TextStyle(fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _dateRange != null
                    ? AppConstants.primaryColor.withOpacity(0.12)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 18,
                    color: _dateRange != null
                        ? AppConstants.primaryColor
                        : Colors.grey[700],
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${_dateRange!.start.month}/${_dateRange!.start.day} - '
                      '${_dateRange!.end.month}/${_dateRange!.end.day}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _dateRange = null),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, String status) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $status bookings',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
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

              // Approve button (only for pending)
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
                      await AdminNotificationService().sendNotification(
                        uid: booking.userId,
                        title: "Ticket Approved",
                        message:
                            "${booking.userName}, your seat #${booking.seatNumber} from ${booking.busFrom} to ${booking.busTo} has been approved.",
                      );
                    }
                  : null,

              // Reject button (only for pending)
              onReject: status == 'pending'
                  ? () async {
                      final rejectData = await _showRejectDialog(booking);
                      if (rejectData == null) return;
                      await _handleAction(
                        bookingId: booking.id,
                        action: () =>
                            context.read<BookingProvider>().rejectBooking(
                              bookingId: booking.id,
                              refundAmount: rejectData['refundAmount']!,
                              refundAccountName:
                                  rejectData['refundAccountName']!,
                              rejectionReason: rejectData['rejectionReason']!,
                            ),
                        successMessage: 'Booking Rejected ✗',
                      );
                      await AdminNotificationService().sendNotification(
                        uid: booking.userId,
                        title: "Ticket Rejected",
                        message:
                            "Your ticket for seat #${booking.seatNumber} from ${booking.busFrom} to ${booking.busTo} was rejected.\nRefund: Rs ${rejectData['refundAmount']}\nAccount: ${rejectData['refundAccountName']}\nReason: ${rejectData['rejectionReason']}",
                      );
                    }
                  : null,

              // Refund button (only for refund_pending)
              onRefund: status == 'refund_pending'
                  ? () async {
                      final refundData = await _showRefundDialog(booking);
                      if (refundData == null) return;
                      await _handleAction(
                        bookingId: booking.id,
                        action: () =>
                            context.read<BookingProvider>().processRefund(
                              bookingId: booking.id,
                              refundAmount: refundData['refundAmount']!,
                              refundAccountName:
                                  refundData['refundAccountName']!,
                              refundReason: refundData['refundReason'] ?? '',
                            ),
                        successMessage: 'Refund Processed ✓',
                      );
                      await AdminNotificationService().sendNotification(
                        uid: booking.userId,
                        title: "Refund Processed",
                        message:
                            "Your refund for seat #${booking.seatNumber} from ${booking.busFrom} to ${booking.busTo} has been processed. Amount: Rs ${refundData['refundAmount']} will be sent to ${refundData['refundAccountName']}.",
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
              _row("Passenger", booking.userName),
              _row("Phone", booking.phone),
              _row("CNIC", booking.cnic),
              _row("Seat", booking.seatNumber),
              _row("Route", "${booking.busFrom} → ${booking.busTo}"),
              _row("Date", booking.travelDate),
              _row("Sender Name", booking.senderName),
              _row("Sender Number", booking.senderNumber),
              _row("Amount", "Rs ${booking.totalAmount}"),
              _row("Status", booking.status.toUpperCase()),
              if (booking.refundAmount.isNotEmpty)
                _row("Refund Amount", "Rs ${booking.refundAmount}"),
              if (booking.refundAccountName.isNotEmpty)
                _row("Refund Account", booking.refundAccountName),
              if (booking.refundReason.isNotEmpty)
                _row("Refund Reason", booking.refundReason),
              if (booking.rejectionReason.isNotEmpty)
                _row("Rejection Reason", booking.rejectionReason),
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
