import 'base_crud_service.dart';
import 'chat_service.dart';

class ChatRequestService extends BaseCrudService {
  static const String collection = 'chat_requests';

  final ChatService _chatService = ChatService();

  // Create a chat request from one user to another
  Future<String?> createChatRequest({
    required String fromId,
    required String toId,
    String? fromName,
    String? toName,
  }) async {
    try {
      final docRef = await firestore.collection(collection).add({
        'from': fromId,
        'to': toId,
        'fromName': fromName ?? '',
        'toName': toName ?? '',
        'status': 'pending', // pending | accepted | declined
        'createdAt': DateTime.now().toIso8601String(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating chat request: $e');
      return null;
    }
  }

  // Get pending chat requests addressed to a user
  Future<List<Map<String, dynamic>>> getPendingRequestsForUser(
      String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snap.docs.map((d) => {'id': d.id, ...(d.data())}).toList();
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  // Respond to a chat request. If accepted, create a chat document and return its id
  Future<String?> respondChatRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      final reqRef = firestore.collection(collection).doc(requestId);
      final reqSnap = await reqRef.get();
      if (!reqSnap.exists) return null;

      final data = reqSnap.data()!;
      final from = data['from'] as String? ?? '';
      final to = data['to'] as String? ?? '';

      await update(
          collection, requestId, {'status': accept ? 'accepted' : 'declined'});

      if (!accept) return null;

      // Create chat for both users
      return await _chatService.createDirectChat(
        user1Id: from,
        user2Id: to,
        user1Name: data['fromName'] ?? '',
        user2Name: data['toName'] ?? '',
      );
    } catch (e) {
      print('Error responding to request: $e');
      return null;
    }
  }
}
