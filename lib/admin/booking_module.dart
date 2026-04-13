import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BookingModule(),
    );
  }
}

// ================= MAIN SCREEN =================

class BookingModule extends StatefulWidget {
  const BookingModule({super.key});

  @override
  State<BookingModule> createState() => _BookingModuleState();
}

class _BookingModuleState extends State<BookingModule> {
  List<Map<String, String>> buses = [
    {
      "busName": "Daewoo Express",
      "route": "Lahore → Islamabad",
      "time": "10:00 AM",
      "seats": "40 Seats",
      "price": "1500",
    },
    {
      "busName": "Faisal Movers",
      "route": "Gujrat → Lahore",
      "time": "02:00 PM",
      "seats": "35 Seats",
      "price": "1200",
    },
  ];

  // ➕ ADD + ✏️ EDIT
  void openForm({Map<String, String>? bus, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBusScreen(bus: bus),
      ),
    );

    if (result != null) {
      setState(() {
        if (index == null) {
          // ➕ ADD NEW CARD
          buses.add(result);
        } else {
          // ✏️ UPDATE EXISTING CARD
          buses[index] = result;
        }
      });
    }
  }

  // ❌ DELETE
  void deleteBus(int index) {
    setState(() {
      buses.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buses Management"),
        backgroundColor: Colors.blue,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () => openForm(),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];

          return BusCard(
            busName: bus["busName"]!,
            route: bus["route"]!,
            time: bus["time"]!,
            seats: bus["seats"]!,
            price: bus["price"]!,
            onEdit: () => openForm(bus: bus, index: index),
            onDelete: () => deleteBus(index),
          );
        },
      ),
    );
  }
}

// ================= BUS CARD =================

class BusCard extends StatelessWidget {
  final String busName;
  final String route;
  final String time;
  final String seats;
  final String price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BusCard({
    super.key,
    required this.busName,
    required this.route,
    required this.time,
    required this.seats,
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            busName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.route, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(route),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(time),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(seats),
              Text(
                "Rs. $price",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onEdit,
                child: const Text("Edit"),
              ),
              TextButton(
                onPressed: onDelete,
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ================= ADD / EDIT SCREEN =================

class AddEditBusScreen extends StatefulWidget {
  final Map<String, String>? bus;

  const AddEditBusScreen({super.key, this.bus});

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  late TextEditingController busName;
  late TextEditingController route;
  late TextEditingController time;
  late TextEditingController seats;
  late TextEditingController price;

  @override
  void initState() {
    super.initState();

    busName = TextEditingController(text: widget.bus?["busName"] ?? "");
    route = TextEditingController(text: widget.bus?["route"] ?? "");
    time = TextEditingController(text: widget.bus?["time"] ?? "");
    seats = TextEditingController(text: widget.bus?["seats"] ?? "");
    price = TextEditingController(text: widget.bus?["price"] ?? "");
  }

  void save() {
    if (busName.text.isEmpty || route.text.isEmpty) return;

    Navigator.pop(context, {
      "busName": busName.text,
      "route": route.text,
      "time": time.text,
      "seats": seats.text,
      "price": price.text,
    });
  }

  Widget field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bus == null ? "Add Booking" : "Edit Booking"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            field(busName, "Bus Name"),
            field(route, "Route"),
            field(time, "Time"),
            field(seats, "Seats"),
            field(price, "Price"),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              child: Text(widget.bus == null ? "Add Booking" : "Update Booking"),
            )
          ],
        ),
      ),
    );
  }
}