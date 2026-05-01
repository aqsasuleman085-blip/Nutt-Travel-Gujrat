import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/bus_card.dart';
import '../../widgets/loading_widget.dart';
import 'add_bus_screen.dart';

class BusesScreen extends StatelessWidget {
  const BusesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddBusScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          if (busProvider.isLoading) {
            return const LoadingWidget(message: 'Loading buses...');
          }

          if (busProvider.buses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No buses added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddBusScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Bus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh is handled by the provider
            },
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: ListView.builder(
                itemCount: busProvider.buses.length,
                itemBuilder: (context, index) {
                  final bus = busProvider.buses[index];
                  return BusCard(
                    bus: bus,
                    onTap: () {
                      // Navigate to bus details
                      _showBusDetails(context, bus);
                    },
                    // onEdit: () {
                    //   _editBus(context, bus);
                    // },
                    onDelete: () {
                      _confirmDeleteBus(context, bus);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBusDetails(BuildContext context, bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${bus.from} → ${bus.to}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Driver', bus.driverName),
            _buildDetailRow('Number Plate', bus.numberPlate),
            _buildDetailRow('Total Seats', bus.totalSeats.toString()),
            _buildDetailRow(
              'Departure',
              '${bus.departureAt.year.toString().padLeft(4, '0')}-'
                  '${bus.departureAt.month.toString().padLeft(2, '0')}-'
                  '${bus.departureAt.day.toString().padLeft(2, '0')} '
                  '${bus.departureAt.hour.toString().padLeft(2, '0')}:'
                  '${bus.departureAt.minute.toString().padLeft(2, '0')}',
            ),
            _buildDetailRow(
              'Ticket Price',
              'Rs. ${bus.ticketPrice.toStringAsFixed(0)}',
            ),
            _buildDetailRow('Status', bus.status),
            _buildDetailRow(
              'Added On',
              '${bus.createdAt.day}/${bus.createdAt.month}/${bus.createdAt.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.darkGreen,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editBus(BuildContext context, bus) {
    // For simplicity, we'll show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality would be implemented here'),
      ),
    );
  }

  void _confirmDeleteBus(BuildContext context, bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text(
          'Are you sure you want to delete the bus from ${bus.from} to ${bus.to}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BusProvider>(
                context,
                listen: false,
              ).deleteBus(bus.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bus deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
