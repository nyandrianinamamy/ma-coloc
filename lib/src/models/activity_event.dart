import 'package:cloud_firestore/cloud_firestore.dart';
import 'house.dart' show TimestampConverter;

enum ActivityEventType {
  badgeEarned,
  streakMilestone,
  deepCleanDone,
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.uid,
    required this.displayName,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final ActivityEventType type;
  final String uid;
  final String displayName;
  final String detail;
  final Timestamp createdAt;

  factory ActivityEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ActivityEvent(
      id: doc.id,
      type: ActivityEventType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityEventType.badgeEarned,
      ),
      uid: data['uid'] as String,
      displayName: data['displayName'] as String,
      detail: data['detail'] as String,
      createdAt: data['createdAt'] as Timestamp,
    );
  }
}
