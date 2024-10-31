class UserProfile {
  final String profileId;
  final String username;
  final String nickname;
  final int avatarId;
  final List<int> badgeShowcase;
  final int bannerId;
  final int exp;
  final int expCap;
  final bool hasShownCongrats;
  final int level;
  final int totalBadgeUnlocked;
  final int totalStageCleared;
  final List<int> unlockedBadge;
  final List<int> unlockedBanner;
  final String email;
  final String birthday;

  UserProfile({
    required this.profileId,
    required this.username,
    required this.nickname,
    required this.avatarId,
    required this.badgeShowcase,
    required this.bannerId,
    required this.exp,
    required this.expCap,
    required this.hasShownCongrats,
    required this.level,
    required this.totalBadgeUnlocked,
    required this.totalStageCleared,
    required this.unlockedBadge,
    required this.unlockedBanner,
    required this.email,
    required this.birthday,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'username': username,
      'nickname': nickname,
      'avatarId': avatarId,
      'badgeShowcase': badgeShowcase,
      'bannerId': bannerId,
      'exp': exp,
      'expCap': expCap,
      'hasShownCongrats': hasShownCongrats,
      'level': level,
      'totalBadgeUnlocked': totalBadgeUnlocked,
      'totalStageCleared': totalStageCleared,
      'unlockedBadge': unlockedBadge,
      'unlockedBanner': unlockedBanner,
      'email': email,
      'birthday': birthday,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      profileId: map['profileId'],
      username: map['username'],
      nickname: map['nickname'],
      avatarId: map['avatarId'],
      badgeShowcase: List<int>.from(map['badgeShowcase']),
      bannerId: map['bannerId'],
      exp: map['exp'],
      expCap: map['expCap'],
      hasShownCongrats: map['hasShownCongrats'],
      level: map['level'],
      totalBadgeUnlocked: map['totalBadgeUnlocked'],
      totalStageCleared: map['totalStageCleared'],
      unlockedBadge: List<int>.from(map['unlockedBadge']),
      unlockedBanner: List<int>.from(map['unlockedBanner']),
      email: map['email'],
      birthday: map['birthday'],
    );
  }

  // Default guest profile
  static final UserProfile guestProfile = UserProfile(
    profileId: 'guest',
    username: 'Guest',
    nickname: 'Guest',
    avatarId: 0,
    badgeShowcase: [],
    bannerId: 0,
    exp: 0,
    expCap: 100,
    hasShownCongrats: false,
    level: 1,
    totalBadgeUnlocked: 0,
    totalStageCleared: 0,
    unlockedBadge: [],
    unlockedBanner: [],
    email: '',
    birthday: '2000-01-01',
  );

  UserProfile copyWith({Map<String, dynamic>? updates}) {
    Map<String, dynamic> currentMap = this.toMap();
    if (updates != null) {
      currentMap.addAll(updates);
    }
    return UserProfile.fromMap(currentMap);
  }
}