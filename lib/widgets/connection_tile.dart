import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service_connection.dart';
import '../providers/auth_provider.dart';

class ConnectionTile extends StatelessWidget {
  final ServiceConnection connection;

  const ConnectionTile({super.key, required this.connection});

  @override
  Widget build(BuildContext context) {
    final isConnected = connection.isConnected;
    final isConnecting = connection.isConnecting;

    Color bgColor;
    Color borderColor;
    if (isConnected) {
      bgColor = const Color(0xFF0A2E1A);
      borderColor = const Color(0xFF00C853);
    } else if (isConnecting) {
      bgColor = const Color(0xFF16213E);
      borderColor = const Color(0xFFFFA726);
    } else {
      bgColor = const Color(0xFF16213E);
      borderColor = const Color(0xFF2A2A4A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isConnecting
              ? null
              : () => _handleTap(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? const Color(0xFF00C853)
                        : isConnecting
                            ? const Color(0xFFFFA726)
                            : Colors.grey,
                    boxShadow: isConnected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00C853).withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(connection.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected
                            ? 'Connected'
                            : isConnecting
                                ? 'Connecting...'
                                : connection.description,
                        style: TextStyle(
                          color: isConnected
                              ? const Color(0xFF00C853)
                              : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isConnected
                      ? Icons.check_circle
                      : isConnecting
                          ? Icons.hourglass_top
                          : Icons.add_circle_outline,
                  color: isConnected
                      ? const Color(0xFF00C853)
                      : Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (connection.isConnected) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          content: Text(
            'Disconnect ${connection.displayName}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                auth.disconnect(connection.type);
                Navigator.pop(ctx);
              },
              child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      auth.connect(connection.type);
    }
  }
}
