import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;
  final String model;

  OpenRouterService({required this.apiKey, required this.model});

  static const List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'get_calendar_events',
        'description': "Gets the user's upcoming Google Calendar events",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of events to return (default 5)',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_calendar_event',
        'description': 'Creates a new Google Calendar event',
        'parameters': {
          'type': 'object',
          'properties': {
            'summary': {
              'type': 'string',
              'description': 'Title of the event',
            },
            'startTime': {
              'type': 'string',
              'description': 'Start time in ISO 8601 format',
            },
            'endTime': {
              'type': 'string',
              'description': 'End time in ISO 8601 format',
            },
            'description': {
              'type': 'string',
              'description': 'Optional description of the event',
            },
          },
          'required': ['summary', 'startTime', 'endTime'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_github_repos',
        'description': "Gets the user's GitHub repositories",
        'parameters': {
          'type': 'object',
          'properties': {
            'sort': {
              'type': 'string',
              'enum': ['updated', 'created', 'pushed'],
              'description': 'Sort order for repositories',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_github_profile',
        'description': "Gets the user's GitHub profile information",
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
  ];

  Future<Map<String, dynamic>> _callApi(
    List<Map<String, dynamic>> messages, {
    bool includeTools = true,
  }) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
    };

    if (includeTools) {
      body['tools'] = _tools;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/LonelyGuy12/auth0',
        'X-Title': 'AI Agent Desktop',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'OpenRouter API error (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String> chat(
    String userMessage, {
    required Future<String> Function(String toolName, Map<String, dynamic> args)
        onToolCall,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    final now = DateTime.now().toIso8601String();
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '''You are an AI assistant called "AI Agent Desktop", powered by Auth0 Token Vault for secure OAuth token management.

Current date and time: $now

You can help users with:
- Google Calendar: View and create calendar events
- GitHub: View repositories and profile information

When using tools, be concise and format results nicely using markdown.
If a service is not connected, tell the user to connect it in the sidebar.
Be helpful, concise, and use markdown formatting for readability.''',
      },
      if (conversationHistory != null) ...conversationHistory,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _callApi(messages);
      final choice = (response['choices'] as List?)?.firstOrNull;
      if (choice == null) return 'No response from the AI model.';

      final message = choice['message'] as Map<String, dynamic>?;
      if (message == null) return 'No response from the AI model.';

      final toolCalls = message['tool_calls'] as List?;

      if (toolCalls != null && toolCalls.isNotEmpty) {
        messages.add(message);

        for (final toolCall in toolCalls) {
          final function = toolCall['function'] as Map<String, dynamic>;
          final toolName = function['name'] as String;
          final argsStr = function['arguments'] as String? ?? '{}';

          Map<String, dynamic> args;
          try {
            args = jsonDecode(argsStr) as Map<String, dynamic>;
          } catch (_) {
            args = {};
          }

          final result = await onToolCall(toolName, args);

          messages.add({
            'role': 'tool',
            'tool_call_id': toolCall['id'] as String? ?? '',
            'content': result,
          });
        }

        final finalResponse = await _callApi(messages, includeTools: false);
        final finalChoice =
            (finalResponse['choices'] as List?)?.firstOrNull;
        final finalContent = finalChoice?['message']?['content'] as String?;
        return finalContent ?? 'I processed the request but have no summary.';
      }

      return message['content'] as String? ??
          'I received an empty response. Please try again.';
    } catch (e) {
      if (e.toString().contains('tool') || e.toString().contains('function')) {
        return '⚠️ This model may not support tool calling. Try switching to **Llama 3.1 8B** or **GPT-4o Mini** from the model selector.';
      }
      rethrow;
    }
  }
}
