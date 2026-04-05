import 'package:flutter/material.dart';
import 'package:nutt/login.dart';
import 'package:nutt/Mysignup.dart';
import 'package:nutt/home_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutt coach',
      initialRoute: '/',
      routes: {
        '/': (context) => MyLogin(),
        '/login': (context) => MyLogin(),
        '/signup': (context) => Mysignup(),
        '/home': (context) => HomeScreen(),
        
      },
    ),
  );
}
