import 'package:chat_app_flutter/screens/chats.dart';
import 'package:chat_app_flutter/screens/home_screen.dart';
import 'package:flutter/material.dart';

class TabsNav extends StatefulWidget {
  const TabsNav({super.key});
  @override
  State<TabsNav> createState() => _TabsNavState();
}

class _TabsNavState extends State<TabsNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    const MyHomePage(title: 'QR Chat'),
    const Chats(),
    const Center(child: Text("Scan QR code")),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'Connect',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
