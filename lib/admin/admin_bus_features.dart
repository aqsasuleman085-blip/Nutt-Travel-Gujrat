import 'package:flutter/material.dart';

//////////////////////////////////////////////////////////////
/// 🔥 GLOBAL BUS LIST (shared for all screens)
//////////////////////////////////////////////////////////////
List<Map<String, String>> buses = [
  {
    "name": "Daewoo Express",
    "number": "BUS101",
    "from": "Lahore",
    "to": "Islamabad",
    "fare": "2500",
  },
  {
    "name": "Faisal Movers",
    "number": "BUS205",
    "from": "Karachi",
    "to": "Lahore",
    "fare": "3200",
  },
];

//////////////////////////////////////////////////////////////
/// 🔹 ADD BUS SCREEN (FULL FUNCTIONAL)
//////////////////////////////////////////////////////////////
class AddBusScreen extends StatefulWidget {
  const AddBusScreen({super.key});

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  final driverController = TextEditingController();
  final contactController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final departureController = TextEditingController();
  final arrivalController = TextEditingController();
  final fareController = TextEditingController();

  void addBus() {
    setState(() {
      buses.add({
        "name": nameController.text,
        "number": numberController.text,
        "from": fromController.text,
        "to": toController.text,
        "fare": fareController.text,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bus Added Successfully")),
    );

    nameController.clear();
    numberController.clear();
    driverController.clear();
    contactController.clear();
    fromController.clear();
    toController.clear();
    departureController.clear();
    arrivalController.clear();
    fareController.clear();
  }

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Bus")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(nameController, "Bus Name"),
          _field(numberController, "Bus Number"),
          _field(driverController, "Driver Name"),
          _field(contactController, "Contact Number"),
          _field(fromController, "From City"),
          _field(toController, "To City"),
          _field(departureController, "Departure Time"),
          _field(arrivalController, "Arrival Time"),
          _field(fareController, "Fare"),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: addBus,
            icon: const Icon(Icons.add),
            label: const Text("ADD"),
          )
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 🔹 UPDATE BUS SCREEN (FULL FUNCTIONAL)
//////////////////////////////////////////////////////////////
class UpdateBusScreen extends StatefulWidget {
  const UpdateBusScreen({super.key});

  @override
  State<UpdateBusScreen> createState() => _UpdateBusScreenState();
}

class _UpdateBusScreenState extends State<UpdateBusScreen> {
  int? selectedIndex;

  final nameController = TextEditingController();
  final numberController = TextEditingController();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final fareController = TextEditingController();

  void fillForm(int index) {
    final bus = buses[index];

    nameController.text = bus["name"]!;
    numberController.text = bus["number"]!;
    fromController.text = bus["from"]!;
    toController.text = bus["to"]!;
    fareController.text = bus["fare"]!;

    setState(() {
      selectedIndex = index;
    });
  }

  void updateBus() {
    if (selectedIndex == null) return;

    setState(() {
      buses[selectedIndex!] = {
        "name": nameController.text,
        "number": numberController.text,
        "from": fromController.text,
        "to": toController.text,
        "fare": fareController.text,
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bus Updated Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Bus")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_bus),
                    title: Text(bus["name"]!),
                    subtitle: Text("${bus["from"]} → ${bus["to"]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => fillForm(index),
                    ),
                  ),
                );
              },
            ),
          ),

          if (selectedIndex != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
              ),
              child: Column(
                children: [
                  const Text(
                    "Edit Bus Details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  _field(nameController, "Bus Name"),
                  _field(numberController, "Bus Number"),
                  _field(fromController, "From"),
                  _field(toController, "To"),
                  _field(fareController, "Fare"),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: updateBus,
                    icon: const Icon(Icons.update),
                    label: const Text("Update"),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 🔹 DELETE BUS SCREEN (FULL FUNCTIONAL)
//////////////////////////////////////////////////////////////
class DeleteBusScreen extends StatefulWidget {
  const DeleteBusScreen({super.key});

  @override
  State<DeleteBusScreen> createState() => _DeleteBusScreenState();
}

class _DeleteBusScreenState extends State<DeleteBusScreen> {
  void deleteBus(int index) {
    setState(() {
      buses.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bus Deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delete Bus")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];

          return ListTile(
            leading: const Icon(Icons.directions_bus),
            title: Text("${bus["name"]} - ${bus["number"]}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteBus(index),
            ),
          );
        },
      ),
    );
  }
}