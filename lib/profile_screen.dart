import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginScreen(), // 🔥 Start from Login Screen
  ));
}

// 🔹 Login Screen (Welcome Page)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff203A43),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: const Text(
            "Login",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// 🔹 Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Aqsa Suleman";
  String userEmail = "aqsa@email.com";
  File? _image;

  final TextEditingController _nameController = TextEditingController();

  // 📸 Pick Image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // ✏️ Edit Name
  void _editName() {
    _nameController.text = userName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "Enter your name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  userName = _nameController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Navigation functions
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: userName,
          currentEmail: userEmail,
          onSave: (name, email, password) {
            setState(() {
              userName = name;
              userEmail = email;
            });
          },
        ),
      ),
    );
  }

  void _navigateToHelpSupport() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Help & Support clicked")));
  }

  void _navigateToContactUs() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Contact Us clicked")));
  }

  // 🔥 Logout → back to LoginScreen
  void _navigateToLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff0F2027),
            Color(0xff203A43),
            Color(0xff2C5364),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Profile",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent.shade700.withOpacity(0.9)),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Image
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : const AssetImage("assets/profile.png")
                            as ImageProvider,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.tealAccent,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _editName,
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: _editName,
                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 5),
            Text(userEmail,
                style: const TextStyle(color: Colors.white70)),

            const SizedBox(height: 20),

            buildTile("Edit Profile", Icons.person, _navigateToEditProfile),
            buildTile("Help & Support", Icons.help, _navigateToHelpSupport),
            buildTile("Contact Us", Icons.contact_page, _navigateToContactUs),
            buildTile("Logout", Icons.logout, _navigateToLogout),
          ],
        ),
      ),
    );
  }

  Widget buildTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.tealAccent.shade700.withOpacity(0.9)),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent.shade700.withOpacity(0.9))),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
      onTap: onTap,
    );
  }
}

// 🔹 Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final Function(String name, String email, String password) onSave;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent.shade700.withOpacity(0.9)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xff203A43),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            buildTextField("Name", _nameController),
            const SizedBox(height: 10),
            buildTextField("Email", _emailController),
            const SizedBox(height: 10),
            buildTextField("Password", _passwordController, obscure: true),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              onPressed: () {
                widget.onSave(
                  _nameController.text,
                  _emailController.text,
                  _passwordController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Profile Updated Successfully")),
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.tealAccent.shade700, width: 2),
        ),
      ),
    );
  }
}