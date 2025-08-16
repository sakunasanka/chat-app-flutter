import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:chat_app_flutter/services/crud_services.dart';

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
          Navigator.pushNamed(context, '/user_chat',
              arguments: user['name'] ?? userId);
        } else {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
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
