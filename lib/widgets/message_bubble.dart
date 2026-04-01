import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:animate_do/animate_do.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.user:
        return _buildUserBubble(context);
      case MessageType.agent:
        return _buildAgentBubble(context);
      case MessageType.system:
        return _buildSystemBubble(context);
      case MessageType.error:
        return _buildErrorBubble(context);
      case MessageType.loading:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F0F0F),
                        Color(0xFF0A0A0A),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF1A1A1A),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 14,
                      letterSpacing: -0.2,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentBubble(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isToolCall == true && message.toolName != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3291FF).withOpacity(0.1),
                              const Color(0xFF3291FF).withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF3291FF).withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: const Color(0xFF3291FF).withOpacity(0.8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              message.toolName!,
                              style: TextStyle(
                                color: const Color(0xFF3291FF).withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F0F0F),
                            Color(0xFF0A0A0A),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF1A1A1A),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: Color(0xFFEDEDED),
                            fontSize: 14,
                            letterSpacing: -0.2,
                            height: 1.6,
                          ),
                          h1: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            height: 1.3,
                          ),
                          h2: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                            height: 1.3,
                          ),
                          h3: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.3,
                          ),
                          code: TextStyle(
                            color: const Color(0xFF3291FF).withOpacity(0.9),
                            backgroundColor: const Color(0xFF000000),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            border: Border.all(color: const Color(0xFF1A1A1A)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          codeblockPadding: const EdgeInsets.all(16),
                          listBullet: const TextStyle(
                              color: Color(0xFFEDEDED)),
                          strong: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w600),
                          em: const TextStyle(
                              color: Color(0xFFEDEDED),
                              fontStyle: FontStyle.italic),
                          a: const TextStyle(
                            color: Color(0xFF3291FF),
                            decoration: TextDecoration.underline,
                          ),
                          blockSpacing: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemBubble(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3291FF).withOpacity(0.1),
                  const Color(0xFF3291FF).withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF3291FF).withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF3291FF).withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  message.content,
                  style: TextStyle(
                    color: const Color(0xFF3291FF).withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBubble(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF6B6B).withOpacity(0.15),
                        const Color(0xFFFF6B6B).withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: const Color(0xFFFF6B6B).withOpacity(0.9),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: const Color(0xFFFF6B6B).withOpacity(0.95),
                            fontSize: 14,
                            letterSpacing: -0.2,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
