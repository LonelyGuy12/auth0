import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class GitHubService {
  final TokenVaultService _tokenVault = TokenVaultService();

  Future<List<dynamic>> getRepositories({
    String sort = 'updated',
    int perPage = 10,
  }) async {
    final token = await _tokenVault.getAccessToken('github');
    if (token == null) {
      throw Exception('GitHub not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://api.github.com/user/repos?sort=$sort&per_page=$perPage',
    );

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
    });

    if (response.statusCode != 200) {
      throw Exception('GitHub API error (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _tokenVault.getAccessToken('github');
    if (token == null) {
      throw Exception('GitHub not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse('https://api.github.com/user');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
    });

    if (response.statusCode != 200) {
      throw Exception('GitHub API error (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
