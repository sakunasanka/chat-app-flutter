import '../models/models.dart';
import 'base_crud_service.dart';

class EphemeralChatService extends BaseCrudService {
  static const String collection = 'ephemeral_chats';
  static const String messagesSubCollection = 'messages';

  // Create an ephemeral session (instant chat)
  Future<String?> createEphemeralSession({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final doc = await firestore.collection(collection).add({
        'participants': [user1Id, user2Id],
        'participantNames': [user1Name ?? '', user2Name ?? ''],
        'createdAt': now,
      });
      return doc.id;
    } catch (e) {
      print('Error creating ephemeral session: $e');
      return null;
    }
  }

  // Send a message to ephemeral session
  Future<void> sendEphemeralMessage({
    required String sessionId,
    required String fromUserId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      await firestore
          .collection(collection)
          .doc(sessionId)
          .collection(messagesSubCollection)
          .add({
        'text': text,
        'from': fromUserId,
        'createdAt': now,
        'status': 'delivered', // Ephemeral messages are immediately delivered
        'deliveredAt': now,
        'readAt': null,
      });
    } catch (e) {
      print('Error sending ephemeral message: $e');
    }
  }

  // Get ephemeral session by ID
  Future<EphemeralChatModel?> getEphemeralSession(String sessionId) async {
    try {
      final doc = await firestore.collection(collection).doc(sessionId).get();
      if (doc.exists) {
        return EphemeralChatModel.fromJson(doc.data()!, docId: doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting ephemeral session: $e');
      return null;
    }
  }

  // Get ephemeral messages
  Future<List<MessageModel>> getEphemeralMessages(String sessionId) async {
    try {
      final snapshot = await firestore
          .collection(collection)
          .doc(sessionId)
          .collection(messagesSubCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      print('Error getting ephemeral messages: $e');
      return [];
    }
  }

  // Get ephemeral messages stream
  Stream<List<MessageModel>> getEphemeralMessagesStream(String sessionId) {
    return firestore
        .collection(collection)
        .doc(sessionId)
        .collection(messagesSubCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data(), docId: doc.id))
            .toList());
  }

  // Delete an ephemeral session and its messages (best-effort)
  Future<void> deleteEphemeralSession(String sessionId) async {
    try {
      final msgs = await firestore
          .collection(collection)
          .doc(sessionId)
          .collection(messagesSubCollection)
          .get();

      final batch = getBatch();
      for (final d in msgs.docs) {
        batch.delete(d.reference);
      }
      await commitBatch(batch);
    } catch (e) {
      // ignore message deletion errors
      print('Error deleting ephemeral messages: $e');
    }

    try {
      await delete(collection, sessionId);
    } catch (e) {
      print('Error deleting ephemeral session: $e');
    }
  }
}
