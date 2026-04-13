import 'package:flutter/material.dart';
import 'package:nutt/admin/admin_login_screen.dart';
import 'package:nutt/user/login.dart';
import 'package:nutt/user/seats_selection.dart';
import 'package:nutt/user/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

// / 🔹 WELCOME SCREEN (WHITE + EMERALD)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 🔹 TOP TEXT
              Column(
                children: const [
                  Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Bus Ticket Booking App",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),

              /// 🔹 IMAGE
              Image.asset("assets/we.jpeg", height: 200),

              /// 🔹 BUTTONS
              Column(
                children: [
                  /// 🟢 ADMIN BUTTON (same size as others)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminLoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Admin",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => UserLogin()),
                        );
                      },
                      child: const Text(
                        "User",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
