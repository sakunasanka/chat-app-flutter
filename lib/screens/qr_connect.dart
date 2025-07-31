import 'package:chat_app_flutter/components/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
                            controller!.scannedDataStream.listen((scanData) {
                              Navigator.of(context).pop(); // Close the dialog
                              controller?.dispose();
                              print('Scanned Code: ${scanData.code}');
                              // Handle scanned data here
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
