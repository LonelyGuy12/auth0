import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'chat_input.dart';
import 'model_selector.dart';
import 'typing_indicator.dart';

class ChatArea extends StatelessWidget {
  const ChatArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF000000),
            border: Border(
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Chat',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              const ModelSelector(),
              const SizedBox(width: 12),
              Consumer<ChatProvider>(
                builder: (context, chat, _) => IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF666666), size: 18),
                  tooltip: 'Clear chat',
                  onPressed: chat.clearChat,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chat, _) {
              final itemCount =
                  chat.messages.length + (chat.isLoading ? 1 : 0);
              return ListView.builder(
                controller: chat.scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= chat.messages.length) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: chat.messages[index]);
                },
              );
            },
          ),
        ),

        // Input
        const ChatInput(),
      ],
    );
  }
}
