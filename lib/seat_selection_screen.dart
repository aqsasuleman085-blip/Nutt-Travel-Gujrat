import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BusScheduleScreen(
        fromCity: "Lahore", toCity: "Karachi", date: "2026-04-08"),
  ));
}

class BusScheduleScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final String date;

  BusScheduleScreen({
    required this.fromCity,
    required this.toCity,
    required this.date,
  });

  @override
  _BusScheduleScreenState createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen> {
  Map<int, List<Map<String, dynamic>>> busesByDay = {
    0: [
      {"time": "08:00 AM", "fare": 500, "seats": 12},
      {"time": "02:30 PM", "fare": 550, "seats": 5},
    ],
  };

  @override
  Widget build(BuildContext context) {
    List buses = busesByDay[0]!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("${widget.fromCity} → ${widget.toCity}"),
      ),
      body: ListView.builder(
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];

          return Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bus['time'],
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text("Rs ${bus['fare']}"),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeatSelectionScreen(
                          fromCity: widget.fromCity,
                          toCity: widget.toCity,
                          time: bus['time'],
                          date: widget.date,
                        ),
                      ),
                    );
                  },
                  child: Text("Seats: ${bus['seats']}"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 🔥 SEAT SCREEN
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
  State<SeatSelectionScreen> createState() =>
      _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Map<int, String> selectedSeats = {};
  Set<int> tempSelected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Seat Selection"),
        centerTitle: true,
      ),
      body: Column(
        children: [

          /// INFO CARD
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text("${widget.fromCity} → ${widget.toCity}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold)),
                    Text("Time: ${widget.time}"),
                    Text("Date: ${widget.date}"),
                  ],
                ),
                Icon(Icons.directions_bus, color: Colors.blue),
              ],
            ),
          ),

          /// LEGEND (Include Selected)
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: const [
              _LegendItem(color: Colors.grey, text: "Available"),
              _LegendItem(color: Colors.yellow, text: "Selected"),
              _LegendItem(color: Colors.blue, text: "Male"),
              _LegendItem(color: Colors.pink, text: "Female"),
            ],
          ),

          SizedBox(height: 10),

          /// 🔥 SCROLLABLE GRID
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: 45,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    int seat = index + 1;
                    String? type = selectedSeats[seat];

                    Color color = Colors.grey;
                    if (tempSelected.contains(seat))
                      color = Colors.yellow;
                    if (type == 'Male') color = Colors.blue;
                    if (type == 'Female') color = Colors.pink;

                    return GestureDetector(
                      onTap: () => _showDialog(seat),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_seat,
                              size: 26, color: color),
                          SizedBox(height: 4),
                          Text(
                            "$seat",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
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

  /// 🔥 CLEAN WHITE POPUP
  void _showDialog(int seat) {
    String? selectedGender;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// TOP ROW: Title + Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Seat $seat",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  /// OPTIONS
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      _genderBox(
                          label: "Male",
                          color: Colors.blue,
                          selected: selectedGender == 'Male',
                          onTap: () {
                            setStateDialog(() {
                              selectedGender = 'Male';
                            });
                          }),
                      _genderBox(
                          label: "Female",
                          color: Colors.pink,
                          selected: selectedGender == 'Female',
                          onTap: () {
                            setStateDialog(() {
                              selectedGender = 'Female';
                            });
                          }),
                    ],
                  ),

                  SizedBox(height: 25),

                  /// BUTTON BLUE
                  ElevatedButton(
                    onPressed: () {
                      if (selectedGender != null) {
                        setState(() {
                          selectedSeats[seat] =
                              selectedGender!;
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(double.infinity, 45),
                    ),
                    child: Text("Confirm"),
                  )
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
        padding:
            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

/// LEGEND
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.event_seat, size: 18, color: color),
        SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 11)),
      ],
    );
  }
}