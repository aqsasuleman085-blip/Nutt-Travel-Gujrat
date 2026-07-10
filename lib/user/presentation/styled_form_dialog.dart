import 'package:flutter/material.dart';

/// Shared visual shell for the Edit and Add-More-Seats dialogs, so both
/// look identical in structure: a green header bar (icon + title, matching
/// the emerald theme used across the user side), a white scrollable body,
/// and a bottom action row with a grey/outline Cancel button and a red
/// primary action button.
///
/// This is a custom [Dialog] (not [AlertDialog]) so it can be given a
/// fixed, wider size - standard AlertDialog width doesn't give the seat
/// grid enough room to look good.
class StyledFormDialog extends StatelessWidget {
  static const Color themeColor = Color(0xff10B981);

  final IconData headerIcon;
  final String title;
  final String? subtitle;
  final Widget body;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onCancelPressed;
  final bool isBusy;

  const StyledFormDialog({
    super.key,
    required this.headerIcon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.onCancelPressed,
    this.subtitle,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 480 ? screenWidth * 0.94 : 440.0;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green header bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(headerIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // White scrollable body
            Flexible(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: SingleChildScrollView(child: body),
              ),
            ),

            // Action row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy ? null : onCancelPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : onPrimaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffE53935),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xffE53935).withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              primaryLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
