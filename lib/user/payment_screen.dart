import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutt/admin_side/widgets/custom_text_field.dart';
import 'package:nutt/admin_side/widgets/loading_widget.dart';
import 'package:nutt/user/home_screen.dart';

import '../services/booking_service.dart';

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

  String _paymentMethod = "JazzCash";
  String _gender = "Male";

  bool _isProcessing = false;

  final BookingService _bookingService = BookingService();

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

    Uint8List? bytes;
    if (kIsWeb) {
      bytes = await picked.readAsBytes();
    }

    // setState(() {
    //   _paymentScreenshot = picked;
    //   _paymentScreenshotBytes = bytes;
    // });
  }

  // Future<String> _uploadScreenshot({required String userId}) async {
  // if (_paymentScreenshot == null) {
  //   throw Exception('Payment screenshot is required');
  // }

  // final fileName =
  //     'payment_proofs/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
  // final ref = FirebaseStorage.instance.ref().child(fileName);

  // if (kIsWeb) {
  //   final bytes =
  //       _paymentScreenshotBytes ?? await _paymentScreenshot!.readAsBytes();
  //   await ref.putData(bytes);
  // } else {
  //   await ref.putFile(File(_paymentScreenshot!.path));
  // }

  // return await ref.getDownloadURL();
  // }

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
          ? const LoadingWidget(message: 'Processing...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 SUMMARY
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

                    /// 🔹 PASSENGER INFO
                    Text(
                      "Passenger Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      label: "Name",
                      controller: _nameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),

                    CustomTextField(
                      label: "Phone Number (11 digits)",
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digitsOnly.length != 11)
                          return "Must be exactly 11 digits";
                        return null;
                      },
                    ),

                    CustomTextField(
                      label: "CNIC (13 digits)",
                      controller: _cnicController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Required";
                        final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digitsOnly.length != 13)
                          return "Must be exactly 13 digits CNIC";
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    /// 🔹 GENDER
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

                    /// 🔹 PAYMENT METHOD
                    Text(
                      "Payment Method",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '0339 4848324',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

                    /// 🔹 JAZZCASH DETAILS
                    Text(
                      "Payment Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    CustomTextField(
                      label: "Sender Name",
                      controller: _senderNameController,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 20),

                    /// 🔹 SUBMIT
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          // if (_paymentScreenshot == null) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text(
                          //         'Please upload payment screenshot',
                          //       ),
                          //     ),
                          //   );
                          //   return;
                          // }

                          setState(() => _isProcessing = true);

                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            setState(() => _isProcessing = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User not logged in'),
                              ),
                            );
                            return;
                          }

                          // final screenshotUrl = await _uploadScreenshot(
                          //   userId: user.uid,
                          // );

                          String? bookingId;
                          try {
                            bookingId = await _bookingService.createBooking(
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
                            );
                          } catch (e) {
                            setState(() => _isProcessing = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                            return;
                          }

                          setState(() => _isProcessing = false);

                          if (bookingId == null) return;

                          if (!mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                        },
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
