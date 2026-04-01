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
    {
      'type': 'function',
      'function': {
        'name': 'get_emails',
        'description': "Gets the user's latest Gmail emails",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of emails to return (default 5)',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_emails',
        'description': 'Searches Gmail for emails matching a query (uses Gmail search syntax)',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Gmail search query (e.g. "from:john", "subject:invoice", "is:unread")',
            },
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of results (default 5)',
            },
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'send_email',
        'description': 'Sends an email via Gmail on behalf of the user',
        'parameters': {
          'type': 'object',
          'properties': {
            'to': {
              'type': 'string',
              'description': 'Recipient email address',
            },
            'subject': {
              'type': 'string',
              'description': 'Email subject line',
            },
            'body': {
              'type': 'string',
              'description': 'Plain text body of the email',
            },
          },
          'required': ['to', 'subject', 'body'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_youtube_channel',
        'description': "Gets the user's YouTube channel info and statistics",
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_youtube_videos',
        'description': "Gets the user's uploaded YouTube videos",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of videos to return (default 5)',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_youtube',
        'description': 'Searches YouTube for videos matching a query',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Search query for YouTube videos',
            },
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of results (default 5)',
            },
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_contacts',
        'description': "Gets the user's Google contacts",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of contacts to return (default 10)',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_contacts',
        'description': 'Searches Google contacts by name or email',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Name or email to search for',
            },
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_drive_files',
        'description': "Lists files in the user's Google Drive",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of files to return (default 10)',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'search_drive',
        'description': 'Searches Google Drive for files by name',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'File name or keyword to search for',
            },
            'maxResults': {
              'type': 'integer',
              'description': 'Maximum number of results (default 10)',
            },
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_drive_storage',
        'description': "Gets the user's Google Drive storage quota usage",
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_task_lists',
        'description': "Gets the user's Google Tasks lists",
        'parameters': {'type': 'object', 'properties': {}, 'required': []},
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_tasks',
        'description': 'Gets tasks from a Google Tasks list',
        'parameters': {
          'type': 'object',
          'properties': {
            'taskListId': {
              'type': 'string',
              'description': 'Task list ID (use "@default" for the default list)',
            },
            'showCompleted': {
              'type': 'boolean',
              'description': 'Whether to include completed tasks (default false)',
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'create_task',
        'description': 'Creates a new task in Google Tasks',
        'parameters': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string', 'description': 'Task title'},
            'taskListId': {
              'type': 'string',
              'description': 'Task list ID (use "@default" for the default list)',
            },
            'notes': {'type': 'string', 'description': 'Optional task notes/description'},
            'due': {
              'type': 'string',
              'description': 'Optional due date in RFC 3339 format (e.g. 2026-04-10T00:00:00.000Z)',
            },
          },
          'required': ['title'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'complete_task',
        'description': 'Marks a Google Task as completed',
        'parameters': {
          'type': 'object',
          'properties': {
            'taskId': {'type': 'string', 'description': 'The task ID to mark complete'},
            'taskListId': {
              'type': 'string',
              'description': 'Task list ID (use "@default" for the default list)',
            },
          },
          'required': ['taskId'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_spreadsheets',
        'description': "Lists the user's recent Google Sheets spreadsheets",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {'type': 'integer', 'description': 'Max number to return (default 10)'},
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_spreadsheet_info',
        'description': 'Gets the sheet names and metadata of a Google Sheets spreadsheet',
        'parameters': {
          'type': 'object',
          'properties': {
            'spreadsheetId': {'type': 'string', 'description': 'The spreadsheet ID'},
          },
          'required': ['spreadsheetId'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'read_sheet_range',
        'description': 'Reads cell values from a range in a Google Sheet (e.g. Sheet1!A1:D10)',
        'parameters': {
          'type': 'object',
          'properties': {
            'spreadsheetId': {'type': 'string', 'description': 'The spreadsheet ID'},
            'range': {'type': 'string', 'description': 'A1 notation range (e.g. "Sheet1!A1:D10")'},
          },
          'required': ['spreadsheetId', 'range'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'append_sheet_rows',
        'description': 'Appends rows of data to a Google Sheet',
        'parameters': {
          'type': 'object',
          'properties': {
            'spreadsheetId': {'type': 'string', 'description': 'The spreadsheet ID'},
            'range': {'type': 'string', 'description': 'Sheet name or range to append to (e.g. "Sheet1")'},
            'values': {
              'type': 'array',
              'description': 'Array of rows to append, each row is an array of cell values',
              'items': {'type': 'array', 'items': {}},
            },
          },
          'required': ['spreadsheetId', 'values'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_presentations',
        'description': "Lists the user's recent Google Slides presentations",
        'parameters': {
          'type': 'object',
          'properties': {
            'maxResults': {'type': 'integer', 'description': 'Max number to return (default 10)'},
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_presentation_info',
        'description': 'Gets title and slide count of a Google Slides presentation',
        'parameters': {
          'type': 'object',
          'properties': {
            'presentationId': {'type': 'string', 'description': 'The presentation ID'},
          },
          'required': ['presentationId'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_presentation_content',
        'description': 'Reads the text content of all slides in a Google Slides presentation',
        'parameters': {
          'type': 'object',
          'properties': {
            'presentationId': {'type': 'string', 'description': 'The presentation ID'},
          },
          'required': ['presentationId'],
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
- Gmail: Read, search, and send emails
- YouTube: View channel info, your videos, and search YouTube
- Google Contacts: View and search contacts
- Google Drive: List, search files and check storage
- Google Tasks: View task lists, view/create/complete tasks
- Google Sheets: List, read, and append data to spreadsheets
- Google Slides: List presentations and read their content

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
