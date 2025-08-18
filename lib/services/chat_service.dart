import '../models/models.dart';
import 'base_crud_service.dart';
import 'user_service.dart';

class ChatService extends BaseCrudService {
  static const String collection = 'chats';
  static const String messagesSubCollection = 'messages';

  final UserService _userService = UserService();

  // Create a direct chat between two users
  Future<String?> createDirectChat({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
  }) async {
    try {
      // Check if chat already exists between these users
      final existingChats = await firestore
          .collection(collection)
          .where('participants', arrayContains: user1Id)
          .get();

      for (final doc in existingChats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(user2Id)) {
          // Chat already exists, return its ID
          return doc.id;
        }
      }

      // Create new chat
      final chatDoc = await firestore.collection(collection).add({
        'participants': [user1Id, user2Id],
        'participantNames': [user1Name ?? '', user2Name ?? ''],
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessage': '',
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      return chatDoc.id;
    } catch (e) {
      print('Error creating direct chat: $e');
      return null;
    }
  }

  // Get chats where the user is a participant
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      print('DEBUG: getUserChats called with userId: $userId');
      final snap = await firestore
          .collection(collection)
          .where('participants', arrayContains: userId)
          .get();

      print('DEBUG: Found ${snap.docs.length} chat documents');
      final result = snap.docs
          .map((d) => ChatModel.fromJson(d.data(), docId: d.id))
          .toList();

      // Sort by lastUpdated in memory
      result.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      print('DEBUG: Returning ${result.length} chats');
      return result;
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }

  // Stream-based method for real-time chat updates
  Stream<List<Map<String, dynamic>>> getUserChatsStream(String userId) {
    return firestore
        .collection(collection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snap) async {
      print(
          'DEBUG: getUserChatsStream received ${snap.docs.length} chat documents');

      final chats = snap.docs.map((d) => {'id': d.id, ...(d.data())}).toList();

      // Sort in memory by lastUpdated
      chats.sort((a, b) {
        final aTime = a['lastUpdated'] as String? ?? '';
        final bTime = b['lastUpdated'] as String? ?? '';
        return bTime.compareTo(aTime); // descending
      });

      // Collect the "other user" ids for each chat
      final otherIds = <String>{};
      for (final c in chats) {
        final participants = List<String>.from(c['participants'] ?? []);
        final other = participants.firstWhere(
          (p) => p != userId,
          orElse: () => '',
        );
        if (other.isNotEmpty) otherIds.add(other);
      }

      // Resolve names from users collection
      final usersMap = await _userService.getUsersByIdsAsMap(otherIds.toList());

      // Process chats with user names and unread counts efficiently
      final List<Map<String, dynamic>> processedChats = [];

      // Get unread counts for all chats in parallel
      final unreadCountFutures = chats
          .map((c) => getUnreadMessagesCount(
                chatId: c['id'],
                currentUserId: userId,
              ))
          .toList();

      final unreadCounts = await Future.wait(unreadCountFutures);

      for (int i = 0; i < chats.length; i++) {
        final c = chats[i];
        final participants = List<String>.from(c['participants'] ?? []);
        final participantNames = List.from(c['participantNames'] ?? []);
        final otherId = participants.firstWhere(
          (p) => p != userId,
          orElse: () => '',
        );
        String otherName = usersMap[otherId]?['name'] as String? ?? '';

        if (otherName.isEmpty) {
          // Fallback to stored participantNames if available
          if (participants.length == participantNames.length) {
            for (var i = 0; i < participants.length; i++) {
              if (participants[i] == otherId) {
                otherName = (participantNames[i] ?? '').toString();
                break;
              }
            }
          }
        }
        if (otherName.isEmpty) otherName = otherId.isEmpty ? 'Chat' : otherId;

        processedChats.add({
          'id': c['id'],
          'name': otherName,
          'lastMessage': c['lastMessage'] ?? '',
          'timestamp': c['lastUpdated'] ?? '',
          'unread': unreadCounts[i],
          'lastMessageFrom': c['lastMessageFrom'] ?? '',
        });
      }

      return processedChats;
    });
  }

  // Get unread messages count for a specific chat
  Future<int> getUnreadMessagesCount({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      // Query only by status to avoid composite index; filter sender client-side
      final snapshot = await firestore
          .collection(collection)
          .doc(chatId)
          .collection(messagesSubCollection)
          .where('status', whereIn: ['sent', 'delivered']).get();

      final count = snapshot.docs
          .where((d) => (d.data()['from'] as String?) != currentUserId)
          .length;
      return count;
    } catch (e) {
      print('Error getting unread messages count: $e');
      return 0;
    }
  }

  // Get total unread chats count
  Future<int> getTotalUnreadMessagesCount(String userId) async {
    try {
      final chats = await getUserChatsStream(userId).first;
      int unreadChatsCount = 0;

      for (final chat in chats) {
        final unreadValue = chat['unread'] ?? 0;
        final unreadCount = unreadValue is int
            ? unreadValue
            : int.tryParse(unreadValue.toString()) ?? 0;
        if (unreadCount > 0) {
          unreadChatsCount++;
        }
      }

      return unreadChatsCount;
    } catch (e) {
      print('Error getting total unread chats count: $e');
      return 0;
    }
  }

  // Update chat last message and timestamp
  Future<void> updateChatLastMessage({
    required String chatId,
    required String lastMessage,
    required String lastMessageFrom,
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      await update(collection, chatId, {
        'lastMessage': lastMessage,
        'lastUpdated': now,
        'lastMessageFrom': lastMessageFrom,
      });
    } catch (e) {
      print('Error updating chat last message: $e');
    }
  }

  // Touch chat to trigger UI refresh
  Future<void> touchChatForRefresh(String chatId) async {
    try {
      await update(collection, chatId, {
        'unreadRecalcAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error touching chat for refresh: $e');
    }
  }
}
