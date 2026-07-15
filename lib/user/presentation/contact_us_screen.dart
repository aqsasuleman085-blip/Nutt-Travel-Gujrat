import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🔹 CONTACT US SCREEN
///
/// Displays company contact information as tappable cards:
/// - Phone (tap to call)
/// - WhatsApp (tap to open chat)
/// - Email (tap to open mail app)
/// - Office address (tap to open in maps)
///
/// This screen is display-only — it does not submit any form data, it just
/// launches the relevant app (phone dialer, WhatsApp, mail client, or maps)
/// using url_launcher.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const Color themeColor = Color(0xff10B981);

  // Update these to your real company details.
  static const String companyName = "Nutt Travel Gujrat";
  static const String phone = "+92 347 2734270";
  static const String whatsApp = "+923472734270"; // no spaces, with country code
  static const String email = "info@nutttravel.com";
  static const String address =
      "Nutt Travel Bus Terminal, G.T Road, Gujrat, Punjab, Pakistan";
  static const String officeHours = "Daily: 6:00 AM - 11:00 PM";

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    await launchUrl(uri);
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$whatsApp');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry - Nutt Travel',
    );
    await launchUrl(uri);
  }

  Future<void> _launchMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Contact Us",
          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: themeColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  companyName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "We're here to help with bookings, refunds, and any "
                  "questions about your journey.",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "GET IN TOUCH",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),

          _ContactTile(
            icon: Icons.call,
            iconColor: themeColor,
            title: "Phone",
            subtitle: phone,
            onTap: _launchPhone,
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.chat,
            iconColor: const Color(0xff25D366),
            title: "WhatsApp",
            subtitle: "Chat with our support team",
            onTap: _launchWhatsApp,
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.email,
            iconColor: Colors.blueGrey,
            title: "Email",
            subtitle: email,
            onTap: _launchEmail,
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            title: "Office Address",
            subtitle: address,
            onTap: _launchMap,
          ),

          const SizedBox(height: 24),

          const Text(
            "OFFICE HOURS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.black54),
                const SizedBox(width: 12),
                const Text(
                  officeHours,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
