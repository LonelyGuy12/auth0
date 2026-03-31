import 'dart:convert';
import '../config/constants.dart';
import 'openrouter_service.dart';
import 'google_calendar_service.dart';
import 'github_service.dart';
import 'token_vault_service.dart';

class AiAgentService {
  OpenRouterService _openRouter;
  final GoogleCalendarService _calendar = GoogleCalendarService();
  final GitHubService _github = GitHubService();
  final TokenVaultService _tokenVault = TokenVaultService();
  String _currentModel;

  AiAgentService()
      : _currentModel = AppConstants.defaultAiModel,
        _openRouter = OpenRouterService(
          apiKey: AppConstants.openRouterApiKey,
          model: AppConstants.defaultAiModel,
        );

  void switchModel(String newModel) {
    _currentModel = newModel;
    _openRouter = OpenRouterService(
      apiKey: AppConstants.openRouterApiKey,
      model: _currentModel,
    );
  }

  Future<String> chat(String userMessage) async {
    return _openRouter.chat(
      userMessage,
      onToolCall: _handleToolCall,
    );
  }

  Future<String> _handleToolCall(
      String toolName, Map<String, dynamic> args) async {
    switch (toolName) {
      case 'get_calendar_events':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google Calendar is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 5;
          final result = await _calendar.getEvents(maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'create_calendar_event':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google Calendar is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final result = await _calendar.createEvent(
            summary: args['summary'] as String? ?? 'New Event',
            startTime: args['startTime'] as String? ?? '',
            endTime: args['endTime'] as String? ?? '',
            description: args['description'] as String?,
          );
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_github_repos':
        if (!await _tokenVault.isConnected('github')) {
          return jsonEncode({
            'error': 'GitHub is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final sort = args['sort'] as String? ?? 'updated';
          final result = await _github.getRepositories(sort: sort);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_github_profile':
        if (!await _tokenVault.isConnected('github')) {
          return jsonEncode({
            'error': 'GitHub is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final result = await _github.getUserProfile();
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      default:
        return jsonEncode({'error': 'Unknown tool: $toolName'});
    }
  }
}
