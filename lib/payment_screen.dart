import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final String date;
  final String time;
  final String toCity;
  final String fromCity;
  final String gender;
  final int seat;

  const PaymentScreen({
    super.key,
    required this.date,
    required this.time,
    required this.toCity,
    required this.fromCity,
    required this.gender,
    required this.seat,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedPayment = "cod";

  final Color c1 = const Color(0xff0F2027);
  final Color c2 = const Color(0xff203A43);
  final Color c3 = const Color(0xff2C5364);

  void showSuccessPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff203A43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "Congratulations 🎉",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "You have successfully booked the seat",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.tealAccent.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.black),
            ),
          )
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

        // 🔹 HEADER UPDATED (BACK BUTTON + STYLISH TITLE)
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // back to seats page
            },
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
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔹 Trip Summary
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.withOpacity(0.2),
                      Colors.white.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.5)),
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
                        const Icon(Icons.directions_bus,
                            color: Colors.tealAccent),
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
                        const Icon(Icons.calendar_today,
                            color: Colors.tealAccent),
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
                        const Icon(Icons.event_seat,
                            color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        Text(
                          "Seat: ${widget.seat}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                keyboardType: TextInputType.phone,
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

              const Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.4)),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Column(
                  children: [
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
                      secondary:
                          const Icon(Icons.money, color: Colors.green),
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
                      secondary: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isEmpty ||
                        phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill all fields"),
                        ),
                      );
                      return;
                    }

                    showSuccessPopup();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.tealAccent.shade700.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Pay Now",
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