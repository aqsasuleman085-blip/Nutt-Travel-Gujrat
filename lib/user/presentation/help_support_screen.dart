import 'package:flutter/material.dart';

/// 🔹 HELP & SUPPORT SCREEN
///
/// Shows an expandable FAQ list covering the most common questions a bus
/// ticket passenger would have (booking, seat selection, payment, refund,
/// cancellation).
///
/// Contact details (Call / WhatsApp / Email / Office Address) live on the
/// separate Contact Us screen, and asking a support question directly is
/// available via the chat icon on the Home screen - both are intentionally
/// not duplicated here.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const Color themeColor = Color(0xff10B981);

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: "How do I book a bus ticket?",
      answer:
          "Go to the Home screen, search for your route by selecting the "
          "'From' city, 'To' city, and travel date. Pick a bus from the "
          "results, choose your seat, enter your details and payment "
          "information, then submit. Your booking will show as 'Pending' "
          "until the admin approves it.",
    ),
    _FaqItem(
      question: "How long does it take for my booking to be approved?",
      answer:
          "Bookings are usually reviewed and approved by our team within a "
          "few hours. You'll see the status change automatically on your "
          "Tickets screen once it's approved — no need to refresh manually.",
    ),
    _FaqItem(
      question: "Can I cancel my ticket and get a refund?",
      answer:
          "Yes. Open the Tickets screen, find your booking, and tap "
          "'Request Refund'. Please note refund requests must be submitted "
          "at least 12 hours before your scheduled departure time. Fill in "
          "the refund form with your account details and reason, then "
          "submit — our team will process it after review.",
    ),
    _FaqItem(
      question: "Why can't I see the 'Request Refund' button on my ticket?",
      answer:
          "The refund option is only available if your trip's departure is "
          "more than 12 hours away. If departure is sooner than that, the "
          "button will be hidden automatically as refunds can no longer be "
          "requested for that trip.",
    ),
    _FaqItem(
      question: "How long does a refund take once approved?",
      answer:
          "Once your refund is approved by the admin, the amount is "
          "typically returned to the account you provided within 3-5 "
          "working days.",
    ),
    _FaqItem(
      question: "What payment methods are supported?",
      answer:
          "Currently we accept JazzCash. When booking, you'll enter the "
          "sender's account name and number used to make the payment.",
    ),
    _FaqItem(
      question: "I made a mistake in my booking. What should I do?",
      answer:
          "If your ticket hasn't been approved yet, contact support "
          "immediately using the chat icon on the Home screen so we can "
          "help before it's processed. If it's already approved, you can "
          "request a refund (subject to the 12-hour policy) and create a "
          "new booking with the correct details.",
    ),
    _FaqItem(
      question: "How do I update my profile information?",
      answer:
          "Go to Profile, tap the edit icon on your profile photo/details "
          "or use 'Change Password' from the menu to update your "
          "credentials.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Help & Support",
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: themeColor, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Need help?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Browse frequently asked questions below.",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "FREQUENTLY ASKED QUESTIONS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: List.generate(_faqs.length, (index) {
                  final faq = _faqs[index];
                  return Column(
                    children: [
                      if (index != 0)
                        const Divider(height: 1, color: Colors.grey),
                      ExpansionTile(
                        iconColor: themeColor,
                        collapsedIconColor: Colors.grey,
                        title: Text(
                          faq.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq.answer,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
