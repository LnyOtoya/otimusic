import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class AirsonicService {
  final String ipPort;
  final String username;
  final String password;
  final http.Client _client;

  AirsonicService({
    required this.ipPort,
    required this.username,
    required this.password,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 测试服务器连接
  Future<void> testConnection() async {
    try {
      String baseUrl = _getBaseUrl();
      Uri url = Uri.parse('$baseUrl/rest/ping.view').replace(queryParameters: {
        'u': username,
        'p': password,
        'v': '1.15.0',
        'c': 'otimusic',
      });

      final response = await _client.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        throw Exception('无法连接到服务器，状态码: ${response.statusCode}');
      }

      final document = XmlDocument.parse(response.body);
      final root = document.rootElement;
      
      if (root.getAttribute('status') != 'ok') {
        final error = root.findElements('error').firstOrNull;
        throw Exception('服务器连接失败: ${error?.getAttribute('message') ?? '未知错误'}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('连接超时，请检查服务器地址和网络');
      }
      rethrow;
    }
  }

  /// 获取随机歌曲
  Future<List<XmlElement>> getRandomSongs({required int count}) async {
    String baseUrl = _getBaseUrl();
    Uri url = Uri.parse('$baseUrl/rest/getRandomSongs.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'v': '1.15.0',
      'c': 'otimusic',
      'size': count.toString(),
    });

    return await _fetchXmlData(url, 'randomSongs', 'song');
  }

  /// 获取最近添加的专辑
  Future<List<XmlElement>> getRecentAlbums({required int count}) async {
    String baseUrl = _getBaseUrl();
    Uri url = Uri.parse('$baseUrl/rest/getAlbumList.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'v': '1.15.0',
      'c': 'otimusic',
      'type': 'recent',
      'size': count.toString(),
    });

    return await _fetchXmlData(url, 'albumList', 'album');
  }

  /// 获取热门播放歌曲 - 修复缺少artist参数问题
  Future<List<XmlElement>> getTopPlayedSongs({
    required int count,
    required String period,
  }) async {
    String baseUrl = _getBaseUrl();
    // 根据错误信息，服务器需要artist参数，即使它是空的
    Uri url = Uri.parse('$baseUrl/rest/getTopSongs.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'v': '1.15.0',
      'c': 'otimusic',
      'count': count.toString(),
      'period': period,
      'artist': '', // 添加空的artist参数以满足服务器要求
    });

    return await _fetchXmlData(url, 'topSongs', 'song');
  }

  /// 获取最近添加的歌曲（当热门歌曲无数据时使用）
  Future<List<XmlElement>> getRecentAddedSongs({
    required int count,
    required List<XmlElement> recentAlbums,
  }) async {
    String baseUrl = _getBaseUrl();
    List<XmlElement> songs = [];

    for (var album in recentAlbums) {
      String albumId = album.getAttribute('id') ?? '';
      if (albumId.isEmpty) {
        print('[警告] 发现无ID的专辑，已跳过');
        continue;
      }

      try {
        // 获取专辑内的歌曲
        Uri songUrl = Uri.parse('$baseUrl/rest/getAlbum.view').replace(queryParameters: {
          'u': username,
          'p': password,
          'v': '1.15.0',
          'c': 'otimusic',
          'id': albumId,
        });

        List<XmlElement> albumSongs = await _fetchXmlData(songUrl, 'album', 'song');
        if (albumSongs.isNotEmpty) {
          songs.add(albumSongs.first);
          print('[调试] 从专辑ID $albumId 获取到歌曲：${albumSongs.first.getAttribute('title')}');
          if (songs.length >= count) break;
        } else {
          print('[警告] 专辑ID $albumId 中无歌曲数据');
        }
      } catch (e) {
        print('[警告] 处理专辑ID $albumId 时出错：$e，已跳过该专辑');
        continue;
      }
    }

    return songs;
  }

  /// 获取封面图片URL
  String getCoverArtUrl(String coverArtId) {
    if (coverArtId.isEmpty || coverArtId == 'null') {
      return '';
    }
    
    String baseUrl = _getBaseUrl();
    return Uri.parse('$baseUrl/rest/getCoverArt.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'id': coverArtId,
      'v': '1.15.0',
      'size': '300',
      'c': 'otimusic',
      't': DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8),
    }).toString();
  }

  /// 生成播放链接
  String generatePlayUrl(String songId) {
    String baseUrl = _getBaseUrl();
    return Uri.parse('$baseUrl/rest/stream.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'id': songId,
      'v': '1.15.0',
      'c': 'otimusic',
    }).toString();
  }

  /// 格式化时长
  String formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 通用XML数据获取方法
  Future<List<XmlElement>> _fetchXmlData(Uri url, String parentNode, String childNode) async {
    try {
      print('[调试] 请求URL: $url');
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('服务器返回空数据');
        }
        
        XmlDocument document;
        try {
          document = XmlDocument.parse(response.body);
        } catch (e) {
          throw Exception('XML解析失败: $e，响应内容: ${response.body.substring(0, 200)}...');
        }
        
        final root = document.rootElement;
        
        if (root.getAttribute('status') == 'ok') {
          final parent = root.findElements(parentNode).firstOrNull;
          final result = parent?.findElements(childNode).toList() ?? root.findElements(childNode).toList();
          print('[调试] 成功获取 ${result.length} 条${childNode}数据');
          return result;
        } else {
          final error = root.findElements('error').firstOrNull;
          final errorCode = error?.getAttribute('code') ?? '未知错误码';
          final errorMsg = error?.getAttribute('message') ?? '未知错误';
          throw Exception('API错误（码：$errorCode）: $errorMsg');
        }
      } else {
        if (response.statusCode == 401) {
          throw Exception('认证失败，请检查用户名和密码');
        }
        throw Exception('请求失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('请求超时，请检查网络连接');
      }
      if (e.toString().contains('SocketException')) {
        throw Exception('网络错误，无法连接到服务器');
      }
      rethrow;
    }
  }

  /// 获取基础URL
  String _getBaseUrl() {
    String cleanedIpPort = ipPort.trim().replaceAll(RegExp(r'\/+$'), '');
    return cleanedIpPort.startsWith(RegExp(r'^https?://')) 
        ? cleanedIpPort 
        : 'http://$cleanedIpPort';
  }

  /// 释放资源
  void dispose() {
    _client.close();
  }
}
    