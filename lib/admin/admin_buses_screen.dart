import 'package:flutter/material.dart';
import 'admin_bus_features.dart';

class AdminBusesScreen extends StatefulWidget {
  const AdminBusesScreen({super.key});

  @override
  State<AdminBusesScreen> createState() => _AdminBusesScreenState();
}

class _AdminBusesScreenState extends State<AdminBusesScreen> {
  String filterType = "name";
  TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> buses = [
    {
      "name": "Daewoo Express",
      "number": "BUS-101",
      "from": "Lahore",
      "to": "Islamabad",
      "departure": "08:00 AM",
      "arrival": "12:30 PM",
      "fare": "2500",
      "status": "Active",
      "city": "Lahore"
    },
    {
      "name": "Faisal Movers",
      "number": "BUS-205",
      "from": "Karachi",
      "to": "Lahore",
      "departure": "09:00 AM",
      "arrival": "05:00 PM",
      "fare": "3200",
      "status": "Active",
      "city": "Karachi"
    },
    {
      "name": "Road Master",
      "number": "BUS-309",
      "from": "Multan",
      "to": "Faisalabad",
      "departure": "10:00 AM",
      "arrival": "01:00 PM",
      "fare": "1800",
      "status": "Inactive",
      "city": "Multan"
    },
  ];

  List<Map<String, String>> get filteredBuses {
    String query = searchController.text.toLowerCase();

    if (query.isEmpty) return buses;

    return buses.where((bus) {
      if (filterType == "name") {
        return bus["name"]!.toLowerCase().contains(query);
      } else if (filterType == "id") {
        return bus["number"]!.toLowerCase().contains(query);
      } else if (filterType == "city") {
        return bus["from"]!.toLowerCase().contains(query) ||
            bus["to"]!.toLowerCase().contains(query);
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      body: SingleChildScrollView(
        child: Column(
          children: [

            //////////////////////////////////////////////////////////
            /// HEADER
            //////////////////////////////////////////////////////////
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 50, left: 15, right: 15, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff4facfe), Color(0xff6a11cb)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white),
                      ),
                      const CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Bus Management",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Manage buses, routes & operations",
                    style: TextStyle(color: Colors.white70),
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            //////////////////////////////////////////////////////////
            /// SEARCH + FILTER (UPDATED 🔥)
            //////////////////////////////////////////////////////////
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [

                  /// SEARCH FIELD (REAL TIME)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: "Search buses...",
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// FILTER MENU
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton(
                      icon: const Icon(Icons.filter_list,
                          color: Colors.white),
                      onSelected: (value) {
                        setState(() {
                          filterType = value.toString();
                        });
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "name",
                          child: Text("Search by Name"),
                        ),
                        PopupMenuItem(
                          value: "id",
                          child: Text("Search by ID"),
                        ),
                        PopupMenuItem(
                          value: "city",
                          child: Text("Search by City"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            //////////////////////////////////////////////////////////
            /// ACTION BUTTONS
            //////////////////////////////////////////////////////////
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
                children: [

                  ActionCard(
                    "Add",
                    Icons.add,
                    Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddBusScreen()),
                      );
                    },
                  ),

                  ActionCard(
                    "Update",
                    Icons.edit,
                    Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UpdateBusScreen()),
                      );
                    },
                  ),

                  ActionCard(
                    "Delete",
                    Icons.delete,
                    Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DeleteBusScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            //////////////////////////////////////////////////////////
            /// BUS LIST (FILTERED 🔥)
            //////////////////////////////////////////////////////////
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredBuses.length,
              itemBuilder: (context, index) {
                final bus = filteredBuses[index];

                return BusCard(
                  bus["name"]!,
                  bus["number"]!,
                  bus["from"]!,
                  bus["to"]!,
                  bus["departure"]!,
                  bus["arrival"]!,
                  bus["fare"]!,
                  bus["status"]!,
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBusScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// ACTION CARD
//////////////////////////////////////////////////////////////
class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCard(this.title, this.icon, this.color,
      {required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(title),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// BUS CARD
//////////////////////////////////////////////////////////////
class BusCard extends StatelessWidget {
  final String name, number, from, to, departure, arrival, fare, status;

  const BusCard(
    this.name,
    this.number,
    this.from,
    this.to,
    this.departure,
    this.arrival,
    this.fare,
    this.status, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == "Active" ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status,
                    style:
                        TextStyle(color: statusColor, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text("Bus No: $number"),
          Text("$from → $to"),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dep: $departure"),
              Text("Arr: $arrival"),
            ],
          ),
          const SizedBox(height: 5),
          Text("Fare: Rs $fare",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
        ],
      ),
    );
  }
}