import 'package:flutter/material.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  int selectedIndex = 0; // 0 = Upcoming, 1 = Past

  // 🔹 Sample ticket data
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
      color: Color(0xff203A43),
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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent.shade700.withOpacity(0.9)),
            ),
            const SizedBox(height: 6),
            Text(
              ticket["route"]!,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date: ${ticket["date"]}", style: TextStyle(color: Colors.white70)),
                Text("Time: ${ticket["time"]}", style: TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Seat: ${ticket["seat"]}", style: TextStyle(color: Colors.white70)),
                Text("ID: ${ticket["id"]}", style: TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700.withOpacity(0.9),
                  ),
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
      return const Center(
        child: Text(
          "No tickets available",
          style: TextStyle(color: Colors.white70),
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
        children: [
          buildButton("Upcoming", 0),
          buildButton("Past Tickets", 1),
        ],
      ),
    );
  }

  Widget buildButton(String text, int index) {
    bool isSelected = selectedIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.tealAccent.shade700.withOpacity(0.9)
                : Colors.grey[700],
            foregroundColor: isSelected ? Colors.white : Colors.white70,
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Tickets Detail",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color:  Colors.tealAccent.shade700.withOpacity(0.9), // ✅ updated color
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
      ),
    );
  }
}