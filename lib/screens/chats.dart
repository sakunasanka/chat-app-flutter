import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app_flutter/services/crud_services.dart';
import 'package:chat_app_flutter/utils/date_utils.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  String? currentUserId;
  final CrudServices crud = CrudServices();

  @override
  void initState() {
    super.initState();
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    print('DEBUG: Current user ID: $uid'); // Debug line
    setState(() {
      currentUserId = uid;
    });
  }

  Future<void> _showLeaveDialog(Map<String, dynamic> chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Leave Chat',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to leave your chat with ${chat['name']}?\n\nIf both participants leave, the chat will be permanently deleted.',
            style: const TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                'Leave',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && currentUserId != null) {
      await _leaveChat(chat);
    }
  }

  Future<void> _leaveChat(Map<String, dynamic> chat) async {
    if (!mounted) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Leaving chat...',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Leave the chat
    final result = await crud.leaveChatForUser(
      chatId: chat['id'],
      userId: currentUserId!,
    );

    // Check if widget is still mounted before using context
    if (!mounted) return;

    if (result['success'] == true) {
      final wasDeleted = result['deleted'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasDeleted
                ? 'Chat with ${chat['name']} was permanently deleted'
                : 'Left chat with ${chat['name']}',
            style: const TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Failed to leave chat. Please try again.',
            style: const TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/new_chat');
      //   },
      //   child: const Icon(Icons.add),
      // ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final width = constraints.maxWidth;
          final hPad = width < 400 ? 12.0 : 16.0;
          final badgeSize = width < 360 ? 18.0 : 22.0;

          return SafeArea(
            top: false,
            bottom: true,
            child: currentUserId == null || currentUserId!.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: crud.getUserChatsStream(currentUserId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading chats',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final chats = snapshot.data ?? [];
                      print(
                          'DEBUG: Stream provided ${chats.length} chats'); // Debug line

                      if (chats.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No chats yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start a conversation by scanning a QR code',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.only(
                            top: 8, left: hPad, right: hPad, bottom: 88),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color:
                                  theme.colorScheme.primary.withOpacity(0.08),
                            ),
                            child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/user_chat',
                                      arguments: {
                                        'title': chat['name'],
                                        'chatId': chat['id'],
                                      });
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: hPad, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.15),
                                    child: Text(
                                      chat['name'].toString().isNotEmpty
                                          ? chat['name']
                                              .toString()
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : 'C',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    chat['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    chat['lastMessage'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            ChatDateUtils.formatLastMessageTime(
                                                chat['timestamp']),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          // Ensure unread is treated as an int and > 0
                                          if (((chat['unread'] ?? 0) is num
                                                  ? (chat['unread'] ?? 0)
                                                      .toInt()
                                                  : int.tryParse(chat['unread']
                                                              ?.toString() ??
                                                          '0') ??
                                                      0) >
                                              0)
                                            Container(
                                              margin:
                                                  const EdgeInsets.only(top: 6),
                                              width: badgeSize,
                                              height: badgeSize,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.green,
                                              ),
                                              child: Text(
                                                '${((chat['unread'] ?? 0) is num ? (chat['unread'] ?? 0).toInt() : int.tryParse(chat['unread']?.toString() ?? '0') ?? 0)}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'leave') {
                                            await _showLeaveDialog(chat);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'leave',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.exit_to_app,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Leave Chat',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
