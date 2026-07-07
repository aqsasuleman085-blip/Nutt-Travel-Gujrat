import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/bus_provider.dart';

/// Detail screen shown when the admin taps the "Total Buses" dashboard
/// card. Lists every bus with its route, status, and seat count.
class BusesDetailScreen extends StatelessWidget {
  const BusesDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final buses = busProvider.buses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Buses'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: buses.isEmpty
          ? const Center(child: Text('No buses added yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: buses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bus = buses[index];
                final isActive = bus.status == 'Active';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bus.from} → ${bus.to}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Driver: ${bus.driverName} • ${bus.totalSeats} seats',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs ${bus.ticketPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isActive ? Colors.green : Colors.grey)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bus.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
