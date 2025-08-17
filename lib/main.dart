import 'package:chat_app_flutter/components/tabs_nav_bar.dart';
import 'package:chat_app_flutter/screens/home_screen.dart';
import 'package:chat_app_flutter/screens/user_chat.dart';
import 'package:chat_app_flutter/screens/unread_messages.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: appTheme,
      home: const TabsNav(),
      routes: <String, WidgetBuilder>{
        '/home': (context) => const MyHomePage(title: 'QR Chat'),
        '/chats': (context) => const TabsNav(initialIndex: 1),
        '/unread_messages': (context) => const UnreadMessages(),
        '/user_chat': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            return UserChat(title: arguments['title'] as String? ?? '');
          } else if (arguments is String) {
            return UserChat(title: arguments);
          } else {
            return const UserChat(title: 'Chat');
          }
        },
      },
    );
  }
}
