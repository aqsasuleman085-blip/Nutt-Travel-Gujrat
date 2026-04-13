import 'package:flutter/material.dart';
import 'package:nutt/admin/dashboard.dart';
import 'package:nutt/user/buses_screen.dart';
import 'package:nutt/user/button.dart';
import 'package:nutt/user/login.dart';
import 'package:nutt/user/profile_screen.dart';
import 'package:nutt/user/signup.dart';
import 'package:nutt/user/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔹 ROUTES (All Screens Registered)
      routes: {
        '/home': (context) => HomeScreen(),
        '/buses': (context) => BusesScreen(),
        '/profile': (context) => ProfileScreen(),
      },

      home: HomePage(),
    );
  }
}

// 🔹 WELCOME SCREEN
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0F2027), Color(0xff203A43), Color(0xff2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔹 Top Text
                Column(
                  children: const [
                    Text(
                      "Welcome",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color for dark background
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Bus Ticket Booking App",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                // 🔹 Image
                Image.asset("assets/welcome.webp", height: 200),

                // 🔹 Buttons
                Column(
                  children: [
                    AppButton(
                      text: 'Admin',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminDashboard(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    // 🔹 Login Button
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 60,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserLogin()),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.transparent,
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Sign Up Button
                    MaterialButton(
                      minWidth: double.infinity,
                      height: 60,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.tealAccent.shade700.withOpacity(0.9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
