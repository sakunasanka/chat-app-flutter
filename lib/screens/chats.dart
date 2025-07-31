import 'package:flutter/material.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  final List<Map<String, dynamic>> chats = [
    {
      'id': '1',
      'name': 'Alice Smith',
      'lastMessage': 'Hey, how are you doing?',
      'timestamp': '10:30 AM',
      'unread': 2,
    },
    {
      'id': '2',
      'name': 'Bob Johnson',
      'lastMessage': 'Can we meet tomorrow?',
      'timestamp': 'Yesterday',
      'unread': 3,
    },
    {
      'id': '3',
      'name': 'Carol Williams',
      'lastMessage': 'Thanks for the info!',
      'timestamp': 'Yesterday',
      'unread': 0,
    },
  ];

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
        body: Column(
          children: [
            Expanded(child: chatsList()),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/new_chat');
                    // Action for adding a new chat
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ));
  }

  Widget chatsList() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/user_chat',
                    arguments: chat['name']);
              },
              child: ListTile(
                shape: const RoundedRectangleBorder(),
                title: Text(
                  chat['name'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(chat['lastMessage']),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(chat['timestamp'],
                        style: const TextStyle(fontSize: 12)),
                    if (chat['unread'] > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2, left: 50),
                        padding: const EdgeInsets.all(6),
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
    );
  }
}
