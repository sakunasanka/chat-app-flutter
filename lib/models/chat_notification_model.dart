enum NotificationStatus { pending, read }

enum NotificationType { openChat }

class ChatNotificationModel {
  final String id;
  final String to;
  final String from;
  final String fromName;
  final String chatId;
  final NotificationType type;
  final String createdAt;
  final NotificationStatus status;

  ChatNotificationModel({
    required this.id,
    required this.to,
    required this.from,
    required this.fromName,
    required this.chatId,
    required this.type,
    required this.createdAt,
    required this.status,
  });

  factory ChatNotificationModel.fromJson(Map<String, dynamic> json,
      {String? docId}) {
    NotificationType type;
    switch (json['type']) {
      default:
        type = NotificationType.openChat;
    }

    NotificationStatus status;
    switch (json['status']) {
      case 'read':
        status = NotificationStatus.read;
        break;
      default:
        status = NotificationStatus.pending;
    }

    return ChatNotificationModel(
      id: docId ?? json['id'] ?? '',
      to: json['to'] ?? '',
      from: json['from'] ?? '',
      fromName: json['fromName'] ?? '',
      chatId: json['chatId'] ?? '',
      type: type,
      createdAt: json['createdAt'] ?? '',
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      default:
        typeString = 'open_chat';
    }

    String statusString;
    switch (status) {
      case NotificationStatus.read:
        statusString = 'read';
        break;
      default:
        statusString = 'pending';
    }

    return {
      'to': to,
      'from': from,
      'fromName': fromName,
      'chatId': chatId,
      'type': typeString,
      'createdAt': createdAt,
      'status': statusString,
    };
  }

  ChatNotificationModel copyWith({
    String? id,
    String? to,
    String? from,
    String? fromName,
    String? chatId,
    NotificationType? type,
    String? createdAt,
    NotificationStatus? status,
  }) {
    return ChatNotificationModel(
      id: id ?? this.id,
      to: to ?? this.to,
      from: from ?? this.from,
      fromName: fromName ?? this.fromName,
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
