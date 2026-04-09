import 'package:flutter/material.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final String time;

  const SeatSelectionScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.time,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<int, String> selectedSeats = {}; // seatNumber -> 'Male'/'Female'
  Set<int> tempSelected = {}; // seatNumber temporarily selected (yellow)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      /// 🔹 HEADER
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Seat Selection",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// 🔹 INFO CARD
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.fromCity} → ${widget.toCity}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Time: ${widget.time}"),
                      const Text("Date: 08 Apr 2026"),
                    ],
                  ),
                  const Icon(Icons.directions_bus, size: 40, color: Colors.blue),
                ],
              ),
            ),

            /// 🔹 LEGEND
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _LegendItem(color: Colors.grey, text: "Available"),
                  _LegendItem(color: Colors.yellow, text: "Selected"),
                  _LegendItem(color: Colors.blue, text: "Male"),
                  _LegendItem(color: Colors.pink, text: "Female"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 SEAT GRID CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 45,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  int seatNumber = index + 1;
                  String? seatType = selectedSeats[seatNumber];

                  Color seatColor = Colors.grey[300]!; // default available
                  if (tempSelected.contains(seatNumber)) seatColor = Colors.yellow;
                  if (seatType == 'Male') seatColor = Colors.blue;
                  if (seatType == 'Female') seatColor = Colors.pink;

                  return GestureDetector(
                    onTap: () => _showGenderDialog(seatNumber),
                    child: Container(
                      decoration: BoxDecoration(
                        color: seatColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_seat,
                                color: (seatColor == Colors.grey[300]) ? Colors.black : Colors.white),
                            const SizedBox(height: 4),
                            Text(
                              "$seatNumber",
                              style: TextStyle(
                                  color: (seatColor == Colors.grey[300]) ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 🔹 POPUP FOR MALE/FEMALE SELECTION
  void _showGenderDialog(int seatNumber) {
    setState(() {
      tempSelected.add(seatNumber); // show yellow temporarily
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Gender for seat $seatNumber"),
          content: const Text("Choose Male or Female"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSeats[seatNumber] = 'Male';
                  tempSelected.remove(seatNumber);
                });
                Navigator.pop(context);
              },
              child: const Text("Male"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSeats[seatNumber] = 'Female';
                  tempSelected.remove(seatNumber);
                });
                Navigator.pop(context);
              },
              child: const Text("Female"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSeats.remove(seatNumber);
                  tempSelected.remove(seatNumber);
                });
                Navigator.pop(context);
              },
              child: const Text("Clear"),
            ),
          ],
        );
      },
    );
  }
}

/// 🔹 LEGEND ITEM WIDGET
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 12))
      ],
    );
  }
}