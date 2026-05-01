import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/bus_service.dart';
import 'seats_selection.dart';

class BusScheduleScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime selectedDate;

  const BusScheduleScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.selectedDate,
  });

  @override
  _BusScheduleScreenState createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen> {
  int selectedIndex = 0;
  final BusService _busService = BusService();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final diff = widget.selectedDate.difference(
      DateTime(today.year, today.month, today.day),
    );
    final index = diff.inDays;
    if (index >= 0 && index < 7) {
      selectedIndex = index;
    }
  }

  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green

  List<DateTime> get dates =>
      List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

  @override
  Widget build(BuildContext context) {
    final selectedDate = dates[selectedIndex];

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
            child: StreamBuilder(
              stream: _busService.streamBuses(),
              builder: (context, snapshot) {
                final buses = snapshot.data ?? [];
                final filtered = buses.where((bus) {
                  if (bus.from != widget.fromCity || bus.to != widget.toCity) {
                    return false;
                  }
                  if (!_isSameDay(bus.departureAt, selectedDate)) {
                    return false;
                  }
                  if (bus.departureAt.isBefore(DateTime.now())) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "No buses available",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildBusCard(filtered[index]);
                  },
                );
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
  Widget _buildBusCard(bus) {
    final dateText = DateFormat('yyyy-MM-dd').format(bus.departureAt);
    final timeText = DateFormat('HH:mm').format(bus.departureAt);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeatSelectionScreen(
              busId: bus.id,
              date: dateText,
              fromCity: bus.from,
              time: timeText,
              toCity: bus.to,
              fare: bus.ticketPrice.toInt(),
              totalSeats: bus.totalSeats,
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
                  timeText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Rs ${bus.ticketPrice.toStringAsFixed(0)}",
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
              '${bus.from} → ${bus.to}',
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
                _infoChip(Icons.event_seat, "${bus.totalSeats} Seats"),
                _infoChip(Icons.calendar_today, dateText),
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
