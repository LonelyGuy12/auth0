import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_vault_service.dart';

class YouTubeService {
  final TokenVaultService _tokenVault = TokenVaultService();

  Future<Map<String, dynamic>> getMyChannel() async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels'
      '?part=snippet,statistics&mine=true',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'YouTube API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return {'error': 'No YouTube channel found'};

    final channel = items[0] as Map<String, dynamic>;
    final snippet = channel['snippet'] as Map<String, dynamic>? ?? {};
    final stats = channel['statistics'] as Map<String, dynamic>? ?? {};

    return {
      'title': snippet['title'],
      'description': snippet['description'],
      'subscriberCount': stats['subscriberCount'],
      'videoCount': stats['videoCount'],
      'viewCount': stats['viewCount'],
    };
  }

  Future<List<Map<String, dynamic>>> getMyVideos({int maxResults = 5}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    // First get the uploads playlist ID
    final channelUrl = Uri.parse(
      'https://www.googleapis.com/youtube/v3/channels'
      '?part=contentDetails&mine=true',
    );

    final channelResp = await http.get(channelUrl, headers: {
      'Authorization': 'Bearer $token',
    });

    if (channelResp.statusCode != 200) {
      throw Exception(
          'YouTube API error (${channelResp.statusCode}): ${channelResp.body}');
    }

    final channelData = jsonDecode(channelResp.body) as Map<String, dynamic>;
    final items = channelData['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return [];

    final uploadsPlaylistId = items[0]['contentDetails']?['relatedPlaylists']
        ?['uploads'] as String?;
    if (uploadsPlaylistId == null) return [];

    // Get videos from uploads playlist
    final videosUrl = Uri.parse(
      'https://www.googleapis.com/youtube/v3/playlistItems'
      '?part=snippet&playlistId=$uploadsPlaylistId&maxResults=$maxResults',
    );

    final videosResp = await http.get(videosUrl, headers: {
      'Authorization': 'Bearer $token',
    });

    if (videosResp.statusCode != 200) {
      throw Exception(
          'YouTube API error (${videosResp.statusCode}): ${videosResp.body}');
    }

    final videosData = jsonDecode(videosResp.body) as Map<String, dynamic>;
    final videoItems = videosData['items'] as List<dynamic>? ?? [];

    return videoItems.map((item) {
      final snippet =
          (item as Map<String, dynamic>)['snippet'] as Map<String, dynamic>? ??
              {};
      return {
        'title': snippet['title'],
        'description': (snippet['description'] as String? ?? '').length > 150
            ? '${(snippet['description'] as String).substring(0, 150)}...'
            : snippet['description'],
        'publishedAt': snippet['publishedAt'],
        'videoId': snippet['resourceId']?['videoId'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>> searchYouTube(String query,
      {int maxResults = 5}) async {
    final token = await _tokenVault.getAccessToken('google');
    if (token == null) {
      throw Exception(
          'Google not connected. Please connect it in the sidebar.');
    }

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&q=${Uri.encodeComponent(query)}'
      '&type=video&maxResults=$maxResults',
    );

    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception(
          'YouTube API error (${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    final results = items.map((item) {
      final snippet =
          (item as Map<String, dynamic>)['snippet'] as Map<String, dynamic>? ??
              {};
      final videoId = item['id']?['videoId'] as String?;
      return {
        'title': snippet['title'],
        'channelTitle': snippet['channelTitle'],
        'publishedAt': snippet['publishedAt'],
        'description': (snippet['description'] as String? ?? '').length > 150
            ? '${(snippet['description'] as String).substring(0, 150)}...'
            : snippet['description'],
        'videoId': videoId,
        'url': videoId != null ? 'https://youtube.com/watch?v=$videoId' : null,
      };
    }).toList();

    return {
      'totalResults': data['pageInfo']?['totalResults'] ?? 0,
      'results': results,
    };
  }
}
