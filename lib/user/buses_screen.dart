import 'package:flutter/material.dart';

import 'payment_screen.dart';

class BusesScreen extends StatelessWidget {
  const BusesScreen({super.key});

  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green

  final List<Map<String, String>> buses = const [
    {
      "name": "Nutt Coach",
      "time": "10:00 AM - 2:00 PM",
      "price": "1500",
      "seats": "12",
    },
    {
      "name": "Nutt Coach",
      "time": "1:00 PM - 5:00 PM",
      "price": "1800",
      "seats": "8",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          "Available Buses",
          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),

      body: ListView.builder(
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: themeColor.withOpacity(0.3)),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus["name"]!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Time: ${bus["time"]}",
                    style: const TextStyle(color: Colors.black87),
                  ),

                  Text(
                    "Available Seats: ${bus["seats"]}",
                    style: const TextStyle(color: Colors.black87),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Price: Rs ${bus["price"]}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),

                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              date: "10 Apr 2026",
                              busFrom: "City A",
                              busTo: "City B",
                              busId: '${index + 1}',
                              departureTime: bus["time"]!,
                              fare: int.parse(bus["price"]!),
                            ),
                          ),
                        );
                      },

                      child: const Text("Book Now"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
