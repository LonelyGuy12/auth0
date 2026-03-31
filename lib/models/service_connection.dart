enum ServiceType { google, github, spotify }

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
        displayName: 'Google Calendar',
        emoji: '📅',
        description: 'Read & create calendar events',
      ),
      ServiceConnection(
        type: ServiceType.github,
        displayName: 'GitHub',
        emoji: '🐙',
        description: 'View repos, profile & activity',
      ),
      ServiceConnection(
        type: ServiceType.spotify,
        displayName: 'Spotify',
        emoji: '🎵',
        description: 'Control playback & view playlists',
      ),
    ];
  }
}
