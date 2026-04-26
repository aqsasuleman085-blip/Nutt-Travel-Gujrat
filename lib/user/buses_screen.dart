import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';

class BusesScreen extends StatelessWidget {
  const BusesScreen({super.key});

  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green

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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').where('status', isEqualTo: 'Active').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading buses'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active buses available at the moment.'));
          }

          final buses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final busDoc = buses[index];
              final busData = busDoc.data() as Map<String, dynamic>;

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
                        "${busData['from']} to ${busData['to']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Departure: ${busData['departureTime']}",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      Text(
                        "Driver: ${busData['driverName']} (${busData['numberPlate']})",
                        style: const TextStyle(color: Colors.black87),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Price: Rs ${busData['ticketPrice']}",
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
                                  date: "Today", // Ideally should pass selected date from previous screen
                                  fromCity: busData['from'],
                                  seat: 1, // Placeholder
                                  time: busData['departureTime'],
                                  toCity: busData['to'],
                                  fare: (busData['ticketPrice'] as num).toInt(),
                                  busId: busDoc.id,
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
          );
        },
      ),
    );
  }
}