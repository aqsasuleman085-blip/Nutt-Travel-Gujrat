import 'package:flutter/material.dart';
import 'package:nutt/seat_selection_screen.dart';

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
  int selectedDayIndex = 0;
  String selectedFilter = "All";

  Map<int, List<Map<String, dynamic>>> busesByDay = {
    0: [
      {
        "time": "08:00 AM",
        "fare": 500,
        "seats": 12,
        "type": "AC",
        "duration": "6h",
        "rating": 4.5
      },
      {
        "time": "02:30 PM",
        "fare": 550,
        "seats": 5,
        "type": "Non-AC",
        "duration": "7h",
        "rating": 4.0
      },
    ],
    1: [
      {
        "time": "09:00 AM",
        "fare": 520,
        "seats": 10,
        "type": "AC",
        "duration": "6h",
        "rating": 4.3
      },
      {
        "time": "06:00 PM",
        "fare": 600,
        "seats": 8,
        "type": "AC",
        "duration": "6.5h",
        "rating": 4.6
      },
    ],
  };

  List<Map<String, dynamic>> getFilteredBuses() {
    List<Map<String, dynamic>> buses =
        busesByDay[selectedDayIndex] ?? [];

    if (selectedFilter == "All") return buses;

    return buses.where((bus) {
      String time = bus['time'];
      if (selectedFilter == "Morning") {
        return time.contains("AM");
      } else if (selectedFilter == "Afternoon") {
        return time.contains("PM") &&
            int.parse(time.split(":")[0]) < 5;
      } else {
        return time.contains("PM") &&
            int.parse(time.split(":")[0]) >= 5;
      }
    }).toList();
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempFilter = selectedFilter;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Filter by Time"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ["All", "Morning", "Afternoon", "Evening"]
                    .map((e) => RadioListTile(
                          activeColor: Colors.blue,
                          title: Text(e),
                          value: e,
                          groupValue: tempFilter,
                          onChanged: (value) {
                            setStateDialog(() {
                              tempFilter = value!;
                            });
                          },
                        ))
                    .toList(),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedFilter = tempFilter;
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Apply Filter"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> buses = getFilteredBuses();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("${widget.fromCity} → ${widget.toCity}"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt_outlined),
            onPressed: showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          /// 🔹 WEEK DAYS
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                DateTime day =
                    DateTime.now().add(Duration(days: index));

                String dayName = _weekDayName(day.weekday);
                String date =
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
                      color:
                          isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4)
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(dayName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black)),
                        SizedBox(height: 4),
                        Text(date,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔹 BUS LIST
          Expanded(
            child: buses.isEmpty
                ? Center(child: Text("No buses available"))
                : ListView.builder(
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      final bus = buses[index];

                      return Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.blue.shade50],
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8)
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.directions_bus,
                                          color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(bus['time'],
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.orange,
                                          size: 18),
                                      Text("${bus['rating']}"),
                                    ],
                                  )
                                ],
                              ),

                              SizedBox(height: 10),

                              Text(
                                "${widget.fromCity} → ${widget.toCity}",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),

                              SizedBox(height: 6),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Type: ${bus['type']}"),
                                  Text("Duration: ${bus['duration']}"),
                                ],
                              ),

                              SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Rs ${bus['fare']}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SeatSelectionScreen(
                                            fromCity:
                                                widget.fromCity,
                                            toCity: widget.toCity,
                                            time: bus['time'],
                                            date: widget.date,
                                          ),
                                        ),
                                      );
                                    },
                                    child:
                                        Text("Seats: ${bus['seats']}"),
                                  )
                                ],
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
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }

  String _weekDayName(int w) {
    const days = [
      "Mon","Tue","Wed","Thu","Fri","Sat","Sun"
    ];
    return days[w - 1];
  }
}

/// 🔹 UPDATED SEAT SELECTION SCREEN
// class SeatSelectionScreen extends StatefulWidget {
//   final String fromCity;
//   final String toCity;
//   final String time;
//   final String date;

//   const SeatSelectionScreen({
//     super.key,
//     required this.fromCity,
//     required this.toCity,
//     required this.time,
//     required this.date,
//   });

//   @override
//   State<SeatSelectionScreen> createState() =>
//       _SeatSelectionScreenState();
// }

// class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
//   Map<int, String> selectedSeats = {}; // seatNumber -> Male/Female
//   Set<int> tempSelected = {}; // temporary yellow

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         title: Text(
//           "Seat Selection",
//           style: TextStyle(
//               fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             /// INFO CARD
//             Container(
//               margin: EdgeInsets.all(16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(color: Colors.black12, blurRadius: 6)
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "${widget.fromCity} → ${widget.toCity}",
//                         style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 6),
//                       Text("Time: ${widget.time}"),
//                       Text("Date: ${widget.date}"),
//                     ],
//                   ),
//                   Icon(Icons.directions_bus,
//                       size: 40, color: Colors.blue),
//                 ],
//               ),
//             ),

//             /// LEGEND
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 16),
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 mainAxisAlignment:
//                     MainAxisAlignment.spaceAround,
//                 children: const [
//                   _LegendItem(color: Colors.grey, text: "Available"),
//                   _LegendItem(color: Colors.yellow, text: "Selected"),
//                   _LegendItem(color: Colors.blue, text: "Male"),
//                   _LegendItem(color: Colors.pink, text: "Female"),
//                 ],
//               ),
//             ),

//             SizedBox(height: 16),

//             /// SEAT GRID
//             Container(
//               margin: EdgeInsets.symmetric(horizontal: 16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(color: Colors.black12, blurRadius: 6)
//                 ],
//               ),
//               child: GridView.builder(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: 45,
//                 gridDelegate:
//                     SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 5,
//                   mainAxisSpacing: 10,
//                   crossAxisSpacing: 10,
//                 ),
//                 itemBuilder: (context, index) {
//                   int seatNumber = index + 1;
//                   String? seatType = selectedSeats[seatNumber];

//                   Color seatColor = Colors.grey[300]!;
//                   if (tempSelected.contains(seatNumber)) seatColor = Colors.yellow;
//                   if (seatType == 'Male') seatColor = Colors.blue;
//                   if (seatType == 'Female') seatColor = Colors.pink;

//                   return GestureDetector(
//                     onTap: () => _showGenderDialog(seatNumber),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: seatColor,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.event_seat,
//                                 color: (seatColor == Colors.grey[300]) ? Colors.black : Colors.white),
//                             SizedBox(height: 4),
//                             Text(
//                               "$seatNumber",
//                               style: TextStyle(
//                                   color: (seatColor == Colors.grey[300]) ? Colors.black : Colors.white,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showGenderDialog(int seatNumber) {
//     setState(() {
//       tempSelected.add(seatNumber);
//     });

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Select Gender for seat $seatNumber"),
//           content: Text("Choose Male or Female"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   selectedSeats[seatNumber] = 'Male';
//                   tempSelected.remove(seatNumber);
//                 });
//                 Navigator.pop(context);
//               },
//               child: Text("Male"),
//             ),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   selectedSeats[seatNumber] = 'Female';
//                   tempSelected.remove(seatNumber);
//                 });
//                 Navigator.pop(context);
//               },
//               child: Text("Female"),
//             ),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   selectedSeats.remove(seatNumber);
//                   tempSelected.remove(seatNumber);
//                 });
//                 Navigator.pop(context);
//               },
//               child: Text("Clear"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

/// LEGEND ITEM
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
        SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 12))
      ],
    );
  }
}