import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app_flutter/services/crud_services.dart';
import 'package:chat_app_flutter/utils/date_utils.dart';

class UnreadMessages extends StatefulWidget {
  const UnreadMessages({super.key});

  @override
  State<UnreadMessages> createState() => _UnreadMessagesState();
}

class _UnreadMessagesState extends State<UnreadMessages> {
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
    setState(() {
      currentUserId = uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        title: const Text(
          'Unread Messages',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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

                      final allChats = snapshot.data ?? [];
                      // Filter to only show chats with unread messages
                      final unreadChats = allChats.where((chat) {
                        final unreadCount = ((chat['unread'] ?? 0) is num
                            ? (chat['unread'] ?? 0).toInt()
                            : int.tryParse(chat['unread']?.toString() ?? '0') ??
                                0);
                        return unreadCount > 0;
                      }).toList();

                      if (unreadChats.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mark_email_read,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No unread messages',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'All caught up! You have no unread messages.',
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
                        itemCount: unreadChats.length,
                        itemBuilder: (context, index) {
                          final chat = unreadChats[index];
                          final unreadCount = ((chat['unread'] ?? 0) is num
                              ? (chat['unread'] ?? 0).toInt()
                              : int.tryParse(
                                      chat['unread']?.toString() ?? '0') ??
                                  0);

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
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      ChatDateUtils.formatLastMessageTime(
                                          chat['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: badgeSize,
                                      height: badgeSize,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
