import 'package:chat_app_flutter/components/custom_card.dart';
import 'package:flutter/material.dart';

class QRCode extends StatefulWidget {
  const QRCode({super.key});

  @override
  State<QRCode> createState() => _QRCodeState();
}

class _QRCodeState extends State<QRCode> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 150),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CustomCard(
                  icon: Icons.camera_enhance_outlined,
                  iconColor: theme.colorScheme.primary,
                  bgColor: theme.colorScheme.primary.withOpacity(0.2),
                  title: 'New Connection',
                  subtitle: 'Tap here to scan a QR code and start a new chat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
