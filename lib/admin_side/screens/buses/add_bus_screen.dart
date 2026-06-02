import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/bus_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddBusScreen extends StatefulWidget {
  const AddBusScreen({Key? key}) : super(key: key);

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _departureAtController = TextEditingController();
  DateTime? _departureAt;
  final _ticketPriceController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _numberPlateController = TextEditingController();
  final _totalSeatsController = TextEditingController();

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
      appBar: AppBar(title: const Text('Add New Bus')),
      body: Consumer<BusProvider>(
        builder: (context, busProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                await busProvider.addBus(
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Bus added successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
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
                              'Add Bus',
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
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (pickedDate == null) return;

            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
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
              _departureAtController.text =
                  '${pickedDate.year.toString().padLeft(4, '0')}-'
                  '${pickedDate.month.toString().padLeft(2, '0')}-'
                  '${pickedDate.day.toString().padLeft(2, '0')} '
                  '${pickedTime.hour.toString().padLeft(2, '0')}:'
                  '${pickedTime.minute.toString().padLeft(2, '0')}';
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
