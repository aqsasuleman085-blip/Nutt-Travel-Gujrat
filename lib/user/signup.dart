import 'package:flutter/material.dart';
import 'package:nutt/user/home_screen.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}
// This is a sign up page

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isButtonPressed = false;

  final Color themeColor = const Color(0xff10B981); // ✅ Emerald Green
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();

  Future<void> signupUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup Successful")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Error occurred")));
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white, // ✅ White background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        "Sign up",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Create an account, It's free",
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),

                  // Input Fields
                  Column(
                    children: <Widget>[
                      inputFile(
                        label: "Username",
                        icon: Icons.person,
                        controller: usernameController,
                      ),
                      inputFile(
                        label: "Email",
                        icon: Icons.email,
                        controller: emailController,
                      ),
                      inputFile(
                        label: "Password",
                        icon: Icons.lock,
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: themeColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      inputFile(
                        label: "Confirm Password",
                        icon: Icons.lock,
                        obscureText: _obscureConfirmPassword,
                        controller: confirmPasswordController,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: themeColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  // Sign up Button
                  GestureDetector(
                    onTapDown: (_) {
                      setState(() => _isButtonPressed = true);
                    },
                    onTapUp: (_) {
                      setState(() => _isButtonPressed = false);
                      signupUser();
                    },
                    onTapCancel: () {
                      setState(() => _isButtonPressed = false);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      transform: Matrix4.identity()
                        ..scale(_isButtonPressed ? 0.95 : 1.0),
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: themeColor, // ✅ Button color
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Login Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserLogin(),
                            ),
                          );
                        },
                        child: Text(
                          " Login",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Input Field Widget
  Widget inputFile({
    required String label,
    TextEditingController? controller, // ✅ ADD THIS
    IconData? icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: themeColor, // ✅ label color
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller, // ✅ ADD THIS
          obscureText: obscureText,
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: themeColor) // ✅ icon color
                : null,
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: themeColor),
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
