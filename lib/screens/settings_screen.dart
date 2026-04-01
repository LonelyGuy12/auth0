import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/service_connection.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            border: Border(
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected Accounts',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Link your accounts to enable AI agent capabilities',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    letterSpacing: -0.2,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      children: auth.connections
                          .map((conn) => _buildConnectionCard(context, conn, auth))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    ServiceConnection connection,
    AuthProvider auth,
  ) {
    final isConnected = connection.isConnected;
    final isConnecting = connection.isConnecting;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isConnected
                  ? const Color(0xFF00D66F).withOpacity(0.15)
                  : Colors.transparent,
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(
                  color: isConnected
                      ? const Color(0xFF00D66F)
                      : const Color(0xFF1A1A1A),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
                gradient: isConnected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00D66F).withOpacity(0.05),
                          Colors.transparent,
                        ],
                      )
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isConnected
                            ? const Color(0xFF00D66F).withOpacity(0.3)
                            : const Color(0xFF1A1A1A),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        connection.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.displayName,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          connection.description,
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                            letterSpacing: -0.2,
                            height: 1.4,
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          child: isConnected
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.elasticOut,
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          alignment: Alignment.centerLeft,
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00D66F).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF00D66F).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(milliseconds: 1500),
                                              curve: Curves.easeInOut,
                                              tween: Tween(begin: 0.6, end: 1.0),
                                              builder: (context, value, child) {
                                                return Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: const Color(0xFF00D66F),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF00D66F).withOpacity(value * 0.8),
                                                        blurRadius: 8 * value,
                                                        spreadRadius: 1 * value,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              onEnd: () {
                                                // Loop animation
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Connected',
                                              style: TextStyle(
                                                color: Color(0xFF00D66F),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      key: ValueKey(isConnected),
                      color: isConnected
                          ? Colors.transparent
                          : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      elevation: isConnected ? 0 : 2,
                      shadowColor: Colors.black.withOpacity(0.2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: isConnecting
                            ? null
                            : () => _handleConnection(context, connection, auth),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: isConnected
                              ? BoxDecoration(
                                  border: Border.all(color: const Color(0xFF1A1A1A)),
                                  borderRadius: BorderRadius.circular(10),
                                )
                              : BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFFFFF),
                                      Color(0xFFF5F5F5),
                                    ],
                                  ),
                                ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isConnecting)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF666666)),
                                  ),
                                )
                              else
                                Icon(
                                  isConnected ? Icons.link_off : Icons.link,
                                  size: 16,
                                  color: isConnected
                                      ? const Color(0xFF666666)
                                      : Colors.black,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                isConnecting
                                    ? 'Connecting...'
                                    : isConnected
                                        ? 'Disconnect'
                                        : 'Connect',
                                style: TextStyle(
                                  color: isConnected
                                      ? const Color(0xFF666666)
                                      : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleConnection(
    BuildContext context,
    ServiceConnection connection,
    AuthProvider auth,
  ) {
    if (connection.isConnected) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1A1A1A)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Disconnect Account',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to disconnect ${connection.displayName}? You\'ll need to reconnect to use this service.',
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 14,
              letterSpacing: -0.2,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Material(
              color: const Color(0xFF1A0A0A),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  auth.disconnect(connection.type);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
