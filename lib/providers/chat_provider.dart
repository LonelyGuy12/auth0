import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/message.dart';
import '../services/ai_agent_service.dart';

class ChatProvider extends ChangeNotifier {
  final AiAgentService _agent = AiAgentService();
  final List<Message> messages = [];
  bool _isLoading = false;
  String _currentModel = AppConstants.defaultAiModel;
  final ScrollController scrollController = ScrollController();

  bool get isLoading => _isLoading;
  String get currentModel => _currentModel;

  ChatProvider() {
    messages.add(Message(
      content:
          "👋 Hi! I'm your AI agent powered by Auth0 Token Vault.\n\n"
          "🔗 Connect your services in the sidebar\n"
          "💬 Then ask me anything!\n\n"
          "I can manage your **Google Calendar**, check your **GitHub repos**, and more.",
      type: MessageType.agent,
    ));
  }

  void switchModel(String model) {
    _currentModel = model;
    _agent.switchModel(model);
    messages.add(Message(
      content: '🔄 Switched to **$model**',
      type: MessageType.system,
    ));
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    messages.add(Message(content: trimmed, type: MessageType.user));
    _isLoading = true;
    notifyListeners();
    _scrollToBottom();

    try {
      final response = await _agent.chat(trimmed);
      messages.add(Message(content: response, type: MessageType.agent));
    } catch (e) {
      messages.add(Message(
        content: 'Error: ${e.toString()}',
        type: MessageType.error,
      ));
    }

    _isLoading = false;
    notifyListeners();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearChat() {
    messages.clear();
    messages.add(Message(
      content:
          "👋 Hi! I'm your AI agent powered by Auth0 Token Vault.\n\n"
          "🔗 Connect your services in the sidebar\n"
          "💬 Then ask me anything!\n\n"
          "I can manage your **Google Calendar**, check your **GitHub repos**, and more.",
      type: MessageType.agent,
    ));
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
