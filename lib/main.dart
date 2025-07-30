import 'package:chat_app_flutter/components/tabs_nav_bar.dart';
import 'package:chat_app_flutter/screens/home_screen.dart';
import 'package:chat_app_flutter/screens/new_chat.dart';
import 'package:chat_app_flutter/screens/user_chat.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

void main() {
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
        '/new_chat': (context) => const NewChat(),
        '/chats': (context) => const TabsNav(initialIndex: 1),
        '/user_chat': (context) => UserChat(
            title: ModalRoute.of(context)!.settings.arguments as String)
      },
    );
  }
}
