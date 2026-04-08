import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: BusScheduleScreen(fromCity: "Lahore", toCity: "Karachi", date: "2026-04-08"),
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
  int selectedDayIndex = 0;

  // Dummy data for buses, can change per day if needed
  Map<int, List<Map<String, dynamic>>> busesByDay = {
    0: [
      {"time": "08:00 AM", "fare": 500, "seats": 12},
      {"time": "10:30 AM", "fare": 550, "seats": 5},
    ],
    1: [
      {"time": "09:00 AM", "fare": 520, "seats": 10},
      {"time": "11:00 AM", "fare": 600, "seats": 8},
    ],
    2: [
      {"time": "07:30 AM", "fare": 480, "seats": 15},
      {"time": "12:00 PM", "fare": 580, "seats": 7},
    ],
    3: [
      {"time": "06:00 AM", "fare": 450, "seats": 20},
      {"time": "02:00 PM", "fare": 600, "seats": 6},
    ],
    4: [
      {"time": "08:30 AM", "fare": 500, "seats": 10},
      {"time": "03:00 PM", "fare": 550, "seats": 5},
    ],
    5: [
      {"time": "09:15 AM", "fare": 520, "seats": 12},
      {"time": "04:00 PM", "fare": 580, "seats": 8},
    ],
    6: [
      {"time": "07:00 AM", "fare": 480, "seats": 10},
      {"time": "05:00 PM", "fare": 600, "seats": 6},
    ],
  };

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> buses = busesByDay[selectedDayIndex]!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Search Results"),
            IconButton(
              icon: Icon(Icons.filter_alt_outlined),
              onPressed: () {
                // TODO: Open filter dialog
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekdays & Dates
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                DateTime day = DateTime.now().add(Duration(days: index));
                String dayName = _weekDayName(day.weekday);
                String formattedDate =
                    "${day.day}-${_monthName(day.month)}";

                bool isSelected = selectedDayIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 90,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isSelected ? Colors.white : Colors.black)),
                        SizedBox(height: 4),
                        Text(formattedDate,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),
          // Bus Cards
          Expanded(
            child: ListView.builder(
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_bus, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(bus['time'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${widget.fromCity} → ${widget.toCity}",
                                style: TextStyle(fontSize: 14)),
                            Text("Fare: Rs ${bus['fare']}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700])),
                          ],
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SeatSelectionScreen(
                                          fromCity: widget.fromCity,
                                          toCity: widget.toCity,
                                          time: bus['time'])));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: Text("Available Seats: ${bus['seats']}"),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }

  String _weekDayName(int w) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[w - 1];
  }
}

// Seat selection screen
class SeatSelectionScreen extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final String time;

  const SeatSelectionScreen(
      {super.key,
      required this.fromCity,
      required this.toCity,
      required this.time});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Seat"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          "Seat selection for $fromCity → $toCity at $time",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}