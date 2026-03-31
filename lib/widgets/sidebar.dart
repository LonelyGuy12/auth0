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
      color: const Color(0xFF000000),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('▲', style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Agent',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Token Vault',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: const Color(0xFF1A1A1A)),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Connections label
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Connections',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
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

                  const SizedBox(height: 20),
                  Container(height: 1, color: const Color(0xFF1A1A1A)),

                  // Try asking label
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  // Suggestion chips
                  ..._buildSuggestions(context),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A1A1A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Built for Authorized to Act\nPowered by Auth0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            hoverColor: const Color(0xFF0A0A0A),
            onTap: () {
              context.read<ChatProvider>().sendMessage(s['text']!);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A1A1A)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(s['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      s['text']!,
                      style: const TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 13,
                        letterSpacing: -0.2,
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
