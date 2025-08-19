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
        'hiddenForUsers': [], // Initialize as empty list
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

      // Filter out chats that are hidden for this user
      final visibleChats = snap.docs.where((d) {
        final data = d.data();
        final hiddenForUsers = List<String>.from(data['hiddenForUsers'] ?? []);
        return !hiddenForUsers.contains(userId);
      }).toList();

      final chats =
          visibleChats.map((d) => {'id': d.id, ...(d.data())}).toList();

      print(
          'DEBUG: Showing ${chats.length} visible chats (${snap.docs.length - chats.length} hidden)');

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

  // Hide a chat for a specific user (instead of deleting completely)
  Future<bool> hideChatForUser({
    required String chatId,
    required String userId,
  }) async {
    try {
      // Get the current chat document
      final chatDoc = await firestore.collection(collection).doc(chatId).get();

      if (!chatDoc.exists) {
        print('Chat $chatId not found');
        return false;
      }

      final data = chatDoc.data()!;
      final hiddenForUsers = List<String>.from(data['hiddenForUsers'] ?? []);

      // Add the user to the hiddenForUsers list if not already there
      if (!hiddenForUsers.contains(userId)) {
        hiddenForUsers.add(userId);

        await update(collection, chatId, {
          'hiddenForUsers': hiddenForUsers,
        });

        print('Successfully hid chat $chatId for user $userId');
      } else {
        print('Chat $chatId already hidden for user $userId');
      }

      return true;
    } catch (e) {
      print('Error hiding chat $chatId for user $userId: $e');
      return false;
    }
  }

  // Unhide a chat for a specific user (when they receive a new message)
  Future<bool> unhideChatForUser({
    required String chatId,
    required String userId,
  }) async {
    try {
      // Get the current chat document
      final chatDoc = await firestore.collection(collection).doc(chatId).get();

      if (!chatDoc.exists) {
        print('Chat $chatId not found');
        return false;
      }

      final data = chatDoc.data()!;
      final hiddenForUsers = List<String>.from(data['hiddenForUsers'] ?? []);

      // Remove the user from the hiddenForUsers list if present
      if (hiddenForUsers.contains(userId)) {
        hiddenForUsers.remove(userId);

        await update(collection, chatId, {
          'hiddenForUsers': hiddenForUsers,
        });

        print('Successfully unhid chat $chatId for user $userId');
      }

      return true;
    } catch (e) {
      print('Error unhiding chat $chatId for user $userId: $e');
      return false;
    }
  }

  // Delete a chat completely (only if both users have hidden it)
  Future<bool> deleteChat(String chatId) async {
    try {
      // Get the current chat document
      final chatDoc = await firestore.collection(collection).doc(chatId).get();

      if (!chatDoc.exists) {
        print('Chat $chatId not found');
        return false;
      }

      final data = chatDoc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final hiddenForUsers = List<String>.from(data['hiddenForUsers'] ?? []);

      // Check if all participants have hidden the chat
      final allParticipantsHidden = participants
          .every((participant) => hiddenForUsers.contains(participant));

      if (!allParticipantsHidden) {
        print(
            'Cannot delete chat $chatId: not all participants have hidden it');
        return false;
      }

      final batch = getBatch();

      // Delete all messages in the chat
      final messagesSnapshot = await firestore
          .collection(collection)
          .doc(chatId)
          .collection(messagesSubCollection)
          .get();

      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the chat document itself
      final chatRef = firestore.collection(collection).doc(chatId);
      batch.delete(chatRef);

      // Commit the batch operation
      await commitBatch(batch);

      print(
          'Successfully deleted chat $chatId and ${messagesSnapshot.docs.length} messages');
      return true;
    } catch (e) {
      print('Error deleting chat $chatId: $e');
      return false;
    }
  }

  // Leave a chat (hide it for the user) and delete it if all participants have left
  Future<Map<String, dynamic>> leaveChatForUser({
    required String chatId,
    required String userId,
  }) async {
    try {
      // First, hide the chat for this user
      final hideSuccess = await hideChatForUser(
        chatId: chatId,
        userId: userId,
      );

      if (!hideSuccess) {
        return {
          'success': false,
          'deleted': false,
          'message': 'Failed to leave chat',
        };
      }

      // Check if all participants have now hidden the chat
      final chatDoc = await firestore.collection(collection).doc(chatId).get();
      if (!chatDoc.exists) {
        return {
          'success': true,
          'deleted': false,
          'message': 'Left chat successfully',
        };
      }

      final data = chatDoc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final hiddenForUsers = List<String>.from(data['hiddenForUsers'] ?? []);

      // Check if all participants have hidden the chat
      final allParticipantsHidden = participants
          .every((participant) => hiddenForUsers.contains(participant));

      if (allParticipantsHidden) {
        // Delete the chat completely
        final deleteSuccess = await deleteChat(chatId);
        return {
          'success': true,
          'deleted': deleteSuccess,
          'message': deleteSuccess
              ? 'Chat deleted completely as all participants have left'
              : 'Left chat successfully',
        };
      }

      return {
        'success': true,
        'deleted': false,
        'message': 'Left chat successfully',
      };
    } catch (e) {
      print('Error leaving chat $chatId for user $userId: $e');
      return {
        'success': false,
        'deleted': false,
        'message': 'Failed to leave chat',
      };
    }
  }
}
