import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_area.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 300, child: Sidebar()),
          Container(width: 1, color: const Color(0xFF2A2A4A)),
          const Expanded(child: ChatArea()),
        ],
      ),
    );
  }
}
