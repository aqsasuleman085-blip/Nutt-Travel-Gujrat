import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/bus_model.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/custom_text_field.dart';

/// Lets the admin edit an existing bus's details. On save, calls
/// [BusProvider.updateBus], which also notifies every user with an
/// approved booking on this bus about what changed.
class EditBusScreen extends StatefulWidget {
  final BusModel bus;

  const EditBusScreen({super.key, required this.bus});

  @override
  State<EditBusScreen> createState() => _EditBusScreenState();
}

class _EditBusScreenState extends State<EditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _departureAtController;
  DateTime? _departureAt;
  late final TextEditingController _ticketPriceController;
  late final TextEditingController _driverNameController;
  late final TextEditingController _numberPlateController;
  late final TextEditingController _totalSeatsController;

  @override
  void initState() {
    super.initState();
    final bus = widget.bus;
    _fromController = TextEditingController(text: bus.from);
    _toController = TextEditingController(text: bus.to);
    _departureAt = bus.departureAt;
    _departureAtController = TextEditingController(
      text: _formatDateTime(bus.departureAt),
    );
    _ticketPriceController = TextEditingController(
      text: bus.ticketPrice.toStringAsFixed(0),
    );
    _driverNameController = TextEditingController(text: bus.driverName);
    _numberPlateController = TextEditingController(text: bus.numberPlate);
    _totalSeatsController = TextEditingController(
      text: bus.totalSeats.toString(),
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _departureAtController.dispose();
    _ticketPriceController.dispose();
    _driverNameController.dispose();
    _numberPlateController.dispose();
    _totalSeatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bus')),
      body: Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner explaining the notification behavior.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Passengers with an approved booking on this '
                            'bus will be notified of any changes you save.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  CustomTextField(
                    label: 'From',
                    hintText: 'e.g., Gujrat',
                    controller: _fromController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the departure city';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'To',
                    hintText: 'e.g., Islamabad',
                    controller: _toController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the destination city';
                      }
                      return null;
                    },
                  ),
                  _buildDepartureAtField(context),
                  CustomTextField(
                    label: 'Ticket Price (Rs.)',
                    hintText: 'e.g., 1200',
                    controller: _ticketPriceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the ticket price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'Driver Name',
                    hintText: 'e.g., Ahmed Khan',
                    controller: _driverNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the driver name';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'Bus Number Plate',
                    hintText: 'e.g., ABC-1234',
                    controller: _numberPlateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the bus number plate';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    label: 'Total Seats',
                    hintText: 'e.g., 45',
                    controller: _totalSeatsController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter total seats';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                if (_departureAt == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a departure date & time',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await busProvider.updateBus(
                                    busId: widget.bus.id,
                                    from: _fromController.text,
                                    to: _toController.text,
                                    departureAt: _departureAt!,
                                    ticketPrice: double.parse(
                                      _ticketPriceController.text,
                                    ),
                                    driverName: _driverNameController.text,
                                    numberPlate: _numberPlateController.text,
                                    totalSeats: int.parse(
                                      _totalSeatsController.text,
                                    ),
                                  );

                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Bus updated successfully. '
                                          'Affected passengers notified.',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update bus: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.buttonRadius,
                          ),
                        ),
                      ),
                      child: busProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDepartureAtField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Departure Date & Time',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppConstants.darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _departureAtController,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Select date & time',
            prefixIcon: Icon(Icons.event),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a departure date & time';
            }
            return null;
          },
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _departureAt ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime(2030),
            );
            if (pickedDate == null) return;

            final pickedTime = await showTimePicker(
              context: context,
              initialTime: _departureAt != null
                  ? TimeOfDay.fromDateTime(_departureAt!)
                  : TimeOfDay.now(),
            );
            if (pickedTime == null) return;

            final departureAt = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );

            setState(() {
              _departureAt = departureAt;
              _departureAtController.text = _formatDateTime(departureAt);
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
