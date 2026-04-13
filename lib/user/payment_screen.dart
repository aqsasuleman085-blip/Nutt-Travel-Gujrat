import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:nutt/user/home_screen.dart';
import 'package:nutt/user/picker.dart';

/// 🎨 THEME COLORS
const Color emeraldGreen = const Color(0xff10B981);
const Color softWhite = Colors.white;

class PaymentScreen extends StatefulWidget {
  final String date;
  final String time;
  final String toCity;
  final String fromCity;
  final String gender;
  final int seat;
  final int fare;

  const PaymentScreen({
    super.key,
    required this.date,
    required this.time,
    required this.toCity,
    required this.fromCity,
    required this.gender,
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

  String selectedPayment = "cod";

  File? paymentImage;
  final ImagePicker picker = ImagePicker();

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        paymentImage = File(picked.path);
      });
    }
  }

  /// 🎉 SUCCESS POPUP
  void showSuccessPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: softWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "🎉 Seat Reserved",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Your seat is reserved and will be confirmed after payment verification.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: emeraldGreen),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// ❓ CONFIRM POPUP
  void showConfirmPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: softWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text("Confirmation"),
        content: const Text("Are you sure to proceed with entered details?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: emeraldGreen),
            onPressed: () {
              Navigator.pop(context);
              showSuccessPopup();
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softWhite,

      /// 🟢 APP BAR
      appBar: AppBar(
        backgroundColor: emeraldGreen,
        centerTitle: true,
        title: const Text(
          "Payment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🟢 TRIP CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: emeraldGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: emeraldGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trip Summary",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text("${widget.fromCity} → ${widget.toCity}"),
                  Text("Date: ${widget.date}"),
                  Text("Seat: ${widget.seat}"),

                  const Divider(),

                  Text(
                    "Fare: Rs ${widget.fare}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: emeraldGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 👤 PASSENGER INFO
            const Text(
              "Passenger Info",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _input(nameController, "Full Name"),
            const SizedBox(height: 10),
            _input(phoneController, "Phone Number"),

            const SizedBox(height: 20),

            /// 💳 PAYMENT METHOD
            const Text(
              "Payment Method",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            RadioListTile(
              activeColor: emeraldGreen,
              value: "cod",
              groupValue: selectedPayment,
              onChanged: (v) {
                setState(() => selectedPayment = v.toString());
              },
              title: const Text("Cash on Delivery"),
            ),

            RadioListTile(
              activeColor: emeraldGreen,
              value: "jazzcash",
              groupValue: selectedPayment,
              onChanged: (v) {
                setState(() => selectedPayment = v.toString());
              },
              title: const Text("JazzCash"),
            ),

            /// 💚 JAZZCASH BOX
            if (selectedPayment == "jazzcash")
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: emeraldGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: emeraldGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text("JazzCash Number: 03001234563"),
                    const SizedBox(height: 10),

                    _input(jazzNameController, "Account Holder Name"),

                    const SizedBox(height: 10),

                    ScreenshotPicker(),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            /// 🔘 BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: showConfirmPopup,
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 INPUT WIDGET
  Widget _input(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: emeraldGreen),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}