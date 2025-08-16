import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app_flutter/services/crud_services.dart';

class UserChat extends StatefulWidget {
  final String title;
  const UserChat({super.key, this.title = ''});

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  final TextEditingController _controller = TextEditingController();
  String? chatTitle;
  String? chatId; // persistent chat id
  String? sessionId; // ephemeral session id
  bool isEphemeral = false;
  String? myUserId;
  bool _ended = false;

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

  Future<void> _ensureMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myUserId = prefs.getString('user_id') ?? 'local_user';
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final crud = CrudServices();
    try {
      if (isEphemeral && sessionId != null) {
        await crud.sendEphemeralMessage(
          sessionId: sessionId!,
          fromUserId: myUserId ?? 'local_user',
          text: text,
        );
      } else if (!isEphemeral && chatId != null) {
        await crud.sendPersistentMessage(
          chatId: chatId!,
          fromUserId: myUserId ?? 'local_user',
          text: text,
        );
      }
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
    _controller.dispose();
    super.dispose();
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
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final isMe = (data['from'] ?? '') == (myUserId ?? '');
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: bubbleMaxWidth),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? theme.colorScheme.primary
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                              ),
                              child: Text(
                                (data['text'] ?? '') as String,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: isSmall ? 14 : 15,
                                ),
                              ),
                            ),
                          ),
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
