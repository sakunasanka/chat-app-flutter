import 'package:chat_app_flutter/components/custom_card.dart';
import 'package:chat_app_flutter/services/crud_services.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRCode extends StatefulWidget {
  const QRCode({super.key});

  @override
  State<QRCode> createState() => _QRCodeState();
}

class _QRCodeState extends State<QRCode> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Scan QR Code'),
                      backgroundColor: Colors.white,
                      content: SizedBox(
                        width: 300,
                        height: 300,
                        child: QRView(
                          key: qrKey,
                          onQRViewCreated: (qrController) {
                            controller = qrController;
                            controller!.scannedDataStream
                                .listen((scanData) async {
                              final navigatorContext = context;
                              final code = scanData.code;
                              // Close the dialog and controller after handling
                              try {
                                if (code == null || code.isEmpty) {
                                  controller?.dispose();
                                  Navigator.of(navigatorContext).pop();
                                  showDialog(
                                    context: navigatorContext,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Invalid QR'),
                                      content: const Text(
                                          'Scanned QR code is empty.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final uri = Uri.tryParse(code);
                                String? userId;
                                if (uri != null &&
                                    (uri.hasScheme || uri.hasAuthority)) {
                                  if (uri.pathSegments.isNotEmpty &&
                                      uri.pathSegments.length >= 2 &&
                                      uri.pathSegments[0] == 'user') {
                                    userId = uri.pathSegments[1];
                                  } else if (uri.queryParameters['id'] !=
                                      null) {
                                    userId = uri.queryParameters['id'];
                                  }
                                }

                                // Fallback: treat raw scanned string as id
                                if ((userId == null || userId.isEmpty) &&
                                    code.isNotEmpty) {
                                  userId = code;
                                }

                                if (userId == null || userId.isEmpty) {
                                  controller?.dispose();
                                  Navigator.of(navigatorContext).pop();
                                  showDialog(
                                    context: navigatorContext,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Invalid QR'),
                                      content: const Text(
                                          'QR code does not contain a valid user id.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final crud = CrudServices();
                                final user = await crud.getUser(userId);

                                controller?.dispose();
                                if (!mounted) return;
                                Navigator.of(navigatorContext).pop();

                                if (user != null) {
                                  // Ask whether to create a persistent chat or just an instant chat
                                  final choice = await showDialog<String>(
                                    context: navigatorContext,
                                    builder: (c) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text('Start chat'),
                                      content: const Text(
                                          'Start an instant chat (won\'t be saved) or request to continue later?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop('instant'),
                                          child: const Text('Instant chat'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop('request'),
                                          child: const Text('Continue to chat'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (choice == 'instant' ||
                                      choice == 'request') {
                                    final crud = CrudServices();

                                    // Get current user info
                                    String fromId = 'local_user';
                                    String fromName = '';
                                    try {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final uid = prefs.getString('user_id');
                                      final uname =
                                          prefs.getString('user_name');
                                      if (uid != null && uid.isNotEmpty)
                                        fromId = uid;
                                      if (uname != null) fromName = uname;
                                    } catch (_) {}

                                    final inviteId =
                                        await crud.createChatInvite(
                                      fromId: fromId,
                                      toId: userId,
                                      fromName: fromName,
                                      toName: user['name'] ?? '',
                                      type: choice == 'instant'
                                          ? 'instant'
                                          : 'continue',
                                    );

                                    if (!mounted) return;
                                    if (inviteId != null) {
                                      ScaffoldMessenger.of(navigatorContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Chat request sent to ${user['name'] ?? userId}'),
                                        ),
                                      );
                                      // Navigation will occur after the other user accepts (handled by Tabs timer)
                                    } else {
                                      showDialog(
                                        context: navigatorContext,
                                        builder: (c) => const AlertDialog(
                                          title: Text('Error'),
                                          content: Text(
                                              'Failed to send chat request. Please try again.'),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  showDialog(
                                    context: navigatorContext,
                                    builder: (c) => AlertDialog(
                                      title: const Text('User not found'),
                                      content: const Text(
                                          'No user found for this QR code.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(c).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                controller?.dispose();
                                if (mounted) Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
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
                              }
                            });
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            controller?.dispose(); // Clean up controller
                            Navigator.of(context).pop(); // Close manually
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  );
                },
                child: CustomCard(
                  icon: Icons.camera_enhance_outlined,
                  iconColor: theme.colorScheme.primary,
                  bgColor: theme.colorScheme.primary.withOpacity(0.2),
                  title: 'New Connection',
                  subtitle: 'Tap here to scan a QR code and start a new chat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
