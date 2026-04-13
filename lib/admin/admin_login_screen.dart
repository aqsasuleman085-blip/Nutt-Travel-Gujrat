import 'package:flutter/material.dart';
import 'package:nutt/admin/dashboard.dart';
import 'package:nutt/widgets/textfield.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color themeColor = const Color(0xff10B981); // 🔵 Nice blue

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white, // ✅ White Background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        // Title Section
                        Column(
                          children: <Widget>[
                            Text(
                              "Admin Login",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Login to your account",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        // Input Fields
                        Column(
                          children: [
                            GTextField(
                              hintText: "Enter your email",
                              labelText: "Email",
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.green,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email is required";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12),
                            GTextField(
                              hintText: "Enter password",
                              labelText: "Password",
                              isPassword: true,
                              prefixIcon: Icon(Icons.lock, color: Colors.green),
                            ),
                          ],
                        ),

                        // Login Button
                        GestureDetector(
                          onTapDown: (_) {
                            setState(() => _isButtonPressed = true);
                          },
                          onTapUp: (_) {
                            setState(() => _isButtonPressed = false);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminDashboard(),
                              ),
                            );
                          },
                          onTapCancel: () {
                            setState(() => _isButtonPressed = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            transform: Matrix4.identity()
                              ..scale(_isButtonPressed ? 0.95 : 1.0),
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: themeColor, // ✅ Button Color
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom Image
                        Container(
                          margin: const EdgeInsets.only(top: 50),
                          height: 200,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/login.jpeg"),
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ),
                      ],
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
