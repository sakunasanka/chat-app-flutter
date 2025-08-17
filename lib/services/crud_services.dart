import 'package:cloud_firestore/cloud_firestore.dart';

class CrudServices {
  final FirebaseFirestore service = FirebaseFirestore.instance;

  Future<void> insert(String collection, dynamic data) async {
    await service.collection(collection).doc(data.id).set(data.toJson());
  }

  // Test endpoint to insert user data into users collection
  Future<bool> insertUser({
    required String userId,
    required String name,
  }) async {
    try {
      await service.collection('users').doc(userId).set({
        'id': userId,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });
      print('User inserted successfully: $userId');
      return true;
    } catch (e) {
      print('Error inserting user: $e');
      return false;
    }
  }

  // Create an ephemeral session (instant chat)
  Future<String?> createEphemeralSession({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final doc = await service.collection('ephemeral_chats').add({
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

  // Insert a user into 'users' collection with an auto-generated document id.
  // Returns the generated document id on success, or null on failure.
  Future<String?> insertUserAuto({
    required String name,
  }) async {
    try {
      final docRef = await service.collection('users').add({
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });
      print('User inserted with auto id: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error inserting user with auto id: $e');
      return null;
    }
  }

  // Test endpoint to get a user from users collection
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await service.collection('users').doc(userId).get();
      if (doc.exists) {
        print('User found: ${doc.data()}');
        return doc.data() as Map<String, dynamic>;
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Bulk fetch users by ids, returns a map id -> user data (at least contains 'name')
  Future<Map<String, Map<String, dynamic>>> getUsersByIds(
      List<String> ids) async {
    final result = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return result;
    try {
      // Firestore allows up to 10 items in 'in' queries; batch accordingly
      const batchSize = 10;
      for (var i = 0; i < ids.length; i += batchSize) {
        final slice = ids.sublist(
            i, i + batchSize > ids.length ? ids.length : i + batchSize);
        final snap = await service
            .collection('users')
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (final d in snap.docs) {
          result[d.id] = (d.data() as Map<String, dynamic>)..['id'] = d.id;
        }
      }
    } catch (e) {
      print('Error bulk fetching users: $e');
    }
    return result;
  }

  // ---------------- Chat Invites & Sessions (new flow) ----------------

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
      final docRef = await service.collection('chat_invites').add({
        'from': fromId,
        'to': toId,
        'fromName': fromName,
        'toName': toName,
        'type': type,
        'status': 'pending', // pending | accepted | declined
        'createdAt': now,
        'updatedAt': now,
        // when responded
        'chatId': null, // set on accept for 'continue'
        'ephemeralId': ephemeralId ?? null, // may be pre-created for instant
        // notification flags
        'fromNotified':
            false, // whether requester has been notified of response
      });
      print(
          'DEBUG: Created chat_invite ${docRef.id} type=$type ephemeralId=$ephemeralId from=$fromId to=$toId');
      return docRef.id;
    } catch (e) {
      print('Error creating chat invite: $e');
      return null;
    }
  }

  // Get pending invites addressed TO the user (they need to accept/decline)
  Future<List<Map<String, dynamic>>> getPendingInvitesForUser(
      String userId) async {
    try {
      final snap = await service
          .collection('chat_invites')
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();
    } catch (e) {
      print('Error getting pending invites: $e');
      return [];
    }
  }

  // Fetch a single invite document by id
  Future<Map<String, dynamic>?> getInviteById(String inviteId) async {
    try {
      final snap = await service.collection('chat_invites').doc(inviteId).get();
      if (!snap.exists) return null;
      return {'id': snap.id, ...(snap.data() as Map<String, dynamic>)};
    } catch (e) {
      print('Error getting invite $inviteId: $e');
      return null;
    }
  }

  // Get invites sent BY the user that have been responded to but not yet notified to the sender
  Future<List<Map<String, dynamic>>> getOutgoingInviteResponses(
      String userId) async {
    try {
      final snap = await service
          .collection('chat_invites')
          .where('from', isEqualTo: userId)
          .where('status', whereIn: ['accepted', 'declined'])
          .where('fromNotified', isEqualTo: false)
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();
    } catch (e) {
      print('Error getting outgoing invite responses: $e');
      return [];
    }
  }

  // Mark that the requester has been notified about the response
  Future<void> markInviteNotifiedForFrom(String inviteId) async {
    try {
      await service.collection('chat_invites').doc(inviteId).update({
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
      final ref = service.collection('chat_invites').doc(inviteId);
      final snap = await ref.get();
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      if (data['status'] != 'pending') {
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
        chatId = await createDirectChat(
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
          final doc = await service.collection('ephemeral_chats').add({
            'participants': [from, to],
            'participantNames': [fromName, toName],
            'createdAt': now,
          });
          ephemeralId = doc.id;
          print(
              'DEBUG: Created new ephemeralId $ephemeralId for invite $inviteId');
        }
      }

      await ref.update({
        'status': 'accepted',
        'updatedAt': now,
        'chatId': chatId,
        'ephemeralId': ephemeralId,
      });

      return {
        if (chatId != null) 'chatId': chatId,
        if (ephemeralId != null) 'ephemeralId': ephemeralId,
      };
    } catch (e) {
      print('Error accepting invite: $e');
      return null;
    }
  }

  Future<void> declineInvite(String inviteId) async {
    try {
      await service.collection('chat_invites').doc(inviteId).update({
        'status': 'declined',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error declining invite: $e');
    }
  }

  // ---------------- Messaging ----------------

  // Send a message to persistent chat
  Future<void> sendPersistentMessage({
    required String chatId,
    required String fromUserId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();
    final batch = service.batch();
    final msgRef =
        service.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'text': text,
      'from': fromUserId,
      'createdAt': now,
      'status': 'sent', // sent, delivered, read
      'deliveredAt': null,
      'readAt': null,
    });
    final chatRef = service.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastUpdated': now,
      'lastMessageFrom': fromUserId,
    });
    await batch.commit();

    // Mark message as delivered immediately (simulating instant delivery)
    await Future.delayed(const Duration(milliseconds: 500));
    await _markMessageAsDelivered(chatId, msgRef.id);
  }

  // Helper method to mark a message as delivered
  Future<void> _markMessageAsDelivered(String chatId, String messageId) async {
    try {
      await service
          .collection('chats')
          .doc(chatId)
          .collection('messages')
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
          'DEBUG: Marking messages as read for chat $chatId by user $currentUserId'); // Debug
      // Query only by status to avoid composite index; filter sender client-side
      final unreadMessages = await service
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status', whereIn: ['sent', 'delivered']).get();

      print(
          'DEBUG: Found ${unreadMessages.docs.length} unread messages'); // Debug

      final batch = service.batch();
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
          print('DEBUG: Marking message ${doc.id} as read'); // Debug
        }
      }

      // Touch the parent chat doc to trigger chat list stream recompute without changing lastUpdated
      final chatRef = service.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'unreadRecalcAt': now,
      });

      if (toUpdate > 0) {
        await batch.commit();
        print('DEBUG: Successfully marked $toUpdate messages as read'); // Debug
      } else {
        // Still commit the parent doc touch to trigger UI refresh
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread messages count for a specific chat
  Future<int> getUnreadMessagesCount({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      // Query only by status to avoid composite index; filter sender client-side
      final snapshot = await service
          .collection('chats')
          .doc(chatId)
          .collection('messages')
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

  // Send a message to ephemeral session
  Future<void> sendEphemeralMessage({
    required String sessionId,
    required String fromUserId,
    required String text,
  }) async {
    final now = DateTime.now().toIso8601String();
    await service
        .collection('ephemeral_chats')
        .doc(sessionId)
        .collection('messages')
        .add({
      'text': text,
      'from': fromUserId,
      'createdAt': now,
      'status': 'delivered', // Ephemeral messages are immediately delivered
      'deliveredAt': now,
      'readAt': null,
    });
  }

  // Delete an ephemeral session and its messages (best-effort)
  Future<void> deleteEphemeralSession(String sessionId) async {
    try {
      final msgs = await service
          .collection('ephemeral_chats')
          .doc(sessionId)
          .collection('messages')
          .get();
      final batch = service.batch();
      for (final d in msgs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      // ignore message deletion errors
      print('Error deleting ephemeral messages: $e');
    }
    try {
      await service.collection('ephemeral_chats').doc(sessionId).delete();
    } catch (e) {
      print('Error deleting ephemeral session: $e');
    }
  }

  // Create a chat request from one user to another. Returns the request id.
  Future<String?> createChatRequest({
    required String fromId,
    required String toId,
    String? fromName,
    String? toName,
  }) async {
    try {
      final docRef = await service.collection('chat_requests').add({
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

  // Get pending chat requests addressed to a user.
  Future<List<Map<String, dynamic>>> getPendingRequestsForUser(
      String userId) async {
    try {
      final snap = await service
          .collection('chat_requests')
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  // Respond to a chat request. If accepted, create a chat document and return its id.
  Future<String?> respondChatRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      final reqRef = service.collection('chat_requests').doc(requestId);
      final reqSnap = await reqRef.get();
      if (!reqSnap.exists) return null;
      final data = reqSnap.data() as Map<String, dynamic>;
      final from = data['from'] as String? ?? '';
      final to = data['to'] as String? ?? '';

      await reqRef.update({'status': accept ? 'accepted' : 'declined'});

      if (!accept) return null;

      // Create chat for both users
      final chatDoc = await service.collection('chats').add({
        'participants': [from, to],
        'participantNames': [data['fromName'] ?? '', data['toName'] ?? ''],
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessage': '',
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      return chatDoc.id;
    } catch (e) {
      print('Error responding to request: $e');
      return null;
    }
  }

  // Create a direct chat between two users. Returns the chat id.
  Future<String?> createDirectChat({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
  }) async {
    try {
      // Check if chat already exists between these users
      final existingChats = await service
          .collection('chats')
          .where('participants', arrayContains: user1Id)
          .get();

      for (final doc in existingChats.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(user2Id)) {
          // Chat already exists, return its ID
          return doc.id;
        }
      }

      // Create new chat
      final chatDoc = await service.collection('chats').add({
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

  // Send a notification to the other user to open the chat
  Future<void> notifyUserToOpenChat({
    required String toUserId,
    required String fromUserId,
    required String chatId,
    String? fromUserName,
  }) async {
    try {
      await service.collection('chat_notifications').add({
        'to': toUserId,
        'from': fromUserId,
        'fromName': fromUserName ?? '',
        'chatId': chatId,
        'type': 'open_chat', // instant | continue
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending', // pending | read
      });
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  // Get pending chat notifications for a user
  Future<List<Map<String, dynamic>>> getPendingChatNotifications(
      String userId) async {
    try {
      final snap = await service
          .collection('chat_notifications')
          .where('to', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();
    } catch (e) {
      print('Error getting chat notifications: $e');
      return [];
    }
  }

  // Mark chat notification as read
  Future<void> markChatNotificationAsRead(String notificationId) async {
    try {
      await service
          .collection('chat_notifications')
          .doc(notificationId)
          .update({
        'status': 'read',
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get chats where the user is a participant.
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      print('DEBUG: getUserChats called with userId: $userId'); // Debug line
      final snap = await service
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get(); // Remove orderBy to avoid index issues
      print('DEBUG: Found ${snap.docs.length} chat documents'); // Debug line
      final result = snap.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();
      // Sort in memory instead
      result.sort((a, b) {
        final aTime = a['lastUpdated'] as String? ?? '';
        final bTime = b['lastUpdated'] as String? ?? '';
        return bTime.compareTo(aTime); // descending
      });
      print('DEBUG: Returning chats: $result'); // Debug line
      return result;
    } catch (e) {
      print('Error getting user chats: $e');
      return [];
    }
  }

  // Stream-based method for real-time chat updates
  Stream<List<Map<String, dynamic>>> getUserChatsStream(String userId) {
    return service
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snap) async {
      print(
          'DEBUG: getUserChatsStream received ${snap.docs.length} chat documents'); // Debug line

      final chats = snap.docs
          .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
          .toList();

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
      final usersMap = await getUsersByIds(otherIds.toList());

      // Process chats with user names and unread counts efficiently
      final List<Map<String, dynamic>> processedChats = [];

      // Get unread counts for all chats in parallel
      final unreadCountFutures = chats
          .map((c) => _getUnreadMessagesCountOptimized(
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

  // Optimized version for concurrent execution
  Future<int> _getUnreadMessagesCountOptimized({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      // Use a single where clause to avoid composite index; filter locally
      final snapshot = await service
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status', whereIn: ['sent', 'delivered']).get();

      final count = snapshot.docs
          .where((d) => (d.data()['from'] as String?) != currentUserId)
          .length;
      return count;
    } catch (e) {
      print('Error getting unread messages count for chat $chatId: $e');
      // Fallback to the original method
      return await getUnreadMessagesCount(
        chatId: chatId,
        currentUserId: currentUserId,
      );
    }
  }

  // Future<dynamic> findOne(
  //     {required String collection, required String filed}) async {
  //   late List data = [];

  //   try {
  //     await service.collection(collection).doc(filed).get().then((value) {

  //       // login user data collect
  //       if (collection == "Users") {
  //         data.add(UserModel.fromSnapshot(value));
  //       }
  //     });
  //     return data;
  //   } on FirebaseException catch (e) {

  //     final ex = CrudFailure.code(e.code);
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: ex.message,
  //       type: 1,
  //     );

  //     throw ex;
  //   } catch (_) {
  //     final ex = CrudFailure();
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: "${ex.message}.",
  //       type: 1,
  //     );
  //     // print("exception-1 ${ex.message}");
  //     throw ex;
  //   }
  // }

  // Future<void> update({
  //   required String collection,
  //   required String documentId,
  //   required dynamic data
  // }) async {
  //     try{
  //       await service.collection(collection).doc(documentId).update(data.toJson());
  //     } on FirebaseException catch(e) {
  //       final ex = CrudFailure.code(e.code);
  //       PopupWarning.Warning(
  //         title: "Try again later",
  //         message: ex.message,
  //         type: 1
  //       );
  //       throw ex;
  //     } catch(e) {
  //       final ex = CrudFailure();
  //       PopupWarning.Warning(
  //           title: "Try again later",
  //           message: ex.message,
  //           type: 1
  //       );
  //       throw ex;
  //     }
  // }

  // Future<List<T>> findAll<T>({
  //   required String collection,
  //   required T Function(dynamic doc) fromSnapshot,
  // }) async {
  //   try {
  //     final snapshot = await service.collection(collection).get();

  //     return snapshot.docs.map<T>((doc) => fromSnapshot(doc)).toList();
  //   } catch (e) {
  //     throw e;
  //   }
  // }

  // Future<T?> findById<T>({
  //   required String collection,
  //   required String docId,
  //   required T Function(DocumentSnapshot doc) fromSnapshot,
  // }) async {
  //   try {
  //     final doc = await service.collection(collection).doc(docId).get();

  //     if (!doc.exists) return null;

  //     return fromSnapshot(doc);
  //   } on FirebaseException catch (e) {
  //     final ex = CrudFailure.code(e.code);
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: ex.message,
  //       type: 1,
  //     );
  //     throw ex;
  //   } catch (_) {
  //     final ex = CrudFailure();
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: "${ex.message}.",
  //       type: 1,
  //     );
  //     throw ex;
  //   }
  // }

  // Get total unread chats count (number of chats with unread messages) for a user
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
}
