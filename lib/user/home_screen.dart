import 'package:flutter/material.dart';
import 'package:nutt/user/bus_schedule.dart';
import 'package:nutt/user/profile_screen.dart';
import 'package:nutt/user/tickets_screen.dart';

// 🔹 MAIN HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final Color themeColor = const Color(0xff10B981);

  final List<Widget> _pages = [
    HomeTab(),
    TicketsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// 🔹 NOTIFICATION SCREEN (NEW)
class NotificationScreen extends StatelessWidget {
  final Color themeColor = const Color(0xff10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: themeColor),
        titleTextStyle: TextStyle(
          color: themeColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: const Center(
        child: Text(
          "No Notifications Yet",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}

// 🔹 HOME TAB
class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final Color themeColor = const Color(0xff10B981);

  String fromCity = "Select City";
  String toCity = "Select Destination";
  String date = "Select Date";

  List<String> cities = [
    "Lahore",
    "Karachi",
    "Islamabad",
    "Multan",
    "Gujrat",
    "Sialkot",
    "Abbottabad",
  ];

  void selectCity(bool isFrom) {
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
            children: cities.map((city) {
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
                      isFrom ? fromCity = city : toCity = city;
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
        date = "${picked.day} ${_monthName(picked.month)} ${picked.year}";
      });
    }
  }

  String _monthName(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec",
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome to",
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                  IconButton(
                    icon: Icon(Icons.notifications_none,
                        size: 28, color: themeColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // BANNER
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
                    Icon(Icons.directions_bus, color: Colors.white, size: 30),
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

            // BOOKING CARD
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
                      child: const Icon(Icons.swap_vert, color: Colors.white),
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
                    child: buildField(date, Icons.calendar_today),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusScheduleScreen(),
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
          const Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}