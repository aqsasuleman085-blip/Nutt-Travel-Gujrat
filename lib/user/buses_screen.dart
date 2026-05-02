// import 'package:flutter/material.dart';

// import '../services/bus_service.dart';
// import 'seats_selection.dart';

// class BusesScreen extends StatelessWidget {
//   BusesScreen({super.key});

//   final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green
//   final BusService _busService = BusService();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       appBar: AppBar(
//         title: Text(
//           "Available Buses",
//           style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: themeColor),
//       ),

//       body: StreamBuilder(
//         stream: _busService.streamBuses(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final buses = snapshot.data ?? [];
//           if (buses.isEmpty) {
//             return const Center(child: Text('No buses available'));
//           }

//           return ListView.builder(
//             itemCount: buses.length,
//             itemBuilder: (context, index) {
//               final bus = buses[index];
//               return Card(
//                 color: Colors.white,
//                 margin: const EdgeInsets.all(10),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   side: BorderSide(color: themeColor.withOpacity(0.3)),
//                 ),
//                 elevation: 3,
//                 child: Padding(
//                   padding: const EdgeInsets.all(15),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${bus.from} → ${bus.to}',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: themeColor,
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         'Time: ${bus.departureAt.hour.toString().padLeft(2, '0')}:${bus.departureAt.minute.toString().padLeft(2, '0')}',
//                         style: const TextStyle(color: Colors.black87),
//                       ),
//                       Text(
//                         'Seats: ${bus.totalSeats}',
//                         style: const TextStyle(color: Colors.black87),
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         'Price: Rs ${bus.ticketPrice.toStringAsFixed(0)}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: themeColor,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => SeatSelectionScreen(
//                                   busId: bus.id,
//                                   fromCity: bus.from,
//                                   toCity: bus.to,
//                                   time:
//                                       '${bus.departureAt.hour.toString().padLeft(2, '0')}:${bus.departureAt.minute.toString().padLeft(2, '0')}',
//                                   date: DateTime.now().toIso8601String(),
//                                   fare: bus.ticketPrice.toInt(),
//                                   totalSeats: bus.totalSeats,
//                                 ),
//                               ),
//                             );
//                           },
//                           child: const Text('Book Now'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
