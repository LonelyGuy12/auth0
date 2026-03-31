import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'token_vault_service.dart';

class AuthService {
  final TokenVaultService _tokenVault = TokenVaultService();

  HttpServer? _callbackServer;

  Future<bool> connectService(String service) async {
    final completer = Completer<String?>();

    try {
      // Use a fixed port so the callback URL is predictable for Auth0
      const fixedPort = 8080;
      try {
        _callbackServer = await HttpServer.bind('localhost', fixedPort);
      } catch (_) {
        // If 8080 is taken, try 8081
        _callbackServer = await HttpServer.bind('localhost', 8081);
      }
      final port = _callbackServer!.port;

      _callbackServer!.listen((request) {
        if (request.uri.path == '/callback') {
          final code = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];

          if (error != null) {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write('''
<!DOCTYPE html>
<html>
<body style="background:#0F0F23;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;font-family:sans-serif;">
<div style="text-align:center;color:#FF5252;">
<h1>❌ Connection Failed</h1>
<p>$error</p>
<p style="color:#888;">You can close this window.</p>
</div>
</body>
</html>
''');
            request.response.close();
            if (!completer.isCompleted) completer.complete(null);
          } else if (code != null) {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.html
              ..write('''
<!DOCTYPE html>
<html>
<body style="background:#0F0F23;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;font-family:sans-serif;">
<div style="text-align:center;color:#00C853;">
<h1>✅ Connected!</h1>
<p style="color:#E0E0E0;">You can close this window and return to the app.</p>
</div>
</body>
</html>
''');
            request.response.close();
            if (!completer.isCompleted) completer.complete(code);
          }
        }
      });

      final authUrl = _tokenVault.getAuthorizationUrl(service, port: port);
      final uri = Uri.parse(authUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open browser');
      }

      final code = await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () => null,
      );

      if (code == null) return false;

      final redirectUri = 'http://localhost:$port/callback';
      final tokens =
          await _tokenVault.exchangeCodeForTokens(code, redirectUri);

      // Fetch the actual identity provider token from Auth0 Management API
      final idToken = tokens['id_token'] as String?;
      if (idToken != null) {
        final userId = _tokenVault.decodeIdTokenSub(idToken);
        if (userId != null) {
          tokens['user_id'] = userId;
          // The access_token is a Management API token (audience was /api/v2/)
          // Use it to fetch the real identity provider access token
          String? idpToken;
          final mgmtToken = tokens['access_token'] as String?;
          if (mgmtToken != null) {
            idpToken =
                await _tokenVault.fetchIdpToken(service, mgmtToken, userId);
          }
          // Fallback: try client_credentials grant for Management API
          if (idpToken == null) {
            final ccToken = await _tokenVault.getManagementApiToken();
            if (ccToken != null) {
              idpToken =
                  await _tokenVault.fetchIdpToken(service, ccToken, userId);
            }
          }
          if (idpToken != null) {
            tokens['idp_access_token'] = idpToken;
          }
        }
      }

      await _tokenVault.storeTokens(service, tokens);

      return true;
    } catch (e) {
      return false;
    } finally {
      await _callbackServer?.close(force: true);
      _callbackServer = null;
    }
  }

  Future<bool> isConnected(String service) => _tokenVault.isConnected(service);

  Future<void> disconnect(String service) => _tokenVault.disconnect(service);
}
