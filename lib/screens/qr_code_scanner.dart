import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_chat/services/crud_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRScannerDialogScreen extends StatefulWidget {
  const QRScannerDialogScreen({super.key});

  @override
  State<QRScannerDialogScreen> createState() => _QRScannerDialogScreenState();
}

class _QRScannerDialogScreenState extends State<QRScannerDialogScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      final code = scanData.code;
      try {
        if (code == null || code.isEmpty) {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Invalid QR'),
              content: const Text('Scanned QR code is empty.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(c).pop(),
                    child: const Text('OK'))
              ],
            ),
          );
          return;
        }

        final uri = Uri.tryParse(code);
        String? userId;
        if (uri != null && (uri.hasScheme || uri.hasAuthority)) {
          if (uri.pathSegments.isNotEmpty &&
              uri.pathSegments.length >= 2 &&
              uri.pathSegments[0] == 'user') {
            userId = uri.pathSegments[1];
          } else if (uri.queryParameters['id'] != null) {
            userId = uri.queryParameters['id'];
          }
        }

        // Fallback: if parsing didn't yield an id, assume the scanned code itself is the id
        if ((userId == null || userId.isEmpty) && code.isNotEmpty) {
          userId = code;
        }

        if (userId == null || userId.isEmpty) {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Invalid QR'),
              content: const Text('QR code does not contain a valid user id.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(c).pop(),
                    child: const Text('OK'))
              ],
            ),
          );
          return;
        }

        final crud = CrudServices();
        final user = await crud.getUser(userId);
        Navigator.of(context).pop();
        if (user != null) {
          // Start an instant chat by default on this dialog scanner
          // 1) Resolve current user info
          String fromId = 'local_user';
          String fromName = '';
          bool createdNewUid = false;
          try {
            final prefs = await SharedPreferences.getInstance();
            String? uid = prefs.getString('user_id');
            String? uname = prefs.getString('user_name');
            if ((uid == null || uid.isEmpty)) {
              if (uname != null && uname.isNotEmpty) {
                final createdId = await crud.insertUserAuto(name: uname);
                if (createdId != null) {
                  await prefs.setString('user_id', createdId);
                  uid = createdId;
                  createdNewUid = true;
                }
              }
            }
            if (uid == null || uid.isEmpty) {
              // Abort and inform user to set a name first
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Set up your profile'),
                    content: const Text(
                        'Please set your name first so others can chat with you.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(c).pop(),
                          child: const Text('OK')),
                    ],
                  ),
                );
              }
              return;
            }
            fromId = uid;
            if (uname != null) fromName = uname;
          } catch (_) {}

          // 2) Create ephemeral session so both sides join same room
          final sessionId = await crud.createEphemeralSession(
            user1Id: fromId,
            user2Id: userId,
            user1Name: fromName,
            user2Name: user['name'] ?? '',
          );

          if (sessionId == null) {
            showDialog(
              context: context,
              builder: (c) => const AlertDialog(
                backgroundColor: Colors.white,
                title: Text('Error'),
                content:
                    Text('Failed to start instant chat. Please try again.'),
              ),
            );
            return;
          }

          // 3) Create an instant invite pointing to the ephemeral session
          await crud.createChatInvite(
            fromId: fromId,
            toId: userId,
            fromName: fromName,
            toName: user['name'] ?? '',
            type: 'instant',
            ephemeralId: sessionId,
          );

          // 4) Do NOT navigate immediately. Inform the user and wait for receiver to accept.
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Instant chat request sent'),
              content: Text(
                  'Waiting for ${user['name'] ?? userId} to accept your instant chat request.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (createdNewUid && mounted) {
            // Ensure app shells are refreshed and timers started for new uid
            Navigator.pushNamed(context, '/chats');
          }
        } else {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('User not found'),
              content: const Text('No user found for this QR code.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(c).pop(),
                    child: const Text('OK'))
              ],
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Scan error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        ),
      ),
    );
  }
}
