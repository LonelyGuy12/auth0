import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class TasksService {
  final TokenVaultService _tokenVault = TokenVaultService();

  static const String _base = 'https://tasks.googleapis.com/tasks/v1';

  Future<Map<String, String>> _headers() async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception('Google not connected. Please connect it in the sidebar.');
    }
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Future<List<Map<String, dynamic>>> getTaskLists() async {
    final headers = await _headers();
    final resp = await http.get(Uri.parse('$_base/users/@me/lists'), headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Tasks API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((i) {
      final item = i as Map<String, dynamic>;
      return {'id': item['id'], 'title': item['title'] ?? 'Untitled'};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTasks(String taskListId,
      {bool showCompleted = false}) async {
    final headers = await _headers();
    final url = Uri.parse(
      '$_base/lists/$taskListId/tasks'
      '?showCompleted=$showCompleted&showHidden=false',
    );
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Tasks API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((i) {
      final item = i as Map<String, dynamic>;
      return {
        'id': item['id'],
        'title': item['title'] ?? '(no title)',
        'status': item['status'] ?? 'needsAction',
        'due': item['due'],
        'notes': item['notes'],
        'updated': item['updated'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>> createTask(
      String taskListId, String title,
      {String? notes, String? due}) async {
    final headers = await _headers();
    final body = <String, dynamic>{'title': title};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (due != null && due.isNotEmpty) body['due'] = due;

    final resp = await http.post(
      Uri.parse('$_base/lists/$taskListId/tasks'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Tasks API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return {
      'success': true,
      'id': data['id'],
      'title': data['title'],
      'status': data['status'],
    };
  }

  Future<Map<String, dynamic>> completeTask(
      String taskListId, String taskId) async {
    final headers = await _headers();
    final resp = await http.patch(
      Uri.parse('$_base/lists/$taskListId/tasks/$taskId'),
      headers: headers,
      body: jsonEncode({'status': 'completed'}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Tasks API error (${resp.statusCode}): ${resp.body}');
    }
    return {'success': true, 'taskId': taskId, 'status': 'completed'};
  }
}
