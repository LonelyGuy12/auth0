import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class SlidesService {
  final TokenVaultService _tokenVault = TokenVaultService();

  static const String _base =
      'https://slides.googleapis.com/v1/presentations';
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

  /// Lists recent presentations from Drive
  Future<List<Map<String, dynamic>>> listPresentations(
      {int maxResults = 10}) async {
    final headers = await _headers();
    final url = Uri.parse(
      '$_driveBase?q=${Uri.encodeComponent("mimeType='application/vnd.google-apps.presentation'")}'
      '&orderBy=modifiedTime+desc&pageSize=$maxResults'
      '&fields=files(id,name,modifiedTime)',
    );
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Slides API error (${resp.statusCode}): ${resp.body}');
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

  /// Gets details of a presentation (title, slide count, slide titles)
  Future<Map<String, dynamic>> getPresentationInfo(
      String presentationId) async {
    final headers = await _headers();
    final resp = await http.get(
      Uri.parse('$_base/$presentationId?fields=presentationId,title,slides.objectId,slides.slideProperties'),
      headers: headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Slides API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final slides = data['slides'] as List<dynamic>? ?? [];
    return {
      'presentationId': data['presentationId'],
      'title': data['title'],
      'slideCount': slides.length,
    };
  }

  /// Reads the text content of a presentation's slides
  Future<Map<String, dynamic>> getPresentationContent(
      String presentationId) async {
    final headers = await _headers();
    final resp = await http.get(
      Uri.parse('$_base/$presentationId'),
      headers: headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Slides API error (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final slides = data['slides'] as List<dynamic>? ?? [];

    final slideTexts = <Map<String, dynamic>>[];
    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i] as Map<String, dynamic>;
      final elements = slide['pageElements'] as List<dynamic>? ?? [];
      final texts = <String>[];
      for (final el in elements) {
        final shape = (el as Map<String, dynamic>)['shape']
            as Map<String, dynamic>?;
        final textContent =
            shape?['text']?['textElements'] as List<dynamic>?;
        if (textContent != null) {
          for (final te in textContent) {
            final run =
                (te as Map<String, dynamic>)['textRun'] as Map<String, dynamic>?;
            final content = run?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              texts.add(content.trim());
            }
          }
        }
      }
      slideTexts.add({'slideNumber': i + 1, 'text': texts.join(' ')});
    }
    return {
      'presentationId': data['presentationId'],
      'title': data['title'],
      'slides': slideTexts,
    };
  }
}
