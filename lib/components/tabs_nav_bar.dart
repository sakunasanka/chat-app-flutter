import 'package:chat_app_flutter/screens/chats.dart';
import 'package:chat_app_flutter/screens/home_screen.dart';
import 'package:chat_app_flutter/screens/qr_connect.dart';
import 'package:chat_app_flutter/services/crud_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class TabsNav extends StatefulWidget {
  final int initialIndex;
  const TabsNav({super.key, this.initialIndex = 0});
  @override
  State<TabsNav> createState() => _TabsNavState();
}

class _TabsNavState extends State<TabsNav> {
  int _selectedIndex = 0;
  Timer? _notificationTimer;

  final List<Widget> _pages = <Widget>[
    const MyHomePage(title: 'QR Chat'),
    const Chats(),
    const QRCode()
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initUserAndStartTimer();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initUserAndStartTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    if (uid != null && uid.isNotEmpty) {
      _startNotificationTimer(uid);
    }
  }

  void _startNotificationTimer(String uid) {
    // Check for incoming invites & outgoing responses every 3 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkIncomingInvites(uid);
      _checkOutgoingResponses(uid);
    });
  }

  // Incoming invites (receiver needs to accept/decline)
  Future<void> _checkIncomingInvites(String uid) async {
    final crud = CrudServices();
    final invites = await crud.getPendingInvitesForUser(uid);

    for (final invite in invites) {
      if (!mounted) return;
      final fromName = invite['fromName'] ?? invite['from'];
      final type = invite['type'] ?? 'instant';
      final inviteId = invite['id'] as String;

      final accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: Text(
              'Chat request (${type == 'continue' ? 'Continue' : 'Instant'})'),
          content: Text(
              '$fromName wants to ${type == 'continue' ? 'continue a chat with you' : 'start an instant chat with you'}. Do you accept?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Decline'),
            ),
            TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Accept'),
            ),
          ],
        ),
      );

      if (accept == true) {
        final res = await crud.acceptInvite(inviteId);
        if (!mounted) return;
        if (res != null) {
          final chatId = res['chatId'];
          final ephemeralId = res['ephemeralId'];
          // Navigate the receiver immediately
          if (chatId != null) {
            Navigator.pushNamed(context, '/user_chat', arguments: {
              'title': fromName,
              'chatId': chatId,
              'ephemeral': false,
            });
          } else if (ephemeralId != null) {
            Navigator.pushNamed(context, '/user_chat', arguments: {
              'title': fromName,
              'sessionId': ephemeralId,
              'ephemeral': true,
            });
          }
        }
      } else {
        await crud.declineInvite(inviteId);
      }
    }
  }

  // Outgoing responses (notify the sender about accepted/declined and navigate)
  Future<void> _checkOutgoingResponses(String uid) async {
    final crud = CrudServices();
    final responses = await crud.getOutgoingInviteResponses(uid);
    for (final inv in responses) {
      final status = inv['status'];
      final toName = inv['toName'] ?? inv['to'];
      final inviteId = inv['id'] as String;
      if (status == 'accepted') {
        final chatId = inv['chatId'];
        final ephemeralId = inv['ephemeralId'];
        if (!mounted) return;
        // Navigate sender
        if (chatId != null) {
          Navigator.pushNamed(context, '/user_chat', arguments: {
            'title': toName,
            'chatId': chatId,
            'ephemeral': false,
          });
        } else if (ephemeralId != null) {
          Navigator.pushNamed(context, '/user_chat', arguments: {
            'title': toName,
            'sessionId': ephemeralId,
            'ephemeral': true,
          });
        }
        // Mark notified
        await crud.markInviteNotifiedForFrom(inviteId);
      } else if (status == 'declined') {
        if (!mounted) return;
        // Inform sender that invite was declined
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your chat request was declined by $toName')),
        );
        await crud.markInviteNotifiedForFrom(inviteId);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Connect',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
