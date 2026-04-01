import 'dart:convert';
import '../config/constants.dart';
import 'openrouter_service.dart';
import 'google_calendar_service.dart';
import 'github_service.dart';
import 'gmail_service.dart';
import 'youtube_service.dart';
import 'contacts_service.dart';
import 'drive_service.dart';
import 'tasks_service.dart';
import 'sheets_service.dart';
import 'slides_service.dart';
import 'token_vault_service.dart';

class AiAgentService {
  OpenRouterService _openRouter;
  final GoogleCalendarService _calendar = GoogleCalendarService();
  final GitHubService _github = GitHubService();
  final GmailService _gmail = GmailService();
  final YouTubeService _youtube = YouTubeService();
  final ContactsService _contacts = ContactsService();
  final DriveService _drive = DriveService();
  final TasksService _tasks = TasksService();
  final SheetsService _sheets = SheetsService();
  final SlidesService _slides = SlidesService();
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

      case 'get_emails':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 5;
          final result = await _gmail.getMessages(maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'search_emails':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final query = args['query'] as String? ?? '';
          final maxResults = args['maxResults'] as int? ?? 5;
          final result =
              await _gmail.searchMessages(query, maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'send_email':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final to = args['to'] as String? ?? '';
          final subject = args['subject'] as String? ?? '';
          final body = args['body'] as String? ?? '';
          if (to.isEmpty) return jsonEncode({'error': 'Recipient (to) is required.'});
          final result = await _gmail.sendEmail(to, subject, body);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_youtube_channel':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final result = await _youtube.getMyChannel();
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_youtube_videos':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 5;
          final result = await _youtube.getMyVideos(maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'search_youtube':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final query = args['query'] as String? ?? '';
          final maxResults = args['maxResults'] as int? ?? 5;
          final result =
              await _youtube.searchYouTube(query, maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_contacts':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 10;
          final result = await _contacts.getContacts(maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'search_contacts':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final query = args['query'] as String? ?? '';
          final result = await _contacts.searchContacts(query);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'list_drive_files':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 10;
          final result = await _drive.listFiles(maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'search_drive':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final query = args['query'] as String? ?? '';
          final maxResults = args['maxResults'] as int? ?? 10;
          final result = await _drive.searchFiles(query, maxResults: maxResults);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_drive_storage':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({
            'error': 'Google is not connected. Please ask the user to connect it in the sidebar.',
          });
        }
        try {
          final result = await _drive.getStorageQuota();
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_task_lists':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final result = await _tasks.getTaskLists();
          return jsonEncode({'taskLists': result});
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_tasks':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final taskListId = args['taskListId'] as String? ?? '@default';
          final showCompleted = args['showCompleted'] as bool? ?? false;
          final result = await _tasks.getTasks(taskListId, showCompleted: showCompleted);
          return jsonEncode({'tasks': result});
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'create_task':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final taskListId = args['taskListId'] as String? ?? '@default';
          final title = args['title'] as String? ?? '';
          final notes = args['notes'] as String?;
          final due = args['due'] as String?;
          if (title.isEmpty) return jsonEncode({'error': 'title is required.'});
          final result = await _tasks.createTask(taskListId, title, notes: notes, due: due);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'complete_task':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final taskListId = args['taskListId'] as String? ?? '@default';
          final taskId = args['taskId'] as String? ?? '';
          if (taskId.isEmpty) return jsonEncode({'error': 'taskId is required.'});
          final result = await _tasks.completeTask(taskListId, taskId);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'list_spreadsheets':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 10;
          final result = await _sheets.listSpreadsheets(maxResults: maxResults);
          return jsonEncode({'spreadsheets': result});
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_spreadsheet_info':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final id = args['spreadsheetId'] as String? ?? '';
          if (id.isEmpty) return jsonEncode({'error': 'spreadsheetId is required.'});
          final result = await _sheets.getSpreadsheetInfo(id);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'read_sheet_range':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final id = args['spreadsheetId'] as String? ?? '';
          final range = args['range'] as String? ?? '';
          if (id.isEmpty || range.isEmpty) return jsonEncode({'error': 'spreadsheetId and range are required.'});
          final result = await _sheets.readRange(id, range);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'append_sheet_rows':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final id = args['spreadsheetId'] as String? ?? '';
          final range = args['range'] as String? ?? '';
          final rawValues = args['values'] as List<dynamic>? ?? [];
          final values = rawValues.map((row) => row as List<dynamic>).toList();
          if (id.isEmpty) return jsonEncode({'error': 'spreadsheetId is required.'});
          final result = await _sheets.appendRows(id, range, values);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'list_presentations':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final maxResults = args['maxResults'] as int? ?? 10;
          final result = await _slides.listPresentations(maxResults: maxResults);
          return jsonEncode({'presentations': result});
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_presentation_info':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final id = args['presentationId'] as String? ?? '';
          if (id.isEmpty) return jsonEncode({'error': 'presentationId is required.'});
          final result = await _slides.getPresentationInfo(id);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      case 'get_presentation_content':
        if (!await _tokenVault.isConnected('google')) {
          return jsonEncode({'error': 'Google is not connected. Please ask the user to connect it in the sidebar.'});
        }
        try {
          final id = args['presentationId'] as String? ?? '';
          if (id.isEmpty) return jsonEncode({'error': 'presentationId is required.'});
          final result = await _slides.getPresentationContent(id);
          return jsonEncode(result);
        } catch (e) {
          return jsonEncode({'error': e.toString()});
        }

      default:
        return jsonEncode({'error': 'Unknown tool: $toolName'});
    }
  }
}
