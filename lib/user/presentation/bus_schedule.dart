import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/bus_service.dart';
import 'pakistani_cities.dart';
import 'seats_selection.dart';

enum _SortOption { priceLowHigh, priceHighLow, timeEarliest, timeLatest }

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.timeEarliest;

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

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green

  List<DateTime> get dates =>
      List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

  List<dynamic> _applySearchAndSort(List<dynamic> buses) {
    var result = buses;

    if (_searchQuery.isNotEmpty) {
      result = result.where((bus) {
        final driver = bus.driverName.toString().toLowerCase();
        final plate = bus.numberPlate.toString().toLowerCase();
        return driver.contains(_searchQuery) || plate.contains(_searchQuery);
      }).toList();
    }

    result = List.from(result);
    switch (_sortOption) {
      case _SortOption.priceLowHigh:
        result.sort((a, b) => a.ticketPrice.compareTo(b.ticketPrice));
        break;
      case _SortOption.priceHighLow:
        result.sort((a, b) => b.ticketPrice.compareTo(a.ticketPrice));
        break;
      case _SortOption.timeEarliest:
        result.sort((a, b) => a.departureAt.compareTo(b.departureAt));
        break;
      case _SortOption.timeLatest:
        result.sort((a, b) => b.departureAt.compareTo(a.departureAt));
        break;
    }
    return result;
  }

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
          const SizedBox(height: 6),
          _buildSearchAndSortBar(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: _busService.streamBuses(),
              builder: (context, snapshot) {
                final buses = snapshot.data ?? [];
                final filtered = buses.where((bus) {
                  if (!citiesMatch(bus.from, widget.fromCity) ||
                      !citiesMatch(bus.to, widget.toCity)) {
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

                final sorted = _applySearchAndSort(filtered);

                if (sorted.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_bus_filled_outlined,
                            size: 56,
                            color: themeColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "No buses match your search"
                                : "No buses are going to that route on this date",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${widget.fromCity} → ${widget.toCity} on '
                              '${DateFormat('dd MMM yyyy').format(selectedDate)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different date or route.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    return _buildBusCard(sorted[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 SEARCH + SORT BAR
  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by driver or bus number',
                        hintStyle: TextStyle(fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_SortOption>(
                value: _sortOption,
                icon: Icon(Icons.sort, color: themeColor, size: 20),
                borderRadius: BorderRadius.circular(10),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortOption = value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: _SortOption.timeEarliest,
                    child: Text('Earliest first'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.timeLatest,
                    child: Text('Latest first'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.priceLowHigh,
                    child: Text('Price: Low to High'),
                  ),
                  DropdownMenuItem(
                    value: _SortOption.priceHighLow,
                    child: Text('Price: High to Low'),
                  ),
                ],
              ),
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

    final double avgRating = bus.averageRating;
    final int ratingCount = bus.ratingCount;

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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bus image header (illustrated, works fully offline)
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withOpacity(0.25),
                    themeColor.withOpacity(0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.directions_bus_rounded,
                  size: 44,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
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

                  const SizedBox(height: 8),

                  // Rating row
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: ratingCount > 0
                            ? Colors.amber
                            : Colors.grey.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingCount > 0
                            ? '${avgRating.toStringAsFixed(1)} ($ratingCount review${ratingCount == 1 ? '' : 's'})'
                            : 'No reviews yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
