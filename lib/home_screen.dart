import 'package:flutter/material.dart';
import 'package:nutt/buses_screen.dart';
import 'package:nutt/profile_screen.dart';
import 'package:nutt/tickets_screen.dart';
import 'bus_schedule_screen.dart'; // ✅ New schedule screen

// 🔹 MAIN HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Widget> _pages = [
    HomeTab(),
    TicketsScreen(),
    BusesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
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
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor:
                Colors.tealAccent.shade700.withOpacity(0.9),
            unselectedItemColor: Colors.white70,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number), label: "Tickets"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.directions_bus), label: "Buses"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
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

class _HomeTabState extends State<HomeTab>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void selectCity(bool isFrom) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: cities.map((city) {
              return Card(
                color: Color(0xff203A43),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.location_city,
                      color: Colors.tealAccent.shade700.withOpacity(0.9)),
                  title: Text(
                    city,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 320,
              child: child!,
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        date = "${picked.day} ${_monthName(picked.month)} ${picked.year}";
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
      "Dec"
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
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔹 Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome to",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        Text("Nutt Travel Gujrat",
                            style: TextStyle(
                              color: Colors.tealAccent.shade700.withOpacity(0.9),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none,
                          size: 28, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 🔹 Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.shade700.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(_animation.value, 0),
                            child: const Icon(Icons.directions_bus,
                                color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 10),
                          const Text("Book Your Bus Now!",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Booking Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff203A43),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                        onTap: () => selectCity(true),
                        child: buildField(fromCity, Icons.location_on)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: swapCities,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.tealAccent.shade700.withOpacity(0.9),
                        child: const Icon(Icons.swap_vert, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                        onTap: () => selectCity(false),
                        child: buildField(toCity, Icons.flag)),
                    const SizedBox(height: 10),
                    GestureDetector(
                        onTap: selectDate,
                        child: buildField(date, Icons.calendar_today)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (fromCity == "Select City" ||
                              toCity == "Select Destination" ||
                              date == "Select Date") {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Please fill all fields")));
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusScheduleScreen(
                                fromCity: fromCity,
                                toCity: toCity,
                                date: date,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text("Find Schedules"),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.tealAccent.shade700.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xff2C5364),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.tealAccent.shade700.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent.shade700.withOpacity(0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
        ],
      ),
    );
  }
}