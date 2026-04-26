import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final Color themeColor = const Color(0xff10B981);

  final List<Map<String, String>> tickets = [
    {
      "bus": "Nutt Coach Service",
      "route": "Gujrat → Lahore",
      "date": "26 Apr 2026",
      "time": "10:00 AM",
      "seat": "A1",
      "id": "TX123",
      "status": "pending"
    },
    {
      "bus": "Nutt Coach Service",
      "route": "Gujrat → Islamabad",
      "date": "20 Apr 2026",
      "time": "02:00 PM",
      "seat": "B3",
      "id": "TX456",
      "status": "approved"
    },
    {
      "bus": "Nutt Coach Service",
      "route": "Lahore → Multan",
      "date": "18 Apr 2026",
      "time": "01:00 PM",
      "seat": "C2",
      "id": "TX789",
      "status": "rejected"
    },
  ];

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
        icon = null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, color: color, size: 18),
        if (icon != null) const SizedBox(width: 4),
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

  Widget buildTicketCard(Map<String, String> ticket) {
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
              ticket["bus"]!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ticket["route"]!,
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
                Text(
                  "ID: ${ticket["id"]}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                buildStatus(ticket["status"]!),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildList() {
    if (tickets.isEmpty) {
      return const Center(
        child: Text(
          "No tickets available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        return buildTicketCard(tickets[index]);
      },
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
              child: const Text("Current"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      //s

      body: Column(
        children: [
          buildTopButton(),
          Expanded(child: buildList()),
        ],
      ),
    );
  }
}