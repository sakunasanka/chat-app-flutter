enum InviteStatus { pending, accepted, declined }

enum InviteType { instant, continues }

class ChatInviteModel {
  final String id;
  final String from;
  final String to;
  final String fromName;
  final String toName;
  final InviteType type;
  final InviteStatus status;
  final String createdAt;
  final String updatedAt;
  final String? chatId;
  final String? ephemeralId;
  final bool fromNotified;

  ChatInviteModel({
    required this.id,
    required this.from,
    required this.to,
    required this.fromName,
    required this.toName,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.chatId,
    this.ephemeralId,
    required this.fromNotified,
  });

  factory ChatInviteModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    InviteType type;
    switch (json['type']) {
      case 'continue':
        type = InviteType.continues;
        break;
      default:
        type = InviteType.instant;
    }

    InviteStatus status;
    switch (json['status']) {
      case 'accepted':
        status = InviteStatus.accepted;
        break;
      case 'declined':
        status = InviteStatus.declined;
        break;
      default:
        status = InviteStatus.pending;
    }

    return ChatInviteModel(
      id: docId ?? json['id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      fromName: json['fromName'] ?? '',
      toName: json['toName'] ?? '',
      type: type,
      status: status,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      chatId: json['chatId'],
      ephemeralId: json['ephemeralId'],
      fromNotified: json['fromNotified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case InviteType.continues:
        typeString = 'continue';
        break;
      default:
        typeString = 'instant';
    }

    String statusString;
    switch (status) {
      case InviteStatus.accepted:
        statusString = 'accepted';
        break;
      case InviteStatus.declined:
        statusString = 'declined';
        break;
      default:
        statusString = 'pending';
    }

    return {
      'from': from,
      'to': to,
      'fromName': fromName,
      'toName': toName,
      'type': typeString,
      'status': statusString,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (chatId != null) 'chatId': chatId,
      if (ephemeralId != null) 'ephemeralId': ephemeralId,
      'fromNotified': fromNotified,
    };
  }

  ChatInviteModel copyWith({
    String? id,
    String? from,
    String? to,
    String? fromName,
    String? toName,
    InviteType? type,
    InviteStatus? status,
    String? createdAt,
    String? updatedAt,
    String? chatId,
    String? ephemeralId,
    bool? fromNotified,
  }) {
    return ChatInviteModel(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      fromName: fromName ?? this.fromName,
      toName: toName ?? this.toName,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatId: chatId ?? this.chatId,
      ephemeralId: ephemeralId ?? this.ephemeralId,
      fromNotified: fromNotified ?? this.fromNotified,
    );
  }
}
