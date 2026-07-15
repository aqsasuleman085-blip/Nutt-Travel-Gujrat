import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/broadcast_model.dart';
import '../../providers/auth_provider.dart' as admin_auth;
import '../../providers/broadcast_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'select_users_screen.dart';
import 'broadcast_history_screen.dart';

/// New admin section: lets the admin send a broadcast/announcement to
/// passengers - e.g. road blockages, weather disruptions, or bus
/// cancellations - as opposed to the automatic per-booking notifications
/// (approved/rejected/refunded) that already exist elsewhere in the app.
///
/// Supports three audiences:
///   - All Users     -> every registered user (e.g. discount offers)
///   - Specific Route -> users with an APPROVED booking matching a from/to
///                       route AND a specific travel date (both required)
///   - Specific Users -> a manually picked list of individual users
class SendBroadcastScreen extends StatefulWidget {
  const SendBroadcastScreen({Key? key}) : super(key: key);

  @override
  State<SendBroadcastScreen> createState() => _SendBroadcastScreenState();
}

class _SendBroadcastScreenState extends State<SendBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  final _routeFromController = TextEditingController();
  final _routeToController = TextEditingController();

  String _category = kBroadcastCategoryInfo;
  String _audienceType = kBroadcastAudienceAll;
  DateTime? _routeDate;
  List<SelectableUser> _selectedUsers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _routeFromController.dispose();
    _routeToController.dispose();
    super.dispose();
  }

  String get _categoryLabel {
    switch (_category) {
      case kBroadcastCategoryWarning:
        return 'Warning';
      case kBroadcastCategoryCritical:
        return 'Critical';
      case kBroadcastCategoryCancellation:
        return 'Cancellation';
      case kBroadcastCategoryInfo:
      default:
        return 'Info';
    }
  }

  Color get _categoryColor {
    switch (_category) {
      case kBroadcastCategoryWarning:
        return Colors.orange;
      case kBroadcastCategoryCritical:
        return Colors.red;
      case kBroadcastCategoryCancellation:
        return Colors.red.shade900;
      case kBroadcastCategoryInfo:
      default:
        return Colors.blue;
    }
  }

  IconData get _categoryIcon {
    switch (_category) {
      case kBroadcastCategoryWarning:
        return Icons.warning_amber_rounded;
      case kBroadcastCategoryCritical:
        return Icons.report_problem_rounded;
      case kBroadcastCategoryCancellation:
        return Icons.cancel_rounded;
      case kBroadcastCategoryInfo:
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _pickRouteDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _routeDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _routeDate = picked);
    }
  }

  Future<void> _openUserPicker() async {
    final result = await Navigator.push<List<SelectableUser>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersScreen(initiallySelected: _selectedUsers),
      ),
    );
    if (result != null) {
      setState(() => _selectedUsers = result);
    }
  }

  bool _validateAudience() {
    switch (_audienceType) {
      case kBroadcastAudienceRoute:
        if (_routeFromController.text.trim().isEmpty ||
            _routeToController.text.trim().isEmpty ||
            _routeDate == null) {
          _showError('Please enter From, To, and select a travel date.');
          return false;
        }
        return true;

      case kBroadcastAudienceUsers:
        if (_selectedUsers.isEmpty) {
          _showError('Please select at least one user.');
          return false;
        }
        return true;

      case kBroadcastAudienceAll:
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _confirmAndSend() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateAudience()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Broadcast?'),
        content: Text(
          'This will send a "$_categoryLabel" notification to '
          '${_audienceSummary()}. This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final broadcastProvider =
        Provider.of<BroadcastProvider>(context, listen: false);
    final adminAuth =
        Provider.of<admin_auth.AuthProvider>(context, listen: false);

    try {
      final count = await broadcastProvider.sendBroadcast(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        category: _category,
        audienceType: _audienceType,
        routeFrom: _routeFromController.text.trim(),
        routeTo: _routeToController.text.trim(),
        routeDate:
            _routeDate != null ? DateFormat('yyyy-MM-dd').format(_routeDate!) : '',
        selectedUsers: _selectedUsers,
        sentByName: adminAuth.admin.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Broadcast sent to $count user(s) successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _titleController.clear();
        _messageController.clear();
        _routeFromController.clear();
        _routeToController.clear();
        _routeDate = null;
        _selectedUsers = [];
        _category = kBroadcastCategoryInfo;
        _audienceType = kBroadcastAudienceAll;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send broadcast: $e');
    }
  }

  String _audienceSummary() {
    switch (_audienceType) {
      case kBroadcastAudienceRoute:
        return 'everyone with an approved booking on '
            '${_routeFromController.text} → ${_routeToController.text} '
            'on ${_routeDate != null ? _formatDate(_routeDate!) : ''}';
      case kBroadcastAudienceUsers:
        return '${_selectedUsers.length} selected user(s)';
      case kBroadcastAudienceAll:
      default:
        return 'all registered users';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sent Broadcasts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BroadcastHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<BroadcastProvider>(
        builder: (context, broadcastProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                _buildPreviewBanner(),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Title',
                  hintText: 'e.g. Road Blockage Alert',
                  controller: _titleController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                CustomTextField(
                  label: 'Message',
                  hintText:
                      'e.g. Due to a landslide, the M-4 route is temporarily closed. Buses on this route are delayed by 2-3 hours.',
                  controller: _messageController,
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Message is required'
                      : null,
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 8),
                _buildCategoryPicker(),

                const SizedBox(height: 20),
                _buildAudiencePicker(),

                const SizedBox(height: 16),
                _buildAudienceDetailFields(),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        broadcastProvider.isSending ? null : _confirmAndSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.buttonRadius),
                      ),
                    ),
                    child: broadcastProvider.isSending
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Send Broadcast',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View Sent Broadcasts'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BroadcastHistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        border: Border.all(color: _categoryColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(_categoryIcon, color: _categoryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _titleController.text.isEmpty
                  ? 'This is how the notification will appear to passengers.'
                  : _titleController.text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _categoryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppConstants.darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kBroadcastCategories.map((cat) {
            final selected = _category == cat;
            return ChoiceChip(
              label: Text(_labelForCategory(cat)),
              selected: selected,
              onSelected: (_) => setState(() => _category = cat),
              selectedColor: _colorForCategory(cat).withOpacity(0.25),
              labelStyle: TextStyle(
                color: selected ? _colorForCategory(cat) : Colors.black87,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              avatar: Icon(
                _iconForCategory(cat),
                size: 18,
                color: _colorForCategory(cat),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAudiencePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Send To',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppConstants.darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        _audienceOption(
          value: kBroadcastAudienceAll,
          title: 'All Users',
          subtitle: 'Every registered passenger (e.g. discount offers)',
          icon: Icons.public,
        ),
        _audienceOption(
          value: kBroadcastAudienceRoute,
          title: 'Specific Route',
          subtitle: 'Passengers with an approved booking on a route + date',
          icon: Icons.alt_route,
        ),
        _audienceOption(
          value: kBroadcastAudienceUsers,
          title: 'Specific Users',
          subtitle: 'Manually pick individual passengers',
          icon: Icons.people_alt,
        ),
      ],
    );
  }

  Widget _audienceOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _audienceType == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? AppConstants.primaryColor.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        side: BorderSide(
          color: selected ? AppConstants.primaryColor : Colors.grey.shade300,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _audienceType,
        onChanged: (v) => setState(() => _audienceType = v!),
        activeColor: AppConstants.primaryColor,
        secondary: Icon(icon, color: AppConstants.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildAudienceDetailFields() {
    switch (_audienceType) {
      case kBroadcastAudienceRoute:
        return Column(
          children: [
            CustomTextField(
              label: 'From City',
              hintText: 'e.g. Gujrat',
              controller: _routeFromController,
              onChanged: (_) => setState(() {}),
            ),
            CustomTextField(
              label: 'To City',
              hintText: 'e.g. Lahore',
              controller: _routeToController,
              onChanged: (_) => setState(() {}),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Travel Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: AppConstants.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickRouteDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppConstants.buttonRadius),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _routeDate == null
                              ? 'Select date'
                              : _formatDate(_routeDate!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        );

      case kBroadcastAudienceUsers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _openUserPicker,
              icon: const Icon(Icons.person_add_alt),
              label: Text(
                _selectedUsers.isEmpty
                    ? 'Select Users'
                    : '${_selectedUsers.length} user(s) selected',
              ),
            ),
            if (_selectedUsers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedUsers
                    .map((u) => Chip(
                          label: Text(u.name),
                          onDeleted: () {
                            setState(() => _selectedUsers = List.of(_selectedUsers)
                              ..remove(u));
                          },
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        );

      case kBroadcastAudienceAll:
      default:
        return const SizedBox.shrink();
    }
  }

  String _labelForCategory(String cat) {
    switch (cat) {
      case kBroadcastCategoryWarning:
        return 'Warning';
      case kBroadcastCategoryCritical:
        return 'Critical';
      case kBroadcastCategoryCancellation:
        return 'Cancellation';
      case kBroadcastCategoryInfo:
      default:
        return 'Info';
    }
  }

  Color _colorForCategory(String cat) {
    switch (cat) {
      case kBroadcastCategoryWarning:
        return Colors.orange;
      case kBroadcastCategoryCritical:
        return Colors.red;
      case kBroadcastCategoryCancellation:
        return Colors.red.shade900;
      case kBroadcastCategoryInfo:
      default:
        return Colors.blue;
    }
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case kBroadcastCategoryWarning:
        return Icons.warning_amber_rounded;
      case kBroadcastCategoryCritical:
        return Icons.report_problem_rounded;
      case kBroadcastCategoryCancellation:
        return Icons.cancel_rounded;
      case kBroadcastCategoryInfo:
      default:
        return Icons.info_rounded;
    }
  }
}
