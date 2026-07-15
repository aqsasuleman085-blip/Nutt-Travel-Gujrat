import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/broadcast_model.dart';
import '../../providers/broadcast_provider.dart';
import '../../widgets/loading_widget.dart';

/// Shows the audit trail of every broadcast the admin has sent - title,
/// category, audience summary, recipient count, and timestamp - pulled
/// from the `broadcasts` Firestore collection.
class BroadcastHistoryScreen extends StatefulWidget {
  const BroadcastHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BroadcastHistoryScreen> createState() =>
      _BroadcastHistoryScreenState();
}

class _BroadcastHistoryScreenState extends State<BroadcastHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BroadcastProvider>(context, listen: false).loadHistory();
    });
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

  String _labelForAudience(BroadcastModel b) {
    switch (b.audienceType) {
      case kBroadcastAudienceRoute:
        return 'Route: ${b.routeFrom} → ${b.routeTo} (${b.routeDate})';
      case kBroadcastAudienceUsers:
        return b.audienceLabel;
      case kBroadcastAudienceAll:
      default:
        return 'All Users';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sent Broadcasts')),
      body: Consumer<BroadcastProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingHistory) {
            return const LoadingWidget(message: 'Loading history...');
          }

          if (provider.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No broadcasts sent yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final b = provider.history[index];
                final color = _colorForCategory(b.category);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.buttonRadius),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(_iconForCategory(b.category), color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                b.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _tag(_labelForAudience(b), Icons.group),
                                  _tag('${b.recipientCount} recipient(s)',
                                      Icons.people),
                                  _tag(_formatDateTime(b.createdAt),
                                      Icons.access_time),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _tag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
