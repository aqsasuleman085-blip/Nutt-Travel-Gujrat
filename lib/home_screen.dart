import 'package:flutter/material.dart';

// 🔹 MAIN HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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

  void selectCity(bool isFrom) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          children: cities.map((city) {
            return ListTile(
              title: Text(city),
              onTap: () {
                setState(() {
                  isFrom ? fromCity = city : toCity = city;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
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
        date = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
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
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number), label: "Tickets"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus), label: "Buses"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// 🔹 HOME TAB (WITH FORM)
class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
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
        return ListView(
          children: cities.map((city) {
            return ListTile(
              title: Text(city),
              onTap: () {
                setState(() {
                  isFrom ? fromCity = city : toCity = city;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
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
        date = "${picked.day}-${picked.month}-${picked.year}";
      });
    }
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFF5F7FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome to", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        Text("Nutt Travel Gujrat",
                            style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                        icon: Icon(Icons.notifications_none, color: Colors.black),
                        onPressed: () {}),
                  ],
                ),
              ),

              // Animated Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                              offset: Offset(_animation.value, 0),
                              child: Icon(Icons.directions_bus, color: Colors.white, size: 30)),
                          SizedBox(width: 10),
                          Text("Book Your Bus Now!",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // Main Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                        onTap: () => selectCity(true),
                        child: buildField("From", fromCity)),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: swapCities,
                      child: CircleAvatar(radius: 20, backgroundColor: Colors.blue, child: Icon(Icons.swap_vert, color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                        onTap: () => selectCity(false),
                        child: buildField("To", toCity)),
                    SizedBox(height: 10),
                    GestureDetector(
                        onTap: selectDate,
                        child: buildField("Date", date)),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          if (fromCity == "Select City" ||
                              toCity == "Select Destination" ||
                              date == "Select Date") {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text("Please fill all fields")));
                            return;
                          }
                          Navigator.pushNamed(context, '/buses');
                        },
                        child: Text("Find Schedules", style: TextStyle(fontSize: 18)),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(String title, String value) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(color: Colors.grey[600])),
          Expanded(
              child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

// 🔹 Placeholder Screens
class TicketsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Tickets Screen", style: TextStyle(fontSize: 24)));
  }
}

class BusesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Buses Screen", style: TextStyle(fontSize: 24)));
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Profile Screen", style: TextStyle(fontSize: 24)));
  }
}