import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app_flutter/services/crud_services.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _initChats();
  }

  Future<void> _initChats() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    print('DEBUG: Current user ID: $uid'); // Debug line
    if (uid == null || uid.isEmpty) return;
    final crud = CrudServices();
    final fetched = await crud.getUserChats(uid);
    print('DEBUG: Fetched ${fetched.length} chats: $fetched'); // Debug line

    // Collect the "other user" ids for each chat
    final otherIds = <String>{};
    for (final c in fetched) {
      final participants = List<String>.from(c['participants'] ?? []);
      final other = participants.firstWhere(
        (p) => p != uid,
        orElse: () => '',
      );
      if (other.isNotEmpty) otherIds.add(other);
    }
    print('DEBUG: Other participant IDs: $otherIds'); // Debug line

    // Resolve names from users collection
    final usersMap = await crud.getUsersByIds(otherIds.toList());
    print('DEBUG: Users map: $usersMap'); // Debug line

    setState(() {
      chats = fetched.map((c) {
        final participants = List<String>.from(c['participants'] ?? []);
        final participantNames = List.from(c['participantNames'] ?? []);
        final otherId = participants.firstWhere(
          (p) => p != uid,
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

        return {
          'id': c['id'],
          'name': otherName,
          'lastMessage': c['lastMessage'] ?? '',
          'timestamp': c['lastUpdated'] ?? '',
          'unread': 0,
        };
      }).toList();
    });
    print('DEBUG: Final chats list: ${chats.length} items'); // Debug line
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
            child: chats.isEmpty
                ? const Center(
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
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                        top: 8, left: hPad, right: hPad, bottom: 88),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.primary.withOpacity(0.08),
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
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.15),
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
                                  Text(chat['timestamp'],
                                      style: const TextStyle(fontSize: 12)),
                                  if (chat['unread'] > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: badgeSize,
                                      height: badgeSize,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      child: Text(
                                        '${chat['unread']}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            )),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
