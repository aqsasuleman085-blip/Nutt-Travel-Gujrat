import 'package:flutter/material.dart';
import 'package:nutt/admin/admin_profile_screen.dart';
import 'package:nutt/admin/booking_module.dart';
import 'package:nutt/admin/routes_screen.dart';
import 'package:nutt/admin/admin_buses_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const DashboardHome(),
    const AdminBusesScreen(),
    const RoutesScreen(),
    const BookingModule(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: "Buses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: "Routes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: "Bookings",
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

// ================= DASHBOARD HOME =================

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 🔷 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4facfe), Color(0xff6a11cb)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 🔷 SMALL CARDS (UNCHANGED)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: const [
                SmallCard("Users", "1,200", Icons.people, Colors.blue),
                SmallCard("Trips", "85", Icons.directions_bus, Colors.orange),
                SmallCard("Earnings", "50K", Icons.attach_money, Colors.green),
                SmallCard("Bookings", "320", Icons.book, Colors.purple),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 🔷 FEATURE CARDS (Users REMOVED ONLY)
          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                FeatureCard("Buses", Icons.directions_bus, Colors.orange),
                FeatureCard("Bookings", Icons.book_online, Colors.purple),
                FeatureCard("Payments", Icons.payment, Colors.green),
                FeatureCard("Notify", Icons.notifications, Colors.red),
                FeatureCard("Routes", Icons.route, Colors.amber),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ================= SMALL CARD =================

class SmallCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SmallCard(this.title, this.value, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ================= FEATURE CARD =================

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const FeatureCard(this.title, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}