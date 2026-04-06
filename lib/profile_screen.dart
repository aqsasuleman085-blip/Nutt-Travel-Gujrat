import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage("assets/profile.png"),
          ),

          const SizedBox(height: 10),

          const Text("Aqsa Suleman",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          const Text("aqsa@email.com",
              style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),

          buildTile(Icons.person, "Edit Profile"),
          buildTile(Icons.history, "My Bookings"),
          buildTile(Icons.notifications, "Notifications"),
          buildTile(Icons.help, "Help & Support"),
          buildTile(Icons.logout, "Logout"),
        ],
      ),
    );
  }

  Widget buildTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}