import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

void main() async {
  // 获取用户输入
  stdout.write('请输入IP和端口（例如：192.168.2.164:4040）：');
  String ipPort = stdin.readLineSync()!.trim();
  
  stdout.write('请输入用户名：');
  String username = stdin.readLineSync()!.trim();
  
  stdout.write('请输入密码：');
  String password = stdin.readLineSync()!.trim();

  try {
    // 测试服务器连接
    await testConnection(ipPort, username, password);
    
    // 1. 获取8首随机歌曲
    List<XmlElement> randomSongs = await getRandomSongs(
      ipPort: ipPort,
      username: username,
      password: password,
      count: 8
    );
    
    // 显示随机歌曲信息
    print('\n==================== 随机8首歌曲 ====================\n');
    if (randomSongs.isEmpty) {
      print('未找到任何随机歌曲');
    } else {
      for (int i = 0; i < randomSongs.length; i++) {
        printRandomSongInfo(randomSongs[i], i + 1, ipPort, username, password);
      }
    }

    // 2. 获取最近添加的专辑
    List<XmlElement> recentAlbums = await getRecentAlbums(
      ipPort: ipPort,
      username: username,
      password: password,
      count: 5
    );
    
    // 显示最近添加的专辑信息
    print('\n==================== 最近添加的专辑 ====================\n');
    if (recentAlbums.isEmpty) {
      print('未找到任何最近添加的专辑');
    } else {
      for (int i = 0; i < recentAlbums.length; i++) {
        printAlbumInfo(recentAlbums[i], i + 1, ipPort, username, password);
      }
    }

    // 3. 获取热门播放歌曲（优化：扩大时间范围+备选接口）
    List<XmlElement> topPlayedSongs = await getTopPlayedSongs(
      ipPort: ipPort,
      username: username,
      password: password,
      count: 5,
      period: 'all' // 时间范围改为"所有时间"
    );
    
    // 若热门歌曲无数据，用"最近添加的歌曲"作为备选
    if (topPlayedSongs.isEmpty) {
      print('\n[提示] 热门播放歌曲无数据，显示最近添加的歌曲...');
      topPlayedSongs = await getRecentAddedSongs(
        ipPort: ipPort,
        username: username,
        password: password,
        count: 5,
        recentAlbums: recentAlbums // 直接复用已获取的专辑列表，减少重复请求
      );
    }
    
    // 显示热门/最近添加歌曲信息
    print('\n==================== 热门/最近添加歌曲 ====================\n');
    if (topPlayedSongs.isEmpty) {
      print('未找到任何歌曲数据');
    } else {
      for (int i = 0; i < topPlayedSongs.length; i++) {
        printTopPlayedInfo(topPlayedSongs[i], i + 1, ipPort, username, password);
      }
    }

  } catch (e) {
    print('\n错误: $e');
  }
}

/// 测试服务器连接
Future<void> testConnection(String ipPort, String username, String password) async {
  String baseUrl = ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
  Uri url = Uri.parse('$baseUrl/rest/ping.view').replace(queryParameters: {
    'u': username,
    'p': password,
    'v': '1.15.0',
    'c': 'music_fetcher',
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
  
  print('✅ 服务器连接成功！API版本: ${root.getAttribute('version')}');
}

/// 1. 获取指定数量的随机歌曲
Future<List<XmlElement>> getRandomSongs({
  required String ipPort,
  required String username,
  required String password,
  required int count,
}) async {
  String baseUrl = ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
  Uri url = Uri.parse('$baseUrl/rest/getRandomSongs.view').replace(queryParameters: {
    'u': username,
    'p': password,
    'v': '1.15.0',
    'c': 'music_fetcher',
    'size': count.toString(),
  });

  return await _fetchXmlData(url, 'randomSongs', 'song');
}

/// 2. 获取最近添加的专辑
Future<List<XmlElement>> getRecentAlbums({
  required String ipPort,
  required String username,
  required String password,
  required int count,
}) async {
  String baseUrl = ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
  Uri url = Uri.parse('$baseUrl/rest/getAlbumList.view').replace(queryParameters: {
    'u': username,
    'p': password,
    'v': '1.15.0',
    'c': 'music_fetcher',
    'type': 'recent',  // 最近添加的专辑
    'size': count.toString(),
  });

  return await _fetchXmlData(url, 'albumList', 'album');
}

/// 3. 获取热门播放歌曲
Future<List<XmlElement>> getTopPlayedSongs({
  required String ipPort,
  required String username,
  required String password,
  required int count,
  required String period, // 时间范围：7d/30d/90d/1y/all
}) async {
  String baseUrl = ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
  Uri url = Uri.parse('$baseUrl/rest/getTopSongs.view').replace(queryParameters: {
    'u': username,
    'p': password,
    'v': '1.15.0',
    'c': 'music_fetcher',
    'count': count.toString(),
    'period': period,
    'artist': '', // 兼容严格模式服务器
  });

  return await _fetchXmlData(url, 'topSongs', 'song');
}

/// 备选：获取最近添加的歌曲（当热门歌曲无数据时使用）
Future<List<XmlElement>> getRecentAddedSongs({
  required String ipPort,
  required String username,
  required String password,
  required int count,
  required List<XmlElement> recentAlbums, // 传入已获取的专辑列表，避免重复请求
}) async {
  String baseUrl = ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
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
        'c': 'music_fetcher',
        'id': albumId,
      });

      List<XmlElement> albumSongs = await _fetchXmlData(songUrl, 'album', 'song');
      if (albumSongs.isNotEmpty) {
        songs.add(albumSongs.first);
        print('[调试] 从专辑ID $albumId 获取到歌曲：${albumSongs.first.getAttribute('title')}');
        if (songs.length >= count) break; // 达到数量后停止
      } else {
        print('[警告] 专辑ID $albumId 中无歌曲数据');
      }
    } catch (e) {
      // 关键修复：捕获专辑不存在的错误并跳过
      print('[警告] 处理专辑ID $albumId 时出错：$e，已跳过该专辑');
      continue;
    }
  }

  return songs;
}

