import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xff10B981),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref("user_notifications/$uid")
            .onValue,

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final event = snapshot.data!;
          final data = event.snapshot.value;

          if (data == null) {
            return const Center(
              child: Text("No Notifications"),
            );
          }

          final notifications = Map<dynamic, dynamic>.from(data as Map);

          final items = notifications.entries.toList();

          items.sort((a, b) =>
              b.value["createdAt"].compareTo(a.value["createdAt"]));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].value;

              return Container(
             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             padding: const EdgeInsets.all(14),
             decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
              BoxShadow(
               color: Colors.black12,
               blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
       ),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      CircleAvatar(
        radius: 22,
        backgroundColor:
            item["title"].toString().contains("Rejected")
                ? Colors.red.shade100
                : Colors.green.shade100,
        child: Icon(
          item["title"].toString().contains("Rejected")
              ? Icons.cancel
              : Icons.check_circle,
          color: item["title"].toString().contains("Rejected")
              ? Colors.red
              : Colors.green,
        ),
      ),
      const SizedBox(width: 12),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item["title"],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item["message"],
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
            },
          );
        },
      ),
    );
  }
}