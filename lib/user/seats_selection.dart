import 'package:flutter/material.dart';
import 'package:nutt/user/payment_screen.dart';
import 'package:nutt/user/seat_selection_screen.dart';

/// 🔥 SEAT SCREEN (SAME AS YOUR CODE)
class SeatSelectionScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final String time;
  final String date;

  const SeatSelectionScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.time,
    required this.date,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<int, String> selectedSeats = {};
  Set<int> tempSelected = {};

  final Color seatColor = Colors.tealAccent.shade700.withOpacity(0.9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff141E30), Color(0xff243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Seat Selection",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent.shade700.withOpacity(0.9),
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.tealAccent.shade700.withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.fromCity} → ${widget.toCity}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Time: ${widget.time}",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Date: ${widget.date}",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Icon(Icons.directions_bus, color: Colors.tealAccent.shade700),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                LegendItem(color: Colors.tealAccent, text: "Available"),
                LegendItem(color: Colors.yellow, text: "Selected"),
                LegendItem(color: Colors.blue, text: "Male"),
                LegendItem(color: Colors.pink, text: "Female"),
              ],
            ),

            SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(10),
                itemCount: 45,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  int seat = index + 1;

                  Color color = seatColor;
                  if (tempSelected.contains(seat)) color = Colors.yellow;
                  if (selectedSeats[seat] == 'Male') color = Colors.blue;
                  if (selectedSeats[seat] == 'Female') color = Colors.pink;

                  return GestureDetector(
                    onTap: () => _showDialog(seat),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_seat, size: 26, color: color),
                        Text("$seat", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ONLY CHANGE = NAVIGATION ADDED HERE
  void _showDialog(int seat) {
    String? selectedGender;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Seat $seat"),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _genderBox(
                        label: "Male",
                        color: Colors.blue,
                        selected: selectedGender == 'Male',
                        onTap: () {
                          setStateDialog(() {
                            selectedGender = 'Male';
                          });
                        },
                      ),
                      _genderBox(
                        label: "Female",
                        color: Colors.pink,
                        selected: selectedGender == 'Female',
                        onTap: () {
                          setStateDialog(() {
                            selectedGender = 'Female';
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      if (selectedGender != null) {
                        setState(() {
                          selectedSeats[seat] = selectedGender!;
                        });

                        Navigator.pop(context);

                        /// ✅ ONLY NAVIGATION ADDED
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              seat: seat,
                              gender: selectedGender!,
                              fromCity: widget.fromCity,
                              toCity: widget.toCity,
                              time: widget.time,
                              date: widget.date,
                              fare: 12,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text("Confirm"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _genderBox({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label),
      ),
    );
  }
}
