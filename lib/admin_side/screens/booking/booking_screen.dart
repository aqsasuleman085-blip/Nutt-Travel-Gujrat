import 'package:flutter/material.dart';
import 'package:nutt/admin_side/core/constants/app_constants.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/widgets/booking_card.dart';
import 'package:nutt/admin_side/widgets/loading_widget.dart';
import 'package:nutt/services/notification_service.dart';
import 'package:nutt/shared/validators.dart';
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

  Future<Map<String, String>?> _showRejectDialog(
    _MergedBookingEntry entry,
  ) async {
    final booking = entry.primary;
    final formKey = GlobalKey<FormState>();
    final refundAmountController = TextEditingController(
      text: entry.combinedTotalAmount.toStringAsFixed(0),
    );
    final refundAccountNameController = TextEditingController();
    final refundAccountNumberController = TextEditingController();
    final reasonController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Booking'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seat(s): ${entry.combinedSeatLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refundAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refund Amount',
                      helperText: 'Combined total for all seats in this booking',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refundAccountNameController,
                    inputFormatters: [NameOnlyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Refund Account Name',
                      hintText: 'JazzCash / Easypaisa / Bank Account',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        validateNameOnly(v, fieldLabel: 'Refund account name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refundAccountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refund Account Number',
                      hintText: '03XXXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                    validator: validatePakistaniPhone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason For Rejection',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                ],
              ),
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
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'refundAmount': refundAmountController.text.trim(),
                  'refundAccountName': refundAccountNameController.text.trim(),
                  'refundAccountNumber':
                      refundAccountNumberController.text.trim(),
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

  Future<Map<String, String>?> _showRefundDialog(
    _MergedBookingEntry entry,
  ) async {
    final booking = entry.primary;
    final formKey = GlobalKey<FormState>();
    final refundAmountController = TextEditingController(
      text: entry.combinedTotalAmount.toStringAsFixed(0),
    );
    final refundAccountNameController = TextEditingController();
    final refundAccountNumberController = TextEditingController();
    final reasonController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Process Refund'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking: ${booking.userName} - Seat(s) ${entry.combinedSeatLabel}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refundAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refund Amount',
                      helperText: 'Combined total for all seats in this booking',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refundAccountNameController,
                    inputFormatters: [NameOnlyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Refund Account Name',
                      hintText: 'JazzCash / Easypaisa / Bank Account',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        validateNameOnly(v, fieldLabel: 'Refund account name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: refundAccountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Refund Account Number',
                      hintText: '03XXXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                    validator: validatePakistaniPhone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'refundAmount': refundAmountController.text.trim(),
                  'refundAccountName': refundAccountNameController.text.trim(),
                  'refundAccountNumber':
                      refundAccountNumberController.text.trim(),
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

  /// Groups bookings so that an original booking and any "extra seats"
  /// bookings linked to it (via linkedBookingId) are combined into ONE
  /// display entry when they're both present in this SAME status-filtered
  /// list (i.e. both currently have the same status, e.g. both approved).
  /// If the original and its addon have DIFFERENT statuses, they simply
  /// won't both appear in the same tab, so each stays a separate card in
  /// its own tab - no special-casing needed for that.
  List<_MergedBookingEntry> _mergeLinkedBookings(List<BookingModel> bookings) {
    final byId = {for (final b in bookings) b.id: b};
    final result = <_MergedBookingEntry>[];

    for (final booking in bookings) {
      if (booking.linkedBookingId.isNotEmpty) {
        // This is an addon booking. If its original is ALSO in this same
        // list, skip it here - it'll be attached under the original below.
        if (byId.containsKey(booking.linkedBookingId)) continue;
        // Its original isn't in this list (different status/tab) - show
        // this addon on its own, as before.
        result.add(_MergedBookingEntry(primary: booking, extras: const []));
        continue;
      }

      // This is an original booking - gather any addons for it that are
      // also present in this same list.
      final addons = bookings
          .where((b) => b.linkedBookingId == booking.id)
          .toList();
      result.add(_MergedBookingEntry(primary: booking, extras: addons));
    }

    return result;
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

    final merged = _mergeLinkedBookings(bookings);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: merged.length,
      itemBuilder: (context, index) {
        final entry = merged[index];
        final booking = entry.primary;
        final isProcessing = _processingId == booking.id;

        return Stack(
          children: [
            BookingCard(
              booking: booking,
              combinedSeatLabel: entry.combinedSeatLabel,
              combinedTotalAmount: entry.combinedTotalAmount,
              extraSeatsCount: entry.extras.length,
              onTap: () => _showDetails(entry),

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
                      final rejectData = await _showRejectDialog(entry);
                      if (rejectData == null) return;
                      await _handleAction(
                        bookingId: booking.id,
                        action: () =>
                            context.read<BookingProvider>().rejectBooking(
                              bookingId: booking.id,
                              refundAmount: rejectData['refundAmount']!,
                              refundAccountName:
                                  rejectData['refundAccountName']!,
                              refundAccountNumber:
                                  rejectData['refundAccountNumber']!,
                              rejectionReason: rejectData['rejectionReason']!,
                            ),
                        successMessage: 'Booking Rejected ✗',
                      );
                      await AdminNotificationService().sendNotification(
                        uid: booking.userId,
                        title: "Ticket Rejected",
                        message:
                            "Your ticket for seat(s) ${entry.combinedSeatLabel} from ${booking.busFrom} to ${booking.busTo} was rejected.\nRefund: Rs ${rejectData['refundAmount']}\nAccount: ${rejectData['refundAccountName']} (${rejectData['refundAccountNumber']})\nReason: ${rejectData['rejectionReason']}",
                      );
                    }
                  : null,

              // Refund button (only for refund_pending)
              onRefund: status == 'refund_pending'
                  ? () async {
                      final refundData = await _showRefundDialog(entry);
                      if (refundData == null) return;
                      await _handleAction(
                        bookingId: booking.id,
                        action: () =>
                            context.read<BookingProvider>().processRefund(
                              bookingId: booking.id,
                              refundAmount: refundData['refundAmount']!,
                              refundAccountName:
                                  refundData['refundAccountName']!,
                              refundAccountNumber:
                                  refundData['refundAccountNumber']!,
                              refundReason: refundData['refundReason'] ?? '',
                            ),
                        successMessage: 'Refund Processed ✓',
                      );
                      await AdminNotificationService().sendNotification(
                        uid: booking.userId,
                        title: "Refund Processed",
                        message:
                            "Your refund for seat(s) ${entry.combinedSeatLabel} from ${booking.busFrom} to ${booking.busTo} has been processed. Amount: Rs ${refundData['refundAmount']} will be sent to ${refundData['refundAccountName']} (${refundData['refundAccountNumber']}).",
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

  void _showDetails(_MergedBookingEntry entry) {
    if (!mounted) return;
    final booking = entry.primary;

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
              _row("Seat(s)", entry.combinedSeatLabel),
              _row("Route", "${booking.busFrom} → ${booking.busTo}"),
              _row("Date", booking.travelDate),
              _row("Sender Name", booking.senderName),
              _row("Sender Number", booking.senderNumber),
              _row(
                "Total Amount",
                "Rs ${entry.combinedTotalAmount.toStringAsFixed(0)}",
              ),
              // Show the per-booking breakdown whenever extra seats were
              // added, so the admin can see exactly how the combined
              // total was made up (original booking + each addon).
              if (entry.extras.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Text(
                  "BREAKDOWN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                _row(
                  "Original - Seat ${booking.seatNumber}",
                  "Rs ${booking.totalAmount.toStringAsFixed(0)}",
                ),
                for (final addon in entry.extras)
                  _row(
                    "Added - Seat ${addon.seatNumber}",
                    "Rs ${addon.totalAmount.toStringAsFixed(0)}",
                  ),
              ],
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

/// Groups an original booking together with any "extra seats" bookings
/// linked to it (present in the same status-filtered list), so the admin
/// UI can display them as one combined card - e.g. original seat 7 plus
/// an addon for seats 9,10 shows as "Seats 7, 9, 10" with the combined
/// total price - while each remains a separate Firestore document
/// underneath.
class _MergedBookingEntry {
  final BookingModel primary;
  final List<BookingModel> extras;

  _MergedBookingEntry({required this.primary, required this.extras});

  /// e.g. "7, 9, 10" - the primary's seat(s) followed by every extra
  /// booking's seat(s), in booking order.
  String get combinedSeatLabel {
    if (extras.isEmpty) return primary.seatNumber;
    final allSeats = [primary.seatNumber, ...extras.map((b) => b.seatNumber)];
    return allSeats.join(', ');
  }

  double get combinedTotalAmount {
    return primary.totalAmount +
        extras.fold(0.0, (sum, b) => sum + b.totalAmount);
  }
}
