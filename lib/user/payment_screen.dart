import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:nutt/user/colors.dart';
import 'package:nutt/user/home_screen.dart';
import 'package:nutt/user/picker.dart';

class PaymentScreen extends StatefulWidget {
  final String date;
  final String time;
  final String toCity;
  final String fromCity;
  final String gender;
  final int seat;
  final int fare; // ✅ NEW

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

  final TextEditingController jazzAccountController = TextEditingController();
  final TextEditingController jazzNameController = TextEditingController();

  String selectedPayment = "cod";

  File? paymentImage;
  final ImagePicker picker = ImagePicker();

  final Color c1 = const Color(0xff0F2027);
  final Color c2 = const Color(0xff203A43);
  final Color c3 = const Color(0xff2C5364);

  // 🔹 IMAGE PICK
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        paymentImage = File(picked.path);
      });
    }
  }

  // 🔹 SUCCESS
  void showSuccessPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff203A43),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Congratulations \nYou seat is reserved and will confirmed after your Jazzcash payment verification. 🎉",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "if you choose COD then reconfirm 30 min before departure on station and confirm your payment",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.tealAccent),
            onPressed: () => Navigator.pop(context),
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: Text('Ok'),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 CONFIRM
  void showConfirmPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff203A43),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Confirmation",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure to proceed according to entered details?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent),
            onPressed: () {
              Navigator.pop(context);
              showSuccessPopup();
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2, c3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // 🔹 SAME HEADER
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.tealAccent, Colors.white],
            ).createShader(bounds),
            child: const Text(
              "Payment",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Trip Summary (IMPROVED)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.5)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Trip Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${widget.fromCity} → ${widget.toCity}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Date: ${widget.date}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        Text(
                          "Seat: ${widget.seat}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.white24),

                    // ✅ FARE ADDED
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Fare: Rs ${widget.fare}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Passenger Info (SAME)
              const Text(
                "Passenger Info",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Full Name",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Phone Number",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Payment Method (SAME)
              const Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              RadioListTile(
                activeColor: Colors.tealAccent,
                value: "cod",
                groupValue: selectedPayment,
                onChanged: (value) {
                  setState(() {
                    selectedPayment = value.toString();
                  });
                },
                title: const Text(
                  "Cash on Delivery",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              RadioListTile(
                activeColor: Colors.tealAccent,
                value: "jazzcash",
                groupValue: selectedPayment,
                onChanged: (value) {
                  setState(() {
                    selectedPayment = value.toString();
                  });
                },
                title: const Text(
                  "JazzCash",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // 🔥 JAZZCASH UI (IMPROVED DESIGN)
              if (selectedPayment == "jazzcash") ...[
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.4),
                    ),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'JazzCash Account Number',
                        style: TextStyle(color: AppColors.textColor),
                      ),
                      Text(
                        '03001234563',
                        style: TextStyle(color: AppColors.textColor),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: jazzNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Account Holder Name",
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),

                      const SizedBox(height: 15),
                      ScreenshotPicker(),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // 🔹 BUTTON (SAME STYLE)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    showConfirmPopup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700.withOpacity(
                      0.9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
}
