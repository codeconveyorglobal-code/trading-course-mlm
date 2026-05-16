class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? profilePicture;
  final String referralCode;
  final String? referredBy;
  final String rank;
  final bool isActive;
  final double walletBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final String? cryptoWalletAddress;
  final List<String> purchasedCourses;
  final DateTime joinDate;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profilePicture,
    required this.referralCode,
    this.referredBy,
    required this.rank,
    required this.isActive,
    required this.walletBalance,
    required this.totalEarnings,
    required this.totalWithdrawn,
    this.cryptoWalletAddress,
    required this.purchasedCourses,
    required this.joinDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      profilePicture: json['profilePicture'],
      referralCode: json['referralCode'] ?? '',
      referredBy: json['referredBy'],
      rank: json['rank'] ?? 'Bronze',
      isActive: json['isActive'] ?? true,
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] ?? 0).toDouble(),
      cryptoWalletAddress: json['cryptoWalletAddress'],
      purchasedCourses: List<String>.from(json['purchasedCourses']?.map((c) => c is String ? c : c['_id'] ?? '') ?? []),
      joinDate: DateTime.tryParse(json['joinDate'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool hasCourse(String courseId) => purchasedCourses.contains(courseId);
}
