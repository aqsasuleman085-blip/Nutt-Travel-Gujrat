import 'package:flutter/material.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 55, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff4facfe), Color(0xff6a11cb)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: NetworkImage(
                      "https://cdn-icons-png.flaticon.com/512/3135/3135715.png",
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Admin Name",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "admin@gmail.com",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= SETTINGS =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [

                  SettingTile(
                    icon: Icons.edit,
                    title: "Edit Profile",
                    onTap: (context) => _editProfile(context),
                  ),

                  SettingTile(
                    icon: Icons.lock,
                    title: "Change Password",
                    onTap: (context) => _changePassword(context),
                  ),

                  SettingTile(
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: (context) {},
                  ),

                  SettingTile(
                    icon: Icons.help,
                    title: "Help & Support",
                    onTap: (context) {},
                  ),

                  SettingTile(
                    icon: Icons.info,
                    title: "About App",
                    onTap: (context) {},
                  ),

                  SettingTile(
                    icon: Icons.logout,
                    title: "Logout",
                    isLogout: true,
                    onTap: (context) => _logout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= EDIT PROFILE (PREMIUM UI) =================
  void _editProfile(BuildContext context) {
    final name = TextEditingController(text: "Admin Name");
    final email = TextEditingController(text: "admin@gmail.com");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _inputField(Icons.person, "Name", name),
              const SizedBox(height: 12),
              _inputField(Icons.email, "Email", email),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff6a11cb),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile Updated")),
                    );
                  },
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= CHANGE PASSWORD =================
  void _changePassword(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Change Password",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _inputField(Icons.lock, "Old Password", oldPass, isPass: true),
              const SizedBox(height: 12),
              _inputField(Icons.lock_outline, "New Password", newPass, isPass: true),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4facfe),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password Updated")),
                    );
                  },
                  child: const Text("Update Password"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= LOGOUT =================
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoggedOutScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _inputField(IconData icon, String hint, TextEditingController c,
      {bool isPass = false}) {
    return TextField(
      controller: c,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xfff1f3f6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ================= TILE =================
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isLogout;
  final Function(BuildContext) onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : const Color(0xff4facfe)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => onTap(context),
    );
  }
}

// ================= LOGOUT SCREEN =================
class LoggedOutScreen extends StatelessWidget {
  const LoggedOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Logged Out Successfully",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}