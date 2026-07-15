import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/broadcast_provider.dart';
import '../../widgets/loading_widget.dart';

/// Search-and-select screen used for the "Specific Users" broadcast
/// audience. Loads every document from the `users` Firestore collection
/// and lets the admin check off individual passengers by name/email.
class SelectUsersScreen extends StatefulWidget {
  final List<SelectableUser> initiallySelected;

  const SelectUsersScreen({Key? key, required this.initiallySelected})
      : super(key: key);

  @override
  State<SelectUsersScreen> createState() => _SelectUsersScreenState();
}

class _SelectUsersScreenState extends State<SelectUsersScreen> {
  late Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initiallySelected.map((u) => u.uid).toSet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BroadcastProvider>(context, listen: false);
      if (provider.allUsers.isEmpty) {
        provider.loadAllUsers();
      }
    });
  }

  void _done() {
    final provider = Provider.of<BroadcastProvider>(context, listen: false);
    final selected =
        provider.allUsers.where((u) => _selectedIds.contains(u.uid)).toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Users'),
        actions: [
          TextButton(
            onPressed: _done,
            child: Text(
              'Done (${_selectedIds.length})',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Consumer<BroadcastProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingUsers) {
            return const LoadingWidget(message: 'Loading users...');
          }

          final filtered = provider.allUsers.where((u) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.buttonRadius),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (filtered.isEmpty)
                const Expanded(
                  child: Center(child: Text('No users found')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final selected = _selectedIds.contains(user.uid);
                      return CheckboxListTile(
                        value: selected,
                        activeColor: AppConstants.primaryColor,
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(user.uid);
                            } else {
                              _selectedIds.remove(user.uid);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
