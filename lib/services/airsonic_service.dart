import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class AirsonicService {
  final String ipPort;
  final String username;
  final String password;

  AirsonicService({
    required this.ipPort,
    required this.username,
    required this.password,
  });

  /// 测试服务器连接
  Future<void> testConnection() async {
    String baseUrl = _getBaseUrl();
    Uri url = Uri.parse('$baseUrl/rest/ping.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'v': '1.15.0',
      'c': 'otimusic',
    });

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('无法连接到服务器，状态码: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final root = document.rootElement;
    
    if (root.getAttribute('status') != 'ok') {
      final error = root.findElements('error').firstOrNull;
      throw Exception('服务器连接失败: ${error?.getAttribute('message') ?? '未知错误'}');
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

  /// 获取热门播放歌曲
  Future<List<XmlElement>> getTopPlayedSongs({
    required int count,
    required String period,
  }) async {
    String baseUrl = _getBaseUrl();
    Uri url = Uri.parse('$baseUrl/rest/getTopSongs.view').replace(queryParameters: {
      'u': username,
      'p': password,
      'v': '1.15.0',
      'c': 'otimusic',
      'count': count.toString(),
      'period': period,
      'artist': '',
    });

    return await _fetchXmlData(url, 'topSongs', 'song');
  }

  /// 获取最近添加的歌曲
  Future<List<XmlElement>> getRecentAddedSongs({
    required int count,
    required List<XmlElement> recentAlbums,
  }) async {
    String baseUrl = _getBaseUrl();
    List<XmlElement> songs = [];

    for (var album in recentAlbums) {
      String albumId = album.getAttribute('id') ?? '';
      if (albumId.isEmpty) continue;

      try {
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
          if (songs.length >= count) break;
        }
      } catch (e) {
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
    return '$baseUrl/rest/getCoverArt.view?u=$username&p=$password&id=$coverArtId&v=1.15.0&size=300';
  }

  /// 生成播放链接
  String generatePlayUrl(String songId) {
    String baseUrl = _getBaseUrl();
    return '$baseUrl/rest/stream.view?u=$username&p=$password&id=$songId&v=1.15.0';
  }

  /// 格式化时长
  String formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 通用XML数据获取方法
  Future<List<XmlElement>> _fetchXmlData(Uri url, String parentNode, String childNode) async {
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final root = document.rootElement;
      
      if (root.getAttribute('status') == 'ok') {
        final parent = root.findElements(parentNode).firstOrNull;
        return parent?.findElements(childNode).toList() ?? root.findElements(childNode).toList();
      } else {
        final error = root.findElements('error').firstOrNull;
        final errorMsg = error?.getAttribute('message') ?? '未知错误';
        throw Exception('API错误: $errorMsg');
      }
    } else {
      throw Exception('请求失败，状态码: ${response.statusCode}');
    }
  }

  /// 获取基础URL
  String _getBaseUrl() {
    return ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
  }
}
