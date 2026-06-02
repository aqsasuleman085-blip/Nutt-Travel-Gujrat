import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutt/admin_side/widgets/custom_text_field.dart';
import 'package:nutt/admin_side/widgets/loading_widget.dart';
import 'package:nutt/user/presentation/home_screen.dart';
import 'package:nutt/widgets/textfield.dart' hide CustomTextField;

import '../../services/booking_service.dart';

/// ✅ Name Formatter
class NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    text = text.replaceAll(RegExp(r'[^a-zA-Z ]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    text = text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final String busId;
  final String busFrom;
  final String busTo;
  final String departureTime;
  final String date;
  final int fare;
  final String seatNumber;

  const PaymentScreen({
    super.key,
    required this.busId,
    required this.busFrom,
    required this.busTo,
    required this.departureTime,
    required this.date,
    required this.fare,
    required this.seatNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final Color themeColor = const Color(0xff10B981);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderNumController = TextEditingController();

  String _paymentMethod = "JazzCash";
  String _gender = "Male";

  bool _isProcessing = false;

  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();

        _nameController.text = data?['name'] ?? '';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _senderNameController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    if (kIsWeb) {
      await picked.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          "Payment",
          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),

      body: _isProcessing
          ? const LoadingWidget(message: "Processing...")
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// SUMMARY
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
                          const SizedBox(height: 10),
                          _row("Route", "${widget.busFrom} → ${widget.busTo}"),
                          _row("Date", widget.date),
                          _row("Time", widget.departureTime),
                          _row("Seat", widget.seatNumber),
                          _row("Fare", "Rs ${widget.fare}"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Passenger Details
                    Text(
                      "Passenger Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// ✅ SAME STYLE AS OTHER FIELDS
                    CustomTextField(
                      label: "Passenger Name",
                      controller: _nameController,
                      inputFormatters: [NameInputFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Passenger name is required";
                        }
                        return null;
                      },
                    ),

                    CustomTextField(
                      label: "Phone Number (11 digits)",
                      controller: _phoneController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Required";
                        }

                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');

                        if (digits.length != 11) {
                          return "Must be exactly 11 digits";
                        }

                        return null;
                      },
                    ),

                    CustomTextField(
                      label: "CNIC (13 digits)",
                      controller: _cnicController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Required";
                        }

                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');

                        if (digits.length != 13) {
                          return "Must be exactly 13 digits CNIC";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    /// Gender
                    Text(
                      "Gender",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female"),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _gender = val!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Payment Method
                    Text(
                      "Payment Method",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text("0339 4848324"),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      items: const [
                        DropdownMenuItem(
                          value: "JazzCash",
                          child: Text("JazzCash"),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _paymentMethod = val!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Sender Name
                    Text(
                      "Payment Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// ✅ SAME STYLE AS OTHER FIELDS
                    CustomTextField(
                      label: "Sender Name",
                      controller: _senderNameController,
                      inputFormatters: [NameInputFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Sender name is required";
                        }
                        return null;
                      },
                    ),

                    // Sender number
                    /// Sender Name
                    const SizedBox(height: 10),

                    /// ✅ SAME STYLE AS OTHER FIELDS
                    CustomTextField(
                      label: "Phone Number (11 digits)",
                      controller: _senderNumController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Required";
                        }

                        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');

                        if (digits.length != 11) {
                          return "Must be exactly 11 digits";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          setState(() {
                            _isProcessing = true;
                          });

                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            setState(() {
                              _isProcessing = false;
                            });

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("User not logged in"),
                              ),
                            );
                            return;
                          }

                          try {
                            await _bookingService.createBooking(
                              totalAmount: widget.fare.toDouble(),
                              name: _nameController.text,
                              phone: _phoneController.text,
                              cnic: _cnicController.text,
                              gender: _gender,
                              busId: widget.busId,
                              from: widget.busFrom,
                              to: widget.busTo,
                              seat: widget.seatNumber,
                              date: widget.date,
                              time: widget.departureTime,
                              paymentMethod: _paymentMethod,
                              senderName: _senderNameController.text,
                              senderNumber: _senderNumController.text,
                            );

                            if (!mounted) return;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }

                          setState(() {
                            _isProcessing = false;
                          });
                        },
                        child: const Text("Submit"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
