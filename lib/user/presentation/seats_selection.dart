import 'package:flutter/material.dart';
import 'package:nutt/user/presentation/payment_screen.dart';

import '../../services/realtime_service.dart';

const Color emeraldGreen = Color(0xFF50C878);
const Color softWhite = Colors.white;

class SeatSelectionScreen extends StatefulWidget {
  final String busId;
  final String fromCity;
  final String toCity;
  final String time;
  final String date;
  final int fare;
  final int totalSeats;

  const SeatSelectionScreen({
    super.key,
    required this.busId,
    required this.fromCity,
    required this.toCity,
    required this.time,
    required this.date,
    required this.fare,
    required this.totalSeats,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final RealtimeService _realtimeService = RealtimeService();

  Set<int> tempSelected = {};
  final Map<int, String> selectedSeats = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softWhite,
      appBar: AppBar(
        backgroundColor: emeraldGreen,
        elevation: 0,
        title: const Text(
          "Seat Selection",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: emeraldGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: emeraldGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.fromCity} → ${widget.toCity}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Time: ${widget.time}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    Text(
                      "Date: ${widget.date}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const Icon(Icons.directions_bus, color: emeraldGreen),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                LegendItem(color: emeraldGreen, text: "Available"),
                LegendItem(color: Colors.orange, text: "Selected"),
                LegendItem(color: Colors.grey, text: "Booked"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _realtimeService.streamSeatLocks(
                busId: widget.busId,
                dateKey: _dateKey(widget.date),
              ),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {};

                final locks = data['locks'] is Map
                    ? Map<String, dynamic>.from(data['locks'])
                    : {};
                final bookedSeats = data['booked'] is Map
                    ? Map<String, dynamic>.from(data['booked'])
                    : {};

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.totalSeats,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    int seat = index + 1;

                    final lock = locks[seat.toString()];
                    final isLocked =
                        lock is Map &&
                        ((lock['expiresAt'] as int? ?? 0) >
                            DateTime.now().millisecondsSinceEpoch);

                    final isBooked = bookedSeats.containsKey(seat.toString());

                    Color color = emeraldGreen.withOpacity(0.8);

                    if (isBooked) {
                      color = Colors.grey; // permanently booked
                    } else if (isLocked) {
                      color = Colors.grey; // temporarily locked
                    } else if (tempSelected.contains(seat)) {
                      color = Colors.orange;
                    } else if (selectedSeats[seat] == 'Male') {
                      color = Colors.blue;
                    } else if (selectedSeats[seat] == 'Female') {
                      color = Colors.pink;
                    }

                    return GestureDetector(
                      onTap: (isLocked || isBooked)
                          ? null
                          : () => _selectAndProceed(seat),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_seat, size: 28, color: color),
                          Text(
                            "$seat",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectAndProceed(int seat) {
    setState(() {
      tempSelected.add(seat);
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          date: widget.date,
          fare: widget.fare,
          busId: widget.busId,
          busFrom: widget.fromCity,
          busTo: widget.toCity,
          departureTime: widget.time,
          seatNumber: seat.toString(),
        ),
      ),
    );
  }

  String _dateKey(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.replaceAll('/', '-');
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.event_seat, size: 18, color: color),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
