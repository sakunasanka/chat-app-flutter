import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/controllers.dart';
import 'services.dart';

// Legacy CRUD Services class for backward compatibility
// This class now delegates to the new structured services and controllers
class CrudServices {
  final FirebaseFirestore service = FirebaseFirestore.instance;

  // New structured dependencies
  final UserController _userController = UserController();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final MessageService _messageService = MessageService();
  final ChatInviteService _inviteService = ChatInviteService();
  final EphemeralChatService _ephemeralService = EphemeralChatService();
  final ChatNotificationService _notificationService =
      ChatNotificationService();
  final ChatRequestService _requestService = ChatRequestService();

  Future<void> insert(String collection, dynamic data) async {
    await service.collection(collection).doc(data.id).set(data.toJson());
  }

  // User methods - delegated to UserController/UserService
  Future<bool> insertUser({
    required String userId,
    required String name,
  }) async {
    return await _userController.createUser(userId: userId, name: name);
  }

  Future<String?> insertUserAuto({
    required String name,
  }) async {
    return await _userController.createUserWithAutoId(name: name);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final user = await _userController.getUserById(userId);
    return user?.toJson();
  }

  Future<Map<String, Map<String, dynamic>>> getUsersByIds(
      List<String> ids) async {
    return await _userService.getUsersByIdsAsMap(ids);
  }

  // Ephemeral chat methods - delegated to EphemeralChatService
  Future<String?> createEphemeralSession({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
  }) async {
    return await _ephemeralService.createEphemeralSession(
      user1Id: user1Id,
      user2Id: user2Id,
      user1Name: user1Name,
      user2Name: user2Name,
    );
  }

  // Chat invite methods - delegated to ChatInviteService
  Future<String?> createChatInvite({
    required String fromId,
    required String toId,
    required String fromName,
    required String toName,
    required String type,
    String? ephemeralId,
  }) async {
    return await _inviteService.createChatInvite(
      fromId: fromId,
      toId: toId,
      fromName: fromName,
      toName: toName,
      type: type,
      ephemeralId: ephemeralId,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingInvitesForUser(
      String userId) async {
    return await _inviteService.getPendingInvitesForUserAsMap(userId);
  }

  Future<Map<String, dynamic>?> getInviteById(String inviteId) async {
    return await _inviteService.getInviteByIdAsMap(inviteId);
  }

  Future<List<Map<String, dynamic>>> getOutgoingInviteResponses(
      String userId) async {
    return await _inviteService.getOutgoingInviteResponsesAsMap(userId);
  }

  Future<void> markInviteNotifiedForFrom(String inviteId) async {
    await _inviteService.markInviteNotifiedForFrom(inviteId);
  }

  Future<Map<String, String>?> acceptInvite(String inviteId) async {
    return await _inviteService.acceptInvite(inviteId);
  }

  Future<void> declineInvite(String inviteId) async {
    await _inviteService.declineInvite(inviteId);
  }

  // Message methods - delegated to MessageService
  Future<void> sendPersistentMessage({
    required String chatId,
    required String fromUserId,
    required String text,
  }) async {
    await _messageService.sendPersistentMessage(
      chatId: chatId,
      fromUserId: fromUserId,
      text: text,
    );
  }

  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    await _messageService.markMessagesAsRead(
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }

  Future<int> getUnreadMessagesCount({
    required String chatId,
    required String currentUserId,
  }) async {
    return await _chatService.getUnreadMessagesCount(
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }

  Future<void> sendEphemeralMessage({
    required String sessionId,
    required String fromUserId,
    required String text,
  }) async {
    await _ephemeralService.sendEphemeralMessage(
      sessionId: sessionId,
      fromUserId: fromUserId,
      text: text,
    );
  }

  Future<void> deleteEphemeralSession(String sessionId) async {
    await _ephemeralService.deleteEphemeralSession(sessionId);
  }

  // Chat request methods - delegated to ChatRequestService
  Future<String?> createChatRequest({
    required String fromId,
    required String toId,
    String? fromName,
    String? toName,
  }) async {
    return await _requestService.createChatRequest(
      fromId: fromId,
      toId: toId,
      fromName: fromName,
      toName: toName,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingRequestsForUser(
      String userId) async {
    return await _requestService.getPendingRequestsForUser(userId);
  }

  Future<String?> respondChatRequest({
    required String requestId,
    required bool accept,
  }) async {
    return await _requestService.respondChatRequest(
      requestId: requestId,
      accept: accept,
    );
  }

  // Chat methods - delegated to ChatService
  Future<String?> createDirectChat({
    required String user1Id,
    required String user2Id,
    String? user1Name,
    String? user2Name,
  }) async {
    return await _chatService.createDirectChat(
      user1Id: user1Id,
      user2Id: user2Id,
      user1Name: user1Name,
      user2Name: user2Name,
    );
  }

  // Notification methods - delegated to ChatNotificationService
  Future<void> notifyUserToOpenChat({
    required String toUserId,
    required String fromUserId,
    required String chatId,
    String? fromUserName,
  }) async {
    await _notificationService.notifyUserToOpenChat(
      toUserId: toUserId,
      fromUserId: fromUserId,
      chatId: chatId,
      fromUserName: fromUserName,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingChatNotifications(
      String userId) async {
    return await _notificationService.getPendingChatNotificationsAsMap(userId);
  }

  Future<void> markChatNotificationAsRead(String notificationId) async {
    await _notificationService.markChatNotificationAsRead(notificationId);
  }

  // Chat list methods - delegated to ChatService
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    final chats = await _chatService.getUserChats(userId);
    return chats.map((chat) => chat.toJson()..['id'] = chat.id).toList();
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream(String userId) {
    return _chatService.getUserChatsStream(userId);
  }

  // Helper method for backward compatibility
  Future<int> _getUnreadMessagesCountOptimized({
    required String chatId,
    required String currentUserId,
  }) async {
    return await _chatService.getUnreadMessagesCount(
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }

  Future<int> getTotalUnreadMessagesCount(String userId) async {
    return await _chatService.getTotalUnreadMessagesCount(userId);
  }
}
