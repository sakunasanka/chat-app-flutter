import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app_flutter/services/crud_services.dart';
import 'qr_connect.dart';

class MyQRPage extends StatefulWidget {
  const MyQRPage({super.key});

  @override
  State<MyQRPage> createState() => _MyQRPageState();
}

class _MyQRPageState extends State<MyQRPage> {
  String? _userId;
  String? _userName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    final name = prefs.getString('user_name');
    if (uid != null && uid.isNotEmpty) {
      setState(() {
        _userId = uid;
        _userName = name;
        _loading = false;
      });
      // After we know our id, check for pending requests
      _checkPendingRequests(uid);
      return;
    }

    // If we don't have a firestore user id but we have a name, create one
    if (name != null && name.isNotEmpty) {
      final crud = CrudServices();
      final generated = await crud.insertUserAuto(name: name);
      if (generated != null) {
        await prefs.setString('user_id', generated);
        setState(() {
          _userId = generated;
          _userName = name;
          _loading = false;
        });
        return;
      }
    }

    // Fallback: no id and no name
    setState(() {
      _userId = null;
      _userName = name;
      _loading = false;
    });
  }

  Future<void> _checkPendingRequests(String uid) async {
    final crud = CrudServices();

    // Check for pending chat requests
    final requests = await crud.getPendingRequestsForUser(uid);
    for (final req in requests) {
      if (!mounted) return;
      final fromName = req['fromName'] ?? req['from'];
      final accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: const Text('Chat request'),
          content: Text('$fromName wants to continue the chat. Accept?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Decline')),
            TextButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Accept')),
          ],
        ),
      );

      final accepted = accept == true;
      final chatId =
          await crud.respondChatRequest(requestId: req['id'], accept: accepted);
      if (accepted && chatId != null) {
        // Open chat UI for the newly created chat (pass title as participant name)
        final otherName = req['fromName'] ?? req['from'];
        if (!mounted) return;
        Navigator.pushNamed(context, '/user_chat', arguments: {
          'title': otherName,
          'chatId': chatId,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('My QR Code',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_userId != null)
                      Column(
                        children: [
                          // Use a URL payload so scanners reliably parse user id
                          Builder(builder: (ctx) {
                            final qrData = 'https://chatapp.app/user/$_userId';
                            return QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 220,
                            );
                          }),
                          const SizedBox(height: 12),
                          Text(
                            _userName ?? '',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${_userId!}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      const Text(
                          'No user id found. Please set your name first.'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        onPressed: () {
                          // navigate to scan screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QRCode()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
