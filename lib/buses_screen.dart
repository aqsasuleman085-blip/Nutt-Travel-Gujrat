import 'package:flutter/material.dart';

class BusesScreen extends StatelessWidget {
  const BusesScreen({super.key});

  final List<Map<String, String>> buses = const [
    {
      "name": "Nutt Coach",
      "time": "10:00 AM - 2:00 PM",
      "price": "1500",
      "seats": "12"
    },
    {
      "name": "Nutt Coach",
      "time": "1:00 PM - 5:00 PM",
      "price": "1800",
      "seats": "8"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff0F2027),
            Color(0xff203A43),
            Color(0xff2C5364),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Available Buses",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor:Colors.tealAccent.shade700.withOpacity(0.9),
          elevation: 0,
        ),
        body: ListView.builder(
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final bus = buses[index];

            return Card(
              color: Color(0xff203A43),
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
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent.shade700.withOpacity(0.9))),
                    const SizedBox(height: 5),
                    Text("Time: ${bus["time"]}", style: TextStyle(color: Colors.white70)),
                    Text("Available Seats: ${bus["seats"]}", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text("Price: Rs ${bus["price"]}",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade700.withOpacity(0.9),
                        ),
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
      ),
    );
  }
}