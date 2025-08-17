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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new_chat');
        },
        child: const Icon(Icons.add),
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
                                      if (chat['unread'] > 0)
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
                                            '${chat['unread']}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
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
