import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutt/user/seats_selection.dart';

class BusScheduleScreen extends StatefulWidget {
  @override
  _BusScheduleScreenState createState() => _BusScheduleScreenState();
}

//file
class _BusScheduleScreenState extends State<BusScheduleScreen> {
  int selectedIndex = 0;

  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green

  List<DateTime> dates = List.generate(
    7,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  Map<String, List<Map<String, dynamic>>> busData = {
    "0": [
      {
        "time": "08:00 AM",
        "route": "Karachi → Multan",
        "type": "AC",
        "seats": 40,
        "duration": "12h",
        "price": 4500,
      },
      {
        "time": "02:00 PM",
        "route": "Karachi → Lahore",
        "type": "Non-AC",
        "seats": 45,
        "duration": "14h",
        "price": 3500,
      },
    ],
    "1": [
      {
        "time": "10:00 AM",
        "route": "Karachi → Islamabad",
        "type": "AC",
        "seats": 38,
        "duration": "16h",
        "price": 6000,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    String key = selectedIndex.toString();
    List buses = busData[key] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          "Bus Schedule",
          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),

      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 10),
          Expanded(
            child: buses.isEmpty
                ? const Center(
                    child: Text(
                      "No buses available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      return _buildBusCard(buses[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🔹 DATE SELECTOR
  Widget _buildDateSelector() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  // 🔹 BUS CARD
  Widget _buildBusCard(Map bus) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeatSelectionScreen(
              date: "Selected",
              fromCity: "Guj",
              time: bus["time"],
              toCity: "Fas",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: themeColor.withOpacity(0.3)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bus["time"],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Rs ${bus["price"]}",
                  style: TextStyle(
                    fontSize: 16,
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Route
            Text(
              bus["route"],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            // Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoChip(Icons.ac_unit, bus["type"]),
                _infoChip(Icons.event_seat, "${bus["seats"]} Seats"),
                _infoChip(Icons.timer, bus["duration"]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 INFO CHIP
  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: themeColor),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
