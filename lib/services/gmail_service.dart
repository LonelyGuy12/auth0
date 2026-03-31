import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class GmailService {
  final TokenVaultService _tokenVault = TokenVaultService();

  Future<List<Map<String, dynamic>>> getMessages({int maxResults = 5}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final listUrl = Uri.parse(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages'
      '?maxResults=$maxResults',
    );

    final listResp = await http.get(listUrl, headers: {
      'Authorization': 'Bearer $token',
    });

    if (listResp.statusCode != 200) {
      throw Exception(
          'Gmail API error (${listResp.statusCode}): ${listResp.body}');
    }

    final listData = jsonDecode(listResp.body) as Map<String, dynamic>;
    final messages = listData['messages'] as List<dynamic>? ?? [];

    final results = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final id = msg['id'] as String;
      final detail = await _getMessageDetail(token, id);
      if (detail != null) results.add(detail);
    }
    return results;
  }

  Future<Map<String, dynamic>?> _getMessageDetail(
      String token, String messageId) async {
    final url = Uri.parse(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId'
      '?format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final headers = (data['payload']?['headers'] as List<dynamic>?) ?? [];

    String? from, subject, date;
    for (final h in headers) {
      final header = h as Map<String, dynamic>;
      final name = (header['name'] as String).toLowerCase();
      if (name == 'from') from = header['value'] as String?;
      if (name == 'subject') subject = header['value'] as String?;
      if (name == 'date') date = header['value'] as String?;
    }

    return {
      'id': messageId,
      'from': from ?? 'Unknown',
      'subject': subject ?? '(no subject)',
      'date': date ?? '',
      'snippet': data['snippet'] ?? '',
    };
  }

  Future<Map<String, dynamic>> searchMessages(String query,
      {int maxResults = 5}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages'
      '?q=${Uri.encodeComponent(query)}&maxResults=$maxResults',
    );

    final listResp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (listResp.statusCode != 200) {
      throw Exception(
          'Gmail API error (${listResp.statusCode}): ${listResp.body}');
    }

    final listData = jsonDecode(listResp.body) as Map<String, dynamic>;
    final messages = listData['messages'] as List<dynamic>? ?? [];

    final results = <Map<String, dynamic>>[];
    for (final msg in messages) {
      final id = msg['id'] as String;
      final detail = await _getMessageDetail(token, id);
      if (detail != null) results.add(detail);
    }

    return {
      'resultSizeEstimate': listData['resultSizeEstimate'] ?? 0,
      'messages': results,
    };
  }

  Future<Map<String, dynamic>> sendEmail(
      String to, String subject, String body) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    // Build RFC 2822 message
    final emailLines = [
      'To: $to',
      'Subject: $subject',
      'Content-Type: text/plain; charset=utf-8',
      '',
      body,
    ];
    final rawEmail = emailLines.join('\r\n');
    final encoded = base64Url.encode(utf8.encode(rawEmail));

    final url = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/send');
    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'raw': encoded}),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
          'Gmail send error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return {
      'success': true,
      'messageId': data['id'] ?? '',
      'to': to,
      'subject': subject,
    };
  }
}
