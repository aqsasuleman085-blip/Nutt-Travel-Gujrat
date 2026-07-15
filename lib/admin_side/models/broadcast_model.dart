/// Represents one "broadcast" announcement sent by the admin - e.g. a road
/// blockage, weather disruption, or bus cancellation notice, as opposed to
/// the existing per-booking transactional notifications (approved/rejected/
/// refunded) that already exist elsewhere in the app.
///
/// Every broadcast is stored as its own document in the `broadcasts`
/// Firestore collection purely as a **send history / audit trail** for the
/// admin ("Sent Broadcasts" screen). The actual delivery to each recipient
/// happens separately by writing one entry per user into the existing
/// `user_notifications/{uid}` Realtime Database path, so it shows up in the
/// same notification bell/screen passengers already use for booking alerts.
class BroadcastModel {
  final String id;
  final String title;
  final String message;

  /// One of [kBroadcastCategories] - drives the color/icon shown on the
  /// user side (Info / Warning / Critical / Cancellation).
  final String category;

  /// One of [kBroadcastAudienceTypes] - describes WHO this was sent to.
  final String audienceType;

  /// Human-readable summary of the target, e.g. "Gujrat → Lahore" for a
  /// route broadcast, or "3 selected users" for a manual pick. Purely for
  /// display in the send-history list - not used for any lookup logic.
  final String audienceLabel;

  /// Route fields - only populated when audienceType == 'route'. Date is
  /// required for route broadcasts so the admin always targets one
  /// specific day's travellers (e.g. "Gujrat → Lahore on 2026-07-20"),
  /// not the whole route indefinitely.
  final String routeFrom;
  final String routeTo;
  final String routeDate;

  /// Recipient user IDs actually notified - kept so the admin can see
  /// exactly who received this broadcast after the fact.
  final List<String> recipientIds;
  final int recipientCount;

  final String sentByName;
  final DateTime createdAt;

  BroadcastModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.audienceType,
    required this.audienceLabel,
    this.routeFrom = '',
    this.routeTo = '',
    this.routeDate = '',
    this.recipientIds = const [],
    this.recipientCount = 0,
    this.sentByName = 'Admin',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'audienceType': audienceType,
      'audienceLabel': audienceLabel,
      'routeFrom': routeFrom,
      'routeTo': routeTo,
      'routeDate': routeDate,
      'recipientIds': recipientIds,
      'recipientCount': recipientCount,
      'sentByName': sentByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BroadcastModel.fromMap(Map<String, dynamic> map) {
    return BroadcastModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      category: map['category'] ?? kBroadcastCategoryInfo,
      audienceType: map['audienceType'] ?? kBroadcastAudienceAll,
      audienceLabel: map['audienceLabel'] ?? '',
      routeFrom: map['routeFrom'] ?? '',
      routeTo: map['routeTo'] ?? '',
      routeDate: map['routeDate'] ?? '',
      recipientIds: map['recipientIds'] != null
          ? List<String>.from(map['recipientIds'])
          : const [],
      recipientCount: (map['recipientCount'] is num)
          ? (map['recipientCount'] as num).toInt()
          : 0,
      sentByName: map['sentByName'] ?? 'Admin',
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared constants - category and audience-type keys, kept in one place so
// the compose screen, model, and card widget can never drift out of sync.
// ─────────────────────────────────────────────────────────────────────────

const String kBroadcastCategoryInfo = 'info';
const String kBroadcastCategoryWarning = 'warning';
const String kBroadcastCategoryCritical = 'critical';
const String kBroadcastCategoryCancellation = 'cancellation';

const List<String> kBroadcastCategories = [
  kBroadcastCategoryInfo,
  kBroadcastCategoryWarning,
  kBroadcastCategoryCritical,
  kBroadcastCategoryCancellation,
];

const String kBroadcastAudienceAll = 'all';
const String kBroadcastAudienceRoute = 'route';
const String kBroadcastAudienceUsers = 'users';

const List<String> kBroadcastAudienceTypes = [
  kBroadcastAudienceAll,
  kBroadcastAudienceRoute,
  kBroadcastAudienceUsers,
];
