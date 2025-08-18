import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app_flutter/services/crud_services.dart';

class QrCodeScannerScreen extends StatefulWidget {
  const QrCodeScannerScreen({super.key});

  @override
  State<QrCodeScannerScreen> createState() => _QRCodeState();
}

class _QRCodeState extends State<QrCodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController p1) {
    controller = p1;
    controller!.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return;

      setState(() {
        _isProcessing = true;
      });
      await controller?.pauseCamera();

      try {
        final code = scanData.code;
        if (code == null || code.isEmpty) {
          await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Invalid QR'),
              content: const Text('Scanned QR code is empty.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'),
                ),
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

        // Fallback: treat raw scanned string as id
        if ((userId == null || userId.isEmpty) && code.isNotEmpty) {
          userId = code;
        }

        if (userId == null || userId.isEmpty) {
          await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Invalid QR'),
              content: const Text('QR code does not contain a valid user id.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        final crud = CrudServices();
        final user = await crud.getUser(userId);

        if (user != null) {
          // Ask whether to create a persistent chat or just an instant chat
          final choice = await showDialog<String>(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Start chat'),
              content: const Text(
                  'Start an instant chat (won\'t be saved) or request to continue later?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop('instant'),
                  child: const Text('Instant chat'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(c).pop('request'),
                  child: const Text('Continue to chat'),
                ),
              ],
            ),
          );

          if (choice == 'instant') {
            // Create an ephemeral session, create an instant invite
            // that references the ephemeralId so the recipient can
            // accept and reuse the same session, then open chat.
            final crud = CrudServices();

            // Get current user info
            String fromId = 'local_user';
            String fromName = '';
            try {
              final prefs = await SharedPreferences.getInstance();
              final uid = prefs.getString('user_id');
              final uname = prefs.getString('user_name');
              if (uid != null && uid.isNotEmpty) fromId = uid;
              if (uname != null) fromName = uname;
            } catch (_) {}

            // Create ephemeral session doc first
            final sessionId = await crud.createEphemeralSession(
              user1Id: fromId,
              user2Id: userId,
              user1Name: fromName,
              user2Name: user['name'] ?? '',
            );

            if (!mounted) return;
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

            // Create invite pointing to the ephemeral session so the
            // recipient accepts into the same session.
            final inviteId = await crud.createChatInvite(
              fromId: fromId,
              toId: userId,
              fromName: fromName,
              toName: user['name'] ?? '',
              type: 'instant',
              ephemeralId: sessionId,
            );
            print(
                'DEBUG: instant invite created $inviteId for session $sessionId');

            // Do not show a persistent popup. Just close the scanner; tabs will navigate when accepted.
            if (!mounted) return;
            // Ensure no lingering snackbars
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.of(context).pop();
          } else if (choice == 'request') {
            // Keep original invite flow for requesting a persistent chat
            final crud = CrudServices();

            // Get current user info
            String fromId = 'local_user';
            String fromName = '';
            try {
              final prefs = await SharedPreferences.getInstance();
              final uid = prefs.getString('user_id');
              final uname = prefs.getString('user_name');
              if (uid != null && uid.isNotEmpty) fromId = uid;
              if (uname != null) fromName = uname;
            } catch (_) {}

            final inviteId = await crud.createChatInvite(
              fromId: fromId,
              toId: userId,
              fromName: fromName,
              toName: user['name'] ?? '',
              type: 'continue',
            );

            if (!mounted) return;
            if (inviteId != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Chat request sent to ${user['name'] ?? userId}'),
                ),
              );
              Navigator.of(context).pop();
            } else {
              showDialog(
                context: context,
                builder: (c) => const AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text('Error'),
                  content:
                      Text('Failed to send chat request. Please try again.'),
                ),
              );
            }
          }
        } else {
          await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('User not found'),
              content: const Text('No user found for this QR code.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(c).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Scan error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          await controller?.resumeCamera();
          setState(() {
            _isProcessing = false;
          });
        }
      }
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
          'Scan QR Code',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }
}
