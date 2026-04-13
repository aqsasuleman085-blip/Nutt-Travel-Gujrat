import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutt/admin/dashboard.dart';
import 'package:nutt/user/button.dart';
import 'home_screen.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _LoginPageState();
}

class _LoginPageState extends State<UserLogin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0F2027), Color(0xff203A43), Color(0xff2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
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
                              const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Login to your account",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),

                          // Input Fields
                          Column(
                            children: <Widget>[
                              inputFile(
                                label: "Email",
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 10),
                              const PasswordInputField(label: "Password"),
                            ],
                          ),
                          // Login Button with animation
                          GestureDetector(
                            onTapDown: (_) {
                              setState(() => _isButtonPressed = true);
                            },
                            onTapUp: (_) {
                              setState(() => _isButtonPressed = false);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(),
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
                                color: Colors.tealAccent.shade700.withOpacity(
                                  0.9,
                                ),
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

                          // Signup Text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Navigate to signup if needed
                                },
                                child: const Text(
                                  " Sign up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Bottom Image
                          Container(
                            margin: const EdgeInsets.only(top: 50),
                            height: 200,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage("assets/background.jpeg"),
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
      ),
    );
  }
}

// Email Input Field with icon
Widget inputFile({required String label, IconData? icon}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 10),
    ],
  );
}

// Password Input Field with lock + eye toggle
class PasswordInputField extends StatefulWidget {
  final String label;
  const PasswordInputField({super.key, required this.label});

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          obscureText: _obscureText,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
