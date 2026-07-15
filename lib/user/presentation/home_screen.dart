import 'package:flutter/material.dart';
import 'package:nutt/user/presentation/bus_schedule.dart';
import 'package:nutt/user/presentation/profile_screen.dart';
import 'package:nutt/user/presentation/tickets_screen.dart';
import 'package:nutt/user/presentation/ask_question_screen.dart';
import 'package:nutt/user/services/notification_service.dart';
import 'notification_screen.dart';
import 'pakistani_cities.dart';
import 'themed_date_picker.dart';

import '../../services/bus_service.dart';

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
  final UserNotificationService _notificationService =
      UserNotificationService();

  String fromCity = "Select City";
  String toCity = "Select Destination";
  DateTime? selectedDate;

  void selectCity(bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CityPickerSheet(
          themeColor: themeColor,
          title: isFrom ? 'Select Departure City' : 'Select Destination',
          cities: kPakistaniCities,
          excludeCity: isFrom ? null : (fromCity == "Select City" ? null : fromCity),
          onSelected: (city) {
            setState(() {
              if (isFrom) {
                fromCity = city;
                // Reset destination if it now matches the new departure.
                if (toCity == city) {
                  toCity = "Select Destination";
                }
              } else {
                toCity = city;
              }
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void selectDate() async {
    DateTime? picked = await showThemedDatePicker(
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

          // Whether at least one bus exists for the exact From -> To route
          // on the selected date. Only meaningful once all three fields
          // are picked; used purely for the inline hint below the date
          // field, not for filtering the city pickers themselves.
          bool? routeHasBuses;
          if (fromCity != "Select City" &&
              toCity != "Select Destination" &&
              selectedDate != null) {
            routeHasBuses = buses.any(
              (b) =>
                  citiesMatch(b.from, fromCity) &&
                  citiesMatch(b.to, toCity) &&
                  _isSameDay(b.departureAt, selectedDate!),
            );
          }

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
                      // Notification Icon (with badge) + Ask a Question icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StreamBuilder<int>(
                            stream: _notificationService.streamUnreadCount(),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.notifications_none,
                                      size: 28,
                                      color: themeColor,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsScreen(),
                                        ),
                                      ).then((_) {
                                        // Refresh the badge count when returning from notifications screen
                                        setState(() {});
                                      });
                                    },
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          unreadCount > 99 ? '99+' : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          // Ask a Question - lets the user send a query
                          // directly to admin support (separate from the
                          // one-way notification bell above).
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              size: 26,
                              color: themeColor,
                            ),
                            tooltip: 'Ask a Question',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AskQuestionScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
                        onTap: () => selectCity(true),
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
                        onTap: () => selectCity(false),
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
                      if (routeHasBuses != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: routeHasBuses
                                ? themeColor.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: routeHasBuses
                                  ? themeColor.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                routeHasBuses
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                size: 16,
                                color: routeHasBuses
                                    ? themeColor
                                    : Colors.orange[800],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  routeHasBuses
                                      ? 'Buses are available for this route on this date'
                                      : 'No buses are going to that route on this date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: routeHasBuses
                                        ? themeColor
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

/// Bottom sheet for picking a city from the full Pakistani cities list,
/// with a search box since the list is long (~30 cities). If
/// [excludeCity] is provided (the already-picked departure city), it's
/// filtered out of the destination list so a user can't pick the same
/// city for both fields.
class _CityPickerSheet extends StatefulWidget {
  final Color themeColor;
  final String title;
  final List<String> cities;
  final String? excludeCity;
  final ValueChanged<String> onSelected;

  const _CityPickerSheet({
    required this.themeColor,
    required this.title,
    required this.cities,
    required this.onSelected,
    this.excludeCity,
  });

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.cities
        .where((c) => c != widget.excludeCity)
        .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.themeColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                              autofocus: false,
                              decoration: const InputDecoration(
                                hintText: 'Search city',
                                hintStyle: TextStyle(fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) {
                                setState(() => _query = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No city matches your search',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final city = filtered[index];
                          return ListTile(
                            leading: Icon(
                              Icons.location_city,
                              color: widget.themeColor,
                            ),
                            title: Text(
                              city,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => widget.onSelected(city),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
