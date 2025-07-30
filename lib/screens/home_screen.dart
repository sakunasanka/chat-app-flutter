import 'package:chat_app_flutter/components/custom_card.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.translate(
              offset: const Offset(-12, -8),
              child: const Text(
                'Connect instantly with QR codes',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 80),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomCard(
                  icon: Icons.qr_code_outlined,
                  iconColor: theme.colorScheme.primary,
                  bgColor: theme.colorScheme.primary.withOpacity(0.2),
                  title: 'New Connection',
                  subtitle: 'Generate or scan a QR code to start a new chat',
                  buttonText: 'Connect Now',
                  onPressed: () {
                    Navigator.pushNamed(context, '/new_chat');
                  },
                ),
                const SizedBox(height: 40),
                CustomCard(
                  icon: Icons.message_outlined,
                  iconColor: theme.colorScheme.secondary,
                  bgColor: theme.colorScheme.secondary.withOpacity(0.2),
                  title: 'Recent Chats',
                  subtitle:
                      'Continue your conversations with recent connections',
                  buttonText: 'View Chats',
                  onPressed: () {
                    Navigator.pushNamed(context, '/chats');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
