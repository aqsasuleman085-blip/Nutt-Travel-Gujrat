import 'package:flutter/material.dart';
import 'package:nutt/user/payment_screen.dart';

/// 🎨 Emerald Theme Colors
const Color emeraldGreen = Color(0xFF50C878);
const Color softWhite = Colors.white;

/// 🔥 SEAT SCREEN (EMERALD + WHITE THEME)
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
          /// 🔹 INFO CARD
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

          /// 🔹 LEGEND
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                LegendItem(color: emeraldGreen, text: "Available"),
                LegendItem(color: Colors.orange, text: "Selected"),
                LegendItem(color: Colors.blue, text: "Male"),
                LegendItem(color: Colors.pink, text: "Female"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 SEATS GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 45,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                int seat = index + 1;

                Color color = emeraldGreen.withOpacity(0.8);

                if (tempSelected.contains(seat)) {
                  color = Colors.orange;
                }
                if (selectedSeats[seat] == 'Male') {
                  color = Colors.blue;
                }
                if (selectedSeats[seat] == 'Female') {
                  color = Colors.pink;
                }

                return GestureDetector(
                  onTap: () => _showDialog(seat),
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
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 SEAT DIALOG
  void _showDialog(int seat) {
    String? selectedGender;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Seat $seat",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 15),

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

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldGreen,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () {
                      if (selectedGender != null) {
                        setState(() {
                          selectedSeats[seat] = selectedGender!;
                        });

                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              date: "10 Apr 2026",
                              fromCity: 'jas',
                              seat: 12,
                              time: 'sdf',
                              toCity: 'Jallalpur',

                              fare: 23,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text("Confirm"),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 🔥 LEGEND WIDGET (UPDATED THEME)
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
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}