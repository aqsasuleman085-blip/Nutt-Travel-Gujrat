import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  int selectedIndex = 0; // 0 = Upcoming, 1 = Past

  // Your custom data (edit freely)
  final List<Map<String, String>> upcomingTickets = [
    {
      "bus": "Nutt Coach Service",
      "route": "Gujrat → Lahore",
      "date": "26 Apr 2026",
      "time": "10:00 AM",
      "seat": "A1",
      "id": "TX123"
    },
  ];

  final List<Map<String, String>> pastTickets = [
    {
      "bus": "Nutt Coach Service",
      "route": "Gujrat → Islamabad",
      "date": "20 Apr 2026",
      "time": "02:00 PM",
      "seat": "B3",
      "id": "TX456"
    },
  ];

  Widget buildTicketCard(Map<String, String> ticket) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket["bus"]!,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 6),
            Text(
              ticket["route"]!,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${ticket["date"]}"),
                Text("Time: ${ticket["time"]}"),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Seat: ${ticket["seat"]}"),
                Text("ID: ${ticket["id"]}"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("View"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildList(List<Map<String, String>> tickets) {
    if (tickets.isEmpty) {
      return const Center(child: Text("No tickets available"));
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        return buildTicketCard(tickets[index]);
      },
    );
  }

  Widget getCurrentScreen() {
    if (selectedIndex == 0) {
      return buildList(upcomingTickets);
    } else {
      return buildList(pastTickets);
    }
  }

  Widget buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildButton("Upcoming", 0),
          buildButton("Past Tickets", 1),
        ],
      ),
    );
  }

  Widget buildButton(String text, int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                selectedIndex == index ? Colors.blue : Colors.grey[300],
            foregroundColor:
                selectedIndex == index ? Colors.white : Colors.black,
          ),
          onPressed: () {
            setState(() {
              selectedIndex = index;
            });
          },
          child: Text(text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tickets Detail",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          buildTopButtons(),
          Expanded(child: getCurrentScreen()),
        ],
      ),
    );
  }
}