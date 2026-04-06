import 'package:flutter/material.dart';
import 'package:nutt/buses_screen.dart';
import 'package:nutt/login.dart';
import 'package:nutt/profile_screen.dart';
import 'package:nutt/signup.dart';
import 'package:nutt/home_screen.dart';

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
      body: SafeArea(
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
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("Bus Ticket Booking App", textAlign: TextAlign.center),
                ],
              ),

              // 🔹 Image
              Image.asset("assets/welcome.png", height: 200),

              // 🔹 Buttons
              Column(
                children: [
                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: const Text("Login"),
                  ),

                  const SizedBox(height: 20),

                  MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    color: Colors.blue,
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
