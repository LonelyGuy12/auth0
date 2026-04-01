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
                  Icons.chat_bubble_outline,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chat',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              const ModelSelector(),
              const SizedBox(width: 12),
              Consumer<ChatProvider>(
                builder: (context, chat, _) => Material(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: chat.clearChat,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1A1A1A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Color(0xFF666666),
                        size: 18,
                      ),
                    ),
                  ),
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
                padding: const EdgeInsets.all(32),
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
