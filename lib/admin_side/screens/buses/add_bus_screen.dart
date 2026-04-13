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
  final _departureTimeController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _numberPlateController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _departureTimeController.dispose();
    _ticketPriceController.dispose();
    _driverNameController.dispose();
    _numberPlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Bus'),
      ),
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
                  CustomTextField(
                    label: 'Departure Time',
                    hintText: 'e.g., 09:30 AM',
                    controller: _departureTimeController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the departure time';
                      }
                      return null;
                    },
                  ),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await busProvider.addBus(
                                  from: _fromController.text,
                                  to: _toController.text,
                                  departureTime: _departureTimeController.text,
                                  ticketPrice: double.parse(_ticketPriceController.text),
                                  driverName: _driverNameController.text,
                                  numberPlate: _numberPlateController.text,
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
                          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
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
}