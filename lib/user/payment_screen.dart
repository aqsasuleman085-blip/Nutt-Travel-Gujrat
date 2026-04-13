import 'package:flutter/material.dart';
import 'package:nutt/admin_side/providers/auth_provider.dart';
import 'package:nutt/admin_side/providers/booking_provider.dart';
import 'package:nutt/admin_side/widgets/custom_text_field.dart';
import 'package:nutt/admin_side/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'tickets_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String busId;
  final String busFrom;
  final String busTo;
  final String departureTime;
  final String date;
  final int fare;

  const PaymentScreen({
    super.key,
    required this.busId,
    required this.busFrom,
    required this.busTo,
    required this.departureTime,
    required this.date,
    required this.fare,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _paymentMethodController = TextEditingController(text: 'Credit Card');
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _paymentMethodController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Payment Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: _isProcessing
          ? const LoadingWidget(message: 'Processing payment...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Booking Summary",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow("Route", "${widget.busFrom} → ${widget.busTo}"),
                          _buildSummaryRow("Date", widget.date),
                          _buildSummaryRow("Departure Time", widget.departureTime),
                          _buildSummaryRow("Fare", "Rs ${widget.fare}"),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Personal Information
                    Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: "Full Name",
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    
                    CustomTextField(
                      label: "Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    CustomTextField(
                      label: "Phone Number",
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    
                    CustomTextField(
                      label: "CNIC",
                      controller: _cnicController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your CNIC';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Payment Information
                    Text(
                      "Payment Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Payment Method",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      ),
                      value: _paymentMethodController.text,
                      items: const [
                        DropdownMenuItem(value: "Credit Card", child: Text("Credit Card")),
                        DropdownMenuItem(value: "Debit Card", child: Text("Debit Card")),
                        DropdownMenuItem(value: "JazzCash", child: Text("JazzCash")),
                        DropdownMenuItem(value: "EasyPaisa", child: Text("EasyPaisa")),
                        DropdownMenuItem(value: "Bank Transfer", child: Text("Bank Transfer")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _paymentMethodController.text = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_paymentMethodController.text == "Credit Card" || 
                        _paymentMethodController.text == "Debit Card") ...[
                      CustomTextField(
                        label: "Card Number",
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your card number';
                          }
                          return null;
                        },
                      ),
                      
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Expiry (MM/YY)",
                              controller: _cardExpiryController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: "CVV",
                              controller: _cardCvvController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isProcessing = true;
                            });
                            
                            // Simulate payment processing
                            await Future.delayed(const Duration(seconds: 2));
                            
                            // Create booking request
                            final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
                            await bookingProvider.addBooking(
                              userName: _nameController.text,
                              userEmail: _emailController.text,
                              busId: widget.busId,
                              busFrom: widget.busFrom,
                              busTo: widget.busTo,
                              price: widget.fare.toDouble(),
                            );
                            
                            // Add notification for admin
                            // This would be handled by the booking provider in a real app
                            
                            setState(() {
                              _isProcessing = false;
                            });
                            
                            if (mounted) {
                              // Navigate to tickets screen
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const TicketsScreen(),
                                ),
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking request submitted! Awaiting admin approval.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Pay Now",
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
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}