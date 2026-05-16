class MLMStats {
  final double walletBalance;
  final double totalEarnings;
  final double totalWithdrawn;
  final double totalCommission;
  final double paidCommission;
  final double pendingCommission;
  final String rank;
  final String referralCode;
  final String referralLink;
  final TeamStats teamStats;
  final int pendingWithdrawals;

  MLMStats({
    required this.walletBalance,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.totalCommission,
    required this.paidCommission,
    required this.pendingCommission,
    required this.rank,
    required this.referralCode,
    required this.referralLink,
    required this.teamStats,
    required this.pendingWithdrawals,
  });

  factory MLMStats.fromJson(Map<String, dynamic> json) {
    return MLMStats(
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      paidCommission: (json['paidCommission'] ?? 0).toDouble(),
      pendingCommission: (json['pendingCommission'] ?? 0).toDouble(),
      rank: json['rank'] ?? 'Bronze',
      referralCode: json['referralCode'] ?? '',
      referralLink: json['referralLink'] ?? '',
      teamStats: TeamStats.fromJson(json['teamStats'] ?? {}),
      pendingWithdrawals: (json['pendingWithdrawals'] ?? 0).toInt(),
    );
  }
}

class TeamStats {
  final int totalTeamSize;
  final int leftCount;
  final int rightCount;
  final int totalDirectReferrals;
  final double leftVolume;
  final double rightVolume;

  TeamStats({required this.totalTeamSize, required this.leftCount, required this.rightCount, required this.totalDirectReferrals, required this.leftVolume, required this.rightVolume});

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      totalTeamSize: (json['totalTeamSize'] ?? 0).toInt(),
      leftCount: (json['leftCount'] ?? 0).toInt(),
      rightCount: (json['rightCount'] ?? 0).toInt(),
      totalDirectReferrals: (json['totalDirectReferrals'] ?? 0).toInt(),
      leftVolume: (json['leftVolume'] ?? 0).toDouble(),
      rightVolume: (json['rightVolume'] ?? 0).toDouble(),
    );
  }
}

class MLMTreeNode {
  final String id;
  final String? userId;
  final dynamic user;
  final String position;
  final int level;
  final double leftVolume;
  final double rightVolume;
  final int leftCount;
  final int rightCount;
  final MLMTreeNode? left;
  final MLMTreeNode? right;

  MLMTreeNode({required this.id, this.userId, this.user, required this.position, required this.level, required this.leftVolume, required this.rightVolume, required this.leftCount, required this.rightCount, this.left, this.right});

  factory MLMTreeNode.fromJson(Map<String, dynamic> json) {
    return MLMTreeNode(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      user: json['user'],
      position: json['position'] ?? 'root',
      level: (json['level'] ?? 0).toInt(),
      leftVolume: (json['leftVolume'] ?? 0).toDouble(),
      rightVolume: (json['rightVolume'] ?? 0).toDouble(),
      leftCount: (json['leftCount'] ?? 0).toInt(),
      rightCount: (json['rightCount'] ?? 0).toInt(),
      left: json['left'] != null ? MLMTreeNode.fromJson(json['left']) : null,
      right: json['right'] != null ? MLMTreeNode.fromJson(json['right']) : null,
    );
  }

  String get userName => user?['name'] ?? 'N/A';
  String get userRank => user?['rank'] ?? 'Bronze';
  bool get isActive => user?['isActive'] ?? true;
}

class Commission {
  final String id;
  final String type;
  final double amount;
  final double baseAmount;
  final String status;
  final int level;
  final double? percentage;
  final String? fromUserName;
  final String? courseName;
  final DateTime createdAt;

  Commission({required this.id, required this.type, required this.amount, required this.baseAmount, required this.status, required this.level, this.percentage, this.fromUserName, this.courseName, required this.createdAt});

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      baseAmount: (json['baseAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      level: (json['level'] ?? 1).toInt(),
      percentage: json['percentage']?.toDouble(),
      fromUserName: json['fromUserId']?['name'],
      courseName: json['courseId']?['title'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
