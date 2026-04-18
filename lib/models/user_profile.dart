class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String profilePicture;
  final String memberSince;
  final String subscription;
  final String farmId;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePicture = '',
    this.memberSince = '',
    this.subscription = 'Free',
    this.farmId = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      memberSince: json['member_since']?.toString() ?? DateTime.now().toIso8601String(),
      subscription: json['subscription'] ?? 'Free',
      farmId: json['farm_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'member_since': memberSince.isNotEmpty ? memberSince : DateTime.now().toIso8601String(),
      'subscription': subscription,
      'farm_id': farmId.isNotEmpty ? farmId : null,
    };
  }
}