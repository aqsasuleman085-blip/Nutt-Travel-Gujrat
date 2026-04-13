import 'package:flutter/material.dart';
import 'package:nutt/admin/dashboard.dart';
import 'package:nutt/admin/welcome_screen.dart';
import 'package:nutt/user/buses_screen.dart';
import 'package:nutt/user/button.dart';
import 'package:nutt/user/login.dart';
import 'package:nutt/user/profile_screen.dart';
import 'package:nutt/user/signup.dart';
import 'package:nutt/user/home_screen.dart';

void main() {
  runApp(const MyApp());
}

/// 💚 EMERALD GREEN THEME COLOR
const Color emeraldGreen = Color(0xFF10B981);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      routes: {
        '/home': (context) => HomeScreen(),
        '/buses': (context) => BusesScreen(),
        '/profile': (context) => ProfileScreen(),
      },

      home: WelcomeScreen(),
    );
  }
}

/// 🔹 WELCOME SCREEN (WHITE + EMERALD)
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,

//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(30),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               /// 🔹 TOP TEXT
//               Column(
//                 children: const [
//                   Text(
//                     "Welcome",
//                     style: TextStyle(
//                       fontSize: 30,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     "Bus Ticket Booking App",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.green),
//                   ),
//                 ],
//               ),

//               /// 🔹 IMAGE
//               Image.asset("assets/we.jpeg", height: 200),

//               /// 🔹 BUTTONS
//               Column(
//                 children: [
//                   /// 🟢 ADMIN BUTTON (same size as others)
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: emeraldGreen,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => AdminDashboard(),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Admin",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   /// 🔹 LOGIN BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: OutlinedButton(
//                       style: OutlinedButton.styleFrom(
//                         side: const BorderSide(color: emeraldGreen),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => UserLogin(),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Login",
//                         style: TextStyle(color: emeraldGreen),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   /// 🔹 SIGNUP BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: emeraldGreen,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => SignupPage(),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Sign Up",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
