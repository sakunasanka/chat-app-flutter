import 'package:chat_app_flutter/components/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:chat_app_flutter/screens/qr_code_scanner.dart';

class QRCode extends StatefulWidget {
  const QRCode({super.key});

  @override
  State<QRCode> createState() => _QRCodeState();
}

class _QRCodeState extends State<QRCode> {
  // No state needed; we navigate directly to the scanner screen

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QRScannerDialogScreen()),
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