/// 通用XML数据获取方法
Future<List<XmlElement>> _fetchXmlData(Uri url, String parentNode, String childNode) async {
  print('\n[调试] 请求URL: $url');
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final document = XmlDocument.parse(response.body);
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
    throw Exception('请求失败，状态码: ${response.statusCode}，响应内容: ${response.body.substring(0, 200)}...');
  }
}

/// 显示随机歌曲信息
void printRandomSongInfo(XmlElement song, int index, String ipPort, String username, String password) {
  String title = song.getAttribute('title') ?? '未知标题';
  String artist = song.getAttribute('artist') ?? '未知歌手';
  String coverArt = song.getAttribute('coverArt') ?? '';
  
  print('$index. 歌曲名: $title');
  print('   歌手: $artist');
  print('   封面URL: ${getCoverArtUrl(ipPort, username, password, coverArt)}');
  print('   --------------------------------------------------');
}

/// 显示专辑信息
void printAlbumInfo(XmlElement album, int index, String ipPort, String username, String password) {
  String albumName = album.getAttribute('name') ?? 
                     album.getAttribute('album') ?? 
                     '未知专辑(${album.getAttribute('id') ?? '无ID'})';
  String artist = album.getAttribute('artist') ?? '未知歌手';
  String year = album.getAttribute('year') ?? '未知年份';
  String coverArt = album.getAttribute('coverArt') ?? '';
  String albumId = album.getAttribute('id') ?? '无ID'; // 显示专辑ID，便于调试
  
  print('$index. 专辑名: $albumName (ID: $albumId)');
  print('   歌手: $artist');
  print('   年份: $year');
  print('   专辑图URL: ${getCoverArtUrl(ipPort, username, password, coverArt)}');
  print('   --------------------------------------------------');
}

/// 显示热门/最近添加歌曲信息
void printTopPlayedInfo(XmlElement song, int index, String ipPort, String username, String password) {
  String title = song.getAttribute('title') ?? '未知标题';
  String artist = song.getAttribute('artist') ?? '未知歌手';
  String coverArt = song.getAttribute('coverArt') ?? '';
  String playCount = song.getAttribute('playCount') ?? '0';
  
  print('$index. 歌曲名: $title');
  print('   歌手: $artist');
  print('   播放次数: $playCount次');
  print('   封面URL: ${getCoverArtUrl(ipPort, username, password, coverArt)}');
  print('   --------------------------------------------------');
}

/// 获取封面图片URL
String getCoverArtUrl(String ipPort, String username, String password, String coverArtId) {
  if (coverArtId.isEmpty || coverArtId == 'null') {
    return '无封面（建议用默认图片替代）';
  }
  
  String baseUrl = ipPort.startsWith(RegExp(r'^https?://')) ? ipPort : 'http://$ipPort';
  return '$baseUrl/rest/getCoverArt.view?u=$username&p=$password&id=$coverArtId&v=1.15.0&size=300';
}
