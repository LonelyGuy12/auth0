import 'package:flutter/material.dart';
import '../models/service_connection.dart';
import '../services/auth_service.dart';
import '../services/token_vault_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenVaultService _tokenVault = TokenVaultService();
  final List<ServiceConnection> connections =
      ServiceConnection.getDefaultConnections();

  AuthProvider() {
    _checkAndRepairConnections();
  }

  Future<void> _checkAndRepairConnections() async {
    for (final conn in connections) {
      conn.isConnected = await _authService.isConnected(conn.type.name);
    }
    notifyListeners();

    // Auto-repair: re-fetch IdP tokens for connected services
    for (final conn in connections) {
      if (conn.isConnected) {
        await _tokenVault.repairConnection(conn.type.name);
      }
    }
  }

  Future<bool> connect(ServiceType type) async {
    final conn = connections.firstWhere((c) => c.type == type);
    conn.isConnecting = true;
    notifyListeners();

    try {
      final success = await _authService.connectService(type.name);
      conn.isConnected = success;
      return success;
    } catch (_) {
      conn.isConnected = false;
      return false;
    } finally {
      conn.isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect(ServiceType type) async {
    await _authService.disconnect(type.name);
    final conn = connections.firstWhere((c) => c.type == type);
    conn.isConnected = false;
    notifyListeners();
  }

  ServiceConnection getConnection(ServiceType type) {
    return connections.firstWhere((c) => c.type == type);
  }
}
