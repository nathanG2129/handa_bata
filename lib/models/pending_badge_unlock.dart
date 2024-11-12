/// Represents a badge unlock operation that needs to be processed later
/// when the device comes back online.
class PendingBadgeUnlock {
  final List<int> badgeIds;
  final String unlockType;  // 'arcade' or 'adventure'
  final Map<String, dynamic> unlockContext;
  final DateTime timestamp;

  const PendingBadgeUnlock({
    required this.badgeIds,
    required this.unlockType,
    required this.unlockContext,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'badgeIds': badgeIds,
    'unlockType': unlockType,
    'unlockContext': unlockContext,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PendingBadgeUnlock.fromJson(Map<String, dynamic> json) => PendingBadgeUnlock(
    badgeIds: List<int>.from(json['badgeIds']),
    unlockType: json['unlockType'],
    unlockContext: Map<String, dynamic>.from(json['unlockContext']),
    timestamp: DateTime.parse(json['timestamp']),
  );
} 