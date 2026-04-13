import 'package:flutter/material.dart';

// /// 🔥 LEGEND (UNCHANGED)
class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.event_seat, size: 18, color: color),
        SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }
}
