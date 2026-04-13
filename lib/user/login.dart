import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'signup.dart';

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
                              "Login",
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
                          children: <Widget>[
                            inputFile(
                              label: "Email",
                              icon: Icons.email_outlined,
                              color: themeColor,
                            ),
                            const SizedBox(height: 10),
                            PasswordInputField(
                              label: "Password",
                              color: themeColor,
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

                        // Signup Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () {
                                // ✅ Navigation added
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupPage(),
                                  ),
                                );
                              },
                              child: Text(
                                " Sign up",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  color: themeColor,
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

// Email Input Field
Widget inputFile({
  required String label,
  IconData? icon,
  required Color color,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: color) : null,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: color),
          ),
        ),
        style: const TextStyle(color: Colors.black),
      ),
      const SizedBox(height: 10),
    ],
  );
}

// Password Input Field
class PasswordInputField extends StatefulWidget {
  final String label;
  final Color color;

  const PasswordInputField({
    super.key,
    required this.label,
    required this.color,
  });

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
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: widget.color,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          obscureText: _obscureText,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: widget.color),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: widget.color,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.color),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.color),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: widget.color),
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}