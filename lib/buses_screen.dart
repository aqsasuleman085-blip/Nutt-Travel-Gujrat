import 'package:flutter/material.dart';

class BusesScreen extends StatelessWidget {
  const BusesScreen({super.key});

  final List<Map<String, String>> buses = const [
    {
      "name": "Daewoo Express",
      "time": "10:00 AM - 2:00 PM",
      "price": "1500",
      "seats": "12"
    },
    {
      "name": "Faisal Movers",
      "time": "1:00 PM - 5:00 PM",
      "price": "1800",
      "seats": "8"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Buses")),
      body: ListView.builder(
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];

          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bus["name"]!,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 5),
                  Text("Time: ${bus["time"]}"),
                  Text("Available Seats: ${bus["seats"]}"),

                  const SizedBox(height: 5),
                  Text("Price: Rs ${bus["price"]}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Booked ${bus["name"]} successfully")),
                        );
                      },
                      child: const Text("Book Now"),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}