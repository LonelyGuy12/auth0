import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class TokenVaultService {
  static final TokenVaultService _instance = TokenVaultService._internal();
  factory TokenVaultService() => _instance;
  TokenVaultService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final Map<String, Map<String, String>> _serviceConfigs = {
    'google': {
      'connection': 'google-oauth2',
      'scopes':
          'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/gmail.readonly',
    },
    'github': {
      'connection': 'github',
      'scopes': 'repo user read:org',
    },
    'spotify': {
      'connection': 'spotify',
      'scopes':
          'user-read-playback-state user-modify-playback-state playlist-read-private user-library-read',
    },
  };

  String getAuthorizationUrl(String service, {int port = 8080}) {
    final config = _serviceConfigs[service];
    if (config == null) throw Exception('Unknown service: $service');

    final domain = AppConstants.auth0Domain;
    final clientId = AppConstants.auth0ClientId;
    final redirectUri = Uri.encodeFull('http://localhost:$port/callback');

    return 'https://$domain/authorize'
        '?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&scope=${Uri.encodeComponent('openid profile email read:user_idp_tokens ${config['scopes']}')}'
        '&connection=${config['connection']}'
        '&audience=${Uri.encodeComponent('https://$domain/api/v2/')}'
        '&prompt=consent'
        '&access_type=offline';
  }

  /// Decode the `sub` claim from an Auth0 id_token JWT.
  String? decodeIdTokenSub(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Get a Management API token via client_credentials grant.
  Future<String?> getManagementApiToken() async {
    final domain = AppConstants.auth0Domain;
    final url = Uri.parse('https://$domain/oauth/token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'client_credentials',
        'client_id': AppConstants.auth0ClientId,
        'client_secret': AppConstants.auth0ClientSecret,
        'audience': 'https://$domain/api/v2/',
      }),
    );

    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['access_token'] as String?;
  }

  /// Fetch the identity provider's access token from Auth0 Management API.
  Future<String?> fetchIdpToken(
      String service, String managementToken, String userId) async {
    final domain = AppConstants.auth0Domain;
    final config = _serviceConfigs[service];
    if (config == null) return null;

    final url = Uri.parse(
      'https://$domain/api/v2/users/${Uri.encodeComponent(userId)}'
      '?fields=identities&include_fields=true',
    );

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $managementToken',
    });

    if (response.statusCode != 200) return null;

    final userData = jsonDecode(response.body) as Map<String, dynamic>;
    final identities = userData['identities'] as List<dynamic>?;
    if (identities == null) return null;

    final connection = config['connection'];
    for (final identity in identities) {
      final id = identity as Map<String, dynamic>;
      if (id['connection'] == connection && id['access_token'] != null) {
        return id['access_token'] as String;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> exchangeCodeForTokens(
      String code, String redirectUri) async {
    final domain = AppConstants.auth0Domain;
    final url = Uri.parse('https://$domain/oauth/token');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'authorization_code',
        'client_id': AppConstants.auth0ClientId,
        'client_secret': AppConstants.auth0ClientSecret,
        'code': code,
        'redirect_uri': redirectUri,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Token exchange failed (${response.statusCode}): ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> storeTokens(
      String service, Map<String, dynamic> tokens) async {
    // Prefer the IdP token (actual service token) over Auth0 Management API token
    final idpToken = tokens['idp_access_token'] as String?;
    final accessToken = idpToken ?? tokens['access_token'] as String?;
    final refreshToken = tokens['refresh_token'] as String?;
    final expiresIn = tokens['expires_in'] as int? ?? 3600;
    final userId = tokens['user_id'] as String?;

    final expiresAt =
        DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;

    if (accessToken != null) {
      await _storage.write(
          key: '${service}_access_token', value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(
          key: '${service}_refresh_token', value: refreshToken);
    }
    if (userId != null) {
      await _storage.write(key: '${service}_user_id', value: userId);
    }
    // Store Auth0 Management API token separately for refresh
    final mgmtToken = tokens['access_token'] as String?;
    if (mgmtToken != null && idpToken != null) {
      await _storage.write(
          key: '${service}_mgmt_token', value: mgmtToken);
    }
    await _storage.write(
        key: '${service}_expires_at', value: expiresAt.toString());
  }

  Future<String?> getAccessToken(String service) async {
    final accessToken =
        await _storage.read(key: '${service}_access_token');
    if (accessToken == null) return null;

    final expiresAtStr =
        await _storage.read(key: '${service}_expires_at');
    if (expiresAtStr != null) {
      final expiresAt = int.tryParse(expiresAtStr) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch >= expiresAt) {
        return await _refreshToken(service);
      }
    }

    return accessToken;
  }

  Future<String?> _refreshToken(String service) async {
    final refreshToken =
        await _storage.read(key: '${service}_refresh_token');
    if (refreshToken == null) return null;

    try {
      final domain = AppConstants.auth0Domain;
      final url = Uri.parse('https://$domain/oauth/token');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'client_id': AppConstants.auth0ClientId,
          'client_secret': AppConstants.auth0ClientSecret,
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode != 200) return null;

      final tokens = jsonDecode(response.body) as Map<String, dynamic>;

      // Try to fetch a fresh IdP token using the new Management API token
      final mgmtToken = tokens['access_token'] as String?;
      final userId = await _storage.read(key: '${service}_user_id');
      if (mgmtToken != null && userId != null) {
        final idpToken = await fetchIdpToken(service, mgmtToken, userId);
        if (idpToken != null) {
          tokens['idp_access_token'] = idpToken;
          tokens['user_id'] = userId;
        }
      }

      await storeTokens(service, tokens);
      return tokens['idp_access_token'] as String? ??
          tokens['access_token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isConnected(String service) async {
    final token = await getAccessToken(service);
    return token != null;
  }

  Future<void> disconnect(String service) async {
    await _storage.delete(key: '${service}_access_token');
    await _storage.delete(key: '${service}_refresh_token');
    await _storage.delete(key: '${service}_expires_at');
    await _storage.delete(key: '${service}_mgmt_token');
    await _storage.delete(key: '${service}_user_id');
  }

  Future<Map<String, dynamic>?> getTokenInfo(String service) async {
    final accessToken =
        await _storage.read(key: '${service}_access_token');
    final refreshToken =
        await _storage.read(key: '${service}_refresh_token');
    final expiresAtStr =
        await _storage.read(key: '${service}_expires_at');

    if (accessToken == null) return null;

    final expiresAt = int.tryParse(expiresAtStr ?? '') ?? 0;
    return {
      'has_access_token': true,
      'has_refresh_token': refreshToken != null,
      'expires_at': expiresAt,
      'is_expired': DateTime.now().millisecondsSinceEpoch >= expiresAt,
    };
  }
}
