import 'package:flutter/material.dart';
import 'package:nutt/payment_screen.dart';
import 'package:nutt/seats_selection.dart';

// void main() {
//   runApp(
//     MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: BusScheduleScreen(
//         fromCity: "Lahore",
//         toCity: "Karachi",
//         date: "2026-04-08",
//       ),
//     ),
//   );
// }

// class BusScheduleScreen extends StatefulWidget {
//   final String fromCity;
//   final String toCity;
//   final String date;

//   BusScheduleScreen({
//     required this.fromCity,
//     required this.toCity,
//     required this.date,
//   });

//   @override
//   _BusScheduleScreenState createState() => _BusScheduleScreenState();
// }

// class _BusScheduleScreenState extends State<BusScheduleScreen> {
//   Map<int, List<Map<String, dynamic>>> busesByDay = {
//     0: [
//       {"time": "08:00 AM", "fare": 500, "seats": 12},
//       {"time": "02:30 PM", "fare": 550, "seats": 5},
//     ],
//   };

//   @override
//   Widget build(BuildContext context) {
//     List buses = busesByDay[0]!;

//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xff1E3C72), Color(0xff2A5298)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: Text(
//             "${widget.fromCity} → ${widget.toCity}",
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.yellowAccent,
//             ),
//           ),
//           centerTitle: true,
//         ),
//         body: ListView.builder(
//           itemCount: buses.length,
//           itemBuilder: (context, index) {
//             final bus = buses[index];

//             return Container(
//               margin: EdgeInsets.all(16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 color: Colors.tealAccent.shade700.withOpacity(0.2),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         bus['time'],
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Text(
//                         "Rs ${bus['fare']}",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 10),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.tealAccent.shade700.withOpacity(
//                         0.9,
//                       ),
//                       minimumSize: Size(double.infinity, 40),
//                     ),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => SeatSelectionScreen(
//                             fromCity: widget.fromCity,
//                             toCity: widget.toCity,
//                             time: bus['time'],
//                             date: widget.date,
//                           ),
//                         ),
//                       );
//                     },
//                     child: Text("Seats: ${bus['seats']}"),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// /// 🔥 LEGEND (UNCHANGED)
class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.event_seat, size: 18, color: color),
        SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }
}
