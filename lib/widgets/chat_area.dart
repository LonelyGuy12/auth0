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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF12122A),
            border: Border(
              bottom: BorderSide(color: Color(0xFF2A2A4A), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Text(
                '💬 Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const ModelSelector(),
              const SizedBox(width: 8),
              Consumer<ChatProvider>(
                builder: (context, chat, _) => IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  tooltip: 'Clear chat',
                  onPressed: chat.clearChat,
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
                padding: const EdgeInsets.all(20),
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
