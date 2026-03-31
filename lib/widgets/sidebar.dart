import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'connection_tile.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Agent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Powered by Auth0 Token Vault',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: const Color(0xFF2A2A4A)),

          // Connections label
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CONNECTIONS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Connection tiles
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Column(
                children: auth.connections
                    .map((conn) => ConnectionTile(connection: conn))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF2A2A4A)),

          // Try asking label
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TRY ASKING',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Suggestion chips
          ..._buildSuggestions(context),

          const Spacer(),

          // Footer
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Built for Authorized to Act Hackathon\nAuth0 Token Vault',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSuggestions(BuildContext context) {
    final suggestions = [
      {'emoji': '📅', 'text': 'What meetings do I have today?'},
      {'emoji': '🐙', 'text': 'Show my GitHub repositories'},
      {'emoji': '➕', 'text': 'Create a meeting tomorrow at 2pm for 1 hour'},
      {'emoji': '👤', 'text': 'Show my GitHub profile'},
    ];

    return suggestions.map((s) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: const Color(0xFF16213E),
            onTap: () {
              context.read<ChatProvider>().sendMessage(s['text']!);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2A2A4A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(s['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      s['text']!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
