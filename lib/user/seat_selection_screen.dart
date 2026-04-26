import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

///  Emerald Green Theme App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color emeraldGreen =  Color(0xff10B981);
  static const Color softWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: softWhite,
        primaryColor: emeraldGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: LegendItem(
            color: MyApp.emeraldGreen,
            text: "Available Seat",
          ),
        ),
      ),
    );
  }
}

/// 🔥 LEGEND ITEM (UPDATED THEME)
class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({
    super.key,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.event_seat,
          size: 22,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}