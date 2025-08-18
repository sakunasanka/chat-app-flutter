class ChatModel {
  final String id;
  final List<String> participants;
  final List<String> participantNames;
  final String createdAt;
  final String lastMessage;
  final String lastUpdated;
  final String? lastMessageFrom;
  final String? unreadRecalcAt;
  final List<String>
      hiddenForUsers; // New field to track users who have hidden this chat

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.createdAt,
    required this.lastMessage,
    required this.lastUpdated,
    this.lastMessageFrom,
    this.unreadRecalcAt,
    this.hiddenForUsers = const [], // Default to empty list
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ChatModel(
      id: docId ?? json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      participantNames: List<String>.from(json['participantNames'] ?? []),
      createdAt: json['createdAt'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastUpdated: json['lastUpdated'] ?? '',
      lastMessageFrom: json['lastMessageFrom'],
      unreadRecalcAt: json['unreadRecalcAt'],
      hiddenForUsers: List<String>.from(json['hiddenForUsers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'createdAt': createdAt,
      'lastMessage': lastMessage,
      'lastUpdated': lastUpdated,
      'hiddenForUsers': hiddenForUsers,
      if (lastMessageFrom != null) 'lastMessageFrom': lastMessageFrom,
      if (unreadRecalcAt != null) 'unreadRecalcAt': unreadRecalcAt,
    };
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    List<String>? participantNames,
    String? createdAt,
    String? lastMessage,
    String? lastUpdated,
    String? lastMessageFrom,
    String? unreadRecalcAt,
    List<String>? hiddenForUsers,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastMessageFrom: lastMessageFrom ?? this.lastMessageFrom,
      unreadRecalcAt: unreadRecalcAt ?? this.unreadRecalcAt,
      hiddenForUsers: hiddenForUsers ?? this.hiddenForUsers,
    );
  }
}
