import 'package:flutter/material.dart';
import 'package:nutt/admin_side/models/booking_model.dart';
import '../../services/booking_service.dart';

/// A compact star-rating control shown on approved ticket cards, letting
/// the user rate their trip (1-5 stars + optional comment). If the
/// booking already has a rating, it displays the stars as read-only.
class TripRatingWidget extends StatefulWidget {
  final BookingModel booking;
  final Color themeColor;

  const TripRatingWidget({
    super.key,
    required this.booking,
    required this.themeColor,
  });

  @override
  State<TripRatingWidget> createState() => _TripRatingWidgetState();
}

class _TripRatingWidgetState extends State<TripRatingWidget> {
  final BookingService _bookingService = BookingService();
  late int _selectedStars;
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selectedStars = widget.booking.userRating;
    _submitted = widget.booking.userRating > 0;
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) return;

    setState(() => _isSubmitting = true);

    try {
      await _bookingService.submitRating(
        bookingId: widget.booking.id,
        busId: widget.booking.busId,
        rating: _selectedStars,
      );

      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for rating your trip!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.themeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.themeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _submitted ? 'Your rating' : 'Rate your trip',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.themeColor,
              ),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final filled = starIndex <= _selectedStars;
              return GestureDetector(
                onTap: (_submitted || _isSubmitting)
                    ? null
                    : () {
                        setState(() => _selectedStars = starIndex);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 20,
                    color: Colors.amber,
                  ),
                ),
              );
            }),
          ),
          if (!_submitted) ...[
            const SizedBox(width: 6),
            _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _selectedStars == 0 ? null : _submitRating,
                    icon: const Icon(Icons.send, size: 18),
                    color: widget.themeColor,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Submit rating',
                  ),
          ],
        ],
      ),
    );
  }
}
