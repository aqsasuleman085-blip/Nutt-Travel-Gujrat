import 'package:flutter/material.dart';
import 'package:nutt/user/bus_schedule.dart';
import 'package:nutt/user/profile_screen.dart';
import 'package:nutt/user/tickets_screen.dart';

import '../services/bus_service.dart';

// 🔹 MAIN HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final Color themeColor = const Color(0xff10B981);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeTab(
        onTabChange: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      const TicketsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          selectedItemColor: themeColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number),
              label: "Tickets",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// 🔹 HOME TAB
class HomeTab extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeTab({super.key, required this.onTabChange});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final Color themeColor = const Color(0xff10B981);
  final BusService _busService = BusService();

  String fromCity = "Select City";
  String toCity = "Select Destination";
  DateTime? selectedDate;

  void selectCity(bool isFrom, List<String> options) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          color: Colors.white,
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: options.map((city) {
              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.location_city, color: themeColor),
                  title: Text(
                    city,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      if (isFrom) {
                        fromCity = city;
                        toCity = "Select Destination";
                      } else {
                        toCity = city;
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _monthName(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m - 1];
  }

  void swapCities() {
    setState(() {
      String temp = fromCity;
      fromCity = toCity;
      toCity = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder(
        stream: _busService.streamBuses(),
        builder: (context, snapshot) {
          final buses = snapshot.data ?? [];
          final dateFiltered = selectedDate == null
              ? buses
              : buses.where((b) => _isSameDay(b.departureAt, selectedDate!));

          final fromOptions = dateFiltered.map((b) => b.from).toSet().toList()
            ..sort();
          final toOptions =
              dateFiltered
                  .where((b) => fromCity == "Select City" || b.from == fromCity)
                  .map((b) => b.to)
                  .toSet()
                  .toList()
                ..sort();

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome to",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            "Nutt Travel Gujrat",
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // IconButton(
                      //   icon: Icon(
                      //     Icons.notifications_none,
                      //     size: 28,
                      //     color: themeColor,
                      //   ),
                      //   onPressed: () {
                      //     widget.onTabChange(2);
                      //   },
                      // ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Book Your Bus Now!",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeColor.withOpacity(0.3)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => selectCity(true, fromOptions),
                        child: buildField(fromCity, Icons.location_on),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: swapCities,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: themeColor,
                          child: const Icon(
                            Icons.swap_vert,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => selectCity(false, toOptions),
                        child: buildField(toCity, Icons.flag),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: selectDate,
                        child: buildField(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.day} ${_monthName(selectedDate!.month)} ${selectedDate!.year}",
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () {
                            if (fromCity == "Select City" ||
                                toCity == "Select Destination" ||
                                selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select route and date'),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusScheduleScreen(
                                  fromCity: fromCity,
                                  toCity: toCity,
                                  selectedDate: selectedDate!,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Find Schedule",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
