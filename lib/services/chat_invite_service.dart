import '../models/models.dart';
import 'base_crud_service.dart';
import 'chat_service.dart';
import 'ephemeral_chat_service.dart';

class ChatInviteService extends BaseCrudService {
  static const String collection = 'chat_invites';

  final ChatService _chatService = ChatService();
  final EphemeralChatService _ephemeralChatService = EphemeralChatService();

  // Create a chat invite of type 'instant' (ephemeral) or 'continue' (persistent)
  Future<String?> createChatInvite({
    required String fromId,
    required String toId,
    required String fromName,
    required String toName,
    required String type, // 'instant' | 'continue'
    String? ephemeralId,
  }) async {
    assert(type == 'instant' || type == 'continue');
    try {
      final now = DateTime.now().toIso8601String();
      final docRef = await firestore.collection(collection).add({
        'from': fromId,
        'to': toId,
        'fromName': fromName,
        'toName': toName,
        'type': type,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
        'chatId': null,
        'ephemeralId': ephemeralId,
        'fromNotified': false,
      });
      print(
          'DEBUG: Created chat_invite ${docRef.id} type=$type ephemeralId=$ephemeralId from=$fromId to=$toId');
      return docRef.id;
    } catch (e) {
      print('Error creating chat invite: $e');
      return null;
    }
  }

  // Get pending invites addressed TO the user
  Future<List<ChatInviteModel>> getPendingInvitesForUser(String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snap.docs
          .map((d) => ChatInviteModel.fromJson(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      print('Error getting pending invites: $e');
      return [];
    }
  }

  // Get pending invites as Map (backward compatibility)
  Future<List<Map<String, dynamic>>> getPendingInvitesForUserAsMap(
      String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      return snap.docs.map((d) => {'id': d.id, ...(d.data())}).toList();
    } catch (e) {
      print('Error getting pending invites: $e');
      return [];
    }
  }

  // Fetch a single invite document by id
  Future<ChatInviteModel?> getInviteById(String inviteId) async {
    try {
      final snap = await firestore.collection(collection).doc(inviteId).get();
      if (!snap.exists) return null;
      return ChatInviteModel.fromJson(snap.data()!, docId: snap.id);
    } catch (e) {
      print('Error getting invite $inviteId: $e');
      return null;
    }
  }

  // Get invite by ID as Map (backward compatibility)
  Future<Map<String, dynamic>?> getInviteByIdAsMap(String inviteId) async {
    try {
      final snap = await firestore.collection(collection).doc(inviteId).get();
      if (!snap.exists) return null;
      return {'id': snap.id, ...(snap.data()!)};
    } catch (e) {
      print('Error getting invite $inviteId: $e');
      return null;
    }
  }

  // Get invites sent BY the user that have been responded to but not yet notified
  Future<List<ChatInviteModel>> getOutgoingInviteResponses(
      String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('from', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'declined'])
          .where('fromNotified', isEqualTo: false)
          .get();

      return snap.docs
          .map((d) => ChatInviteModel.fromJson(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      print('Error getting outgoing invite responses: $e');
      return [];
    }
  }

  // Get outgoing invite responses as Map (backward compatibility)
  Future<List<Map<String, dynamic>>> getOutgoingInviteResponsesAsMap(
      String userId) async {
    try {
      final snap = await firestore
          .collection(collection)
          .where('from', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'declined'])
          .where('fromNotified', isEqualTo: false)
          .get();

      return snap.docs.map((d) => {'id': d.id, ...(d.data())}).toList();
    } catch (e) {
      print('Error getting outgoing invite responses: $e');
      return [];
    }
  }

  // Mark that the requester has been notified about the response
  Future<void> markInviteNotifiedForFrom(String inviteId) async {
    try {
      await update(collection, inviteId, {
        'fromNotified': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error marking invite notified: $e');
    }
  }

  // Accept an invite; creates persistent chat or ephemeral session and returns ids
  Future<Map<String, String>?> acceptInvite(String inviteId) async {
    try {
      final ref = firestore.collection(collection).doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return null;

      final data = snap.data()!;

      // If already accepted/declined, return existing result if available
      if (data['status'] != 'pending') {
        print(
            'DEBUG: Invite $inviteId already processed with status: ${data['status']}');
        return {
          if (data['chatId'] != null) 'chatId': data['chatId'],
          if (data['ephemeralId'] != null) 'ephemeralId': data['ephemeralId'],
        };
      }

      final from = data['from'] as String;
      final to = data['to'] as String;
      final type = data['type'] as String;
      final fromName = (data['fromName'] as String?) ?? '';
      final toName = (data['toName'] as String?) ?? '';

      String? chatId;
      String? ephemeralId;
      final now = DateTime.now().toIso8601String();

      if (type == 'continue') {
        // Create or reuse persistent chat
        chatId = await _chatService.createDirectChat(
          user1Id: from,
          user2Id: to,
          user1Name: fromName,
          user2Name: toName,
        );
      } else {
        // If an ephemeral session was already attached to the invite, reuse it.
        if (data['ephemeralId'] != null &&
            (data['ephemeralId'] as String).isNotEmpty) {
          ephemeralId = data['ephemeralId'] as String;
          print(
              'DEBUG: Reusing ephemeralId from invite $inviteId -> $ephemeralId');
        } else {
          // Create ephemeral session document
          ephemeralId = await _ephemeralChatService.createEphemeralSession(
            user1Id: from,
            user2Id: to,
            user1Name: fromName,
            user2Name: toName,
          );
          print(
              'DEBUG: Created new ephemeralId $ephemeralId for invite $inviteId');
        }
      }

      // Use a transaction to ensure atomic update and prevent double-processing
      await firestore.runTransaction((transaction) async {
        final currentSnap = await transaction.get(ref);
        if (!currentSnap.exists) {
          throw Exception('Invite was deleted during processing');
        }

        final currentData = currentSnap.data()!;
        if (currentData['status'] != 'pending') {
          throw Exception('Invite was already processed during this request');
        }

        transaction.update(ref, {
          'status': 'accepted',
          'updatedAt': now,
          'chatId': chatId,
          'ephemeralId': ephemeralId,
        });
      });

      print('DEBUG: Successfully accepted invite $inviteId');
      return {
        if (chatId != null) 'chatId': chatId,
        if (ephemeralId != null) 'ephemeralId': ephemeralId,
      };
    } catch (e) {
      print('Error accepting invite: $e');
      return null;
    }
  }

  // Decline an invite
  Future<void> declineInvite(String inviteId) async {
    try {
      final ref = firestore.collection(collection).doc(inviteId);

      // Use a transaction to ensure atomic update and prevent double-processing
      await firestore.runTransaction((transaction) async {
        final currentSnap = await transaction.get(ref);
        if (!currentSnap.exists) {
          throw Exception('Invite was deleted during processing');
        }

        final currentData = currentSnap.data()!;
        if (currentData['status'] != 'pending') {
          print(
              'DEBUG: Invite $inviteId already processed with status: ${currentData['status']}');
          return; // Already processed, nothing to do
        }

        transaction.update(ref, {
          'status': 'declined',
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });

      print('DEBUG: Successfully declined invite $inviteId');
    } catch (e) {
      print('Error declining invite: $e');
    }
  }
}
