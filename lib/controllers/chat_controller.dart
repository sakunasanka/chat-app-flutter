import '../models/models.dart';
import '../services/services.dart';

class ChatController {
  final ChatService _chatService = ChatService();
  final MessageService _messageService = MessageService();
  final ChatInviteService _inviteService = ChatInviteService();
  final EphemeralChatService _ephemeralService = EphemeralChatService();
  final ChatNotificationService _notificationService =
      ChatNotificationService();
  final UserService _userService = UserService();

  // Chat management
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

  Future<List<ChatModel>> getUserChats(String userId) async {
    return await _chatService.getUserChats(userId);
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream(String userId) {
    return _chatService.getUserChatsStream(userId);
  }

  // Message handling
  Future<void> sendMessage({
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

  Future<List<MessageModel>> getMessages(String chatId) async {
    return await _messageService.getMessages(chatId);
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _messageService.getMessagesStream(chatId);
  }

  // Unread counts
  Future<int> getUnreadMessagesCount({
    required String chatId,
    required String currentUserId,
  }) async {
    return await _chatService.getUnreadMessagesCount(
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }

  Future<int> getTotalUnreadChatsCount(String userId) async {
    return await _chatService.getTotalUnreadMessagesCount(userId);
  }

  // Invite management
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

  Future<List<ChatInviteModel>> getPendingInvites(String userId) async {
    return await _inviteService.getPendingInvitesForUser(userId);
  }

  Future<Map<String, String>?> acceptInvite(String inviteId) async {
    return await _inviteService.acceptInvite(inviteId);
  }

  Future<void> declineInvite(String inviteId) async {
    await _inviteService.declineInvite(inviteId);
  }

  // Ephemeral chat handling
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

  // Notifications
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

  Future<List<ChatNotificationModel>> getPendingNotifications(
      String userId) async {
    return await _notificationService.getPendingChatNotifications(userId);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationService.markChatNotificationAsRead(notificationId);
  }

  // Business logic methods
  Future<String> getOtherUserNameInChat(
      String chatId, String currentUserId) async {
    final chats = await getUserChats(currentUserId);
    final chat = chats.firstWhere((c) => c.id == chatId,
        orElse: () => ChatModel(
            id: '',
            participants: [],
            participantNames: [],
            createdAt: '',
            lastMessage: '',
            lastUpdated: ''));

    if (chat.id.isEmpty) return 'Unknown';

    final otherUserId = chat.participants.firstWhere(
      (p) => p != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return 'Unknown';

    final user = await _userService.getUser(otherUserId);
    return user?.name ?? otherUserId;
  }

  Future<bool> hasUnreadMessages(String chatId, String userId) async {
    final count = await getUnreadMessagesCount(
      chatId: chatId,
      currentUserId: userId,
    );
    return count > 0;
  }
}
