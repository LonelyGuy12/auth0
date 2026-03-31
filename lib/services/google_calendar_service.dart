import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class GoogleCalendarService {
  final TokenVaultService _tokenVault = TokenVaultService();

  Future<Map<String, dynamic>> getEvents({int maxResults = 5}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception('Google Calendar not connected. Please connect it in the sidebar.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final url = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events'
      '?maxResults=$maxResults'
      '&orderBy=startTime'
      '&singleEvents=true'
      '&timeMin=$now',
    );

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception('Google Calendar API error (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createEvent({
    required String summary,
    required String startTime,
    required String endTime,
    String? description,
  }) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception('Google Calendar not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events',
    );

    final body = <String, dynamic>{
      'summary': summary,
      'start': {'dateTime': startTime},
      'end': {'dateTime': endTime},
    };
    if (description != null) {
      body['description'] = description;
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create event (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
