import 'package:chat_app_flutter/components/custom_card.dart';
import 'package:chat_app_flutter/services/crud_services.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  Future<void> testFirebaseConnection(BuildContext context) async {
    final crudServices = CrudServices();

    // Test inserting a user
    bool success = await crudServices.insertUser(
      userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test User',
      email: 'test@example.com',
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Firebase connection successful! User inserted.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Firebase connection failed!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
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
              offset: const Offset(-12, 0),
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
                const SizedBox(height: 40),
                // Test Firebase Connection Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => testFirebaseConnection(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Test Firebase Connection',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
