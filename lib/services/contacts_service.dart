import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class ContactsService {
  final TokenVaultService _tokenVault = TokenVaultService();

  Future<List<Map<String, dynamic>>> getContacts({int maxResults = 10}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://people.googleapis.com/v1/people/me/connections'
      '?personFields=names,emailAddresses,phoneNumbers'
      '&pageSize=$maxResults'
      '&sortOrder=LAST_MODIFIED_DESCENDING',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'Contacts API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final connections = data['connections'] as List<dynamic>? ?? [];

    return connections.map((c) {
      final contact = c as Map<String, dynamic>;
      final names = contact['names'] as List<dynamic>? ?? [];
      final emails = contact['emailAddresses'] as List<dynamic>? ?? [];
      final phones = contact['phoneNumbers'] as List<dynamic>? ?? [];

      return {
        'name': names.isNotEmpty
            ? (names[0] as Map<String, dynamic>)['displayName']
            : 'Unknown',
        'email': emails.isNotEmpty
            ? (emails[0] as Map<String, dynamic>)['value']
            : null,
        'phone': phones.isNotEmpty
            ? (phones[0] as Map<String, dynamic>)['value']
            : null,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> searchContacts(String query) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://people.googleapis.com/v1/people:searchContacts'
      '?query=${Uri.encodeComponent(query)}'
      '&readMask=names,emailAddresses,phoneNumbers',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'Contacts API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];

    final contacts = results.map((r) {
      final person =
          (r as Map<String, dynamic>)['person'] as Map<String, dynamic>? ?? {};
      final names = person['names'] as List<dynamic>? ?? [];
      final emails = person['emailAddresses'] as List<dynamic>? ?? [];
      final phones = person['phoneNumbers'] as List<dynamic>? ?? [];

      return {
        'name': names.isNotEmpty
            ? (names[0] as Map<String, dynamic>)['displayName']
            : 'Unknown',
        'email': emails.isNotEmpty
            ? (emails[0] as Map<String, dynamic>)['value']
            : null,
        'phone': phones.isNotEmpty
            ? (phones[0] as Map<String, dynamic>)['value']
            : null,
      };
    }).toList();

    return {
      'totalItems': contacts.length,
      'contacts': contacts,
    };
  }
}
