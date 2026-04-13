import 'package:flutter/material.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, String>> routes = [
    {"from": "Lahore", "to": "Islamabad", "time": "3h 45m"},
    {"from": "Gujrat", "to": "Lahore", "time": "1h 30m"},
    {"from": "Karachi", "to": "Hyderabad", "time": "2h"},
    {"from": "Islamabad", "to": "Lahore", "time": "3h 30m"},
  ];

  String searchText = "";
  String selectedFilter = "All";

  final fromController = TextEditingController();
  final toController = TextEditingController();
  final timeController = TextEditingController();

  // ================= FILTER LOGIC =================
  List<Map<String, String>> get filteredRoutes {
    return routes.where((r) {
      final from = r["from"]!.toLowerCase();
      final to = r["to"]!.toLowerCase();

      final matchSearch = from.contains(searchText.toLowerCase()) ||
          to.contains(searchText.toLowerCase());

      final matchFilter = selectedFilter == "All" ||
          from == selectedFilter.toLowerCase() ||
          to == selectedFilter.toLowerCase();

      return matchSearch && matchFilter;
    }).toList();
  }

  // ================= ADD =================
  void addRouteDialog() {
    fromController.clear();
    toController.clear();
    timeController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Route"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(labelText: "From"),
            ),
            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: "To"),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Duration"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                routes.add({
                  "from": fromController.text,
                  "to": toController.text,
                  "time": timeController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================= UPDATE =================
  void openUpdateDialog(int index) {
    final route = filteredRoutes[index];

    fromController.text = route["from"]!;
    toController.text = route["to"]!;
    timeController.text = route["time"]!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Route"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(labelText: "From"),
            ),
            TextField(
              controller: toController,
              decoration: const InputDecoration(labelText: "To"),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "Duration"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                int realIndex = routes.indexOf(route);
                routes[realIndex] = {
                  "from": fromController.text,
                  "to": toController.text,
                  "time": timeController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================
  void deleteRoute(int index) {
    final route = filteredRoutes[index];

    setState(() {
      routes.remove(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff6dd5ed), Color(0xff2193b0)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                "Route Management",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),

            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search routes...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ⚙️ FILTER DROPDOWN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All Routes")),
                    DropdownMenuItem(value: "Lahore", child: Text("Lahore")),
                    DropdownMenuItem(value: "Islamabad", child: Text("Islamabad")),
                    DropdownMenuItem(value: "Karachi", child: Text("Karachi")),
                    DropdownMenuItem(value: "Gujrat", child: Text("Gujrat")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ➕ ADD CARD ONLY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: actionCard(Icons.add, "Add Route", Colors.green, addRouteDialog),
            ),

            const SizedBox(height: 15),

            // LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredRoutes.length,
                itemBuilder: (context, index) {
                  final r = filteredRoutes[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text("${r["from"]} → ${r["to"]}"),
                      subtitle: Text("Duration: ${r["time"]}"),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => openUpdateDialog(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteRoute(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ADD CARD UI =================
  Widget actionCard(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}