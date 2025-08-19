enum MessageStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String text;
  final String from;
  final String createdAt;
  final MessageStatus status;
  final String? deliveredAt;
  final String? readAt;

  MessageModel({
    required this.id,
    required this.text,
    required this.from,
    required this.createdAt,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    MessageStatus status;
    switch (json['status']) {
      case 'delivered':
        status = MessageStatus.delivered;
        break;
      case 'read':
        status = MessageStatus.read;
        break;
      default:
        status = MessageStatus.sent;
    }

    return MessageModel(
      id: docId ?? json['id'] ?? '',
      text: json['text'] ?? '',
      from: json['from'] ?? '',
      createdAt: json['createdAt'] ?? '',
      status: status,
      deliveredAt: json['deliveredAt'],
      readAt: json['readAt'],
    );
  }

  Map<String, dynamic> toJson() {
    String statusString;
    switch (status) {
      case MessageStatus.delivered:
        statusString = 'delivered';
        break;
      case MessageStatus.read:
        statusString = 'read';
        break;
      default:
        statusString = 'sent';
    }

    return {
      'text': text,
      'from': from,
      'createdAt': createdAt,
      'status': statusString,
      if (deliveredAt != null) 'deliveredAt': deliveredAt,
      if (readAt != null) 'readAt': readAt,
    };
  }

  MessageModel copyWith({
    String? id,
    String? text,
    String? from,
    String? createdAt,
    MessageStatus? status,
    String? deliveredAt,
    String? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      from: from ?? this.from,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
