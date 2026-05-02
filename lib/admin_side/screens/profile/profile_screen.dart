import 'package:flutter/material.dart';
import 'package:nutt/welcome_screen.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.admin.name;
    _emailController.text = auth.admin.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasMinLength && hasUpper && hasLower && hasDigit && hasSpecial;
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppConstants.lightGreen,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkGreen,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Profile'),
            elevation: 0,
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(authProvider.admin.name, authProvider.admin.email),
                Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Personal Information Section
                      // _buildSectionCard(
                      //   title: 'Personal Information',
                      //   icon: Icons.person_outline,
                      //   children: [
                      //     CustomTextField(
                      //       label: 'Full Name',
                      //       controller: _nameController,
                      //       prefixIcon: const Icon(Icons.person),
                      //     ),
                      //     CustomTextField(
                      //       label: 'Email Address',
                      //       controller: _emailController,
                      //       keyboardType: TextInputType.emailAddress,
                      //       prefixIcon: const Icon(Icons.email),
                      //       enabled: false, // Email should remain unchanged
                      //     ),
                      //     const SizedBox(height: 8),
                      //     SizedBox(
                      //       width: double.infinity,
                      //       child: ElevatedButton.icon(
                      //         onPressed: authProvider.isLoading
                      //             ? null
                      //             : () async {
                      //                 final success = await authProvider
                      //                     .updateProfile(
                      //                       name: _nameController.text,
                      //                       // Email update removed
                      //                     );

                      //                 if (!mounted) return;

                      //                 ScaffoldMessenger.of(
                      //                   context,
                      //                 ).showSnackBar(
                      //                   SnackBar(
                      //                     content: Text(
                      //                       success
                      //                           ? 'Profile updated successfully'
                      //                           : (authProvider.errorMessage ??
                      //                                 'Unable to update profile'),
                      //                     ),
                      //                     backgroundColor: success
                      //                         ? Colors.green
                      //                         : Colors.red,
                      //                     behavior: SnackBarBehavior.floating,
                      //                   ),
                      //                 );
                      //               },
                      //         icon: authProvider.isLoading
                      //             ? const SizedBox.shrink()
                      //             : const Icon(Icons.save),
                      //         label: authProvider.isLoading
                      //             ? const SizedBox(
                      //                 height: 20,
                      //                 width: 20,
                      //                 child: CircularProgressIndicator(
                      //                   color: Colors.white,
                      //                   strokeWidth: 2,
                      //                 ),
                      //               )
                      //             : const Text(
                      //                 'Save Changes',
                      //                 style: TextStyle(
                      //                   fontSize: 16,
                      //                   fontWeight: FontWeight.bold,
                      //                 ),
                      //               ),
                      //         style: ElevatedButton.styleFrom(
                      //           backgroundColor: AppConstants.primaryColor,
                      //           foregroundColor: Colors.white,
                      //           padding: const EdgeInsets.symmetric(
                      //             vertical: 16,
                      //           ),
                      //           shape: RoundedRectangleBorder(
                      //             borderRadius: BorderRadius.circular(12),
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 24),
                      // Security / Change Password Section
                      _buildSectionCard(
                        title: 'Security',
                        icon: Icons.lock_outline,
                        children: [
                          CustomTextField(
                            label: 'Current Password',
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            prefixIcon: const Icon(Icons.lock_clock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrent = !_obscureCurrent;
                                });
                              },
                            ),
                          ),
                          CustomTextField(
                            label: 'New Password',
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            prefixIcon: const Icon(Icons.lock_reset),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNew = !_obscureNew;
                                });
                              },
                            ),
                          ),
                          CustomTextField(
                            label: 'Confirm New Password',
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            prefixIcon: const Icon(Icons.check_circle_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                      if (_currentPasswordController
                                              .text
                                              .isEmpty ||
                                          _newPasswordController.text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please fill all fields',
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }

                                      if (_newPasswordController.text !=
                                          _confirmPasswordController.text) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'New passwords do not match',
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }

                                      if (!_isStrongPassword(
                                        _newPasswordController.text,
                                      )) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Password must be at least 8 characters and include upper, lower, number, and special character',
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        return;
                                      }

                                      final success = await authProvider
                                          .changePassword(
                                            _currentPasswordController.text,
                                            _newPasswordController.text,
                                          );

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Password changed successfully'
                                                : (authProvider.errorMessage ??
                                                      'Failed to change password'),
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );

                                      if (success) {
                                        _currentPasswordController.clear();
                                        _newPasswordController.clear();
                                        _confirmPasswordController.clear();
                                      }
                                    },
                              icon: authProvider.isLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.security),
                              label: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Update Password',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from the admin dashboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<AuthProvider>(
                rootContext,
                listen: false,
              ).logout();

              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              Navigator.of(rootContext).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
