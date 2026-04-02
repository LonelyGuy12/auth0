import 'dart:convert';
import 'package:flutter/foundation.dart';
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
          'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/gmail.send https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/contacts.readonly https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/tasks https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/presentations',
    },
    'github': {
      'connection': 'github',
      'scopes': 'repo user read:org',
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

    if (response.statusCode != 200) {
      debugPrint('[TokenVault] Management API token failed: ${response.statusCode} ${response.body}');
      return null;
    }
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

    if (response.statusCode != 200) {
      debugPrint('[TokenVault] Fetch user identities failed: ${response.statusCode} ${response.body}');
      return null;
    }

    final userData = jsonDecode(response.body) as Map<String, dynamic>;
    final identities = userData['identities'] as List<dynamic>?;
    debugPrint('[TokenVault] Identities found: ${identities?.length ?? 0}');
    if (identities == null) return null;

    final connection = config['connection'];
    for (final identity in identities) {
      final id = identity as Map<String, dynamic>;
      debugPrint('[TokenVault] Identity: connection=${id['connection']}, has_token=${id['access_token'] != null}');
      if (id['connection'] == connection && id['access_token'] != null) {
        return id['access_token'] as String;
      }
    }
    debugPrint('[TokenVault] No matching identity found for connection: $connection');
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

      // Use client_credentials to get a real Management API token
      // (the user's access_token lacks read:users permission)
      final userId = await _storage.read(key: '${service}_user_id');
      if (userId != null) {
        final ccToken = await getManagementApiToken();
        if (ccToken != null) {
          final idpToken = await fetchIdpToken(service, ccToken, userId);
          if (idpToken != null) {
            tokens['idp_access_token'] = idpToken;
            tokens['user_id'] = userId;
            await storeTokens(service, tokens);
            debugPrint('[TokenVault] Refreshed $service token successfully');
            return idpToken;
          }
        }
      }

      // Could not get IdP token — do NOT fall back to Auth0 mgmt token
      debugPrint('[TokenVault] Could not refresh IdP token for $service');
      return null;
    } catch (e) {
      debugPrint('[TokenVault] Refresh error for $service: $e');
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

  /// Repair an existing connection by re-fetching the IdP token.
  /// Uses the stored refresh token to get a fresh id_token with user_id,
  /// then fetches the real provider token from the Management API.
  Future<bool> repairConnection(String service) async {
    final refreshToken =
        await _storage.read(key: '${service}_refresh_token');
    if (refreshToken == null) {
      debugPrint('[Repair] No refresh token for $service');
      return false;
    }

    try {
      final domain = AppConstants.auth0Domain;

      // Step 1: Use refresh token to get a fresh id_token (contains user_id)
      final refreshUrl = Uri.parse('https://$domain/oauth/token');
      final refreshResp = await http.post(
        refreshUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'client_id': AppConstants.auth0ClientId,
          'client_secret': AppConstants.auth0ClientSecret,
          'refresh_token': refreshToken,
        }),
      );

      if (refreshResp.statusCode != 200) {
        debugPrint('[Repair] Refresh token exchange failed: ${refreshResp.statusCode}');
        return false;
      }

      final tokens = jsonDecode(refreshResp.body) as Map<String, dynamic>;
      final idToken = tokens['id_token'] as String?;
      String? userId = await _storage.read(key: '${service}_user_id');

      if (userId == null && idToken != null) {
        userId = decodeIdTokenSub(idToken);
        debugPrint('[Repair] Decoded userId from id_token: $userId');
      }

      if (userId == null) {
        debugPrint('[Repair] Could not determine userId for $service');
        return false;
      }

      // Step 2: Get Management API token via client_credentials
      final ccToken = await getManagementApiToken();
      if (ccToken == null) {
        debugPrint('[Repair] Could not get Management API token');
        return false;
      }

      // Step 3: Fetch the real IdP token
      final idpToken = await fetchIdpToken(service, ccToken, userId);
      if (idpToken == null) {
        debugPrint('[Repair] Could not fetch IdP token for $service');
        return false;
      }

      // Step 4: Store everything properly
      tokens['idp_access_token'] = idpToken;
      tokens['user_id'] = userId;
      await storeTokens(service, tokens);
      debugPrint('[Repair] Successfully repaired $service connection!');
      return true;
    } catch (e) {
      debugPrint('[Repair] Error repairing $service: $e');
      return false;
    }
  }
}
