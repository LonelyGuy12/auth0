enum ServiceType { google, github }

class ServiceConnection {
  final ServiceType type;
  final String displayName;
  final String emoji;
  final String description;
  bool isConnected;
  bool isConnecting;

  ServiceConnection({
    required this.type,
    required this.displayName,
    required this.emoji,
    required this.description,
    this.isConnected = false,
    this.isConnecting = false,
  });

  static List<ServiceConnection> getDefaultConnections() {
    return [
      ServiceConnection(
        type: ServiceType.google,
        displayName: 'Google Account',
        emoji: '🇬',
        description: 'Calendar, Gmail, Drive, Contacts, Docs & YouTube',
      ),
      ServiceConnection(
        type: ServiceType.github,
        displayName: 'GitHub',
        emoji: '🐙',
        description: 'View repos, profile & activity',
      ),
    ];
  }
}
