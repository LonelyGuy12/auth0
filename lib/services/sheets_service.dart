import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class SheetsService {
  final TokenVaultService _tokenVault = TokenVaultService();

  static const String _base = 'https://sheets.googleapis.com/v4/spreadsheets';
  static const String _driveBase =
      'https://www.googleapis.com/drive/v3/files';

  Future<Map<String, String>> _headers() async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Lists recent spreadsheets from Drive
  Future<List<Map<String, dynamic>>> listSpreadsheets(
      {int maxResults = 10}) async {
    final headers = await _headers();
    final url = Uri.parse(
      '$_driveBase?q=${Uri.encodeComponent("mimeType='application/vnd.google-apps.spreadsheet'")}'
      '&orderBy=modifiedTime+desc&pageSize=$maxResults'
      '&fields=files(id,name,modifiedTime)',
    );
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Sheets API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];
    return files.map((f) {
      final file = f as Map<String, dynamic>;
      return {
        'id': file['id'],
        'name': file['name'],
        'modifiedTime': file['modifiedTime'],
      };
    }).toList();
  }

  /// Gets the sheet names and basic info of a spreadsheet
  Future<Map<String, dynamic>> getSpreadsheetInfo(
      String spreadsheetId) async {
    final headers = await _headers();
    final resp = await http.get(
      Uri.parse('$_base/$spreadsheetId?fields=spreadsheetId,properties,sheets.properties'),
      headers: headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Sheets API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final sheets = (data['sheets'] as List<dynamic>? ?? []).map((s) {
      final props = (s as Map<String, dynamic>)['properties'] as Map<String, dynamic>;
      return {'title': props['title'], 'sheetId': props['sheetId']};
    }).toList();
    return {
      'spreadsheetId': data['spreadsheetId'],
      'title': (data['properties'] as Map<String, dynamic>?)?['title'],
      'sheets': sheets,
    };
  }

  /// Reads values from a range (e.g. "Sheet1!A1:D10")
  Future<Map<String, dynamic>> readRange(
      String spreadsheetId, String range) async {
    final headers = await _headers();
    final url = Uri.parse(
        '$_base/$spreadsheetId/values/${Uri.encodeComponent(range)}');
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Sheets API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return {
      'range': data['range'],
      'values': data['values'] ?? [],
    };
  }

  /// Appends rows to a sheet
  Future<Map<String, dynamic>> appendRows(
      String spreadsheetId, String range, List<List<dynamic>> values) async {
    final headers = await _headers();
    final url = Uri.parse(
      '$_base/$spreadsheetId/values/${Uri.encodeComponent(range)}:append'
      '?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS',
    );
    final resp = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'values': values}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Sheets API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final updates = data['updates'] as Map<String, dynamic>? ?? {};
    return {
      'success': true,
      'updatedRange': updates['updatedRange'],
      'updatedRows': updates['updatedRows'],
    };
  }
}
