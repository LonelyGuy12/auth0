import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class DriveService {
  final TokenVaultService _tokenVault = TokenVaultService();

  Future<List<Map<String, dynamic>>> listFiles({
    int maxResults = 10,
    String? folderId,
  }) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final query = folderId != null
        ? "'$folderId' in parents"
        : "'root' in parents and trashed=false";

    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?q=${Uri.encodeComponent(query)}'
      '&fields=files(id,name,mimeType,size,modifiedTime,webViewLink)'
      '&pageSize=$maxResults'
      '&orderBy=modifiedTime desc',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'Drive API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];

    return files.map((f) {
      final file = f as Map<String, dynamic>;
      return {
        'id': file['id'],
        'name': file['name'],
        'type': _simplifyMimeType(file['mimeType'] as String? ?? ''),
        'size': file['size'],
        'modifiedTime': file['modifiedTime'],
        'url': file['webViewLink'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>> searchFiles(String query,
      {int maxResults = 10}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final driveQuery = "name contains '${query.replaceAll("'", "\\'")}' and trashed=false";

    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/files'
      '?q=${Uri.encodeComponent(driveQuery)}'
      '&fields=files(id,name,mimeType,size,modifiedTime,webViewLink)'
      '&pageSize=$maxResults'
      '&orderBy=modifiedTime desc',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'Drive API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];

    final results = files.map((f) {
      final file = f as Map<String, dynamic>;
      return {
        'id': file['id'],
        'name': file['name'],
        'type': _simplifyMimeType(file['mimeType'] as String? ?? ''),
        'size': file['size'],
        'modifiedTime': file['modifiedTime'],
        'url': file['webViewLink'],
      };
    }).toList();

    return {
      'totalResults': results.length,
      'files': results,
    };
  }

  Future<Map<String, dynamic>> getStorageQuota() async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://www.googleapis.com/drive/v3/about?fields=storageQuota',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'Drive API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final quota = data['storageQuota'] as Map<String, dynamic>? ?? {};

    int? toMB(String? val) {
      if (val == null) return null;
      final bytes = int.tryParse(val);
      return bytes != null ? (bytes / 1024 / 1024).round() : null;
    }

    return {
      'usedMB': toMB(quota['usage'] as String?),
      'limitMB': toMB(quota['limit'] as String?),
      'usedInDriveMB': toMB(quota['usageInDrive'] as String?),
      'usedInTrashMB': toMB(quota['usageInDriveTrash'] as String?),
    };
  }

  String _simplifyMimeType(String mimeType) {
    const map = {
      'application/vnd.google-apps.folder': 'Folder',
      'application/vnd.google-apps.document': 'Google Doc',
      'application/vnd.google-apps.spreadsheet': 'Google Sheet',
      'application/vnd.google-apps.presentation': 'Google Slides',
      'application/vnd.google-apps.form': 'Google Form',
      'application/pdf': 'PDF',
      'image/jpeg': 'Image',
      'image/png': 'Image',
      'video/mp4': 'Video',
      'text/plain': 'Text',
    };
    return map[mimeType] ?? mimeType.split('/').last;
  }
}
