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
      bgColor = const Color(0xFF0A0A0A);
      borderColor = const Color(0xFF00D66F);
    } else if (isConnecting) {
      bgColor = const Color(0xFF0A0A0A);
      borderColor = const Color(0xFFFFA726);
    } else {
      bgColor = const Color(0xFF0A0A0A);
      borderColor = const Color(0xFF1A1A1A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isConnecting
              ? null
              : () => _handleTap(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? const Color(0xFF00D66F)
                        : isConnecting
                            ? const Color(0xFFFFA726)
                            : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(width: 10),
                Text(connection.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.displayName,
                        style: const TextStyle(
                          color: Color(0xFFEDEDED),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
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
                              ? const Color(0xFF00D66F)
                              : const Color(0xFF666666),
                          fontSize: 11,
                          letterSpacing: -0.2,
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
                      ? const Color(0xFF00D66F)
                      : const Color(0xFF666666),
                  size: 16,
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
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1A1A1A)),
          ),
          title: const Text(
            'Disconnect',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          content: Text(
            'Disconnect ${connection.displayName}?',
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
            TextButton(
              onPressed: () {
                auth.disconnect(connection.type);
                Navigator.pop(ctx);
              },
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          ],
        ),
      );
    } else {
      auth.connect(connection.type);
    }
  }
}
