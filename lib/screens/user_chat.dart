import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_chat/services/crud_services.dart';
import 'package:qr_chat/utils/date_utils.dart';

class UserChat extends StatefulWidget {
  final String title;
  const UserChat({super.key, this.title = ''});

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? chatTitle;
  String? chatId; // persistent chat id
  String? sessionId; // ephemeral session id
  bool isEphemeral = false;
  String? myUserId;
  bool _ended = false;
  Timer? _markReadDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments != null) {
      if (arguments is Map<String, dynamic>) {
        // New format with chatId and title
        chatTitle = arguments['title'] as String?;
        chatId = arguments['chatId'] as String?;
        sessionId = arguments['sessionId'] as String?;
        isEphemeral = arguments['ephemeral'] == true;
      } else if (arguments is String) {
        // Legacy format - just title
        chatTitle = arguments;
      }
    } else {
      chatTitle = widget.title.isEmpty ? 'Chat' : widget.title;
    }
    _ensureMyUserId();
  }

  Future<void> _markMessagesAsReadWhenOpened() async {
    if (!isEphemeral && chatId != null && myUserId != null) {
      final crud = CrudServices();
      await crud.markMessagesAsRead(
        chatId: chatId!,
        currentUserId: myUserId!,
      );
    }
  }

  Future<void> _ensureMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myUserId = prefs.getString('user_id') ?? 'local_user';
    });
    // Mark messages as read after getting user ID
    _markMessagesAsReadWhenOpened();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final crud = CrudServices();
    // Prevent sending with placeholder id which can cause one-sided chats
    if ((myUserId == null || myUserId == 'local_user')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set your name in the home screen first.'),
          ),
        );
      }
      return;
    }
    try {
      if (isEphemeral && sessionId != null) {
        await crud.sendEphemeralMessage(
          sessionId: sessionId!,
          fromUserId: myUserId!,
          text: text,
        );
      } else if (!isEphemeral && chatId != null) {
        await crud.sendPersistentMessage(
          chatId: chatId!,
          fromUserId: myUserId!,
          text: text,
        );
      }
      // Scroll to bottom after sending message
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (isEphemeral && sessionId != null && !_ended) {
      _ended = true;
      await CrudServices().deleteEphemeralSession(sessionId!);
    }
    return true;
  }

  @override
  void dispose() {
    // Best-effort cleanup for ephemeral sessions
    if (isEphemeral && sessionId != null && !_ended) {
      CrudServices().deleteEphemeralSession(sessionId!);
      _ended = true;
    }
    _markReadDebounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageStatusIcon(Map<String, dynamic> messageData) {
    final status = messageData['status'] as String? ?? 'sent';
    final messageId = messageData['id'] as String? ?? 'unknown';

    print('DEBUG: Message $messageId has status: $status'); // Debug logging

    switch (status) {
      case 'sent':
        return Icon(
          Icons.access_time,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
      case 'delivered':
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
      case 'read':
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withOpacity(0.7), // Blue color for read status
        );
      default:
        return Icon(
          Icons.access_time,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final bubbleMaxWidth = size.width * (size.width < 400 ? 0.78 : 0.72);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        // We'll handle keyboard inset manually so the input bar stays
        // fixed at the keyboard height using AnimatedPadding below.
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: Colors.white,
          title: Text(
            chatTitle ?? 'Chat',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (isEphemeral)
              IconButton(
                tooltip: 'End chat',
                onPressed: () async {
                  if (sessionId != null && !_ended) {
                    _ended = true;
                    await CrudServices().deleteEphemeralSession(sessionId!);
                  }
                  if (mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: isEphemeral && sessionId != null
                      ? FirebaseFirestore.instance
                          .collection('ephemeral_chats')
                          .doc(sessionId)
                          .collection('messages')
                          .orderBy('createdAt')
                          .snapshots()
                      : (!isEphemeral && chatId != null)
                          ? FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .collection('messages')
                              .orderBy('createdAt')
                              .snapshots()
                          : null,
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];

                    // Auto-mark any received (non-read) messages as read while this screen is open
                    if (!isEphemeral && chatId != null && myUserId != null) {
                      final hasUnreadFromOthers = docs.any((d) {
                        final m = d.data();
                        final from = (m['from'] as String?) ?? '';
                        final status = (m['status'] as String?) ?? 'sent';
                        return from != myUserId &&
                            (status == 'sent' || status == 'delivered');
                      });
                      if (hasUnreadFromOthers) {
                        _markReadDebounce?.cancel();
                        _markReadDebounce =
                            Timer(const Duration(milliseconds: 250), () async {
                          if (!mounted) return;
                          await CrudServices().markMessagesAsRead(
                            chatId: chatId!,
                            currentUserId: myUserId!,
                          );
                        });
                      }
                    }

                    // Auto-scroll to bottom when new messages arrive or when first loading
                    if (docs.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final isMe = (data['from'] ?? '') == (myUserId ?? '');
                        final currentMessageDate =
                            data['createdAt'] as String? ?? '';
                        final previousMessageDate = index > 0
                            ? docs[index - 1].data()['createdAt'] as String?
                            : null;

                        final showDateSeparator =
                            ChatDateUtils.shouldShowDateSeparator(
                                currentMessageDate, previousMessageDate);

                        return Column(
                          children: [
                            // Date separator
                            if (showDateSeparator &&
                                currentMessageDate.isNotEmpty)
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ChatDateUtils.formatDateSeparator(
                                        currentMessageDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            // Message bubble
                            Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: bubbleMaxWidth),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? theme.colorScheme.primary
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isMe ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isMe ? 4 : 16),
                                    ),
                                  ),
                                  child: IntrinsicWidth(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Message text with flexible layout for timestamp
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: bubbleMaxWidth -
                                                24, // Account for padding
                                          ),
                                          child: Wrap(
                                            alignment: isMe
                                                ? WrapAlignment.end
                                                : WrapAlignment.start,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.end,
                                            children: [
                                              Text(
                                                (data['text'] ?? '') as String,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: isSmall ? 14 : 15,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    ChatDateUtils
                                                        .formatMessageTime(
                                                            currentMessageDate),
                                                    style: TextStyle(
                                                      color: isMe
                                                          ? Colors.white
                                                              .withOpacity(0.7)
                                                          : Colors.grey[600],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  if (isMe)
                                                    const SizedBox(width: 4),
                                                  if (isMe)
                                                    _buildMessageStatusIcon(
                                                        data),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // AnimatedPadding makes the input bar move smoothly with the
              // keyboard by using viewInsets.bottom. This keeps the bar fixed
              // just above the keyboard when it appears.
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, 8 + MediaQuery.of(context).viewInsets.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _sendMessage,
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
