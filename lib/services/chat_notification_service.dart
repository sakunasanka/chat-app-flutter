import '../models/models.dart';
import 'base_crud_service.dart';

class ChatNotificationService extends BaseCrudService {
  static const String collection = 'chat_notifications';

  // Send a notification to the other user to open the chat
  Future<void> notifyUserToOpenChat({
    required String toUserId,
    required String fromUserId,
    required String chatId,
    String? fromUserName,
  }) async {
    try {
      await insertAuto(collection, {
        'to': toUserId,
        'from': fromUserId,
        'fromName': fromUserName ?? '',
        'chatId': chatId,
        'type': 'open_chat',
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  // Get pending chat notifications for a user
  Future<List<ChatNotificationModel>> getPendingChatNotifications(
      String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snap.docs
          .map((d) => ChatNotificationModel.fromJson(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      print('Error getting chat notifications: $e');
      return [];
    }
  }

  // Get pending chat notifications as Map (backward compatibility)
  Future<List<Map<String, dynamic>>> getPendingChatNotificationsAsMap(
      String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snap.docs.map((d) => {'id': d.id, ...(d.data())}).toList();
    } catch (e) {
      print('Error getting chat notifications: $e');
      return [];
    }
  }

  // Mark chat notification as read
  Future<void> markChatNotificationAsRead(String notificationId) async {
    try {
      await update(collection, notificationId, {
        'status': 'read',
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
