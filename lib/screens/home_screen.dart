import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_area.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          Container(width: 1, color: const Color(0xFF1A1A1A)),
          Expanded(
            child: _selectedIndex == 0
                ? const ChatArea()
                : const SettingsScreen(),
          ),
        ],
      ),
    );
  }
}
