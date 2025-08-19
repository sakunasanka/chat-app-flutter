class EphemeralChatModel {
  final String id;
  final List<String> participants;
  final List<String> participantNames;
  final String createdAt;

  EphemeralChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.createdAt,
  });

  factory EphemeralChatModel.fromJson(Map<String, dynamic> json,
      {String? docId}) {
    return EphemeralChatModel(
      id: docId ?? json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      participantNames: List<String>.from(json['participantNames'] ?? []),
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'createdAt': createdAt,
    };
  }

  EphemeralChatModel copyWith({
    String? id,
    List<String>? participants,
    List<String>? participantNames,
    String? createdAt,
  }) {
    return EphemeralChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
