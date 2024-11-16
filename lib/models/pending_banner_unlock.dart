/// Represents a banner unlock operation that needs to be processed later
/// when the device comes back online.
class PendingBannerUnlock {
  final int bannerId;
  final int unlockedAtLevel;
  final DateTime timestamp;
  final List<int> unlockState;  // Store complete unlock array

  const PendingBannerUnlock({
    required this.bannerId,
    required this.unlockedAtLevel,
    required this.timestamp,
    required this.unlockState,  // Add to constructor
  });

  Map<String, dynamic> toJson() => {
    'bannerId': bannerId,
    'unlockedAtLevel': unlockedAtLevel,
    'timestamp': timestamp.toIso8601String(),
    'unlockState': unlockState.toList(),  // Add to JSON
  };

  factory PendingBannerUnlock.fromJson(Map<String, dynamic> json) => 
    PendingBannerUnlock(
      bannerId: json['bannerId'] as int,
      unlockedAtLevel: json['unlockedAtLevel'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      unlockState: List<int>.from(json['unlockState']),
    );
} 