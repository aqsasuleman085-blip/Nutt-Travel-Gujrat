import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final Color themeColor = const Color(0xff10B981);

  Widget buildStatus(String status) {
    Color color;
    IconData? icon;

    switch (status) {
      case "approved":
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case "rejected":
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildTicketCard(Map<String, dynamic> ticket, String ticketId) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: themeColor.withOpacity(0.3)),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nutt Coach Service",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${ticket["busFrom"]} → ${ticket["busTo"]}",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date: ${ticket["date"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Time: ${ticket["time"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Seat: ${ticket["seat"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Flexible(
                  child: Text(
                    "ID: $ticketId",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  "Fare: Rs ${ticket["price"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                buildStatus(ticket["status"] ?? "pending"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildTopButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {},
              child: const Text("My Tickets"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Tickets Detail",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        iconTheme: IconThemeData(color: themeColor),
      ),

      body: Column(
        children: [
          buildTopButton(),
          Expanded(
            child: userUid == null
                ? const Center(child: Text("Please log in to view tickets"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('userUid', isEqualTo: userUid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const Center(child: Text("Error fetching tickets"));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No tickets available",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final tickets = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {
                          final doc = tickets[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return buildTicketCard(data, doc.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}