import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:nutt/user/colors.dart';
import 'package:nutt/user/home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String date;
  final String time;
  final String toCity;
  final String fromCity;
  final int seat;
  final int fare;

  const PaymentScreen({
    super.key,
    required this.date,
    required this.time,
    required this.toCity,
    required this.fromCity,
    required this.seat,
    required this.fare,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController jazzNameController = TextEditingController();
  final Color primaryGreen = AppColors.primary;

  String selectedPayment = "cod"; // "cod" or "jazzcash"
  File? paymentScreenshot;
  final ImagePicker picker = ImagePicker();

  bool get isSubmitEnabled {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      return false;
    }
    if (selectedPayment == "jazzcash") {
      return paymentScreenshot != null &&
          jazzNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> pickScreenshot() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        paymentScreenshot = File(picked.path);
      });
    }
  }

  void showSuccessPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "🎉 Booking Submitted",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Your booking request has been sent. You will be notified once approved.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showConfirmPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Booking"),
        content: const Text("Are you sure you want to proceed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () {
              Navigator.pop(context);
              // Here you would call your booking provider
              // For now, just show success
              showSuccessPopup();
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text("Payment", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trip Summary",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("${widget.fromCity} → ${widget.toCity}"),
                  Text("Date: ${widget.date}"),
                  Text("Time: ${widget.time}"),
                  Text("Seat: ${widget.seat}"),
                  const Divider(),
                  Text(
                    "Fare: Rs ${widget.fare}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Passenger Info
            const Text(
              "Passenger Info",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Full Name",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Phone Number",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method
            const Text(
              "Payment Method",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile(
              activeColor: primaryGreen,
              value: "cod",
              groupValue: selectedPayment,
              onChanged: (val) {
                setState(() {
                  selectedPayment = val.toString();
                });
              },
              title: const Text("Cash on Delivery"),
            ),
            RadioListTile(
              activeColor: primaryGreen,
              value: "jazzcash",
              groupValue: selectedPayment,
              onChanged: (val) {
                setState(() {
                  selectedPayment = val.toString();
                });
              },
              title: const Text("JazzCash"),
            ),

            // JazzCash details
            if (selectedPayment == "jazzcash")
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "JazzCash Number: 03001234563",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: jazzNameController,
                      decoration: InputDecoration(
                        hintText: "Account Holder Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: pickScreenshot,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryGreen),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              paymentScreenshot == null
                                  ? Icons.camera_alt
                                  : Icons.check_circle,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              paymentScreenshot == null
                                  ? "Attach Screenshot"
                                  : "Screenshot Attached",
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (paymentScreenshot != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          paymentScreenshot!.path.split('/').last,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Submit Button (disabled until valid)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: isSubmitEnabled ? showConfirmPopup : null,
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
