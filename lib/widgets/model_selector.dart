import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key});

  static const List<Map<String, String>> models = [
    {'id': 'qwen/qwen3.6-plus-preview:free', 'name': '🆓 Qwen 3.6 Plus'},
    {'id': 'nvidia/nemotron-3-super-120b-a12b:free', 'name': '🆓 Nemotron 3 Super'},
    {'id': 'minimax/minimax-m2.5:free', 'name': '🆓 MiniMax M2.5'},
    {'id': 'z-ai/glm-4.5-air:free', 'name': '🆓 GLM 4.5 Air'},
    {'id': 'openai/gpt-oss-120b:free', 'name': '🆓 GPT-OSS 120B'},
    {'id': 'nvidia/nemotron-3-nano-30b-a3b:free', 'name': '🆓 Nemotron 3 Nano'},
    {'id': 'stepfun/step-3.5-flash:free', 'name': '🆓 Step 3.5 Flash'},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border.all(color: const Color(0xFF1A1A1A)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: models.any((m) => m['id'] == chat.currentModel)
                  ? chat.currentModel
                  : models.first['id'],
              dropdownColor: const Color(0xFF0A0A0A),
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 12,
                letterSpacing: -0.2,
              ),
              icon: const Icon(Icons.expand_more, color: Color(0xFF666666), size: 16),
              isDense: true,
              items: models.map((m) {
                return DropdownMenuItem(
                  value: m['id'],
                  child: Text(
                    m['name']!,
                    style: const TextStyle(fontSize: 12, letterSpacing: -0.2),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  chat.switchModel(value);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
