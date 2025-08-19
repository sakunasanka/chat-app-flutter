import '../models/models.dart';
import 'base_crud_service.dart';
import 'chat_service.dart';

class MessageService extends BaseCrudService {
  final ChatService _chatService = ChatService();

  // Send a message to persistent chat
  Future<void> sendPersistentMessage({
    required String chatId,
    required String fromUserId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();
    final batch = getBatch();

    final msgRef = firestore
        .collection(ChatService.collection)
        .doc(chatId)
        .collection(ChatService.messagesSubCollection)
        .doc();

    batch.set(msgRef, {
      'text': text,
      'from': fromUserId,
      'createdAt': now,
      'status': 'sent',
      'deliveredAt': null,
      'readAt': null,
    });

    // Get chat participants to unhide the chat for any user who had hidden it
    final chatDoc =
        await firestore.collection(ChatService.collection).doc(chatId).get();

    if (chatDoc.exists) {
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final hiddenForUsers =
          List<String>.from(chatData['hiddenForUsers'] ?? []);

      // Remove all participants from hiddenForUsers when a new message is sent
      // This ensures the chat reappears for anyone who had hidden it
      final updatedHiddenForUsers = hiddenForUsers
          .where((userId) => !participants.contains(userId))
          .toList();

      batch.update(firestore.collection(ChatService.collection).doc(chatId), {
        'lastMessage': text,
        'lastUpdated': now,
        'lastMessageFrom': fromUserId,
        'hiddenForUsers': updatedHiddenForUsers,
      });
    } else {
      // Fallback if chat doesn't exist (shouldn't happen)
      batch.update(firestore.collection(ChatService.collection).doc(chatId), {
        'lastMessage': text,
        'lastUpdated': now,
        'lastMessageFrom': fromUserId,
      });
    }

    await commitBatch(batch);

    // Mark message as delivered immediately (simulating instant delivery)
    await Future.delayed(const Duration(milliseconds: 500));
    await _markMessageAsDelivered(chatId, msgRef.id);
  }

  // Helper method to mark a message as delivered
  Future<void> _markMessageAsDelivered(String chatId, String messageId) async {
    try {
      await firestore
          .collection(ChatService.collection)
          .doc(chatId)
          .collection(ChatService.messagesSubCollection)
          .doc(messageId)
          .update({
        'status': 'delivered',
        'deliveredAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error marking message as delivered: $e');
    }
  }

  // Mark messages as read when user opens the chat
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      print(
          'DEBUG: Marking messages as read for chat $chatId by user $currentUserId');

      // Query only by status to avoid composite index; filter sender client-side
      final unreadMessages = await firestore
          .collection(ChatService.collection)
          .doc(chatId)
          .collection(ChatService.messagesSubCollection)
          .where('status', whereIn: ['sent', 'delivered']).get();

      print('DEBUG: Found ${unreadMessages.docs.length} unread messages');

      final batch = getBatch();
      final now = DateTime.now().toIso8601String();

      int toUpdate = 0;
      for (final doc in unreadMessages.docs) {
        final data = doc.data();
        final from = (data['from'] as String?) ?? '';
        final status = (data['status'] as String?) ?? 'sent';
        if (from != currentUserId &&
            (status == 'sent' || status == 'delivered')) {
          batch.update(doc.reference, {
            'status': 'read',
            'readAt': now,
          });
          toUpdate++;
          print('DEBUG: Marking message ${doc.id} as read');
        }
      }

      // Touch the parent chat doc to trigger chat list stream recompute
      await _chatService.touchChatForRefresh(chatId);

      if (toUpdate > 0) {
        await commitBatch(batch);
        print('DEBUG: Successfully marked $toUpdate messages as read');
      } else {
        // Still commit to ensure any other changes are applied
        await commitBatch(batch);
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get messages for a chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final snapshot = await firestore
          .collection(ChatService.collection)
          .doc(chatId)
          .collection(ChatService.messagesSubCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Get messages stream for real-time updates
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return firestore
        .collection(ChatService.collection)
        .doc(chatId)
        .collection(ChatService.messagesSubCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }
}
